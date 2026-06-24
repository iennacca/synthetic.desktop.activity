<#
.SYNOPSIS
Sets up the synthetic desktop activity scaffold on the local endpoint.
.DESCRIPTION
Creates required folders and writes a scheduled task conceptually.
#>

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path -Path (Join-Path $root "..")
$requiredDirs = @('logs', 'temp')

foreach ($dir in $requiredDirs) {
    $path = Join-Path $repoRoot $dir
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory | Out-Null
    }
}

Write-Host 'Required folders are present.'
Write-Host 'To run the workload manually, execute:'
Write-Host "powershell -ExecutionPolicy Bypass -File `"$repoRoot\scripts\workload.ps1`""

# Optional scheduled task registration is intentionally conceptual.
Write-Host 'Install complete. For endpoint automation, create a scheduled task to run workload.ps1 during business hours.'
