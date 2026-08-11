[CmdletBinding()]
param(
    [string]$CodexHome,
    [switch]$SkipConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required to update the routing-rules repository."
}

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot ".git"))) {
    throw "This script must be run from a Git clone of codex-routing-rules: $RepoRoot"
}

$Dirty = & git -C $RepoRoot status --porcelain
if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect Git status for $RepoRoot"
}

if (-not [string]::IsNullOrWhiteSpace(($Dirty -join "`n"))) {
    throw "The routing-rules clone has uncommitted changes. Commit or discard them before updating.`n$($Dirty -join "`n")"
}

Write-Host "Updating shared Codex routing rules..."
& git -C $RepoRoot pull --ff-only
if ($LASTEXITCODE -ne 0) {
    throw "git pull --ff-only failed."
}

$Installer = Join-Path $PSScriptRoot "install.ps1"
$Arguments = @{}
if (-not [string]::IsNullOrWhiteSpace($CodexHome)) {
    $Arguments["CodexHome"] = $CodexHome
}
if ($SkipConfig) {
    $Arguments["SkipConfig"] = $true
}

& $Installer @Arguments
