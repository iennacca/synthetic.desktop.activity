function Initialize-ActivityLogger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $LogDirectory
    )

    if (-not (Test-Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory | Out-Null
    }

    $script:ActivityLogPath = Join-Path $LogDirectory 'synthetic-desktop-activity.log'
    Write-Verbose "Activity logger initialized at $script:ActivityLogPath"
}

function Write-ActivityLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Message,
        [Parameter()] [ValidateSet('Verbose','Information','Warning','Error')] [string] $Level = 'Information'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[$timestamp] [$Level] $Message"
    if ($script:ActivityLogPath) {
        $entry | Out-File -FilePath $script:ActivityLogPath -Append -Encoding utf8
    }
    Write-Verbose $entry
}

Export-ModuleMember -Function Initialize-ActivityLogger, Write-ActivityLog
