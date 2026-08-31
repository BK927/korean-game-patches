[CmdletBinding()]
param(
    [ValidateSet('Install', 'Verify', 'Restore')]
    [string]$Mode = 'Install',

    [Parameter(Mandatory = $true)]
    [string]$GameRoot,

    [string]$PayloadPath,
    [string]$BackupRoot,
    [string]$BackupId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($PayloadPath)) {
    $PayloadPath = Join-Path $PSScriptRoot 'payload\translations.json'
}

$script:JsonSerializer = $null
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    Add-Type -AssemblyName System.Web.Extensions
    $script:JsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $script:JsonSerializer.MaxJsonLength = [int]::MaxValue
    $script:JsonSerializer.RecursionLimit = 512
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
    $prefix = (Get-FullPath $Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes the selected root: $RelativePath"
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

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Path)
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToUpperInvariant()
        }
        finally {
            $sha.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

function Get-StringSha256Hex {
    param([AllowEmptyString()][string]$Value)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Value)
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToUpperInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Read-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    Assert-RegularFile $Path
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    if ($null -ne $script:JsonSerializer) {
        $result = $script:JsonSerializer.DeserializeObject($text)
    }
    else {
        $result = $text | ConvertFrom-Json -AsHashtable -Depth 512
    }
    return [pscustomobject]@{ Document = $result }
}

function Get-JsonPathValue {
    param(
        [Parameter(Mandatory = $true)]$Root,
        [Parameter(Mandatory = $true)]$Parts
    )
    $current = $Root
    foreach ($part in @($Parts)) {
        if ($part -is [string]) {
            if ($current -is [System.Collections.IDictionary]) {
                if (-not ($current.Keys -contains [string]$part)) {
                    throw "JSON property was not found: $part"
                }
                $current = $current[$part]
            }
            else {
                $property = $current.PSObject.Properties[$part]
                if ($null -eq $property) {
                    throw "JSON property was not found: $part"
                }
                $current = $property.Value
            }
        }
        else {
            $current = $current[[int]$part]
        }
    }
    return $current
}

function Set-JsonPathValue {
    param(
        [Parameter(Mandatory = $true)]$Root,
        [Parameter(Mandatory = $true)]$Parts,
        [Parameter(Mandatory = $true)][string]$Value
    )
    $path = @($Parts)
    if ($path.Count -eq 0) {
        throw 'Empty JSON path is not supported.'
    }
    $current = $Root
    if ($path.Count -gt 1) {
        foreach ($part in $path[0..($path.Count - 2)]) {
            if ($part -is [string]) {
                if ($current -is [System.Collections.IDictionary]) {
                    if (-not ($current.Keys -contains [string]$part)) {
                        throw "JSON property was not found: $part"
                    }
                    $current = $current[$part]
                }
                else {
                    $property = $current.PSObject.Properties[$part]
                    if ($null -eq $property) {
                        throw "JSON property was not found: $part"
                    }
                    $current = $property.Value
                }
            }
            else {
                $current = $current[[int]$part]
            }
        }
    }
    $last = $path[-1]
    if ($last -is [string]) {
        if ($current -is [System.Collections.IDictionary]) {
            if (-not ($current.Keys -contains [string]$last)) {
                throw "JSON property was not found: $last"
            }
            $current[$last] = $Value
        }
        else {
            $property = $current.PSObject.Properties[$last]
            if ($null -eq $property) {
                throw "JSON property was not found: $last"
            }
            $property.Value = $Value
        }
    }
    else {
        $current[[int]$last] = $Value
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
        [System.IO.File]::Copy($temporary, $Path, $true)
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

function Write-JsonAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value,
        [switch]$Compact
    )
    if ($null -ne $script:JsonSerializer) {
        $json = $script:JsonSerializer.Serialize($Value)
    }
    else {
        $json = $Value | ConvertTo-Json -Compress -Depth 100
    }
    if (-not $Compact) {
        $json += [Environment]::NewLine
    }
    Write-BytesAtomic -Path $Path -Bytes ([System.Text.UTF8Encoding]::new($false).GetBytes($json))
}

$gameRootFull = Get-FullPath $GameRoot
if (-not [System.IO.Directory]::Exists($gameRootFull)) {
    throw "Game root does not exist: $gameRootFull"
}
Assert-RegularFile (Join-Path $gameRootFull 'nw.exe')
Assert-RegularFile (Join-Path $gameRootFull 'www\data\System.json')

