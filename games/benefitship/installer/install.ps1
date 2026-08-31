[CmdletBinding()]
param(
    [ValidateSet('Install', 'Restore', 'Verify')]
    [string]$Mode = 'Install',

    [Parameter(Mandatory = $true)]
    [string]$GameRoot,

    [string]$ManifestPath,
    [string]$PayloadRoot,
    [string]$BackupRoot,
    [string]$BackupId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $PSScriptRoot 'package-manifest.json'
}
if ([string]::IsNullOrWhiteSpace($PayloadRoot)) {
    $PayloadRoot = Join-Path $PSScriptRoot 'payload'
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
        throw "Rooted relative path is not allowed: $RelativePath"
    }

    $normalized = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $candidate = Get-FullPath (Join-Path $Root $normalized)
    $rootPrefix = (Get-FullPath $Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
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

function Get-Sha256HexFromBytes {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant()
        }
        finally {
            $sha.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

function Get-FileState {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not [System.IO.File]::Exists($Path)) {
        return [pscustomobject]@{ exists = $false; size = 0L; sha256 = $null }
    }
    Assert-RegularFile $Path
    return [pscustomobject]@{
        exists = $true
        size = [long](Get-Item -LiteralPath $Path -Force).Length
        sha256 = Get-Sha256Hex $Path
    }
}

function Test-StateBinding {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)]$Binding
    )

    return $State.exists -and
        $State.size -eq [long]$Binding.size -and
        $State.sha256 -eq ([string]$Binding.sha256).ToLowerInvariant()
}

function Test-TextPatchInstalled {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)]$Item
    )

    if (Test-StateBinding -State $State -Binding $Item.patched) {
        return $true
    }
    foreach ($binding in @($Item.acceptedPatchedBindings)) {
        if (Test-StateBinding -State $State -Binding $binding) {
            return $true
        }
    }
    return $false
}

function Assert-FileBinding {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Binding,
        [Parameter(Mandatory = $true)][string]$Role
    )

    $state = Get-FileState $Path
    if (-not (Test-StateBinding -State $state -Binding $Binding)) {
        throw "$Role binding mismatch: $Path (size=$($state.size) sha256=$($state.sha256))"
    }
}

function Write-BytesAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes
    )

    $directory = [System.IO.Path]::GetDirectoryName($Path)
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $temporary = Join-Path $directory ('.' + [System.IO.Path]::GetFileName($Path) + '.' + [System.Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllBytes($temporary, $Bytes)
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

function Copy-FileAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    Assert-RegularFile $Source
    Write-BytesAtomic -Path $Destination -Bytes ([System.IO.File]::ReadAllBytes($Source))
}

function Write-TextAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Text
    )
    Write-BytesAtomic -Path $Path -Bytes ([System.Text.UTF8Encoding]::new($false).GetBytes($Text))
}

function Write-JsonAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )
    Write-TextAtomic -Path $Path -Text (($Value | ConvertTo-Json -Depth 16) + [Environment]::NewLine)
}

function Get-TransformedBytes {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)]$Replacements
    )

    $sourceBytes = [System.IO.File]::ReadAllBytes($SourcePath)
    $hasUtf8Bom = $sourceBytes.Length -ge 3 -and $sourceBytes[0] -eq 0xEF -and $sourceBytes[1] -eq 0xBB -and $sourceBytes[2] -eq 0xBF
    $offset = if ($hasUtf8Bom) { 3 } else { 0 }
    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    $text = $utf8.GetString($sourceBytes, $offset, $sourceBytes.Length - $offset)
    $newLine = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }

    foreach ($replacement in @($Replacements)) {
        $oldLines = @($replacement.oldLines | ForEach-Object { [string]$_ })
        $newLines = @($replacement.newLines | ForEach-Object { [string]$_ })
        $oldText = [string]::Join($newLine, $oldLines)
        $newText = [string]::Join($newLine, $newLines)
        $count = [System.Text.RegularExpressions.Regex]::Matches($text, [System.Text.RegularExpressions.Regex]::Escape($oldText)).Count
        if ($count -ne 1) {
            throw "Text patch expected exactly one match in $SourcePath but found $count."
        }
        $text = $text.Replace($oldText, $newText)
    }

    $body = $utf8.GetBytes($text)
    if (-not $hasUtf8Bom) {
        return $body
    }

    $result = [byte[]]::new($body.Length + 3)
    $result[0] = 0xEF
    $result[1] = 0xBB
    $result[2] = 0xBF
    [System.Array]::Copy($body, 0, $result, 3, $body.Length)
    return $result
}

