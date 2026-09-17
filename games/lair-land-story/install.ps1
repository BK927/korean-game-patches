param(
    [string]$GameRoot = "D:\SteamLibrary\steamapps\common\Lair Land Story Remake Edition",
    [switch]$Force,
    [string]$XdeltaPath = "",
    [string]$BackupRoot = ""
)
$ErrorActionPreference = "Stop"
if (-not $Force) { throw "한글 패치 설치는 게임 파일을 교체합니다. 검토 후 -Force를 명시하세요." }
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Manifest = Get-Content -LiteralPath (Join-Path $PackageRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$ResolvedGameRoot = [IO.Path]::GetFullPath($GameRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not (Test-Path -LiteralPath (Join-Path $GameRoot "Lair Land Story Remake Edition.exe"))) { throw "게임 실행 파일을 찾을 수 없습니다: $GameRoot" }
if (Get-Process -Name "Lair Land Story Remake Edition" -ErrorAction SilentlyContinue) { throw "게임을 먼저 종료하세요." }
if ([string]::IsNullOrWhiteSpace($XdeltaPath)) {
    $BundledXdelta = Join-Path $PackageRoot "tools\xdelta3.exe"
    if (Test-Path -LiteralPath $BundledXdelta) { $XdeltaPath = $BundledXdelta }
    else { $XdeltaPath = (Get-Command "xdelta3.exe" -ErrorAction Stop).Source }
}
if (-not (Test-Path -LiteralPath $XdeltaPath)) { throw "xdelta3를 찾을 수 없습니다: $XdeltaPath" }
$RelativePaths = @($Manifest.target_relative_paths)
function Resolve-GamePath([string]$RelativePath) {
    $Resolved = [IO.Path]::GetFullPath((Join-Path $GameRoot $RelativePath))
    if (-not $Resolved.StartsWith($ResolvedGameRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "게임 폴더 밖의 경로가 감지되었습니다: $RelativePath" }
    return $Resolved
}
$Matches = @()
foreach ($variantProperty in @($Manifest.source_variants.PSObject.Properties)) {
    $variant = $variantProperty.Value
    $match = $true
    foreach ($relative in $RelativePaths) {
        $target = Resolve-GamePath $relative
        if (-not (Test-Path -LiteralPath $target)) { $match = $false; continue }
        $expected = $variant.source_hashes.PSObject.Properties[$relative].Value
        $observed = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($observed -ne $expected) { $match = $false }
    }
    if ($match) { $Matches += $variantProperty }
}
if ($Matches.Count -ne 1) { throw "지원 원본 hash gate 실패: 일치하는 원본 변형 수=$($Matches.Count)" }
$VariantName = $Matches[0].Name
$Variant = $Matches[0].Value
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $BackupRoot = Join-Path $GameRoot (".korean-patch-backup\Lair-Land-Story-" + $stamp)
}
$BackupRoot = [IO.Path]::GetFullPath($BackupRoot)
if (Test-Path -LiteralPath $BackupRoot) { throw "백업 경로가 이미 존재합니다: $BackupRoot" }
$BackupFiles = Join-Path $BackupRoot "files"
New-Item -ItemType Directory -Force -Path $BackupFiles | Out-Null
$Record = [ordered]@{
    schema = "lair-land-story-korean-patch/backup/v1"
    created_at = (Get-Date).ToUniversalTime().ToString("o")
    game_root = $GameRoot
    source_variant = $VariantName
    relative_paths = $RelativePaths
    source_hashes = [ordered]@{}
    patched_hashes = [ordered]@{}
}
try {
    foreach ($relative in $RelativePaths) {
        $target = Resolve-GamePath $relative
        $backup = Join-Path $BackupFiles $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
        Copy-Item -LiteralPath $target -Destination $backup -Force
        $expectedSource = $Variant.source_hashes.PSObject.Properties[$relative].Value
        $backupHash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($backupHash -ne $expectedSource) { throw "백업 hash 실패: $relative" }
        $Record.source_hashes[$relative] = $backupHash
        $Record.patched_hashes[$relative] = $Manifest.output_assets.PSObject.Properties[$relative].Value.sha256
    }
    $Record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $BackupRoot "backup-manifest.json") -Encoding UTF8
    foreach ($relative in $RelativePaths) {
        $target = Resolve-GamePath $relative
        $deltaRelative = $Variant.delta_files.PSObject.Properties[$relative].Value
        $delta = Join-Path $PackageRoot $deltaRelative
        $expectedDelta = $Variant.delta_sha256.PSObject.Properties[$relative].Value
        if (-not (Test-Path -LiteralPath $delta)) { throw "delta가 없습니다: $deltaRelative" }
        if ((Get-FileHash -LiteralPath $delta -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedDelta) { throw "delta hash 실패: $relative" }
        $temporary = $target + ".korean-patch.tmp"
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
        $xdeltaOutput = @(& $XdeltaPath -q -f -d -s $target $delta $temporary 2>&1)
        $xdeltaExit = $LASTEXITCODE
        if ($xdeltaExit -ne 0) {
            $detail = ($xdeltaOutput | ForEach-Object { $_.ToString() }) -join " / "
            throw "xdelta 적용 실패(exit=$xdeltaExit): $relative / $detail"
        }
        $expectedOutput = $Manifest.output_assets.PSObject.Properties[$relative].Value.sha256
        if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedOutput) { throw "임시 출력 hash 실패: $relative" }
        Copy-Item -LiteralPath $temporary -Destination $target -Force
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedOutput) { throw "설치 후 hash 실패: $relative" }
        Remove-Item -LiteralPath $temporary -Force
    }
    Write-Output "Lair Land Story 한국어 패치 설치 완료. backup=$BackupRoot"
    Write-Output "복구: .\restore.ps1 -Force -GameRoot `"$GameRoot`" -BackupRoot `"$BackupRoot`""
} catch {
    $Failure = $_.Exception.Message
    $RollbackErrors = @()
    foreach ($relative in $RelativePaths) {
        $backup = Join-Path $BackupFiles $relative
        $target = Resolve-GamePath $relative
        if (Test-Path -LiteralPath $backup) {
            try { Copy-Item -LiteralPath $backup -Destination $target -Force } catch { $RollbackErrors += "${relative}: $($_.Exception.Message)" }
        }
    }
    if ($RollbackErrors.Count -gt 0) { throw "설치 실패 및 자동 롤백 실패: $($RollbackErrors -join '; ') / $Failure" }
    throw "설치 실패. 자동 롤백 완료: $Failure"
}
