param(
    [string]$GameDir = ""
)

$ErrorActionPreference = "Stop"

function Add-Candidate([System.Collections.Generic.List[string]]$Candidates, [string]$Path) {
    if (-not [string]::IsNullOrWhiteSpace($Path) -and -not $Candidates.Contains($Path)) {
        $Candidates.Add($Path)
    }
}

function Find-GameDir([string]$RequestedPath) {
    $Candidates = [System.Collections.Generic.List[string]]::new()
    Add-Candidate $Candidates ($RequestedPath.Trim('"'))
    Add-Candidate $Candidates "D:\SteamLibrary\steamapps\common\Surmount"
    if (${env:ProgramFiles(x86)}) {
        Add-Candidate $Candidates (Join-Path ${env:ProgramFiles(x86)} "Steam\steamapps\common\Surmount")
    }
    if ($env:ProgramFiles) {
        Add-Candidate $Candidates (Join-Path $env:ProgramFiles "Steam\steamapps\common\Surmount")
    }
    try {
        $SteamRoot = (Get-ItemProperty -LiteralPath "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath
        Add-Candidate $Candidates (Join-Path $SteamRoot "steamapps\common\Surmount")
        $LibraryFile = Join-Path $SteamRoot "steamapps\libraryfolders.vdf"
        if (Test-Path -LiteralPath $LibraryFile) {
            $Content = Get-Content -LiteralPath $LibraryFile -Raw
            foreach ($Match in [regex]::Matches($Content, '"path"\s+"([^"]+)"')) {
                $Library = $Match.Groups[1].Value.Replace('\\', '\')
                Add-Candidate $Candidates (Join-Path $Library "steamapps\common\Surmount")
            }
        }
    } catch {}
    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath (Join-Path $Candidate "Surmount_Data\resources.assets") -PathType Leaf) {
            return (Resolve-Path -LiteralPath $Candidate).Path
        }
    }
    $Entered = (Read-Host "Surmount 게임 폴더를 입력하세요").Trim('"')
    if ($Entered -and (Test-Path -LiteralPath (Join-Path $Entered "Surmount_Data\resources.assets") -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $Entered).Path
    }
    throw "Surmount 설치 폴더를 찾지 못했습니다."
}

function Read-RegistryState([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "설치 당시 레지스트리 상태 파일을 찾을 수 없습니다: $Path"
    }
    $payload = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($payload.state_version -ne 1 -or
        $payload.registry_path -ne $RegistryPath -or
        $payload.property_name -ne $LanguageProperty -or
        $null -eq $payload.registry_state) {
        throw "레지스트리 상태 파일 형식이 올바르지 않습니다: $Path"
    }
    if ($null -eq $payload.registry_state.key_exists -or
        $null -eq $payload.registry_state.property_exists -or
        ([bool]$payload.registry_state.property_exists -and
            [string]::IsNullOrWhiteSpace([string]$payload.registry_state.property_type))) {
        throw "레지스트리 상태 파일의 값 정보가 올바르지 않습니다: $Path"
    }
    $payload
}

$GameDir = Find-GameDir $GameDir
$TargetPath = Join-Path $GameDir "Surmount_Data\resources.assets"
$BackupPath = "$TargetPath.koreanpatch-original"
$RestoreTempPath = "$TargetPath.koreanpatch-restore"
$PatchDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManifestPath = Join-Path $PatchDir "manifest.json"
$RegistryPath = "HKCU:\Software\MaopaoStudio\Surmount"
$LanguageProperty = "option_language"
$StatePath = Join-Path $GameDir "Surmount.koreanpatch-state.json"

if (-not (Test-Path -LiteralPath $BackupPath -PathType Leaf)) {
    throw "복원용 원본 백업을 찾을 수 없습니다. Steam 무결성 검사를 이용해 주세요."
}
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "manifest.json을 찾을 수 없습니다."
}

$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$BackupHash = (Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash
if ($BackupHash -ne $Manifest.original_sha256) {
    throw "복원용 백업의 해시가 지원 원본과 다릅니다. 대상 파일은 변경하지 않았습니다. Steam 무결성 검사를 이용해 주세요."
}

$State = Read-RegistryState $StatePath
$RegistryState = $State.registry_state
$PropertyExists = [bool]$RegistryState.property_exists
if ($PropertyExists) {
    $PropertyType = [string]$RegistryState.property_type
    $SupportedPropertyTypes = @("String", "ExpandString", "Binary", "DWord", "QWord", "MultiString")
    if ($SupportedPropertyTypes -notcontains $PropertyType) {
        throw "저장된 레지스트리 값 형식을 복구할 수 없습니다: $PropertyType"
    }
}

if (Test-Path -LiteralPath $RestoreTempPath -PathType Leaf) {
    Remove-Item -LiteralPath $RestoreTempPath -Force
}
Copy-Item -LiteralPath $BackupPath -Destination $RestoreTempPath
$RestoreTempHash = (Get-FileHash -LiteralPath $RestoreTempPath -Algorithm SHA256).Hash
if ($RestoreTempHash -ne $Manifest.original_sha256) {
    Remove-Item -LiteralPath $RestoreTempPath -Force -ErrorAction SilentlyContinue
    throw "임시 복원 파일의 해시 검증에 실패했습니다. 대상 파일은 변경하지 않았습니다."
}

Move-Item -LiteralPath $RestoreTempPath -Destination $TargetPath -Force
$RestoredHash = (Get-FileHash -LiteralPath $TargetPath -Algorithm SHA256).Hash
if ($RestoredHash -ne $Manifest.original_sha256) {
    throw "복원한 파일이 지원 원본과 일치하지 않습니다. Steam 무결성 검사를 이용해 주세요."
}

if ($PropertyExists) {
    $RestoreValue = switch ($PropertyType) {
        "DWord" { [int]$RegistryState.value; break }
        "QWord" { [long]$RegistryState.value; break }
        "Binary" { [byte[]]@($RegistryState.value | ForEach-Object { [byte]$_ }); break }
        "MultiString" { [string[]]@($RegistryState.value | ForEach-Object { [string]$_ }); break }
        default { [string]$RegistryState.value; break }
    }
    New-Item -Path $RegistryPath -Force | Out-Null
    New-ItemProperty -Path $RegistryPath -Name $LanguageProperty -PropertyType $PropertyType -Value $RestoreValue -Force | Out-Null
} elseif (Test-Path -LiteralPath $RegistryPath) {
    $RegistryKey = Get-Item -LiteralPath $RegistryPath -ErrorAction Stop
    if ($RegistryKey.GetValueNames() -contains $LanguageProperty) {
        Remove-ItemProperty -LiteralPath $RegistryPath -Name $LanguageProperty -Force
    }
}

Remove-Item -LiteralPath $StatePath -Force
Write-Host "원본 게임 파일과 설치 전 언어 설정으로 복원했습니다: $RestoredHash"
