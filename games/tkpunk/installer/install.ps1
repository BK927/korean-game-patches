param(
    [string]$GamePath = ""
)

$ErrorActionPreference = "Stop"
$OriginalSha256 = "D6F10010E181672B1D1A444BBF500035336D3B35E6D8EE26F7A9ADAC0AB6A09A"
$PatchedSha256 = "409B7385CF54616480E6CCD9EC66C0044B420531EDF34C3B9DC35A4ABD67150B"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DeltaPath = Join-Path $PackageRoot "payload\app.asar.vcdiff"
$XdeltaPath = Join-Path $PackageRoot "tools\xdelta3.exe"

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Add-Candidate([System.Collections.Generic.List[string]]$Candidates, [string]$Path) {
    if (-not [string]::IsNullOrWhiteSpace($Path) -and -not $Candidates.Contains($Path)) {
        $Candidates.Add($Path)
    }
}

function Find-GameRoot([string]$RequestedPath) {
    $candidates = [System.Collections.Generic.List[string]]::new()
    Add-Candidate $candidates ($RequestedPath.Trim('"'))
    Add-Candidate $candidates "D:\SteamLibrary\steamapps\common\tkpunk"

    if (${env:ProgramFiles(x86)}) {
        Add-Candidate $candidates (Join-Path ${env:ProgramFiles(x86)} "Steam\steamapps\common\tkpunk")
    }
    if ($env:ProgramFiles) {
        Add-Candidate $candidates (Join-Path $env:ProgramFiles "Steam\steamapps\common\tkpunk")
    }

    $steamRoots = [System.Collections.Generic.List[string]]::new()
    try {
        $steamPath = (Get-ItemProperty -LiteralPath "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath
        if ($steamPath) { $steamRoots.Add($steamPath) }
    } catch {}

    foreach ($steamRoot in $steamRoots) {
        Add-Candidate $candidates (Join-Path $steamRoot "steamapps\common\tkpunk")
        $libraryFile = Join-Path $steamRoot "steamapps\libraryfolders.vdf"
        if (Test-Path -LiteralPath $libraryFile) {
            $content = Get-Content -Raw -LiteralPath $libraryFile
            foreach ($match in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
                $library = $match.Groups[1].Value.Replace('\\', '\')
                Add-Candidate $candidates (Join-Path $library "steamapps\common\tkpunk")
            }
        }
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate "resources\app.asar")) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $entered = (Read-Host "Enter the TKPUNK game folder").Trim('"')
    if ($entered -and (Test-Path -LiteralPath (Join-Path $entered "resources\app.asar"))) {
        return (Resolve-Path -LiteralPath $entered).Path
    }
    throw "Could not find resources\app.asar. Select the game's tkpunk folder."
}

try {
    if (-not (Test-Path -LiteralPath $DeltaPath)) { throw "Missing payload\app.asar.vcdiff." }
    if (-not (Test-Path -LiteralPath $XdeltaPath)) { throw "Missing tools\xdelta3.exe." }

    $root = Find-GameRoot $GamePath
    $appAsar = Join-Path $root "resources\app.asar"
    $backup = Join-Path $root "resources\app.asar.korean-patch-backup"
    $temporary = Join-Path $root "resources\app.asar.korean-patch-new"
    $currentHash = Get-Sha256 $appAsar

    Write-Host "Game folder: $root"
    if ($currentHash -eq $PatchedSha256) {
        Write-Host "The Korean patch is already installed."
        exit 0
    }
    if ($currentHash -ne $OriginalSha256) {
        throw "Unsupported app.asar version. Current SHA-256: $currentHash"
    }

    if (Test-Path -LiteralPath $backup) {
        $backupHash = Get-Sha256 $backup
        if ($backupHash -ne $OriginalSha256) {
            throw "The existing backup is not the supported original. Move it elsewhere and retry."
        }
    } else {
        Copy-Item -LiteralPath $appAsar -Destination $backup
        Write-Host "Original backup created: $backup"
    }

    if (Test-Path -LiteralPath $temporary) {
        Remove-Item -LiteralPath $temporary -Force
    }

    Write-Host "Building the Korean app.asar..."
    & $XdeltaPath -d -s $appAsar $DeltaPath $temporary
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $temporary)) {
        throw "Xdelta failed with exit code $LASTEXITCODE."
    }

    $newHash = Get-Sha256 $temporary
    if ($newHash -ne $PatchedSha256) {
        throw "Patched file verification failed. SHA-256: $newHash"
    }

    Copy-Item -LiteralPath $temporary -Destination $appAsar -Force
    Remove-Item -LiteralPath $temporary -Force

    if ((Get-Sha256 $appAsar) -ne $PatchedSha256) {
        throw "Final verification failed. Restore the backup before launching the game."
    }

    Write-Host "Korean patch v1.0.0 installed successfully."
    Write-Host "Backup: $backup"
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
