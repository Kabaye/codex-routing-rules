[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
    [string[]] $Prompt,

    [string] $PromptFile,

    [string] $Cwd = (Get-Location).ProviderPath,

    [string] $Name = "luna-subagent",

    [ValidateSet("default", "explorer", "worker", "advisor", "verifier")]
    [string] $Role = "default",

    [ValidateSet("read-only", "workspace-write", "danger-full-access")]
    [string] $Sandbox = "read-only",

    [ValidateSet("low", "medium", "high", "xhigh", "max")]
    [string] $Reasoning = "max",

    [string] $Model = "gpt-5.6-luna",

    [string] $OutDir,

    [string] $ServiceTier,

    [switch] $Background,

    [string] $WaitRun,

    [ValidateRange(0, 86400)]
    [int] $TimeoutSeconds = 7200,

    [ValidateRange(1, 60)]
    [int] $WaitIntervalSeconds = 2,

    [switch] $Json,

    [switch] $SkipGitRepoCheck,

    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

function ConvertTo-SafeName {
    param([string] $Value)

    $safe = ($Value -replace "[^A-Za-z0-9_.-]", "-").Trim("-")
    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "luna-subagent"
    }
    return $safe
}

function ConvertTo-DisplayArgument {
    param([string] $Value)

    if ($Value -notmatch "[\s`"']") {
        return $Value
    }

    return "'" + ($Value -replace "'", "''") + "'"
}

function ConvertTo-PowerShellLiteral {
    param([string] $Value)

    return "'" + ($Value -replace "'", "''") + "'"
}

function Get-RequestedPrompt {
    $parts = New-Object System.Collections.Generic.List[string]

    if ($PromptFile) {
        if (-not (Test-Path -LiteralPath $PromptFile -PathType Leaf)) {
            throw "Prompt file not found: $PromptFile"
        }
        [void] $parts.Add((Get-Content -LiteralPath $PromptFile -Raw))
    }

    if ($Prompt -and $Prompt.Count -gt 0) {
        [void] $parts.Add(($Prompt -join " "))
    }

    $rawPrompt = ($parts -join ([Environment]::NewLine + [Environment]::NewLine)).Trim()
    if ([string]::IsNullOrWhiteSpace($rawPrompt)) {
        throw "Provide a prompt as arguments, with -PromptFile, or through stdin."
    }

    return $rawPrompt
}

function Get-RunStatus {
    param([string] $StatusPath)

    if (-not (Test-Path -LiteralPath $StatusPath -PathType Leaf)) {
        return $null
    }

    try {
        return (Get-Content -LiteralPath $StatusPath -Raw | ConvertFrom-Json)
    }
    catch {
        return $null
    }
}

function Test-TerminalState {
    param([string] $State)

    return $State -in @("DECISION_REQUIRED", "COMPLETED", "FAILED")
}

function Wait-LunaRun {
    param(
        [Parameter(Mandatory = $true)][string] $RunDir,
        [int] $Timeout,
        [int] $Interval
    )

    $resolvedRunDir = (Resolve-Path -LiteralPath $RunDir).ProviderPath
    $runMetadataPath = Join-Path $resolvedRunDir "run.json"
    $statusPath = Join-Path $resolvedRunDir "status.json"
    $lastMessagePath = Join-Path $resolvedRunDir "last-message.md"
    $consoleLogPath = Join-Path $resolvedRunDir "console.log"

    if (-not (Test-Path -LiteralPath $runMetadataPath -PathType Leaf)) {
        throw "Run metadata not found: $runMetadataPath"
    }

    $runMetadata = Get-Content -LiteralPath $runMetadataPath -Raw | ConvertFrom-Json
    $childPid = [int] $runMetadata.Pid
    $startedWaiting = Get-Date
    $timedOut = $false

    while ($true) {
        $status = Get-RunStatus -StatusPath $statusPath
        if ($null -ne $status -and (Test-TerminalState -State ([string] $status.State))) {
            break
        }

        $childProcess = Get-Process -Id $childPid -ErrorAction SilentlyContinue
        if ($null -eq $childProcess) {
            break
        }

        if ($Timeout -gt 0 -and ((Get-Date) - $startedWaiting).TotalSeconds -ge $Timeout) {
            $timedOut = $true
            break
        }

        Start-Sleep -Seconds $Interval
    }

    if ($timedOut) {
        [pscustomobject] @{
            State = "TIMEOUT"
            Pid = $childPid
            RunDir = $resolvedRunDir
            Status = $statusPath
            LastMessage = $lastMessagePath
            ConsoleLog = $consoleLogPath
        } | Format-List
        return
    }

    # Give the background process a short chance to flush final status after exit.
    $status = $null
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        $status = Get-RunStatus -StatusPath $statusPath
        if ($null -ne $status -and (Test-TerminalState -State ([string] $status.State))) {
            break
        }
        Start-Sleep -Milliseconds 100
    }

    $lastMessage = if (Test-Path -LiteralPath $lastMessagePath -PathType Leaf) {
        Get-Content -LiteralPath $lastMessagePath -Raw
    }
    else {
        ""
    }

    if ($null -eq $status -or -not (Test-TerminalState -State ([string] $status.State))) {
        $inferredState = if (-not [string]::IsNullOrWhiteSpace($lastMessage)) {
            if ($lastMessage -match '(?im)^\s*DECISION REQUIRED\b') {
                "DECISION_REQUIRED"
            }
            else {
                "COMPLETED"
            }
        }
        else {
            "FAILED"
        }

        $status = [pscustomobject] @{
            State = $inferredState
            ExitCode = $null
            Error = if ($inferredState -eq "FAILED") { "Background process exited without a final status or last-message.md." } else { $null }
        }
    }

    [pscustomobject] @{
        State = [string] $status.State
        ExitCode = $status.ExitCode
        Pid = $childPid
        RunDir = $resolvedRunDir
        LastMessage = $lastMessagePath
        ConsoleLog = $consoleLogPath
        Error = $status.Error
    } | Format-List

    if (-not [string]::IsNullOrWhiteSpace($lastMessage)) {
        Write-Output ""
        Write-Output "Luna result:"
        Write-Output $lastMessage.TrimEnd()
        return
    }

    if ([string] $status.State -eq "FAILED" -and (Test-Path -LiteralPath $consoleLogPath -PathType Leaf)) {
        Write-Output ""
        Write-Output "No last-message.md was produced. Last 80 console lines:"
        Get-Content -LiteralPath $consoleLogPath -Tail 80
    }
}

