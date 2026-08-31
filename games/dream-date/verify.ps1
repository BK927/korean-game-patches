param(
    [string]$GameRoot = "D:\SteamLibrary\steamapps\common\Dream Date",
    [ValidateSet("patched", "source")][string]$State = "patched",
    [string]$OutputJson = ""
)
$ErrorActionPreference = "Stop"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Manifest = Get-Content -LiteralPath (Join-Path $PackageRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$DataRoot = Join-Path $GameRoot "Dream Date_Data"
$Names = @("resources.assets", "sharedassets0.assets", "level2")
$Observed = [ordered]@{}
$Pass = $true
foreach ($name in $Names) {
    $target = Join-Path $DataRoot $name
    if (-not (Test-Path -LiteralPath $target)) { $Pass = $false; $Observed[$name] = $null; continue }
    $Observed[$name] = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
}
if ($State -eq "patched") {
    foreach ($name in $Names) { if ($Observed[$name] -ne $Manifest.output_assets.PSObject.Properties[$name].Value.sha256) { $Pass = $false } }
    $MatchedVariant = $null
} else {
    $MatchedVariant = $null
    foreach ($variantProperty in @($Manifest.source_variants.PSObject.Properties)) {
        $isMatch = $true
        foreach ($name in $Names) { if ($Observed[$name] -ne $variantProperty.Value.source_hashes.PSObject.Properties[$name].Value) { $isMatch = $false } }
        if ($isMatch) { $MatchedVariant = $variantProperty.Name }
    }
    if ($null -eq $MatchedVariant) { $Pass = $false }
}
$Result = [ordered]@{ schema = "dream-date-release/verify/v1"; checked_at = (Get-Date).ToUniversalTime().ToString("o"); game_root = $GameRoot; state = $State; pass = $Pass; observed_sha256 = $Observed; matched_source_variant = $MatchedVariant; sidecars_touched = $false }
if (-not [string]::IsNullOrWhiteSpace($OutputJson)) { $Result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputJson -Encoding UTF8 }
$Result | ConvertTo-Json -Depth 8
if (-not $Pass) { exit 2 }
