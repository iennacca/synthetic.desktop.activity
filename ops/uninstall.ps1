<#
.SYNOPSIS
Removes local setup artifacts for synthetic desktop activity.
.DESCRIPTION
Deletes generated folders and provides cleanup guidance. Does not remove unrelated endpoint configuration.
#>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path -Path (Join-Path $root "..")
$pathsToClean = @('logs', 'temp')

foreach ($relative in $pathsToClean) {
    $path = Join-Path $repoRoot $relative
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force
        Write-Host "Removed $relative"
    }
}

Write-Host 'Cleanup complete. If you created a scheduled task for workload.ps1, remove it manually.'
