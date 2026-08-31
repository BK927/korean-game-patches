param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [switch]$Force,
    [string]$XdeltaPath = "",
    [string]$BackupRoot = ""
)
$ErrorActionPreference = "Stop"
if (-not $Force) { throw "릴리스 후보 설치입니다. 검토 후 -Force를 명시하세요." }
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Manifest = Get-Content -LiteralPath (Join-Path $PackageRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$DataRoot = Join-Path $GameRoot "SwayingGirl_Data"
if (-not (Test-Path -LiteralPath (Join-Path $GameRoot "SwayingGirl.exe"))) { throw "SwayingGirl.exe가 없습니다: $GameRoot" }
if (Get-Process -Name "SwayingGirl" -ErrorAction SilentlyContinue) { throw "게임을 먼저 종료하세요." }
if ([string]::IsNullOrWhiteSpace($XdeltaPath)) { $XdeltaPath = (Get-Command "xdelta3.exe" -ErrorAction Stop).Source }
if (-not (Test-Path -LiteralPath $XdeltaPath)) { throw "xdelta3를 찾을 수 없습니다: $XdeltaPath" }
$Names = @("sharedassets1.assets", "level1")
$Matches = @()
foreach ($property in @($Manifest.source_variants.PSObject.Properties)) {
    $match = $true
    foreach ($name in $Names) {
        $target = Join-Path $DataRoot $name
        if (-not (Test-Path -LiteralPath $target)) { $match = $false; continue }
        $observed = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($observed -ne $property.Value.source_hashes.PSObject.Properties[$name].Value) { $match = $false }
    }
    if ($match) { $Matches += $property }
}
$already = $true
foreach ($name in $Names) {
    $target = Join-Path $DataRoot $name
    if (-not (Test-Path -LiteralPath $target)) { $already = $false; continue }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant() -ne $Manifest.output_assets.PSObject.Properties[$name].Value.sha256) { $already = $false }
}
if ($already) { Write-Output "Swaying Girl Korean recovery is already installed."; exit 0 }
if ($Matches.Count -ne 1) { throw "원본 hash gate 실패: 일치하는 source variant 수=$($Matches.Count)" }
$VariantName = $Matches[0].Name
$Variant = $Matches[0].Value
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $GameRoot (".korean-patch-backup\Swaying-Girl\" + (Get-Date -Format "yyyyMMdd-HHmmss"))
}
$BackupRoot = [IO.Path]::GetFullPath($BackupRoot)
if (Test-Path -LiteralPath $BackupRoot) { throw "백업 경로가 이미 존재합니다: $BackupRoot" }
New-Item -ItemType Directory -Force -Path (Join-Path $BackupRoot "files") | Out-Null
$Record = [ordered]@{ schema="bk927.swaying-girl-backup/v1"; created_at=(Get-Date).ToUniversalTime().ToString("o"); game_root=$GameRoot; source_variant=$VariantName; source_hashes=[ordered]@{}; patched_hashes=[ordered]@{}; assets=$Names }
try {
    foreach ($name in $Names) {
        $target = Join-Path $DataRoot $name
        $backup = Join-Path (Join-Path $BackupRoot "files") $name
        Copy-Item -LiteralPath $target -Destination $backup -Force
        $hash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($hash -ne $Variant.source_hashes.PSObject.Properties[$name].Value) { throw "백업 hash 실패: $name" }
        $Record.source_hashes[$name] = $hash
        $Record.patched_hashes[$name] = $Manifest.output_assets.PSObject.Properties[$name].Value.sha256
    }
    $Record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $BackupRoot "backup-manifest.json") -Encoding UTF8
    foreach ($name in $Names) {
        $target = Join-Path $DataRoot $name
        $delta = Join-Path $PackageRoot $Variant.delta_files.PSObject.Properties[$name].Value
        if ((Get-FileHash -LiteralPath $delta -Algorithm SHA256).Hash.ToUpperInvariant() -ne $Variant.delta_sha256.PSObject.Properties[$name].Value) { throw "delta hash 실패: $name" }
        $temporary = Join-Path $DataRoot ($name + ".swaying-korean.tmp")
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
        & $XdeltaPath -q -d -s $target $delta $temporary
        if ($LASTEXITCODE -ne 0) { throw "xdelta 적용 실패: $name" }
        $expected = $Manifest.output_assets.PSObject.Properties[$name].Value.sha256
        if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expected) { throw "임시 출력 hash 실패: $name" }
        [IO.File]::Move($temporary, $target, $true)
    }
    Write-Output "Swaying Girl Korean recovery installed. source=$VariantName backup=$BackupRoot"
} catch {
    $message = $_.Exception.Message
    foreach ($name in $Names) {
        $backup = Join-Path (Join-Path $BackupRoot "files") $name
        if (Test-Path -LiteralPath $backup) { Copy-Item -LiteralPath $backup -Destination (Join-Path $DataRoot $name) -Force }
    }
    throw "설치 실패. 자동 롤백 완료: $message"
}
