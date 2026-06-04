function Start-BrowserActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [array] $Websites,
        [Parameter(Mandatory)] [pscustomobject] $DeviceConfig
    )

    Write-Verbose 'Browser activity invoked.'
    Write-ActivityLog -Message 'Starting browser activity.' -Level 'Information'

    try {
        $website = $Websites | Get-Random
        if (-not $website) {
            Write-ActivityLog -Message 'No websites configured.' -Level 'Warning'
            return
        }

        $browserPath = $null
        $browserName = $null

        # TO-DO: implement this in applications.json
        $edgePath = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
        $chromePath = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
        $chromePath2 = 'C:\Program Files\Google\Chrome\Application\chrome.exe'

        if (Test-Path $edgePath) {
            $browserPath = $edgePath
            $browserName = 'Microsoft Edge'
        }
        elseif (Test-Path $chromePath) {
            $browserPath = $chromePath
            $browserName = 'Google Chrome'
        }
        elseif (Test-Path $chromePath2) {
            $browserPath = $chromePath2
            $browserName = 'Google Chrome'
        }
        else {
            Write-ActivityLog -Message 'No supported browser found (Edge or Chrome).' -Level 'Warning'
            return
        }

        Write-ActivityLog -Message "Opening URL: $($website.url) - Activity: $($website.activityHint)" -Level 'Information'
        
        try {
            $process = Start-Process -FilePath $browserPath -ArgumentList $website.url -PassThru
            
            if ($process) {
                $duration = if ($website.durationSeconds -and $website.durationSeconds -gt 0) {
                    $website.durationSeconds
                }
                else {
                    Get-Random -Minimum 20 -Maximum 60
                }

                Write-ActivityLog -Message "Simulating browsing for $duration seconds." -Level 'Information'
                Start-Sleep -Seconds $duration
                
                $process | Stop-Process -Force -ErrorAction SilentlyContinue | Out-Null
                Write-ActivityLog -Message "Browser closed." -Level 'Information'
            }
        }
        catch {
            Write-ActivityLog -Message "Failed to open browser with URL $($website.url): $_" -Level 'Warning'
        }
    }
    catch {
        Write-ActivityLog -Message "Browser activity error: $_" -Level 'Error'
    }
}

Export-ModuleMember -Function Start-BrowserActivity
