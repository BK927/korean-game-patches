param(
    [string]$GamePath = ""
)

$ErrorActionPreference = "Stop"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManifestPath = Join-Path $PackageRoot "payload\files.json"
$BackupSuffix = ".korean-patch-backup"
$BackupList = "korean-patch-backup.txt"

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
    Add-Candidate $candidates "D:\SteamLibrary\steamapps\common\amehazu"
    if (${env:ProgramFiles(x86)}) { Add-Candidate $candidates (Join-Path ${env:ProgramFiles(x86)} "Steam\steamapps\common\amehazu") }
    if ($env:ProgramFiles)        { Add-Candidate $candidates (Join-Path $env:ProgramFiles "Steam\steamapps\common\amehazu") }

    try {
        $steamPath = (Get-ItemProperty -LiteralPath "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath
        if ($steamPath) {
            Add-Candidate $candidates (Join-Path $steamPath "steamapps\common\amehazu")
            $libraryFile = Join-Path $steamPath "steamapps\libraryfolders.vdf"
            if (Test-Path -LiteralPath $libraryFile) {
                $content = Get-Content -Raw -LiteralPath $libraryFile
                foreach ($match in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
                    Add-Candidate $candidates (Join-Path ($match.Groups[1].Value.Replace('\\','\')) "steamapps\common\amehazu")
                }
            }
        }
    } catch {}

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate "resources\app\data\scenario\first.ks")) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    $entered = (Read-Host "Enter the Absent in the Rain (amehazu) game folder").Trim('"')
    if ($entered -and (Test-Path -LiteralPath (Join-Path $entered "resources\app\data\scenario\first.ks"))) {
        return (Resolve-Path -LiteralPath $entered).Path
    }
    throw "Could not find the game folder."
}

try {
    if (-not (Test-Path -LiteralPath $ManifestPath)) { throw "Missing payload\files.json." }

    $root = Find-GameRoot $GamePath
    $appRoot = Join-Path $root "resources\app"
    Write-Host "Game folder: $root"

    $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    $entries = $manifest.entries

    # 1. put every backed-up original back
    $restored = 0
    foreach ($e in $entries) {
        $target = Join-Path $appRoot ($e.target -replace '/', '\')
        $backup = "$target$BackupSuffix"
        if (-not (Test-Path -LiteralPath $backup)) { continue }
        Copy-Item -LiteralPath $backup -Destination $target -Force
        Remove-Item -LiteralPath $backup -Force
        $restored++
    }

    # 2. delete the files the patch added
    $listPath = Join-Path $appRoot $BackupList
    $removed = 0
    $addedTargets = @()
    if (Test-Path -LiteralPath $listPath) {
        $addedTargets = Get-Content -LiteralPath $listPath | Where-Object { $_.Trim() -ne "" }
    } else {
        # fall back to the manifest: anything with no same-path original was added by us
        $addedTargets = $entries | Where-Object {
            $t = $_.target
            -not ($entries | Where-Object { $_.source -eq $t })
        } | ForEach-Object { $_.target }
    }
    foreach ($t in $addedTargets) {
        $p = Join-Path $appRoot ($t -replace '/', '\')
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force; $removed++ }
    }
    if (Test-Path -LiteralPath $listPath) { Remove-Item -LiteralPath $listPath -Force }

    # 3. drop the folders the patch created, if they are now empty
    foreach ($d in @(
        "data\scenario\scenario_ko",
        "data\image\ko",
        "tyrano\images\system\ko\menu",
        "tyrano\images\system\ko"
    )) {
        $p = Join-Path $appRoot $d
        if ((Test-Path -LiteralPath $p) -and -not (Get-ChildItem -LiteralPath $p -Force)) {
            Remove-Item -LiteralPath $p -Force
        }
    }

    # 4. confirm the originals are back
    $bad = 0
    foreach ($e in $entries) {
        if (-not $e.source) { continue }
        $src = Join-Path $appRoot ($e.source -replace '/', '\')
        if (-not (Test-Path -LiteralPath $src)) { Write-Warning "missing: $($e.source)"; $bad++; continue }
        if ((Get-Sha256 $src) -ne $e.sourceSha256) { Write-Warning "not original: $($e.source)"; $bad++ }
    }

    Write-Host ""
    Write-Host "Restored $restored original files, removed $removed patch files."
    if ($bad -gt 0) {
        Write-Warning "$bad file(s) did not match the original hash. Use Steam's 'Verify integrity of game files' to finish restoring."
        exit 1
    }
    Write-Host "All original files verified. The game is back to its unpatched state."
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
