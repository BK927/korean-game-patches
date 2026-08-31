param(
    [string]$GameDir = ""
)

$ErrorActionPreference = "Stop"
$PatchDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManifestPath = Join-Path $PatchDir "manifest.json"
$DeltaPath = Join-Path $PatchDir "payload\resources.assets.xdelta"
$DecoderPath = Join-Path $PatchDir "tools\xdelta3.exe"
$RegistryPath = "HKCU:\Software\MaopaoStudio\Surmount"
$LanguageProperty = "option_language"

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

function Get-RegistryState([string]$Path, [string]$PropertyName) {
    $keyExists = Test-Path -LiteralPath $Path
    $propertyExists = $false
    $propertyType = $null
    $value = $null
    if ($keyExists) {
        $key = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($key.GetValueNames() -contains $PropertyName) {
            $propertyExists = $true
            $propertyType = $key.GetValueKind($PropertyName).ToString()
            $value = (Get-ItemProperty -LiteralPath $Path -Name $PropertyName -ErrorAction Stop).$PropertyName
        }
    }
    [ordered]@{
        key_exists      = [bool]$keyExists
        property_exists = [bool]$propertyExists
        property_type   = $propertyType
        value           = $value
    }
}

function Write-RegistryState([string]$Path, [object]$State) {
    $payload = [ordered]@{
        state_version  = 1
        registry_path  = $RegistryPath
        property_name  = $LanguageProperty
        registry_state = $State
    }
    $temporaryStatePath = "$Path.tmp"
    if (Test-Path -LiteralPath $temporaryStatePath -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryStatePath -Force
    }
    $payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $temporaryStatePath -Encoding UTF8
    Move-Item -LiteralPath $temporaryStatePath -Destination $Path -Force
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
$TempPath = "$TargetPath.koreanpatch-new"
$StatePath = Join-Path $GameDir "Surmount.koreanpatch-state.json"

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "manifest.json을 찾을 수 없습니다."
}
if (-not (Test-Path -LiteralPath $DeltaPath -PathType Leaf)) {
    throw "한글 패치 파일을 찾을 수 없습니다."
}
if (-not (Test-Path -LiteralPath $DecoderPath -PathType Leaf)) {
    throw "xdelta 도구를 찾을 수 없습니다."
}
if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
    throw "Surmount 설치 경로가 올바르지 않습니다: $GameDir"
}
Write-Host "게임 폴더: $GameDir"

$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$CurrentHash = (Get-FileHash -LiteralPath $TargetPath -Algorithm SHA256).Hash

if ($CurrentHash -eq $Manifest.patch_sha256) {
    Write-Host "이미 한글 패치가 설치되어 있습니다."
    [void](Read-RegistryState $StatePath)
} else {
    if ($CurrentHash -ne $Manifest.original_sha256) {
        throw "지원하지 않는 게임 버전입니다. Steam 무결성 검사를 한 뒤 다시 실행해 주세요."
    }
    if (Test-Path -LiteralPath $BackupPath -PathType Leaf) {
        $ExistingBackupHash = (Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash
        if ($ExistingBackupHash -ne $Manifest.original_sha256) {
            throw "기존 원본 백업의 해시가 지원 원본과 다릅니다. 백업을 삭제하지 말고 Steam 무결성 검사를 이용해 주세요."
        }
    } else {
        Copy-Item -LiteralPath $TargetPath -Destination $BackupPath
        $CreatedBackupHash = (Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash
        if ($CreatedBackupHash -ne $Manifest.original_sha256) {
            throw "생성한 원본 백업의 해시 검증에 실패했습니다."
        }
    }
    if (Test-Path -LiteralPath $TempPath -PathType Leaf) {
        Remove-Item -LiteralPath $TempPath -Force
    }
    & $DecoderPath -d -s $TargetPath $DeltaPath $TempPath
    if ($LASTEXITCODE -ne 0) {
        throw "xdelta 패치 적용에 실패했습니다."
    }
    $InstalledHash = (Get-FileHash -LiteralPath $TempPath -Algorithm SHA256).Hash
    if ($InstalledHash -ne $Manifest.patch_sha256) {
        Remove-Item -LiteralPath $TempPath -Force -ErrorAction SilentlyContinue
        throw "설치 후 파일 검증에 실패했습니다."
    }

    # Save the pre-install language setting before changing either the target
    # registry value or the game file. This makes a complete rollback possible.
    $RegistryState = Get-RegistryState $RegistryPath $LanguageProperty
    Write-RegistryState $StatePath $RegistryState
    Move-Item -LiteralPath $TempPath -Destination $TargetPath -Force
    $InstalledTargetHash = (Get-FileHash -LiteralPath $TargetPath -Algorithm SHA256).Hash
    if ($InstalledTargetHash -ne $Manifest.patch_sha256) {
        throw "교체 후 파일 검증에 실패했습니다."
    }
    Write-Host "Surmount 한글 패치를 설치했습니다."
}

New-Item -Path $RegistryPath -Force | Out-Null
New-ItemProperty -Path $RegistryPath -Name $LanguageProperty -PropertyType DWord -Value 1 -Force | Out-Null
Write-Host "게임 언어를 한국어 슬롯으로 설정했습니다."
