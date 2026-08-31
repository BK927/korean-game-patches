[CmdletBinding()]
param(
    [ValidateSet('Install', 'Restore', 'Verify')]
    [string]$Mode = 'Install',

    [Parameter(Mandatory = $true)]
    [string]$GameRoot,

    [string]$ManifestPath = (Join-Path $PSScriptRoot 'package-manifest.json'),
    [string]$BasePayloadRoot = (Join-Path $PSScriptRoot 'payload-base'),
    [string]$DeltaPayloadRoot = (Join-Path $PSScriptRoot 'payload-delta'),
    [string]$BackupRoot,
    [string]$BackupId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $bytes = $sha.ComputeHash($stream)
            return ([System.BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant()
        }
        finally {
            $sha.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

function Get-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path)
}

function Get-SafeChildPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        throw "Rooted payload path is not allowed: $RelativePath"
    }

    $normalized = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $candidate = Get-FullPath (Join-Path $Root $normalized)
    $rootFull = (Get-FullPath $Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

    if (-not $candidate.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes root: $RelativePath"
    }

    return $candidate
}

function Assert-RegularFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not [System.IO.File]::Exists($Path)) {
        throw "Required file is missing: $Path"
    }

    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Reparse-point file is not allowed: $Path"
    }
}

function Assert-FileBinding {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][long]$ExpectedSize,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256,
        [Parameter(Mandatory = $true)][string]$Role
    )

    Assert-RegularFile $Path
    $actualSize = (Get-Item -LiteralPath $Path -Force).Length
    $actualHash = Get-Sha256Hex $Path
    if ($actualSize -ne $ExpectedSize -or $actualHash -ne $ExpectedSha256.ToLowerInvariant()) {
        throw "$Role binding mismatch: $Path (size=$actualSize sha256=$actualHash)"
    }
}

function Copy-FileAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    Assert-RegularFile $Source
    $directory = [System.IO.Path]::GetDirectoryName($Destination)
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $temporary = Join-Path $directory ('.' + [System.IO.Path]::GetFileName($Destination) + '.' + [System.Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::Copy($Source, $temporary, $true)
        if ([System.IO.File]::Exists($Destination)) {
            [System.IO.File]::Delete($Destination)
        }
        [System.IO.File]::Move($temporary, $Destination)
    }
    finally {
        if ([System.IO.File]::Exists($temporary)) {
            [System.IO.File]::Delete($temporary)
        }
    }
}

function Write-TextAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Text
    )

    $directory = [System.IO.Path]::GetDirectoryName($Path)
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $temporary = Join-Path $directory ('.' + [System.IO.Path]::GetFileName($Path) + '.' + [System.Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllText($temporary, $Text, [System.Text.UTF8Encoding]::new($false))
        if ([System.IO.File]::Exists($Path)) {
            [System.IO.File]::Delete($Path)
        }
        [System.IO.File]::Move($temporary, $Path)
    }
    finally {
        if ([System.IO.File]::Exists($temporary)) {
            [System.IO.File]::Delete($temporary)
        }
    }
}

function Write-JsonAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )

    $json = $Value | ConvertTo-Json -Depth 12
    Write-TextAtomic -Path $Path -Text ($json + [Environment]::NewLine)
}

$manifestFull = Get-FullPath $ManifestPath
Assert-RegularFile $manifestFull
$manifest = Get-Content -LiteralPath $manifestFull -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.schema -ne 'bk927.outsidethedoor-release-package/v1') {
    throw "Unsupported manifest schema: $($manifest.schema)"
}

$gameRootFull = Get-FullPath $GameRoot
if (-not [System.IO.Directory]::Exists($gameRootFull)) {
    throw "Game root does not exist: $gameRootFull"
}
if (-not [System.IO.File]::Exists((Join-Path $gameRootFull 'OutsideTheDoor.exe'))) {
    throw "OutsideTheDoor.exe was not found under game root: $gameRootFull"
}

