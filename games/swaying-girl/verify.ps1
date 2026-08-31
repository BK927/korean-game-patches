param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [ValidateSet("patched", "source")][string]$State = "patched"
)
$ErrorActionPreference = "Stop"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Manifest = Get-Content -LiteralPath (Join-Path $PackageRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$DataRoot = Join-Path $GameRoot "SwayingGirl_Data"
$Names = @("sharedassets1.assets", "level1")
$Observed = [ordered]@{}
foreach ($name in $Names) {
    $path = Join-Path $DataRoot $name
    $Observed[$name] = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant() } else { $null }
}
$Pass = $true
$Variant = $null
if ($State -eq "patched") {
    foreach ($name in $Names) { if ($Observed[$name] -ne $Manifest.output_assets.PSObject.Properties[$name].Value.sha256) { $Pass = $false } }
} else {
    foreach ($property in @($Manifest.source_variants.PSObject.Properties)) {
        $match = $true
        foreach ($name in $Names) { if ($Observed[$name] -ne $property.Value.source_hashes.PSObject.Properties[$name].Value) { $match = $false } }
        if ($match) { $Variant = $property.Name }
    }
    if ($null -eq $Variant) { $Pass = $false }
}
$Result = [ordered]@{ schema="bk927.swaying-girl-verify/v1"; checked_at=(Get-Date).ToUniversalTime().ToString("o"); state=$State; pass=$Pass; matched_source_variant=$Variant; observed_sha256=$Observed }
$Result | ConvertTo-Json -Depth 6
if (-not $Pass) { exit 2 }
