[CmdletBinding()]
param(
    [string]$CodexHome,
    [switch]$SkipConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$PolicySource = Join-Path $RepoRoot "AGENTS.md"
$StartMarker = "<!-- BEGIN SHARED CODEX ROUTING POLICY -->"
$EndMarker = "<!-- END SHARED CODEX ROUTING POLICY -->"
$Utf8NoBom = New-Object System.Text.UTF8Encoding -ArgumentList $false
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Backups = New-Object System.Collections.Generic.List[string]
$Changed = New-Object System.Collections.Generic.List[string]

if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        $CodexHome = $env:CODEX_HOME
    }
    else {
        $CodexHome = Join-Path $HOME ".codex"
    }
}

$CodexHome = [System.IO.Path]::GetFullPath($CodexHome)
New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $Parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($Parent)) {
        New-Item -ItemType Directory -Force -Path $Parent | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Backup-ExistingFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $BackupPath = "$Path.backup-$Timestamp"
    $Counter = 1
    while (Test-Path -LiteralPath $BackupPath) {
        $BackupPath = "$Path.backup-$Timestamp-$Counter"
        $Counter++
    }

    Copy-Item -LiteralPath $Path -Destination $BackupPath
    $Backups.Add($BackupPath)
    return $BackupPath
}

function Get-ManagedPolicyBlock {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Policy source does not exist: $Path"
    }

    $Text = [System.IO.File]::ReadAllText($Path)
    $Start = $Text.IndexOf($StartMarker, [System.StringComparison]::Ordinal)
    $End = $Text.IndexOf($EndMarker, [System.StringComparison]::Ordinal)

    if ($Start -lt 0 -or $End -lt $Start) {
        throw "Managed policy markers are missing or invalid in $Path"
    }

    $End += $EndMarker.Length
    return $Text.Substring($Start, $End - $Start).Trim() + [Environment]::NewLine
}

function Merge-ManagedPolicy {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$Block
    )

    $OriginalExists = Test-Path -LiteralPath $TargetPath -PathType Leaf
    $Original = if ($OriginalExists) {
        [System.IO.File]::ReadAllText($TargetPath)
    }
    else {
        ""
    }

    $Start = $Original.IndexOf($StartMarker, [System.StringComparison]::Ordinal)
    $End = $Original.IndexOf($EndMarker, [System.StringComparison]::Ordinal)

    if ($Start -ge 0 -and $End -ge $Start) {
        $End += $EndMarker.Length
        $Updated = $Original.Substring(0, $Start) + $Block.TrimEnd() + $Original.Substring($End)
    }
    elseif ($Start -ge 0 -or $End -ge 0) {
        throw "Only one routing-policy marker exists in $TargetPath; repair it manually before installing."
    }
    elseif ([string]::IsNullOrWhiteSpace($Original)) {
        $Updated = $Block
    }
    else {
        $Updated = $Original.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $Block
    }

    if ($Updated -ne $Original) {
        if ($OriginalExists) {
            Backup-ExistingFile -Path $TargetPath | Out-Null
        }
        Write-Utf8NoBom -Path $TargetPath -Content $Updated
        $Changed.Add($TargetPath)
    }
}

function Find-FirstTomlTableIndex {
    param([string[]]$Lines)

    for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
        if ($Lines[$Index] -match '^\s*\[[^\]]+\]\s*(?:#.*)?$') {
            return $Index
        }
    }

    return $Lines.Count
}

