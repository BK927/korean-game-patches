param(
    [string]$GameRoot = "D:\SteamLibrary\steamapps\common\Lair Land Story Remake Edition",
    [ValidateSet("patched", "source")][string]$State = "patched",
    [string]$OutputJson = ""
)
$ErrorActionPreference = "Stop"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Manifest = Get-Content -LiteralPath (Join-Path $PackageRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$ResolvedGameRoot = [IO.Path]::GetFullPath($GameRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$Observed = [ordered]@{}
$Pass = $true
foreach ($relative in @($Manifest.target_relative_paths)) {
    $target = [IO.Path]::GetFullPath((Join-Path $GameRoot $relative))
    if (-not $target.StartsWith($ResolvedGameRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "게임 폴더 밖의 경로가 감지되었습니다: $relative" }
    if (-not (Test-Path -LiteralPath $target)) { $Pass = $false; $Observed[$relative] = $null; continue }
    $Observed[$relative] = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
}
$MatchedVariant = $null
if ($State -eq "patched") {
    foreach ($relative in @($Manifest.target_relative_paths)) {
        if ($Observed[$relative] -ne $Manifest.output_assets.PSObject.Properties[$relative].Value.sha256) { $Pass = $false }
    }
} else {
    foreach ($variantProperty in @($Manifest.source_variants.PSObject.Properties)) {
        $match = $true
        foreach ($relative in @($Manifest.target_relative_paths)) {
            if ($Observed[$relative] -ne $variantProperty.Value.source_hashes.PSObject.Properties[$relative].Value) { $match = $false }
        }
        if ($match) { $MatchedVariant = $variantProperty.Name }
    }
    if ($null -eq $MatchedVariant) { $Pass = $false }
}
$Result = [ordered]@{ schema = "lair-land-story-korean-patch/verify/v1"; checked_at = (Get-Date).ToUniversalTime().ToString("o"); game_root = $GameRoot; state = $State; pass = $Pass; observed_sha256 = $Observed; matched_source_variant = $MatchedVariant }
if (-not [string]::IsNullOrWhiteSpace($OutputJson)) { $Result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputJson -Encoding UTF8 }
$Result | ConvertTo-Json -Depth 10
if (-not $Pass) { exit 2 }