function Get-ExpectedInstalledBinding {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    foreach ($item in @($Manifest.textPatches)) {
        if ([string]$item.relativePath -eq $RelativePath) {
            return $item.patched
        }
    }
    foreach ($item in @($Manifest.payloadFiles)) {
        if ([string]$item.relativePath -eq $RelativePath) {
            return $item
        }
    }
    return $null
}

$manifestFull = Get-FullPath $ManifestPath
Assert-RegularFile $manifestFull
$manifest = Get-Content -LiteralPath $manifestFull -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.schema -ne 'bk927.benefitship-release-package/v1') {
    throw "Unsupported manifest schema: $($manifest.schema)"
}

$gameRootFull = Get-FullPath $GameRoot
if (-not [System.IO.Directory]::Exists($gameRootFull)) {
    throw "Game root does not exist: $gameRootFull"
}
if (-not [System.IO.File]::Exists((Join-Path $gameRootFull 'Benefitship.exe'))) {
    throw "Benefitship.exe was not found under game root: $gameRootFull"
}

$payloadRootFull = Get-FullPath $PayloadRoot
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $gameRootFull '.korean-patch-backup\Benefitship'
}
$backupRootFull = Get-FullPath $BackupRoot

foreach ($item in @($manifest.payloadFiles)) {
    $payloadPath = Get-SafeChildPath -Root $payloadRootFull -RelativePath ([string]$item.relativePath)
    Assert-FileBinding -Path $payloadPath -Binding $item -Role 'Payload'
}

if ($Mode -eq 'Verify') {
    $verified = @()
    foreach ($item in @($manifest.textPatches)) {
        $target = Get-SafeChildPath -Root $gameRootFull -RelativePath ([string]$item.relativePath)
        $state = Get-FileState $target
        if (-not (Test-TextPatchInstalled -State $state -Item $item)) {
            throw "Installed text patch binding mismatch: $target (size=$($state.size) sha256=$($state.sha256))"
        }
        $verified += [string]$item.relativePath
    }
    foreach ($item in @($manifest.payloadFiles)) {
        $target = Get-SafeChildPath -Root $gameRootFull -RelativePath ([string]$item.relativePath)
        Assert-FileBinding -Path $target -Binding $item -Role 'Installed payload'
        $verified += [string]$item.relativePath
    }
    [ordered]@{ status = 'PASS'; mode = 'Verify'; packageVersion = [string]$manifest.packageVersion; verifiedFiles = $verified.Count; files = $verified } | ConvertTo-Json -Depth 8
    exit 0
}

