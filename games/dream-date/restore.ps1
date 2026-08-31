param(
    [string]$GameRoot = "D:\SteamLibrary\steamapps\common\Dream Date",
    [string]$BackupRoot = "",
    [switch]$Force
)
$ErrorActionPreference = "Stop"
if (-not $Force) { throw "복구는 대상 자산을 교체합니다. 검토 후 -Force를 명시하세요." }
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Manifest = Get-Content -LiteralPath (Join-Path $PackageRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$DataRoot = Join-Path $GameRoot "Dream Date_Data"
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $candidates = @(Get-ChildItem -LiteralPath $GameRoot -Directory -Filter ".codex-dream-date-release-backup-*" | Sort-Object LastWriteTime -Descending)
    if ($candidates.Count -ne 1) { throw "복구 백업을 하나로 특정할 수 없습니다. -BackupRoot를 지정하세요." }
    $BackupRoot = $candidates[0].FullName
}
$BackupRoot = [IO.Path]::GetFullPath($BackupRoot)
$RecordPath = Join-Path $BackupRoot "backup-manifest.json"
if (-not (Test-Path -LiteralPath $RecordPath)) { throw "backup-manifest.json이 없습니다: $BackupRoot" }
$Record = Get-Content -LiteralPath $RecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Names = @("resources.assets", "sharedassets0.assets", "level2")
foreach ($name in $Names) {
    $target = Join-Path $DataRoot $name
    $backup = Join-Path (Join-Path $BackupRoot "assets") $name
    if (-not (Test-Path -LiteralPath $target)) { throw "현재 대상이 없습니다: $target" }
    if (-not (Test-Path -LiteralPath $backup)) { throw "백업 파일이 없습니다: $backup" }
    $expectedPatched = $Record.patched_hashes.PSObject.Properties[$name].Value
    $currentHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($currentHash -ne $expectedPatched) { throw "현재 설치 hash gate 실패: $name" }
    $expectedSource = $Record.source_hashes.PSObject.Properties[$name].Value
    $backupHash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($backupHash -ne $expectedSource) { throw "백업 hash gate 실패: $name" }
}
foreach ($name in $Names) {
    $target = Join-Path $DataRoot $name
    $backup = Join-Path (Join-Path $BackupRoot "assets") $name
    $temporary = Join-Path $DataRoot ($name + ".codex-restore.tmp")
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    Copy-Item -LiteralPath $backup -Destination $temporary -Force
    if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Record.source_hashes.PSObject.Properties[$name].Value) { throw "복구 임시 hash 실패: $name" }
    [IO.File]::Move($temporary, $target, $true)
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Record.source_hashes.PSObject.Properties[$name].Value) { throw "복구 후 hash 실패: $name" }
}
Write-Output "Dream Date assets restored from $BackupRoot"