function Set-TopLevelTomlString {
    param(
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[string]]$Lines,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $FirstTable = Find-FirstTomlTableIndex -Lines $Lines.ToArray()
    $Pattern = '^\s*' + [regex]::Escape($Key) + '\s*='

    for ($Index = 0; $Index -lt $FirstTable; $Index++) {
        if ($Lines[$Index] -match $Pattern) {
            $Lines[$Index] = "$Key = `"$Value`""
            return
        }
    }

    $Lines.Insert($FirstTable, "$Key = `"$Value`"")
}

function Remove-TopLevelFastTier {
    param([Parameter(Mandatory = $true)][System.Collections.Generic.List[string]]$Lines)

    $FirstTable = Find-FirstTomlTableIndex -Lines $Lines.ToArray()
    for ($Index = $FirstTable - 1; $Index -ge 0; $Index--) {
        if ($Lines[$Index] -match '^\s*service_tier\s*=\s*["'']fast["'']\s*(?:#.*)?$') {
            $Lines.RemoveAt($Index)
        }
    }
}

function Test-TomlFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $ValidationCode = "import sys; import tomllib; tomllib.load(open(sys.argv[1], 'rb'))"

    if (Get-Command python -ErrorAction SilentlyContinue) {
        & python -c $ValidationCode $Path
        if ($LASTEXITCODE -ne 0) {
            throw "TOML validation failed: $Path"
        }
        return
    }

    if (Get-Command py -ErrorAction SilentlyContinue) {
        & py -3 -c $ValidationCode $Path
        if ($LASTEXITCODE -ne 0) {
            throw "TOML validation failed: $Path"
        }
        return
    }

    Write-Warning "Python 3.11+ was not found; config.toml could not be parsed with tomllib."
}

$PolicyBlock = Get-ManagedPolicyBlock -Path $PolicySource
$GlobalAgents = Join-Path $CodexHome "AGENTS.md"
Merge-ManagedPolicy -TargetPath $GlobalAgents -Block $PolicyBlock

$GlobalOverride = Join-Path $CodexHome "AGENTS.override.md"
if ((Test-Path -LiteralPath $GlobalOverride -PathType Leaf) -and
    ((Get-Item -LiteralPath $GlobalOverride).Length -gt 0)) {
    Merge-ManagedPolicy -TargetPath $GlobalOverride -Block $PolicyBlock
}

if (-not $SkipConfig) {
    $ConfigPath = Join-Path $CodexHome "config.toml"
    $ConfigExisted = Test-Path -LiteralPath $ConfigPath -PathType Leaf
    $OriginalConfig = if ($ConfigExisted) {
        [System.IO.File]::ReadAllText($ConfigPath)
    }
    else {
        ""
    }

    $NewLine = if ($OriginalConfig.Contains("`r`n")) { "`r`n" } else { "`n" }
    $RawLines = [regex]::Split($OriginalConfig, '\r?\n')
    $Lines = New-Object 'System.Collections.Generic.List[string]'
    foreach ($Line in $RawLines) {
        $Lines.Add($Line)
    }

    while ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -eq "") {
        $Lines.RemoveAt($Lines.Count - 1)
    }

    Set-TopLevelTomlString -Lines $Lines -Key "model" -Value "gpt-5.6-sol"
    Set-TopLevelTomlString -Lines $Lines -Key "model_reasoning_effort" -Value "high"
    Remove-TopLevelFastTier -Lines $Lines

    $UpdatedConfig = [string]::Join($NewLine, $Lines.ToArray()).TrimEnd() + $NewLine

    if ($UpdatedConfig -ne $OriginalConfig) {
        $ConfigBackup = if ($ConfigExisted) {
            Backup-ExistingFile -Path $ConfigPath
        }
        else {
            $null
        }

        try {
            Write-Utf8NoBom -Path $ConfigPath -Content $UpdatedConfig
            Test-TomlFile -Path $ConfigPath
            $Changed.Add($ConfigPath)
        }
        catch {
            if ($null -ne $ConfigBackup) {
                Copy-Item -LiteralPath $ConfigBackup -Destination $ConfigPath -Force
            }
            elseif (Test-Path -LiteralPath $ConfigPath) {
                Remove-Item -LiteralPath $ConfigPath -Force
            }
            throw
        }
    }
    else {
        Test-TomlFile -Path $ConfigPath
    }
}

Write-Host "Codex routing rules installed."
Write-Host "CODEX_HOME: $CodexHome"
Write-Host "Primary model: gpt-5.6-sol / high"
Write-Host "Worker model policy: gpt-5.6-luna / max through the existing CLI/thread runner"

if ($Changed.Count -eq 0) {
    Write-Host "Changed files: none (already up to date)"
}
else {
    Write-Host "Changed files:"
    foreach ($Path in $Changed) {
        Write-Host "  - $Path"
    }
}

if ($Backups.Count -gt 0) {
    Write-Host "Backups:"
    foreach ($Path in $Backups) {
        Write-Host "  - $Path"
    }
}

Write-Host "Restart Codex sessions to load the updated global instructions."