if ($Mode -eq 'Install') {
    $plan = [System.Collections.ArrayList]::new()

    foreach ($item in @($manifest.textPatches)) {
        $relative = [string]$item.relativePath
        $target = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
        $state = Get-FileState $target
        if (Test-TextPatchInstalled -State $state -Item $item) {
            continue
        }

        $accepted = $false
        foreach ($binding in @($item.sourceBindings)) {
            if (Test-StateBinding -State $state -Binding $binding) {
                $accepted = $true
                break
            }
        }
        if (-not $accepted) {
            throw "Unsupported source file: $target (size=$($state.size) sha256=$($state.sha256)). Run Steam file verification before installing."
        }

        $bytes = Get-TransformedBytes -SourcePath $target -Replacements $item.replacements
        $transformed = [pscustomobject]@{ exists = $true; size = [long]$bytes.Length; sha256 = Get-Sha256HexFromBytes $bytes }
        if (-not (Test-StateBinding -State $transformed -Binding $item.patched)) {
            throw "Internal text-patch binding mismatch for $relative (size=$($transformed.size) sha256=$($transformed.sha256))."
        }

        [void]$plan.Add([pscustomobject]@{
            kind = 'bytes'
            relativePath = $relative
            target = $target
            bytes = $bytes
            source = $null
            derivedPaths = @($item.derivedPaths | ForEach-Object { [string]$_ })
        })
    }

    foreach ($item in @($manifest.payloadFiles)) {
        $relative = [string]$item.relativePath
        $target = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
        $state = Get-FileState $target
        if (Test-StateBinding -State $state -Binding $item) {
            continue
        }

        if ($state.exists) {
            $accepted = $false
            foreach ($binding in @($item.acceptedExistingBindings)) {
                if (Test-StateBinding -State $state -Binding $binding) {
                    $accepted = $true
                    break
                }
            }
            if (-not $accepted) {
                throw "Existing file is not a supported prior patch: $target (size=$($state.size) sha256=$($state.sha256))."
            }
        }

        $payloadPath = Get-SafeChildPath -Root $payloadRootFull -RelativePath $relative
        [void]$plan.Add([pscustomobject]@{
            kind = 'copy'
            relativePath = $relative
            target = $target
            bytes = $null
            source = $payloadPath
            derivedPaths = @($item.derivedPaths | ForEach-Object { [string]$_ })
        })
    }

    if ($plan.Count -eq 0) {
        [ordered]@{ status = 'PASS'; mode = 'Install'; result = 'AlreadyInstalled'; packageVersion = [string]$manifest.packageVersion; changedFiles = 0 } | ConvertTo-Json -Depth 6
        exit 0
    }

    [System.IO.Directory]::CreateDirectory($backupRootFull) | Out-Null
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

    $backupEntries = @()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in @($plan)) {
        if ($seen.Add([string]$entry.relativePath)) {
            $state = Get-FileState $entry.target
            $record = [ordered]@{ relativePath = [string]$entry.relativePath; role = 'target'; existed = [bool]$state.exists; size = $state.size; sha256 = $state.sha256 }
            if ($state.exists) {
                $backupPath = Get-SafeChildPath -Root $backupDirectory -RelativePath ('files/' + [string]$entry.relativePath)
                Copy-FileAtomic -Source $entry.target -Destination $backupPath
                Assert-FileBinding -Path $backupPath -Binding $record -Role 'Backup'
            }
            $backupEntries += $record
        }

        foreach ($derivedRelative in @($entry.derivedPaths)) {
            if (-not $seen.Add($derivedRelative)) {
                continue
            }
            $derivedTarget = Get-SafeChildPath -Root $gameRootFull -RelativePath $derivedRelative
            $derivedState = Get-FileState $derivedTarget
            $derivedRecord = [ordered]@{ relativePath = $derivedRelative; role = 'derived'; existed = [bool]$derivedState.exists; size = $derivedState.size; sha256 = $derivedState.sha256 }
            if ($derivedState.exists) {
                $derivedBackup = Get-SafeChildPath -Root $backupDirectory -RelativePath ('files/' + $derivedRelative)
                Copy-FileAtomic -Source $derivedTarget -Destination $derivedBackup
                Assert-FileBinding -Path $derivedBackup -Binding $derivedRecord -Role 'Derived backup'
            }
            $backupEntries += $derivedRecord
        }
    }

    $backupManifest = [ordered]@{
        schema = 'bk927.benefitship-backup/v1'
        packageVersion = [string]$manifest.packageVersion
        backupId = $BackupId
        createdAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        gameRoot = $gameRootFull
        entries = $backupEntries
    }
    Write-JsonAtomic -Path (Join-Path $backupDirectory 'backup-manifest.json') -Value $backupManifest

    foreach ($entry in @($plan)) {
        if ($entry.kind -eq 'bytes') {
            Write-BytesAtomic -Path $entry.target -Bytes $entry.bytes
        }
        elseif ($entry.kind -eq 'copy') {
            Copy-FileAtomic -Source $entry.source -Destination $entry.target
        }
        else {
            throw "Unknown plan kind: $($entry.kind)"
        }
        if ([System.IO.Path]::GetExtension($entry.target) -ieq '.rpy') {
            [System.IO.File]::SetLastWriteTimeUtc($entry.target, [System.DateTime]::UtcNow)
        }
    }

    foreach ($item in @($manifest.textPatches)) {
        $target = Get-SafeChildPath -Root $gameRootFull -RelativePath ([string]$item.relativePath)
        $state = Get-FileState $target
        if (-not (Test-TextPatchInstalled -State $state -Item $item)) {
            throw "Installed text patch binding mismatch: $target (size=$($state.size) sha256=$($state.sha256))"
        }
    }
    foreach ($item in @($manifest.payloadFiles)) {
        $target = Get-SafeChildPath -Root $gameRootFull -RelativePath ([string]$item.relativePath)
        Assert-FileBinding -Path $target -Binding $item -Role 'Installed payload'
    }

    $receipt = [ordered]@{
        schema = 'bk927.benefitship-install-receipt/v1'
        status = 'PASS'
        mode = 'Install'
        packageVersion = [string]$manifest.packageVersion
        backupId = $BackupId
        installedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        gameRoot = $gameRootFull
        changedFiles = $plan.Count
        files = @($plan | ForEach-Object { [string]$_.relativePath })
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
if ($backupManifest.schema -ne 'bk927.benefitship-backup/v1') {
    throw "Unsupported backup manifest schema: $($backupManifest.schema)"
}

foreach ($entry in @($backupManifest.entries)) {
    $relative = [string]$entry.relativePath
    $target = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
    if ([string]$entry.role -eq 'target') {
        $expected = Get-ExpectedInstalledBinding -Manifest $manifest -RelativePath $relative
        if ($null -eq $expected) {
            throw "No installed binding for restore target: $relative"
        }
        Assert-FileBinding -Path $target -Binding $expected -Role 'Installed patch before restore'
    }
    if ([bool]$entry.existed) {
        $backupPath = Get-SafeChildPath -Root $restoreDirectory -RelativePath ('files/' + $relative)
        Assert-FileBinding -Path $backupPath -Binding $entry -Role 'Backup before restore'
    }
}

$restored = @()
foreach ($entry in @($backupManifest.entries)) {
    $relative = [string]$entry.relativePath
    $target = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
    if ([bool]$entry.existed) {
        $backupPath = Get-SafeChildPath -Root $restoreDirectory -RelativePath ('files/' + $relative)
        Copy-FileAtomic -Source $backupPath -Destination $target
        Assert-FileBinding -Path $target -Binding $entry -Role 'Restored file'
        if ([System.IO.Path]::GetExtension($target) -ieq '.rpy') {
            [System.IO.File]::SetLastWriteTimeUtc($target, [System.DateTime]::UtcNow)
        }
        $restored += [ordered]@{ relativePath = $relative; action = 'restored' }
    }
    else {
        if ([System.IO.File]::Exists($target)) {
            [System.IO.File]::Delete($target)
        }
        if ([System.IO.File]::Exists($target)) {
            throw "Failed to remove added file: $target"
        }
        $restored += [ordered]@{ relativePath = $relative; action = 'removed' }
    }
}

$restoreReceipt = [ordered]@{
    schema = 'bk927.benefitship-restore-receipt/v1'
    status = 'PASS'
    mode = 'Restore'
    packageVersion = [string]$manifest.packageVersion
    backupId = $BackupId
    restoredAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    gameRoot = $gameRootFull
    entries = $restored
}
Write-JsonAtomic -Path (Join-Path $restoreDirectory 'restore-receipt.json') -Value $restoreReceipt
$restoreReceipt | ConvertTo-Json -Depth 8
