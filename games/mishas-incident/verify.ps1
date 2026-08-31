[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameRoot
)

& (Join-Path $PSScriptRoot 'install.ps1') -Mode Verify -GameRoot $GameRoot
exit $LASTEXITCODE
