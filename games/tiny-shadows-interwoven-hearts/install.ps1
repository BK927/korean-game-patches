# Tiny Shadows Interwoven Hearts Korean recovery installer.
# -GameRoot may be either the Steam game directory or its `game` subdirectory.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$PackageRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $MyInvocation.MyCommand.Path)).Path
$ManifestPath = Join-Path $PackageRoot 'manifest.json'
$StateName = '.tiny-shadows-korean-recovery-state.json'

function Resolve-SafePath([string]$Base, [string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative)) {
        throw "Manifest path is not a safe relative path: $Relative"
    }
    $baseFull = [IO.Path]::GetFullPath($Base).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $full = [IO.Path]::GetFullPath([IO.Path]::Combine($Base, $Relative))
    if (-not $full.StartsWith($baseFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Manifest path escapes its root: $Relative"
    }
    return $full
}

function Resolve-GameDirectory([string]$Root) {
    $rootFull = [IO.Path]::GetFullPath($Root)
    $nested = Join-Path $rootFull 'game'
    if (Test-Path -LiteralPath (Join-Path $nested 'scripts.rpa') -PathType Leaf) { return $nested }
    if (Test-Path -LiteralPath (Join-Path $rootFull 'scripts.rpa') -PathType Leaf) { return $rootFull }
    throw "Could not find game/scripts.rpa below GameRoot: $Root"
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Write-JsonAtomic($Value, [string]$Path) {
    $temp = "$Path.tmp.$PID"
    try {
        $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temp -Encoding UTF8
        Move-Item -LiteralPath $temp -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
    }
}

if (-not (Test-Path -LiteralPath $GameRoot -PathType Container)) {
    throw "GameRoot does not exist or is not a directory: $GameRoot"
}
$GameRoot = [IO.Path]::GetFullPath($GameRoot)
$GameDir = Resolve-GameDirectory $GameRoot
$StatePath = Join-Path $GameDir $StateName
if (Test-Path -LiteralPath $StatePath) {
    $existingState = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($existingState.format -ne 'tiny-shadows-korean-recovery-state/v1' -or $existingState.status -ne 'restored') {
        throw "A non-restored recovery state already exists. Restore it first or inspect it: $StatePath"
    }
}
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($Manifest.format -ne 'tiny-shadows-korean-recovery/v1') { throw 'Unsupported manifest format.' }

$replacePlan = @()
$removePlan = @()

# Complete preflight: validate every payload hash and every existing target
# before creating a backup or changing the installation.
foreach ($entry in @($Manifest.files)) {
    $target = Resolve-SafePath $GameDir ([string]$entry.path)
    $payload = Resolve-SafePath $PackageRoot ([string]$entry.patch)
    if (-not (Test-Path -LiteralPath $payload -PathType Leaf)) { throw "Missing payload: $payload" }
    $payloadHash = Get-Sha256 $payload
    if ($payloadHash -ne ([string]$entry.sha256).ToUpperInvariant()) { throw "Payload hash mismatch: $payload" }
    $exists = Test-Path -LiteralPath $target
    if ($exists -and -not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Target is not a regular file: $target" }
    $beforeHash = $null
    if ($exists) {
        $beforeHash = Get-Sha256 $target
        $allowed = @($entry.allowed_base_sha256 | ForEach-Object { [string]$_ } | Where-Object { $_ })
        if ($allowed -notcontains $beforeHash) {
            throw "Unexpected existing target hash; refusing to overwrite: $target ($beforeHash)"
        }
    } elseif (-not [bool]$entry.base_missing_allowed) {
        throw "Required base target is missing: $target"
    }
    $replacePlan += [pscustomobject]@{ kind = 'replace'; path = [string]$entry.path; target = $target; payload = $payload; payload_hash = $payloadHash; original_exists = [bool]$exists; original_hash = $beforeHash }
}

foreach ($entry in @($Manifest.remove)) {
    $target = Resolve-SafePath $GameDir ([string]$entry.path)
    $exists = Test-Path -LiteralPath $target
    if ($exists -and -not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Removal target is not a regular file: $target" }
    $beforeHash = $null
    if ($exists) {
        if ([bool]$entry.missing_only) { throw "Unexpected legacy file is present; refusing to remove: $target" }
        $beforeHash = Get-Sha256 $target
        $allowed = @($entry.allowed_sha256 | ForEach-Object { [string]$_ } | Where-Object { $_ })
        if ($allowed -notcontains $beforeHash) { throw "Unexpected legacy file hash; refusing to remove: $target ($beforeHash)" }
    }
    $removePlan += [pscustomobject]@{ kind = 'remove'; path = [string]$entry.path; target = $target; original_exists = [bool]$exists; original_hash = $beforeHash }
}

$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$BackupRootName = "_tiny_shadows_korean_recovery_backup_${stamp}_$PID"
# Keep the backup beside `game`, not inside it: Ren'Py recursively scans the
# game directory and would otherwise load backup .rpyc files as live scripts.
$BackupParent = Split-Path -Parent $GameDir
$BackupRoot = Join-Path $BackupParent $BackupRootName
$StateEntries = @()

try {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    foreach ($op in @($replacePlan + $removePlan)) {
        $backupRel = $null
        if ($op.original_exists) {
            $backupPath = Resolve-SafePath $BackupRoot ([string]$op.path)
            New-Item -ItemType Directory -Path (Split-Path -Parent $backupPath) -Force | Out-Null
            Copy-Item -LiteralPath $op.target -Destination $backupPath -Force
            if ((Get-Sha256 $backupPath) -ne $op.original_hash) { throw "Backup verification failed: $($op.path)" }
            $backupRel = [string]$op.path
        }
        $StateEntries += [pscustomobject]@{
            action = $op.kind
            path = [string]$op.path
            original_exists = [bool]$op.original_exists
            original_sha256 = $op.original_hash
            installed_sha256 = if ($op.kind -eq 'replace') { $op.payload_hash } else { $null }
            backup_relative = $backupRel
        }
    }

    foreach ($item in @($replacePlan)) {
        if ($item.original_exists) {
            if ((Get-Sha256 $item.target) -ne $item.original_hash) { throw "Target changed during install preflight: $($item.path)" }
        } elseif (Test-Path -LiteralPath $item.target) { throw "Target appeared during install preflight: $($item.path)" }
        New-Item -ItemType Directory -Path (Split-Path -Parent $item.target) -Force | Out-Null
        $temp = "$($item.target).tiny-shadows.tmp.$PID"
        try {
            Copy-Item -LiteralPath $item.payload -Destination $temp -Force
            if ((Get-Sha256 $temp) -ne $item.payload_hash) { throw "Temporary payload verification failed: $($item.path)" }
            Move-Item -LiteralPath $temp -Destination $item.target -Force
            if ((Get-Sha256 $item.target) -ne $item.payload_hash) { throw "Installed payload verification failed: $($item.path)" }
        } finally {
            if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
        }
    }

    foreach ($item in @($removePlan)) {
        if ($item.original_exists) {
            if ((Get-Sha256 $item.target) -ne $item.original_hash) { throw "Legacy target changed during install: $($item.path)" }
            Remove-Item -LiteralPath $item.target -Force
            if (Test-Path -LiteralPath $item.target) { throw "Legacy removal verification failed: $($item.path)" }
        }
    }

    $state = [pscustomobject]@{
        format = 'tiny-shadows-korean-recovery-state/v1'
        status = 'installed'
        manifest_sha256 = Get-Sha256 $ManifestPath
        backup_root = $BackupRootName
        entries = @($StateEntries)
        installed_utc = (Get-Date).ToUniversalTime().ToString('o')
    }
    Write-JsonAtomic $state $StatePath
    Write-Output "Installed safely. Backup: $BackupRoot"
} catch {
    # Restore every operation for which a verified backup was made.  New files
    # are removed; original files are copied back through a verified temp.
    for ($index = $StateEntries.Count - 1; $index -ge 0; $index--) {
        $entry = $StateEntries[$index]
        $target = Resolve-SafePath $GameDir ([string]$entry.path)
        if ([bool]$entry.original_exists) {
            $backup = Resolve-SafePath $BackupRoot ([string]$entry.backup_relative)
            if (Test-Path -LiteralPath $backup -PathType Leaf) {
                $temp = "$target.tiny-shadows.rollback.$PID"
                try {
                    Copy-Item -LiteralPath $backup -Destination $temp -Force
                    if ((Get-Sha256 $temp) -ne $entry.original_sha256) { throw "Rollback backup hash mismatch: $($entry.path)" }
                    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
                    Move-Item -LiteralPath $temp -Destination $target -Force
                } finally {
                    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
                }
            }
        } elseif (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Force
        }
    }
    throw "Installation failed and was rolled back. Verified backup retained at $BackupRoot. Details: $($_.Exception.Message)"
}