if (-not [string]::IsNullOrWhiteSpace($WaitRun)) {
    Wait-LunaRun -RunDir $WaitRun -Timeout $TimeoutSeconds -Interval $WaitIntervalSeconds
    return
}

$codex = Get-Command codex -ErrorAction Stop
$resolvedCwd = (Resolve-Path -LiteralPath $Cwd).ProviderPath
$safeName = ConvertTo-SafeName $Name
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $resolvedCwd "temp\codex-subagents"
}

$runDir = Join-Path $OutDir "$stamp-$safeName"
$promptPath = Join-Path $runDir "prompt.md"
$lastMessagePath = Join-Path $runDir "last-message.md"
$consoleLogPath = Join-Path $runDir "console.log"
$commandPath = Join-Path $runDir "command.txt"
$statusPath = Join-Path $runDir "status.json"
$runMetadataPath = Join-Path $runDir "run.json"

New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$requestedPrompt = Get-RequestedPrompt
$wrappedPrompt = @"
You are a CLI-backed Luna Max Codex subagent launched by a parent Codex task.

Global routing policy:
- Native multi-agent tools are disabled. Do not use spawn_agent, wait_agent, send_input, fork_thread, or any other native subagent mechanism.
- Do not spawn nested agents.
- Keep work scoped to this delegated task.
- If edits are requested, do not revert unrelated changes. State exactly which files you changed and which checks you ran.
- Return a concise final answer for the parent agent to integrate.
- If stronger parent judgment is required, stop and begin the final answer with `DECISION REQUIRED` followed by the concrete decision, evidence, options, and recommendation.

Subagent metadata:
- Name: $Name
- Role: $Role
- Working directory: $resolvedCwd
- Sandbox: $Sandbox

Assigned task:
$requestedPrompt
"@

Set-Content -LiteralPath $promptPath -Value $wrappedPrompt -Encoding UTF8

$codexArgs = @(
    "exec",
    "--model", $Model,
    "-C", $resolvedCwd,
    "--sandbox", $Sandbox,
    "-c", "model_reasoning_effort=`"$Reasoning`"",
    "-c", "agents.enabled=false",
    "-o", $lastMessagePath
)

if (-not [string]::IsNullOrWhiteSpace($ServiceTier)) {
    $codexArgs += @("-c", "service_tier=`"$ServiceTier`"")
}

if ($Json) {
    $codexArgs += "--json"
}

if ($SkipGitRepoCheck) {
    $codexArgs += "--skip-git-repo-check"
}

$codexArgs += "-"

$displayCommand = @($codex.Source) + ($codexArgs | ForEach-Object { ConvertTo-DisplayArgument $_ })
Set-Content -LiteralPath $commandPath -Value ($displayCommand -join " ") -Encoding UTF8

