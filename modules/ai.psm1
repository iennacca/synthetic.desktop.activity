function Start-AIActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [array] $Prompts,
        [Parameter(Mandatory)] [pscustomobject] $DeviceConfig
    )

    Write-Verbose 'AI activity invoked.'
    Write-ActivityLog -Message 'Executing AI activity.' -Level 'Information'

    $providers = @(
        [pscustomobject]@{
            Name = 'ChatGPT'
            UrlTemplate = 'https://chat.openai.com'
        },
        [pscustomobject]@{
            Name = 'Duck.ai'
            UrlTemplate = 'https://duck.ai/?q={0}'
        },
        [pscustomobject]@{
            Name = 'Perplexity'
            UrlTemplate = 'https://www.perplexity.ai/search?q={0}'
        }
    )

    $promptEntry = Get-Random -InputObject $Prompts
    $promptText = if ($promptEntry -and $promptEntry.prompt) { $promptEntry.prompt } else { 'Open the browser and review a generic AI research overview page.' }
    $provider = Get-Random -InputObject $providers
    $encodedPrompt = [System.Uri]::EscapeDataString($promptText)

    if ($provider.UrlTemplate -match '\{0\}') {
        $url = $provider.UrlTemplate -f $encodedPrompt
    }
    else {
        $url = $provider.UrlTemplate
    }

    Write-ActivityLog -Message "Opening Edge for AI provider '$($provider.Name)' with prompt '$promptText'." -Level 'Information'

    try {
        Start-Process -FilePath 'msedge.exe' -ArgumentList $url
    }
    catch {
        Write-ActivityLog -Message "Failed to launch Edge for AI activity: $_" -Level 'Warning'
    }
}

Export-ModuleMember -Function Start-AIActivity
