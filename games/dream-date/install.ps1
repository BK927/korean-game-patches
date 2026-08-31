param(
    [string]$GameRoot = "D:\SteamLibrary\steamapps\common\Dream Date",
    [switch]$Force,
    [string]$XdeltaPath = "",
    [string]$BackupRoot = ""
)
$ErrorActionPreference = "Stop"
if (-not $Force) { throw "릴리스 후보 설치입니다. 검토 후 -Force를 명시하세요." }
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManifestPath = Join-Path $PackageRoot "manifest.json"
if (-not (Test-Path -LiteralPath $ManifestPath)) { throw "manifest.json이 없습니다." }
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$DataRoot = Join-Path $GameRoot "Dream Date_Data"
if (-not (Test-Path -LiteralPath $DataRoot)) { throw "Dream Date_Data가 없습니다: $DataRoot" }
if (Get-Process -Name "Dream Date" -ErrorAction SilentlyContinue) { throw "게임 프로세스를 먼저 종료하세요." }
if ([string]::IsNullOrWhiteSpace($XdeltaPath)) {
    $xdeltaCommand = Get-Command "xdelta3.exe" -ErrorAction Stop
    $XdeltaPath = $xdeltaCommand.Source
}
if (-not (Test-Path -LiteralPath $XdeltaPath)) { throw "xdelta3를 찾을 수 없습니다: $XdeltaPath" }
$Names = @("resources.assets", "sharedassets0.assets", "level2")
$Variants = @($Manifest.source_variants.PSObject.Properties)
$Matches = @()
foreach ($variantProperty in $Variants) {
    $variant = $variantProperty.Value
    $match = $true
    foreach ($name in $Names) {
        $target = Join-Path $DataRoot $name
        if (-not (Test-Path -LiteralPath $target)) { $match = $false; continue }
        $expected = $variant.source_hashes.PSObject.Properties[$name].Value
        $observed = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($observed -ne $expected) { $match = $false }
    }
    if ($match) { $Matches += $variantProperty }
}
if ($Matches.Count -ne 1) { throw "원본 hash gate 실패: 일치하는 source variant 수=$($Matches.Count)" }
$VariantProperty = $Matches[0]
$VariantName = $VariantProperty.Name
$Variant = $VariantProperty.Value
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $BackupRoot = Join-Path $GameRoot (".codex-dream-date-release-backup-" + $stamp)
}
$BackupRoot = [IO.Path]::GetFullPath($BackupRoot)
if (Test-Path -LiteralPath $BackupRoot) { throw "백업 경로가 이미 존재합니다. 다른 -BackupRoot를 지정하세요: $BackupRoot" }
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
$BackupFiles = Join-Path $BackupRoot "assets"
New-Item -ItemType Directory -Force -Path $BackupFiles | Out-Null
$BackupRecord = [ordered]@{
    schema = "dream-date-release/backup/v1"
    created_at = (Get-Date).ToUniversalTime().ToString("o")
    game_root = $GameRoot
    source_variant = $VariantName
    source_hashes = [ordered]@{}
    patched_hashes = [ordered]@{}
    assets = $Names
}
$Installed = @()
try {
    foreach ($name in $Names) {
        $target = Join-Path $DataRoot $name
        $backup = Join-Path $BackupFiles $name
        Copy-Item -LiteralPath $target -Destination $backup -Force
        $backupHash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedSource = $Variant.source_hashes.PSObject.Properties[$name].Value
        if ($backupHash -ne $expectedSource) { throw "백업 hash 실패: $name" }
        $BackupRecord.source_hashes[$name] = $backupHash
        $BackupRecord.patched_hashes[$name] = $Manifest.output_assets.PSObject.Properties[$name].Value.sha256
    }
    $BackupRecord | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $BackupRoot "backup-manifest.json") -Encoding UTF8
    foreach ($name in $Names) {
        $target = Join-Path $DataRoot $name
        $deltaRelative = $Variant.delta_files.PSObject.Properties[$name].Value
        $delta = Join-Path $PackageRoot $deltaRelative
        $expectedDelta = $Variant.delta_sha256.PSObject.Properties[$name].Value
        if (-not (Test-Path -LiteralPath $delta)) { throw "delta가 없습니다: $delta" }
        if ((Get-FileHash -LiteralPath $delta -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedDelta) { throw "delta hash 실패: $name" }
        $temporary = Join-Path $DataRoot ($name + ".codex-release.tmp")
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
        & $XdeltaPath -q -d -s $target $delta $temporary
        if ($LASTEXITCODE -ne 0) { throw "xdelta 적용 실패: $name" }
        $expectedOutput = $Manifest.output_assets.PSObject.Properties[$name].Value.sha256
        if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedOutput) { throw "임시 출력 hash 실패: $name" }
        [IO.File]::Move($temporary, $target, $true)
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedOutput) { throw "설치 후 hash 실패: $name" }
        $Installed += $name
    }
    Write-Output "Dream Date delta recovery installed. source=$VariantName backup=$BackupRoot"
    Write-Output "복구: restore.ps1 -Force -BackupRoot `"$BackupRoot`""
} catch {
    $rollbackErrors = @()
    foreach ($name in $Names) {
        $backup = Join-Path $BackupFiles $name
        $target = Join-Path $DataRoot $name
        if (Test-Path -LiteralPath $backup) {
            try { Copy-Item -LiteralPath $backup -Destination $target -Force } catch { $rollbackErrors += "${name}: $($_.Exception.Message)" }
        }
    }
    if ($rollbackErrors.Count -gt 0) { throw "설치 실패 및 자동 롤백 실패: $($rollbackErrors -join '; ') / $($_.Exception.Message)" }
    throw "설치 실패. 자동 롤백 완료: $($_.Exception.Message)"
}