if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $gameRootFull '.korean-patch-backup\OutsideTheDoor'
}
$backupRootFull = Get-FullPath $BackupRoot
[System.IO.Directory]::CreateDirectory($backupRootFull) | Out-Null

$basePayloadFull = Get-FullPath $BasePayloadRoot
$deltaPayloadFull = Get-FullPath $DeltaPayloadRoot
$payloadBindings = @{}
foreach ($item in $manifest.payloadFiles) {
    $payloadRoot = if ($item.payloadGroup -eq 'base') { $basePayloadFull } elseif ($item.payloadGroup -eq 'delta') { $deltaPayloadFull } else { throw "Unknown payload group: $($item.payloadGroup)" }
    $sourcePath = Get-SafeChildPath -Root $payloadRoot -RelativePath $item.relativePath
    Assert-FileBinding -Path $sourcePath -ExpectedSize ([long]$item.size) -ExpectedSha256 ([string]$item.sha256) -Role 'Payload'
    $payloadBindings[[string]$item.relativePath] = $sourcePath
}

if ($Mode -eq 'Verify') {
    $verified = @()
    foreach ($item in $manifest.payloadFiles) {
        $target = Get-SafeChildPath -Root $gameRootFull -RelativePath $item.relativePath
        Assert-FileBinding -Path $target -ExpectedSize ([long]$item.size) -ExpectedSha256 ([string]$item.sha256) -Role 'Installed patch'
        $verified += [ordered]@{ path = [string]$item.relativePath; sha256 = [string]$item.sha256 }
    }
    [ordered]@{ status = 'PASS'; mode = 'Verify'; verifiedFiles = $verified.Count; files = $verified } | ConvertTo-Json -Depth 8
    exit 0
}

if ($Mode -eq 'Install') {
    foreach ($property in $manifest.sourceBindings.PSObject.Properties) {
        $relative = [string]$property.Name
        $binding = $property.Value
        $target = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
        Assert-FileBinding -Path $target -ExpectedSize ([long]$binding.size) -ExpectedSha256 ([string]$binding.sha256) -Role 'Clean game source'
    }

    if ([string]::IsNullOrWhiteSpace($BackupId)) {
        $BackupId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + '-' + [System.Guid]::NewGuid().ToString('N').Substring(0, 8)
    }
    if ($BackupId -notmatch '^[A-Za-z0-9._-]+$') {
        throw "Unsafe backup id: $BackupId"
    }

    $backupDirectory = Get-SafeChildPath -Root $backupRootFull -RelativePath $BackupId
    if ([System.IO.Directory]::Exists($backupDirectory)) {
        throw "Backup id already exists: $BackupId"
    }
    [System.IO.Directory]::CreateDirectory($backupDirectory) | Out-Null

    $originalFiles = @()
    foreach ($property in $manifest.sourceBindings.PSObject.Properties) {
        $relative = [string]$property.Name
        $binding = $property.Value
        $source = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
        $backup = Get-SafeChildPath -Root $backupDirectory -RelativePath ('files/' + $relative)
        Copy-FileAtomic -Source $source -Destination $backup
        Assert-FileBinding -Path $backup -ExpectedSize ([long]$binding.size) -ExpectedSha256 ([string]$binding.sha256) -Role 'Backup'
        $originalFiles += [ordered]@{ relativePath = $relative; size = [long]$binding.size; sha256 = [string]$binding.sha256 }
    }

    $addedFiles = @($manifest.payloadFiles | Where-Object { $_.operation -eq 'add' } | ForEach-Object { [string]$_.relativePath })
    $backupManifest = [ordered]@{
        schema = 'bk927.outsidethedoor-backup/v1'
        packageVersion = [string]$manifest.packageVersion
        backupId = $BackupId
        createdAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        gameRoot = $gameRootFull
        originalFiles = $originalFiles
        addedFiles = $addedFiles
    }
    Write-JsonAtomic -Path (Join-Path $backupDirectory 'backup-manifest.json') -Value $backupManifest

    $installed = @()
    foreach ($item in $manifest.payloadFiles) {
        $relative = [string]$item.relativePath
        $target = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
        Copy-FileAtomic -Source $payloadBindings[$relative] -Destination $target
        Assert-FileBinding -Path $target -ExpectedSize ([long]$item.size) -ExpectedSha256 ([string]$item.sha256) -Role 'Installed patch'
        $installed += [ordered]@{ relativePath = $relative; size = [long]$item.size; sha256 = [string]$item.sha256 }
    }

    $receipt = [ordered]@{
        schema = 'bk927.outsidethedoor-install-receipt/v1'
        status = 'PASS'
        mode = 'Install'
        packageVersion = [string]$manifest.packageVersion
        backupId = $BackupId
        installedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        gameRoot = $gameRootFull
        installedFiles = $installed
    }
    Write-JsonAtomic -Path (Join-Path $backupDirectory 'install-receipt.json') -Value $receipt
    Write-TextAtomic -Path (Join-Path $backupRootFull 'latest.txt') -Text ($BackupId + [Environment]::NewLine)
    $receipt | ConvertTo-Json -Depth 8
    exit 0
}

