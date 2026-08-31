param(
    [string]$GamePath = ""
)

$ErrorActionPreference = "Stop"
$PatchVersion = "1.0.2"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PayloadRoot = Join-Path $PackageRoot "payload"
$ManifestPath = Join-Path $PayloadRoot "files.json"
$XdeltaPath = Join-Path $PackageRoot "tools\xdelta3.exe"
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

    if (${env:ProgramFiles(x86)}) {
        Add-Candidate $candidates (Join-Path ${env:ProgramFiles(x86)} "Steam\steamapps\common\amehazu")
    }
    if ($env:ProgramFiles) {
        Add-Candidate $candidates (Join-Path $env:ProgramFiles "Steam\steamapps\common\amehazu")
    }

    $steamRoots = [System.Collections.Generic.List[string]]::new()
    try {
        $steamPath = (Get-ItemProperty -LiteralPath "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath
        if ($steamPath) { $steamRoots.Add($steamPath) }
    } catch {}

    foreach ($steamRoot in $steamRoots) {
        Add-Candidate $candidates (Join-Path $steamRoot "steamapps\common\amehazu")
        $libraryFile = Join-Path $steamRoot "steamapps\libraryfolders.vdf"
        if (Test-Path -LiteralPath $libraryFile) {
            $content = Get-Content -Raw -LiteralPath $libraryFile
            foreach ($match in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
                $library = $match.Groups[1].Value.Replace('\\', '\')
                Add-Candidate $candidates (Join-Path $library "steamapps\common\amehazu")
            }
        }
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate "resources\app\data\scenario\first.ks")) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $entered = (Read-Host "Enter the Absent in the Rain (amehazu) game folder").Trim('"')
    if ($entered -and (Test-Path -LiteralPath (Join-Path $entered "resources\app\data\scenario\first.ks"))) {
        return (Resolve-Path -LiteralPath $entered).Path
    }
    throw "Could not find resources\app\data\scenario\first.ks. Select the game's amehazu folder."
}

try {
    if (-not (Test-Path -LiteralPath $ManifestPath)) { throw "Missing payload\files.json." }
    if (-not (Test-Path -LiteralPath $XdeltaPath))   { throw "Missing tools\xdelta3.exe." }

    $root = Find-GameRoot $GamePath
    $appRoot = Join-Path $root "resources\app"
    Write-Host "Game folder: $root"

    $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    $entries = $manifest.entries

    # --- already installed? -------------------------------------------------
    $installed = 0
    foreach ($e in $entries) {
        $target = Join-Path $appRoot ($e.target -replace '/', '\')
        if ((Test-Path -LiteralPath $target) -and ((Get-Sha256 $target) -eq $e.resultSha256)) { $installed++ }
    }
    if ($installed -eq $entries.Count) {
        Write-Host "The Korean patch is already installed. Nothing to do."
        exit 0
    }
    if ($installed -gt 0) {
        Write-Host "Found a partial installation ($installed of $($entries.Count) files). It will be completed."
    }

    # --- verify every source file is the supported original -----------------
    Write-Host "Checking game files..."
    foreach ($e in $entries) {
        if (-not $e.source) { continue }
        $src = Join-Path $appRoot ($e.source -replace '/', '\')
        $backup = "$src$BackupSuffix"
        # a source that we also replace may already be patched; fall back to its backup
        if ((Test-Path -LiteralPath $backup) -and ((Get-Sha256 $backup) -eq $e.sourceSha256)) { continue }
        if (-not (Test-Path -LiteralPath $src)) { throw "Missing game file: $($e.source)" }
        $h = Get-Sha256 $src
        if ($h -ne $e.sourceSha256) {
            throw "Unsupported game version. $($e.source) has SHA-256 $h, expected $($e.sourceSha256). Verify the game files in Steam and retry."
        }
    }

    # --- back up every original we are going to overwrite -------------------
    $backupRecord = Join-Path $appRoot $BackupList
    $backedUp = New-Object System.Collections.Generic.List[string]
    foreach ($e in $entries) {
        $target = Join-Path $appRoot ($e.target -replace '/', '\')
        $isExistingOriginal = $entries | Where-Object { $_.source -eq $e.target } | Select-Object -First 1
        if ($null -eq $isExistingOriginal) { continue }   # brand new file: nothing to preserve
        $backup = "$target$BackupSuffix"
        if (-not (Test-Path -LiteralPath $backup)) {
            Copy-Item -LiteralPath $target -Destination $backup
            $backedUp.Add($e.target)
        }
    }
    if ($backedUp.Count -gt 0) {
        Write-Host "Backed up $($backedUp.Count) original files (*$BackupSuffix)."
    }

    # --- apply ---------------------------------------------------------------
    Write-Host "Applying the Korean patch..."
    $added = New-Object System.Collections.Generic.List[string]
    # Keep the original added-file list when upgrading an existing patch.
    # Otherwise every target already exists and an empty list would make restore
    # leave the patch-only files behind.
    if (Test-Path -LiteralPath $backupRecord) {
        foreach ($targetName in (Get-Content -LiteralPath $backupRecord)) {
            if ($targetName.Trim() -and -not $added.Contains($targetName)) { $added.Add($targetName) }
        }
    }
    foreach ($e in $entries) {
        $target = Join-Path $appRoot ($e.target -replace '/', '\')
        $targetDir = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Force $targetDir | Out-Null }

        $existedBefore = Test-Path -LiteralPath $target

        if ($e.delta) {
            $src = Join-Path $appRoot ($e.source -replace '/', '\')
            $backup = "$src$BackupSuffix"
            if (Test-Path -LiteralPath $backup) {
                if ((Get-Sha256 $backup) -eq $e.sourceSha256) { $src = $backup }
            }
            $delta = Join-Path $PayloadRoot ($e.delta -replace '/', '\')
            $tmp = "$target.korean-patch-new"
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
            & $XdeltaPath -d -f -s $src $delta $tmp
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmp)) {
                throw "Xdelta failed for $($e.target) (exit $LASTEXITCODE)."
            }
            $h = Get-Sha256 $tmp
            if ($h -ne $e.resultSha256) {
                Remove-Item -LiteralPath $tmp -Force
                throw "Rebuilt file did not verify: $($e.target) (SHA-256 $h)."
            }
            Move-Item -LiteralPath $tmp -Destination $target -Force
        }
        else {
            $file = Join-Path $PayloadRoot ($e.file -replace '/', '\')
            Copy-Item -LiteralPath $file -Destination $target -Force
        }

        if (-not $existedBefore -and -not $added.Contains($e.target)) { $added.Add($e.target) }
    }

    # --- verify --------------------------------------------------------------
    Write-Host "Verifying..."
    foreach ($e in $entries) {
        $target = Join-Path $appRoot ($e.target -replace '/', '\')
        $h = Get-Sha256 $target
        if ($h -ne $e.resultSha256) {
            throw "Final verification failed for $($e.target). Run RESTORE_ORIGINAL.bat before launching the game."
        }
    }

    # record what we added so restore can remove exactly those files
    $added | Set-Content -LiteralPath $backupRecord -Encoding UTF8

    Write-Host ""
    Write-Host "Korean patch v$PatchVersion installed successfully."
    Write-Host "  files written : $($entries.Count)"
    Write-Host "  originals kept: *$BackupSuffix"
    Write-Host "Pick 한국어 from the title screen's Language menu."
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
