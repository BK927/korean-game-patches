param(
    [string]$GamePath = ""
)

$ErrorActionPreference = "Stop"
$OriginalSha256 = "D6F10010E181672B1D1A444BBF500035336D3B35E6D8EE26F7A9ADAC0AB6A09A"

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

    try {
        $steamRoot = (Get-ItemProperty -LiteralPath "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath
        if ($steamRoot) {
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
    } catch {}

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
    $root = Find-GameRoot $GamePath
    $appAsar = Join-Path $root "resources\app.asar"
    $backup = Join-Path $root "resources\app.asar.korean-patch-backup"

    if (-not (Test-Path -LiteralPath $backup)) {
        throw "Original backup not found: $backup"
    }
    if ((Get-Sha256 $backup) -ne $OriginalSha256) {
        throw "Backup SHA-256 does not match the supported original."
    }

    if ((Get-Sha256 $appAsar) -eq $OriginalSha256) {
        Write-Host "The original file is already installed."
        exit 0
    }

    Copy-Item -LiteralPath $backup -Destination $appAsar -Force
    if ((Get-Sha256 $appAsar) -ne $OriginalSha256) {
        throw "Restore verification failed."
    }

    Write-Host "Original app.asar restored successfully."
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