if ([string]::IsNullOrWhiteSpace($BackupId)) {
    $latestPath = Join-Path $backupRootFull 'latest.txt'
    Assert-RegularFile $latestPath
    $BackupId = (Get-Content -LiteralPath $latestPath -Raw -Encoding UTF8).Trim()
}
if ($BackupId -notmatch '^[A-Za-z0-9._-]+$') {
    throw "Unsafe backup id: $BackupId"
}

$restoreDirectory = Get-SafeChildPath -Root $backupRootFull -RelativePath $BackupId
$backupManifestPath = Join-Path $restoreDirectory 'backup-manifest.json'
Assert-RegularFile $backupManifestPath
$backupManifest = Get-Content -LiteralPath $backupManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($backupManifest.schema -ne 'bk927.outsidethedoor-backup/v1') {
    throw "Unsupported backup manifest schema: $($backupManifest.schema)"
}

$restored = @()
foreach ($item in $backupManifest.originalFiles) {
    $relative = [string]$item.relativePath
    $backup = Get-SafeChildPath -Root $restoreDirectory -RelativePath ('files/' + $relative)
    Assert-FileBinding -Path $backup -ExpectedSize ([long]$item.size) -ExpectedSha256 ([string]$item.sha256) -Role 'Backup'
    $target = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
    Copy-FileAtomic -Source $backup -Destination $target
    Assert-FileBinding -Path $target -ExpectedSize ([long]$item.size) -ExpectedSha256 ([string]$item.sha256) -Role 'Restored source'
    $restored += [ordered]@{ relativePath = $relative; size = [long]$item.size; sha256 = [string]$item.sha256 }
}

$removed = @()
foreach ($relativeValue in $backupManifest.addedFiles) {
    $relative = [string]$relativeValue
    $target = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
    if ([System.IO.File]::Exists($target)) {
        $payloadItem = @($manifest.payloadFiles | Where-Object { $_.relativePath -eq $relative })
        if ($payloadItem.Count -ne 1) {
            throw "Added file is not uniquely bound in package manifest: $relative"
        }
        Assert-FileBinding -Path $target -ExpectedSize ([long]$payloadItem[0].size) -ExpectedSha256 ([string]$payloadItem[0].sha256) -Role 'Added patch file before removal'
        [System.IO.File]::Delete($target)
    }
    if ([System.IO.File]::Exists($target)) {
        throw "Failed to remove added patch file: $relative"
    }
    $removed += $relative
}

$restoreReceipt = [ordered]@{
    schema = 'bk927.outsidethedoor-restore-receipt/v1'
    status = 'PASS'
    mode = 'Restore'
    packageVersion = [string]$manifest.packageVersion
    backupId = $BackupId
    restoredAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    gameRoot = $gameRootFull
    restoredFiles = $restored
    removedAddedFiles = $removed
}
Write-JsonAtomic -Path (Join-Path $restoreDirectory 'restore-receipt.json') -Value $restoreReceipt
$restoreReceipt | ConvertTo-Json -Depth 8
