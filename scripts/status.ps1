[CmdletBinding()]
param(
    [string]$CodexHome
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$StartMarker = "<!-- BEGIN SHARED CODEX ROUTING POLICY -->"
$EndMarker = "<!-- END SHARED CODEX ROUTING POLICY -->"

if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        $CodexHome = $env:CODEX_HOME
    }
    else {
        $CodexHome = Join-Path $HOME ".codex"
    }
}

$CodexHome = [System.IO.Path]::GetFullPath($CodexHome)
$ConfigPath = Join-Path $CodexHome "config.toml"
$AgentsPath = Join-Path $CodexHome "AGENTS.md"
$OverridePath = Join-Path $CodexHome "AGENTS.override.md"

function Test-ManagedBlock {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    $Text = [System.IO.File]::ReadAllText($Path)
    return $Text.Contains($StartMarker) -and $Text.Contains($EndMarker)
}

function Get-TopLevelTomlValue {
    param(
        [string]$Path,
        [string]$Key
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $Lines = [System.IO.File]::ReadAllLines($Path)
    $Pattern = '^\s*' + [regex]::Escape($Key) + '\s*=\s*["'']([^"'']+)["'']'

    foreach ($Line in $Lines) {
        if ($Line -match '^\s*\[\[?.+\]\]?\s*(?:#.*)?$') {
            break
        }
        if ($Line -match $Pattern) {
            return $Matches[1]
        }
    }

    return $null
}

$Commit = "unknown"
if (Get-Command git -ErrorAction SilentlyContinue) {
    $CommitOutput = & git -C $RepoRoot rev-parse --short HEAD 2>$null
    if ($LASTEXITCODE -eq 0) {
        $Commit = ($CommitOutput | Select-Object -First 1).Trim()
    }
}

$CodexVersion = "not found"
if (Get-Command codex -ErrorAction SilentlyContinue) {
    $VersionOutput = & codex --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $CodexVersion = ($VersionOutput | Select-Object -First 1).Trim()
    }
}

$Model = Get-TopLevelTomlValue -Path $ConfigPath -Key "model"
$Effort = Get-TopLevelTomlValue -Path $ConfigPath -Key "model_reasoning_effort"
$Tier = Get-TopLevelTomlValue -Path $ConfigPath -Key "service_tier"

Write-Host "Shared routing repository: $RepoRoot"
Write-Host "Repository commit: $Commit"
Write-Host "CODEX_HOME: $CodexHome"
Write-Host "Codex version: $CodexVersion"
Write-Host "Primary model: $Model"
Write-Host "Reasoning effort: $Effort"
Write-Host "Service tier override: $(if ($null -eq $Tier) { '<none>' } else { $Tier })"
Write-Host "AGENTS.md policy installed: $(Test-ManagedBlock -Path $AgentsPath)"

if ((Test-Path -LiteralPath $OverridePath -PathType Leaf) -and
    ((Get-Item -LiteralPath $OverridePath).Length -gt 0)) {
    Write-Host "AGENTS.override.md policy installed: $(Test-ManagedBlock -Path $OverridePath)"
}
else {
    Write-Host "AGENTS.override.md: <not active>"
}

$Healthy = ($Model -eq "gpt-5.6-sol") -and
           ($Effort -eq "high") -and
           ($Tier -ne "fast") -and
           (Test-ManagedBlock -Path $AgentsPath)

if ($Healthy) {
    Write-Host "Status: OK — Sol High main, Luna Max worker policy installed."
    exit 0
}

Write-Warning "Status: routing installation is incomplete or differs from the repository policy."
exit 1
