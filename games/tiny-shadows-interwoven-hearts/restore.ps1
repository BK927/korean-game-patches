# Tiny Shadows Interwoven Hearts Korean recovery restore helper.
# -GameRoot may be either the Steam game directory or its `game` subdirectory.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$StateName = '.tiny-shadows-korean-recovery-state.json'

function Resolve-SafePath([string]$Base, [string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative)) { throw "Unsafe state path: $Relative" }
    $baseFull = [IO.Path]::GetFullPath($Base).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $full = [IO.Path]::GetFullPath([IO.Path]::Combine($Base, $Relative))
    if (-not $full.StartsWith($baseFull, [StringComparison]::OrdinalIgnoreCase)) { throw "State path escapes its root: $Relative" }
    return $full
}

function Resolve-GameDirectory([string]$Root) {
    $rootFull = [IO.Path]::GetFullPath($Root)
    $nested = Join-Path $rootFull 'game'
    if (Test-Path -LiteralPath (Join-Path $nested 'scripts.rpa') -PathType Leaf) { return $nested }
    if (Test-Path -LiteralPath (Join-Path $rootFull 'scripts.rpa') -PathType Leaf) { return $rootFull }
    throw "Could not find game/scripts.rpa below GameRoot: $Root"
}

function Get-Sha256([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant() }
function Write-JsonAtomic($Value, [string]$Path) {
    $temp = "$Path.tmp.$PID"
    try { $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temp -Encoding UTF8; Move-Item -LiteralPath $temp -Destination $Path -Force }
    finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
}

function Test-RecoveryGeneratedSidecar($Entry, [string]$Target) {
    # Ren'Py recompiles loose .rpy files on first launch.  Those cache files
    # are safe to discard during restore only when their source is one of the
    # installer payloads and still has the recorded installed hash.
    if (-not ([string]$Entry.path).ToLowerInvariant().EndsWith('.rpyc')) { return $false }
    $sourceRelative = [IO.Path]::ChangeExtension([string]$Entry.path, '.rpy')
    $sourceEntry = @($state.entries | Where-Object { [string]$_.action -eq 'replace' -and [string]$_.path -eq $sourceRelative })
    if ($sourceEntry.Count -ne 1) { return $false }
    $sourceTarget = Resolve-SafePath $GameDir $sourceRelative
    if (-not (Test-Path -LiteralPath $sourceTarget -PathType Leaf)) { return $false }
    return (Get-Sha256 $sourceTarget) -eq ([string]$sourceEntry[0].installed_sha256).ToUpperInvariant()
}

if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) { throw "GameRoot does not exist: $GameRoot" }
$GameDir = Resolve-GameDirectory $GameRoot
$StatePath = Join-Path $GameDir $StateName
if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) { throw "Recovery state not found: $StatePath" }
$state = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($state.format -ne 'tiny-shadows-korean-recovery-state/v1' -or $state.status -ne 'installed') { throw 'State is not an installed recovery state.' }
$backupParent = Split-Path -Parent $GameDir
$backupRoot = Resolve-SafePath $backupParent ([string]$state.backup_root)

# Verify all backups and all installed targets before touching anything.
foreach ($entry in @($state.entries)) {
    $target = Resolve-SafePath $GameDir ([string]$entry.path)
    if ([bool]$entry.original_exists) {
        $backup = Resolve-SafePath $backupRoot ([string]$entry.backup_relative)
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) { throw "Backup is missing: $($entry.path)" }
        if ((Get-Sha256 $backup) -ne ([string]$entry.original_sha256).ToUpperInvariant()) { throw "Backup hash mismatch: $($entry.path)" }
    }
    if ([string]$entry.action -eq 'replace') {
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Installed target is missing: $($entry.path)" }
        if ((Get-Sha256 $target) -ne ([string]$entry.installed_sha256).ToUpperInvariant()) { throw "Installed target was modified; refusing to restore: $($entry.path)" }
    } elseif ([string]$entry.action -eq 'remove') {
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            if (-not (Test-RecoveryGeneratedSidecar $entry $target)) {
                throw "Removed legacy target reappeared; refusing to restore: $($entry.path)"
            }
        } elseif (Test-Path -LiteralPath $target) {
            throw "Removed legacy target is not a regular file: $($entry.path)"
        }
    } else { throw "Unknown state action: $($entry.action)" }
}

foreach ($entry in @($state.entries)) {
    $target = Resolve-SafePath $GameDir ([string]$entry.path)
    if ([bool]$entry.original_exists) {
        $backup = Resolve-SafePath $backupRoot ([string]$entry.backup_relative)
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        $temp = "$target.tiny-shadows.restore.$PID"
        try {
            Copy-Item -LiteralPath $backup -Destination $temp -Force
            if ((Get-Sha256 $temp) -ne ([string]$entry.original_sha256).ToUpperInvariant()) { throw "Temporary restore verification failed: $($entry.path)" }
            Move-Item -LiteralPath $temp -Destination $target -Force
            if ((Get-Sha256 $target) -ne ([string]$entry.original_sha256).ToUpperInvariant()) { throw "Restored target verification failed: $($entry.path)" }
        } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
    } elseif (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Force
        if (Test-Path -LiteralPath $target) { throw "Removal of new target failed: $($entry.path)" }
    }
}

$state.status = 'restored'
$state | Add-Member -NotePropertyName restored_utc -NotePropertyValue ((Get-Date).ToUniversalTime().ToString('o')) -Force
Write-JsonAtomic $state $StatePath
Write-Output "Restored original files. Backup retained at $backupRoot"
