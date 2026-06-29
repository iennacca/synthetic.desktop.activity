<#
.SYNOPSIS
Endpoint workload loop for synthetic desktop activity.
.DESCRIPTION
Loads local JSON configuration and runs a randomized, modular activity loop.
#>

[CmdletBinding()]
param()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path -Path (Join-Path $ScriptDir "..")
$configPath = Join-Path $RepoRoot "config"
$modulePath = Join-Path $RepoRoot "modules"

Import-Module (Join-Path $modulePath "browser.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $modulePath "applications.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $modulePath "files.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $modulePath "ai.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $modulePath "input.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $modulePath "mouse.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $modulePath "keyboard.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $modulePath "logging.psm1") -Force -ErrorAction Stop

function Load-JsonConfig {
    param(
        [Parameter(Mandatory)] [string] $Path
    )
    if (-Not (Test-Path $Path)) {
        throw "Configuration file not found: $Path"
    }

    Get-Content -Path $Path -Raw | ConvertFrom-Json
}

function Is-BusinessHour {
    param(
        [Parameter(Mandatory)] [pscustomobject] $BusinessHours
    )

    $now = Get-Date
    $today = $now.DayOfWeek.ToString()
    $window = $BusinessHours | Where-Object { $_.day -eq $today }
    if (-not $window) { return $false }

    $start = [DateTime]::ParseExact($window.start, 'HH:mm', $null)
    $end = [DateTime]::ParseExact($window.end, 'HH:mm', $null)
    $currentTime = Get-Date -Format 'HH:mm'
    $current = [DateTime]::ParseExact($currentTime, 'HH:mm', $null)

    return ($current -ge $start -and $current -le $end)
}

function Get-RandomActivity {
    param(
        [Parameter(Mandatory)] [pscustomobject] $DeviceConfig
    )

    $actions = @()
    if ($DeviceConfig.features.browser) { $actions += 'Browser' }
    if ($DeviceConfig.features.applications) { $actions += 'Application' }
    if ($DeviceConfig.features.files) { $actions += 'File' }
    if ($DeviceConfig.features.ai) { $actions += 'AI' }
    if ($DeviceConfig.features.mouse -eq $true) { $actions += 'Mouse' }
    if ($DeviceConfig.features.keyboard -eq $true) { $actions += 'Keyboard' }
    $actions += 'Idle'

    return Get-Random -InputObject $actions
}

function Start-Workload {
    param(
        [Parameter(Mandatory)] [pscustomobject] $DeviceConfig,
        [Parameter(Mandatory)] [array] $Websites,
        [Parameter(Mandatory)] [array] $Applications,
        [Parameter(Mandatory)] [array] $FileOperations,
        [Parameter(Mandatory)] [array] $AIPrompts
    )

    Write-ActivityLog -Message 'Starting synthetic desktop workload.' -Level 'Information'

    while ($true) {
        if (-not (Is-BusinessHour -BusinessHours $DeviceConfig.businessHours)) {
            Write-ActivityLog -Message 'Outside business hours. Sleeping until next check.' -Level 'Verbose'
            Start-Sleep -Seconds 300
            continue
        }

        $activityType = Get-RandomActivity -DeviceConfig $DeviceConfig
        Write-ActivityLog -Message "Selected activity: $activityType" -Level 'Verbose'

        switch ($activityType) {
            'Browser' {
                Start-BrowserActivity -Websites $Websites -DeviceConfig $DeviceConfig
            }
            'Application' {
                Start-ApplicationActivity -Applications $Applications -DeviceConfig $DeviceConfig
            }
            'File' {
                Start-FileActivity -Operations $FileOperations -DeviceConfig $DeviceConfig
            }
            'AI' {
                Start-AIActivity -Prompts $AIPrompts -DeviceConfig $DeviceConfig
            }
            'Mouse' {
                Start-MouseJiggle -DeviceConfig $DeviceConfig
            }
            'Keyboard' {
                Start-KeyboardBurst -DeviceConfig $DeviceConfig -Applications $Applications
            }
            'Idle' {
                Start-IdleCycle -DeviceConfig $DeviceConfig
            }
        }

        $pause = Get-Random -Minimum $DeviceConfig.activityInterval.min -Maximum $DeviceConfig.activityInterval.max
        Write-ActivityLog -Message "Pausing for $pause seconds." -Level 'Verbose'
        Start-Sleep -Seconds $pause
    }
}

try {
    $deviceConfig = Load-JsonConfig -Path (Join-Path $configPath 'device.json')
    $websites = Load-JsonConfig -Path (Join-Path $configPath 'websites.json')
    $applications = Load-JsonConfig -Path (Join-Path $configPath 'applications.json')
    $fileOperations = Load-JsonConfig -Path (Join-Path $configPath 'files.json')
    $aiPrompts = Load-JsonConfig -Path (Join-Path $configPath 'ai-prompts.json')

    Initialize-ActivityLogger -LogDirectory (Join-Path $RepoRoot 'logs')
    Start-Workload -DeviceConfig $deviceConfig -Websites $websites -Applications $applications -FileOperations $fileOperations -AIPrompts $aiPrompts
}
catch {
    Write-Error "Failed to start synthetic workload: $_"
    exit 1
}
