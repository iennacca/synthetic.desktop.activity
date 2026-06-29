function Initialize-KeyboardInterop {
    [CmdletBinding()]
    param()

    if (-not ([System.Management.Automation.PSTypeName]'SyntheticDesktop.KeyboardInterop').Type) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace SyntheticDesktop {
    public static class KeyboardInterop {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    }
}
'@
    }
}

function Get-KeyboardBurstApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject] $DeviceConfig,
        [Parameter()] [array] $Applications
    )

    $keyboardBurstApp = $DeviceConfig.keyboardBurst.app
    if (-not $keyboardBurstApp) {
        return $null
    }

    $appGroup = $keyboardBurstApp.group
    if ($appGroup -and $Applications) {
        $groupedApp = $Applications | Where-Object { $_.group -eq $appGroup } | Select-Object -First 1
        if ($groupedApp) {
            return $groupedApp
        }

        Write-ActivityLog -Message "No application matched keyboard burst group '$appGroup'; falling back to the configured app entry." -Level 'Warning'
    }

    return $keyboardBurstApp
}

function Start-KeyboardBurstApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject] $App
    )

    if (-not (Test-Path $App.path)) {
        Write-ActivityLog -Message "Keyboard burst application not found: $($App.path)" -Level 'Warning'
        return $null
    }

    try {
        $process = if ($App.arguments) {
            Start-Process -FilePath $App.path -ArgumentList $App.arguments -PassThru
        }
        else {
            Start-Process -FilePath $App.path -PassThru
        }

        if (-not $process) {
            return $null
        }

        $windowHandle = [IntPtr]::Zero
        for ($attempt = 0; $attempt -lt 20; $attempt++) {
            $process.Refresh()
            if ($process.MainWindowHandle -ne 0) {
                $windowHandle = [IntPtr]$process.MainWindowHandle
                break
            }

            Start-Sleep -Milliseconds 250
        }

        if ($windowHandle -ne [IntPtr]::Zero) {
            [SyntheticDesktop.KeyboardInterop]::ShowWindowAsync($windowHandle, 9) | Out-Null
            [SyntheticDesktop.KeyboardInterop]::SetForegroundWindow($windowHandle) | Out-Null
        }
        else {
            Write-ActivityLog -Message "Launched $($App.name) but could not resolve a foreground window handle." -Level 'Warning'
        }

        return $process
    }
    catch {
        Write-ActivityLog -Message "Failed to launch keyboard burst application $($App.name): $_" -Level 'Warning'
        return $null
    }
}

function Stop-KeyboardBurstApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [System.Diagnostics.Process] $Process,
        [Parameter(Mandatory)] [string] $AppName
    )

    try {
        $Process.Refresh()
        if ($Process.HasExited) {
            Write-ActivityLog -Message "$AppName exited naturally after the keyboard burst." -Level 'Information'
            return
        }

        if ($Process.CloseMainWindow()) {
            if ($Process.WaitForExit(5000)) {
                Write-ActivityLog -Message "Closed keyboard burst application: $AppName" -Level 'Information'
                return
            }
        }

        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
        Write-ActivityLog -Message "Force-closed keyboard burst application: $AppName" -Level 'Information'
    }
    catch {
        Write-ActivityLog -Message "Failed to close keyboard burst application ${AppName}: $_" -Level 'Warning'
    }
}

function Invoke-SpoofKeyPress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [byte] $VirtualKey
    )

    [SyntheticDesktop.KeyboardInterop]::keybd_event($VirtualKey, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds (Get-Random -Minimum 30 -Maximum 130)
    [SyntheticDesktop.KeyboardInterop]::keybd_event($VirtualKey, 0, 0x0002, [UIntPtr]::Zero)
}

