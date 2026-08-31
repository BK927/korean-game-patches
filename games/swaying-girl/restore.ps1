param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [Parameter(Mandatory=$true)][string]$BackupRoot,
    [switch]$Force
)
$ErrorActionPreference = "Stop"
if (-not $Force) { throw "복구는 게임 자산을 교체합니다. 검토 후 -Force를 명시하세요." }
$DataRoot = Join-Path $GameRoot "SwayingGirl_Data"
$RecordPath = Join-Path $BackupRoot "backup-manifest.json"
if (-not (Test-Path -LiteralPath $RecordPath)) { throw "backup-manifest.json이 없습니다: $BackupRoot" }
$Record = Get-Content -LiteralPath $RecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($Record.schema -ne "bk927.swaying-girl-backup/v1") { throw "지원하지 않는 백업입니다." }
foreach ($name in @($Record.assets)) {
    $target = Join-Path $DataRoot $name
    $backup = Join-Path (Join-Path $BackupRoot "files") $name
    if (-not (Test-Path -LiteralPath $backup)) { throw "백업 파일이 없습니다: $name" }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant() -ne $Record.patched_hashes.PSObject.Properties[$name].Value) { throw "현재 설치 hash gate 실패: $name" }
    if ((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToUpperInvariant() -ne $Record.source_hashes.PSObject.Properties[$name].Value) { throw "백업 hash gate 실패: $name" }
}
foreach ($name in @($Record.assets)) {
    $target = Join-Path $DataRoot $name
    $backup = Join-Path (Join-Path $BackupRoot "files") $name
    $temporary = Join-Path $DataRoot ($name + ".swaying-restore.tmp")
    Copy-Item -LiteralPath $backup -Destination $temporary -Force
    [IO.File]::Move($temporary, $target, $true)
}
Write-Output "Swaying Girl assets restored from $BackupRoot"