$payloadFull = Get-FullPath $PayloadPath
$payload = (Read-JsonFile $payloadFull).Document
if ([string]$payload.format -ne 'mishas-incident-field-patch-v1') {
    throw "Unsupported payload format: $($payload.format)"
}

if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $gameRootFull '.korean-patch-backup\Mishas-incident'
}
$backupRootFull = Get-FullPath $BackupRoot

if ($Mode -eq 'Restore') {
    if ([string]::IsNullOrWhiteSpace($BackupId)) {
        $latestPath = Join-Path $backupRootFull 'latest.txt'
        Assert-RegularFile $latestPath
        $BackupId = ([System.IO.File]::ReadAllText($latestPath, [System.Text.Encoding]::UTF8)).Trim()
    }
    if ($BackupId -notmatch '^[A-Za-z0-9._-]+$') {
        throw "Unsafe backup id: $BackupId"
    }
    $backupDirectory = Get-SafeChildPath -Root $backupRootFull -RelativePath $BackupId
    $backupManifestPath = Join-Path $backupDirectory 'backup-manifest.json'
    $backupManifest = (Read-JsonFile $backupManifestPath).Document
    if ([string]$backupManifest.schema -ne 'bk927.mishas-incident-backup/v1') {
        throw "Unsupported backup manifest: $($backupManifest.schema)"
    }
    foreach ($entry in @($backupManifest.files)) {
        $relative = [string]$entry.relativePath
        $backupPath = Get-SafeChildPath -Root $backupDirectory -RelativePath ('files/' + $relative)
        Assert-RegularFile $backupPath
        if ((Get-Sha256Hex $backupPath) -ne ([string]$entry.sha256).ToUpperInvariant()) {
            throw "Backup hash mismatch: $relative"
        }
    }
    foreach ($entry in @($backupManifest.files)) {
        $relative = [string]$entry.relativePath
        $backupPath = Get-SafeChildPath -Root $backupDirectory -RelativePath ('files/' + $relative)
        $targetPath = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
        Copy-FileAtomic -Source $backupPath -Destination $targetPath
        if ((Get-Sha256Hex $targetPath) -ne ([string]$entry.sha256).ToUpperInvariant()) {
            throw "Restored file hash mismatch: $relative"
        }
    }
    $receipt = [ordered]@{
        schema = 'bk927.mishas-incident-restore-receipt/v1'
        status = 'PASS'
        mode = 'Restore'
        backupId = $BackupId
        restoredAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        gameRoot = $gameRootFull
        restoredFiles = @($backupManifest.files).Count
    }
    Write-JsonAtomic -Path (Join-Path $backupDirectory 'restore-receipt.json') -Value $receipt
    $receipt | ConvertTo-Json -Depth 8
    exit 0
}

$operationsByFile = @{}
foreach ($operation in @($payload.operations)) {
    $relative = [string]$operation.file
    if (-not $operationsByFile.ContainsKey($relative)) {
        $operationsByFile[$relative] = [System.Collections.ArrayList]::new()
    }
    [void]$operationsByFile[$relative].Add($operation)
}

$plan = [System.Collections.ArrayList]::new()
$verifiedOperations = 0
foreach ($file in @($payload.files)) {
    $relative = [string]$file.path
    $targetPath = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
    Assert-RegularFile $targetPath
    $document = (Read-JsonFile $targetPath).Document
    $changed = 0
    foreach ($operation in @($operationsByFile[$relative])) {
        $current = [string](Get-JsonPathValue -Root $document -Parts $operation.path)
        $target = [string]$operation.target
        if ($current -eq $target) {
            $verifiedOperations++
            continue
        }
        if ($Mode -eq 'Verify') {
            throw "Translation mismatch: $relative path=$(@($operation.path) -join '/')"
        }
        $currentHash = Get-StringSha256Hex $current
        $accepted = $currentHash -eq ([string]$operation.sourceSha256).ToUpperInvariant()
        $previousAliases = @()
        if ($operation -is [System.Collections.IDictionary]) {
            if ($operation.Keys -contains 'acceptedPreviousSha256') {
                $previousAliases += [string]$operation['acceptedPreviousSha256']
            }
            if ($operation.Keys -contains 'acceptedPreviousSha256s') {
                foreach ($alias in @($operation['acceptedPreviousSha256s'])) {
                    $previousAliases += [string]$alias
                }
            }
        }
        else {
            $property = $operation.PSObject.Properties['acceptedPreviousSha256']
            if ($null -ne $property) {
                $previousAliases += [string]$property.Value
            }
            $properties = $operation.PSObject.Properties['acceptedPreviousSha256s']
            if ($null -ne $properties) {
                foreach ($alias in @($properties.Value)) {
                    $previousAliases += [string]$alias
                }
            }
        }
        if (-not $accepted) {
            foreach ($previousAlias in @($previousAliases | Select-Object -Unique)) {
                if ($currentHash -eq $previousAlias.ToUpperInvariant()) {
                    $accepted = $true
                    break
                }
            }
        }
        if (-not $accepted) {
            throw "Unsupported text at $relative path=$(@($operation.path) -join '/') hash=$currentHash"
        }
        Set-JsonPathValue -Root $document -Parts $operation.path -Value $target
        $changed++
        $verifiedOperations++
    }
    if ($changed -gt 0) {
        [void]$plan.Add([pscustomobject]@{
            relativePath = $relative
            targetPath = $targetPath
            document = $document
            changedOperations = $changed
            sourceSha256 = Get-Sha256Hex $targetPath
        })
    }
}

