[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameRoot,

    [string]$BackupId,
    [string]$BackupRoot
)

$arguments = @{
    Mode = 'Restore'
    GameRoot = $GameRoot
}
if (-not [string]::IsNullOrWhiteSpace($BackupId)) {
    $arguments.BackupId = $BackupId
}
if (-not [string]::IsNullOrWhiteSpace($BackupRoot)) {
    $arguments.BackupRoot = $BackupRoot
}
& (Join-Path $PSScriptRoot 'install.ps1') @arguments
exit $LASTEXITCODE
