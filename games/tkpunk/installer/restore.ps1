param(
    [string]$GamePath = ""
)

$ErrorActionPreference = "Stop"
$OriginalSha256 = "6796F141A3C8CBA15D7283AD98AE121AEBB33904BA1CB2EC9D62E54B0731A536"
$PatchedSha256 = "A621837E8133ACC9455BBBA263A799B8C4D3E9D324A2DDADE9E485B5971126AC"
$GameBuild = "1.0.260821.1"
$BackupFileName = "app.asar.korean-patch-backup.$GameBuild"

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
    $backup = Join-Path $root "resources\$BackupFileName"

    if (-not (Test-Path -LiteralPath $backup)) {
        throw "Original backup not found: $backup"
    }
    if ((Get-Sha256 $backup) -ne $OriginalSha256) {
        throw "Backup SHA-256 does not match the supported original."
    }

    $currentHash = Get-Sha256 $appAsar
    if ($currentHash -eq $OriginalSha256) {
        Write-Host "The original file is already installed."
        exit 0
    }
    if ($currentHash -ne $PatchedSha256) {
        throw "The current app.asar is neither the supported original nor Korean patch v1.1.0. Current SHA-256: $currentHash"
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