if ($verifiedOperations -ne [int]$payload.operationCount) {
    throw "Operation count mismatch: expected $($payload.operationCount), checked $verifiedOperations"
}

if ($Mode -eq 'Verify') {
    [ordered]@{
        status = 'PASS'
        mode = 'Verify'
        verifiedFiles = @($payload.files).Count
        verifiedOperations = $verifiedOperations
    } | ConvertTo-Json -Depth 6
    exit 0
}

if ($plan.Count -eq 0) {
    [ordered]@{
        status = 'PASS'
        mode = 'Install'
        result = 'AlreadyInstalled'
        changedFiles = 0
        verifiedOperations = $verifiedOperations
    } | ConvertTo-Json -Depth 6
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

$backupFiles = @()
foreach ($entry in @($plan)) {
    $backupPath = Get-SafeChildPath -Root $backupDirectory -RelativePath ('files/' + [string]$entry.relativePath)
    Copy-FileAtomic -Source $entry.targetPath -Destination $backupPath
    if ((Get-Sha256Hex $backupPath) -ne [string]$entry.sourceSha256) {
        throw "Backup verification failed: $($entry.relativePath)"
    }
    $backupFiles += [ordered]@{
        relativePath = [string]$entry.relativePath
        sha256 = [string]$entry.sourceSha256
    }
}

$backupManifest = [ordered]@{
    schema = 'bk927.mishas-incident-backup/v1'
    payloadSha256 = Get-Sha256Hex $payloadFull
    backupId = $BackupId
    createdAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    gameRoot = $gameRootFull
    files = $backupFiles
}
Write-JsonAtomic -Path (Join-Path $backupDirectory 'backup-manifest.json') -Value $backupManifest

foreach ($entry in @($plan)) {
    Write-JsonAtomic -Path $entry.targetPath -Value $entry.document -Compact
}

foreach ($file in @($payload.files)) {
    $relative = [string]$file.path
    $targetPath = Get-SafeChildPath -Root $gameRootFull -RelativePath $relative
    $document = (Read-JsonFile $targetPath).Document
    foreach ($operation in @($operationsByFile[$relative])) {
        $current = [string](Get-JsonPathValue -Root $document -Parts $operation.path)
        if ($current -ne [string]$operation.target) {
            throw "Post-install verification failed: $relative path=$(@($operation.path) -join '/')"
        }
    }
}

$receipt = [ordered]@{
    schema = 'bk927.mishas-incident-install-receipt/v1'
    status = 'PASS'
    mode = 'Install'
    backupId = $BackupId
    installedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    gameRoot = $gameRootFull
    changedFiles = $plan.Count
    changedOperations = (@($plan | ForEach-Object { [int]$_.changedOperations }) | Measure-Object -Sum).Sum
    verifiedOperations = $verifiedOperations
}
Write-JsonAtomic -Path (Join-Path $backupDirectory 'install-receipt.json') -Value $receipt
Write-BytesAtomic -Path (Join-Path $backupRootFull 'latest.txt') -Bytes ([System.Text.UTF8Encoding]::new($false).GetBytes($BackupId + [Environment]::NewLine))
$receipt | ConvertTo-Json -Depth 8
