function Start-ApplicationActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [array] $Applications,
        [Parameter(Mandatory)] [pscustomobject] $DeviceConfig
    )

    Write-Verbose 'Application activity invoked.'
    Write-ActivityLog -Message 'Starting application activity.' -Level 'Information'

    try {
        $app = $Applications | Get-Random
        if (-not $app) {
            Write-ActivityLog -Message 'No applications configured.' -Level 'Warning'
            return
        }

        if (-not (Test-Path $app.path)) {
            Write-ActivityLog -Message "Application not found: $($app.path)" -Level 'Warning'
            return
        }

        Write-ActivityLog -Message "Launching application: $($app.name)" -Level 'Information'
        
        try {
            $process = if ($app.arguments) {
                Start-Process -FilePath $app.path -ArgumentList $app.arguments -PassThru
            }
            else {
                Start-Process -FilePath $app.path -PassThru
            }

            if ($process) {
                Write-ActivityLog -Message "$($app.name) started with PID $($process.Id)." -Level 'Information'
                
                $duration = if ($app.durationSeconds -and $app.durationSeconds -gt 0) {
                    $app.durationSeconds
                }
                else {
                    Get-Random -Minimum 10 -Maximum 30
                }

                Start-Sleep -Seconds $duration
                
                if (-not $process.HasExited) {
                    $process | Stop-Process -Force -ErrorAction SilentlyContinue
                    Write-ActivityLog -Message "Closed application: $($app.name)" -Level 'Information'
                }
                else {
                    Write-ActivityLog -Message "$($app.name) exited naturally." -Level 'Information'
                }
            }
        }
        catch {
            Write-ActivityLog -Message "Failed to launch $($app.name): $_" -Level 'Warning'
        }
    }
    catch {
        Write-ActivityLog -Message "Application activity error: $_" -Level 'Error'
    }
}

Export-ModuleMember -Function Start-ApplicationActivity
