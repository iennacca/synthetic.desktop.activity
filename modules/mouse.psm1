function Start-MouseJiggle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject] $DeviceConfig
    )

    Write-Verbose 'Mouse jiggler invoked.'
    Write-ActivityLog -Message 'Executing mouse jiggler activity.' -Level 'Information'

    try {
        Add-Type -AssemblyName System.Windows.Forms | Out-Null
        $current = [System.Windows.Forms.Cursor]::Position
        $moveMin = if ($DeviceConfig.mouseJiggle.moveMin) { [int]$DeviceConfig.mouseJiggle.moveMin } else { 5 }
        $moveMax = if ($DeviceConfig.mouseJiggle.moveMax) { [int]$DeviceConfig.mouseJiggle.moveMax } else { 10 }
        $sleepMilliseconds = if ($DeviceConfig.mouseJiggle.sleepMilliseconds) { [int]$DeviceConfig.mouseJiggle.sleepMilliseconds } else { 250 }

        if ($moveMax -lt $moveMin) { $moveMax = $moveMin }

        $moves = Get-Random -Minimum $moveMin -Maximum ($moveMax + 1)

        for ($i = 0; $i -lt $moves; $i++) {
            $deltaX = Get-Random -Minimum -10 -Maximum 10
            $deltaY = Get-Random -Minimum -10 -Maximum 10
            $newPosition = [System.Drawing.Point]::new(
                [Math]::Max(0, $current.X + $deltaX),
                [Math]::Max(0, $current.Y + $deltaY)
            )
            [System.Windows.Forms.Cursor]::Position = $newPosition
            Start-Sleep -Milliseconds $sleepMilliseconds
        }

        Write-ActivityLog -Message "Mouse jiggled $moves times." -Level 'Information'
    }
    catch {
        Write-ActivityLog -Message "Mouse jiggler failed: $_" -Level 'Warning'
    }
}

Export-ModuleMember -Function Start-MouseJiggle
