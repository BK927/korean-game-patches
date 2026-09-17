param(
    [string]$GameRoot = "D:\SteamLibrary\steamapps\common\Lair Land Story Remake Edition",
    [string]$BackupRoot = "",
    [switch]$Force
)
$ErrorActionPreference = "Stop"
if (-not $Force) { throw "복구는 현재 패치 파일을 원본으로 교체합니다. 검토 후 -Force를 명시하세요." }
$ResolvedGameRoot = [IO.Path]::GetFullPath($GameRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupBase = Join-Path $GameRoot ".korean-patch-backup"
    $Candidates = @(Get-ChildItem -LiteralPath $BackupBase -Directory -Filter "Lair-Land-Story-*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    if ($Candidates.Count -ne 1) { throw "복구 백업을 하나로 특정할 수 없습니다. -BackupRoot를 지정하세요." }
    $BackupRoot = $Candidates[0].FullName
}
$BackupRoot = [IO.Path]::GetFullPath($BackupRoot)
$RecordPath = Join-Path $BackupRoot "backup-manifest.json"
if (-not (Test-Path -LiteralPath $RecordPath)) { throw "backup-manifest.json이 없습니다: $BackupRoot" }
$Record = Get-Content -LiteralPath $RecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($relative in @($Record.relative_paths)) {
    $target = [IO.Path]::GetFullPath((Join-Path $GameRoot $relative))
    if (-not $target.StartsWith($ResolvedGameRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "게임 폴더 밖의 경로가 감지되었습니다: $relative" }
    $backup = Join-Path (Join-Path $BackupRoot "files") $relative
    if (-not (Test-Path -LiteralPath $target)) { throw "현재 대상이 없습니다: $relative" }
    if (-not (Test-Path -LiteralPath $backup)) { throw "백업 파일이 없습니다: $relative" }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Record.patched_hashes.PSObject.Properties[$relative].Value) { throw "현재 설치 hash gate 실패: $relative" }
    if ((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Record.source_hashes.PSObject.Properties[$relative].Value) { throw "백업 hash gate 실패: $relative" }
}
foreach ($relative in @($Record.relative_paths)) {
    $target = [IO.Path]::GetFullPath((Join-Path $GameRoot $relative))
    $backup = Join-Path (Join-Path $BackupRoot "files") $relative
    $temporary = $target + ".korean-restore.tmp"
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    Copy-Item -LiteralPath $backup -Destination $temporary -Force
    Copy-Item -LiteralPath $temporary -Destination $target -Force
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Record.source_hashes.PSObject.Properties[$relative].Value) { throw "복구 후 hash 실패: $relative" }
    Remove-Item -LiteralPath $temporary -Force
}
Write-Output "Lair Land Story 원본 복구 완료: $BackupRoot"