function Start-KeyboardBurst {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject] $DeviceConfig,
        [Parameter()] [array] $Applications = @()
    )

    Write-Verbose 'Keyboard burst activity invoked.'
    $currentTime = Get-Date
    if ($script:KeyboardCooldownUntil -and $currentTime -lt $script:KeyboardCooldownUntil) {
        $remaining = [int][Math]::Ceiling(($script:KeyboardCooldownUntil - $currentTime).TotalSeconds)
        Write-ActivityLog -Message "Keyboard burst skipped due to cooldown ($remaining second(s) remaining)." -Level 'Verbose'
        return
    }

    Write-ActivityLog -Message 'Executing keyboard burst activity.' -Level 'Information'

    $keyboardBurstProcess = $null
    $keyboardBurstApp = $null

    try {
        Initialize-KeyboardInterop

        $burstMin = if ($DeviceConfig.keyboardBurst.minBursts) { [int]$DeviceConfig.keyboardBurst.minBursts } else { 1 }
        $burstMax = if ($DeviceConfig.keyboardBurst.maxBursts) { [int]$DeviceConfig.keyboardBurst.maxBursts } else { 4 }
        $pressMin = if ($DeviceConfig.keyboardBurst.minPressesPerBurst) { [int]$DeviceConfig.keyboardBurst.minPressesPerBurst } else { 2 }
        $pressMax = if ($DeviceConfig.keyboardBurst.maxPressesPerBurst) { [int]$DeviceConfig.keyboardBurst.maxPressesPerBurst } else { 8 }
        $cooldownMin = if ($DeviceConfig.keyboardBurst.cooldownSecondsMin) { [int]$DeviceConfig.keyboardBurst.cooldownSecondsMin } else { 120 }
        $cooldownMax = if ($DeviceConfig.keyboardBurst.cooldownSecondsMax) { [int]$DeviceConfig.keyboardBurst.cooldownSecondsMax } else { 300 }

        if ($burstMax -lt $burstMin) { $burstMax = $burstMin }
        if ($pressMax -lt $pressMin) { $pressMax = $pressMin }
        if ($cooldownMax -lt $cooldownMin) { $cooldownMax = $cooldownMin }

        $keyboardBurstApp = Get-KeyboardBurstApp -DeviceConfig $DeviceConfig -Applications $Applications
        if ($keyboardBurstApp) {
            Write-ActivityLog -Message "Launching keyboard burst application: $($keyboardBurstApp.name)" -Level 'Information'
            $keyboardBurstProcess = Start-KeyboardBurstApp -App $keyboardBurstApp

            if (-not $keyboardBurstProcess) {
                Write-ActivityLog -Message 'Keyboard burst application could not be started; aborting burst activity.' -Level 'Warning'
                return
            }
        }

        $keys = @(
            [byte]0x21, # PAGE UP
            [byte]0x22, # PAGE DOWN
            [byte]0x23, # END
            [byte]0x24, # HOME
            [byte]0x25, # LEFT
            [byte]0x26, # UP
            [byte]0x27, # RIGHT
            [byte]0x28  # DOWN
        )

        $bursts = Get-Random -Minimum $burstMin -Maximum ($burstMax + 1)
        $totalPresses = 0

        for ($burstIndex = 0; $burstIndex -lt $bursts; $burstIndex++) {
            $presses = Get-Random -Minimum $pressMin -Maximum ($pressMax + 1)

            for ($pressIndex = 0; $pressIndex -lt $presses; $pressIndex++) {
                $key = Get-Random -InputObject $keys
                Invoke-SpoofKeyPress -VirtualKey $key
                $totalPresses++
                Start-Sleep -Milliseconds (Get-Random -Minimum 60 -Maximum 220)
            }

            if ($burstIndex -lt ($bursts - 1)) {
                Start-Sleep -Milliseconds (Get-Random -Minimum 300 -Maximum 1200)
            }
        }

        $cooldownSeconds = Get-Random -Minimum $cooldownMin -Maximum ($cooldownMax + 1)
        $script:KeyboardCooldownUntil = (Get-Date).AddSeconds($cooldownSeconds)

        Write-ActivityLog -Message "Keyboard burst completed with $bursts burst(s), $totalPresses key press(es), cooldown $cooldownSeconds second(s)." -Level 'Information'
    }
    catch {
        Write-ActivityLog -Message "Keyboard burst failed: $_" -Level 'Warning'
    }
    finally {
        if ($keyboardBurstProcess -and $keyboardBurstApp) {
            Stop-KeyboardBurstApp -Process $keyboardBurstProcess -AppName $keyboardBurstApp.name
        }
    }
}

Export-ModuleMember -Function Start-KeyboardBurst