if ($DryRun) {
    [pscustomobject] @{
        Mode = if ($Background) { "background" } else { "foreground" }
        Model = $Model
        Reasoning = $Reasoning
        Sandbox = $Sandbox
        Role = $Role
        Cwd = $resolvedCwd
        RunDir = $runDir
        Prompt = $promptPath
        LastMessage = $lastMessagePath
        ConsoleLog = $consoleLogPath
        Status = $statusPath
        Command = $commandPath
    } | Format-List
    return
}

if ($Background) {
    $argsLiteral = "@(" + (($codexArgs | ForEach-Object { ConvertTo-PowerShellLiteral $_ }) -join ", ") + ")"
    $runner = @"
`$ErrorActionPreference = 'Stop'
`$startedAtUtc = [DateTime]::UtcNow.ToString('o')
`$statusPath = $(ConvertTo-PowerShellLiteral $statusPath)
`$lastMessagePath = $(ConvertTo-PowerShellLiteral $lastMessagePath)
`$consoleLogPath = $(ConvertTo-PowerShellLiteral $consoleLogPath)

[ordered]@{
    State = 'RUNNING'
    Pid = `$PID
    StartedAtUtc = `$startedAtUtc
    EndedAtUtc = `$null
    ExitCode = `$null
    Error = `$null
} | ConvertTo-Json | Set-Content -LiteralPath `$statusPath -Encoding UTF8

`$exitCode = 1
`$errorText = `$null

try {
    `$prompt = Get-Content -LiteralPath $(ConvertTo-PowerShellLiteral $promptPath) -Raw
    `$codex = $(ConvertTo-PowerShellLiteral $codex.Source)
    `$codexArgs = $argsLiteral
    `$prompt | & `$codex @codexArgs 2>&1 | Tee-Object -FilePath `$consoleLogPath
    `$exitCode = `$LASTEXITCODE
}
catch {
    `$errorText = `$_.Exception.Message
    "Wrapper failure: `$errorText" | Add-Content -LiteralPath `$consoleLogPath -Encoding UTF8
    `$exitCode = 1
}

`$state = if (`$exitCode -eq 0) { 'COMPLETED' } else { 'FAILED' }
if (`$exitCode -eq 0) {
    if (Test-Path -LiteralPath `$lastMessagePath -PathType Leaf) {
        `$last = Get-Content -LiteralPath `$lastMessagePath -Raw
        if (`$last -match '(?im)^\s*DECISION REQUIRED\b') {
            `$state = 'DECISION_REQUIRED'
        }
    }
    else {
        `$state = 'FAILED'
        `$errorText = 'codex exec exited successfully but last-message.md was not produced.'
        `$exitCode = 2
    }
}

[ordered]@{
    State = `$state
    Pid = `$PID
    StartedAtUtc = `$startedAtUtc
    EndedAtUtc = [DateTime]::UtcNow.ToString('o')
    ExitCode = `$exitCode
    Error = `$errorText
} | ConvertTo-Json | Set-Content -LiteralPath `$statusPath -Encoding UTF8

exit `$exitCode
"@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($runner))
    $powershell = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $powershell) {
        $powershell = Get-Command powershell -ErrorAction Stop
    }

    $process = Start-Process -FilePath $powershell.Source -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-EncodedCommand", $encoded
    ) -WindowStyle Hidden -PassThru

    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    else {
        $MyInvocation.MyCommand.Path
    }

    $waitCommand = "& " + (ConvertTo-PowerShellLiteral $scriptPath) +
        " -WaitRun " + (ConvertTo-PowerShellLiteral $runDir) +
        " -TimeoutSeconds 7200"

    [ordered] @{
        Pid = $process.Id
        RunDir = $runDir
        Prompt = $promptPath
        ConsoleLog = $consoleLogPath
        LastMessage = $lastMessagePath
        Status = $statusPath
        Command = $commandPath
        WaitCommand = $waitCommand
    } | ConvertTo-Json | Set-Content -LiteralPath $runMetadataPath -Encoding UTF8

    [pscustomobject] @{
        Pid = $process.Id
        RunDir = $runDir
        Prompt = $promptPath
        ConsoleLog = $consoleLogPath
        LastMessage = $lastMessagePath
        Status = $statusPath
        Command = $commandPath
        WaitCommand = $waitCommand
    } | Format-List
    return
}

$promptText = Get-Content -LiteralPath $promptPath -Raw
$promptText | & $codex.Source @codexArgs 2>&1 | Tee-Object -FilePath $consoleLogPath
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    throw "codex exec failed with exit code $exitCode. See $consoleLogPath"
}

Write-Output ""
Write-Output "Luna subagent completed."
Write-Output "RunDir: $runDir"
Write-Output "LastMessage: $lastMessagePath"
