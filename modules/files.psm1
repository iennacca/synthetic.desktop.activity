function Start-FileActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [array] $Operations,
        [Parameter(Mandatory)] [pscustomobject] $DeviceConfig
    )

    Write-Verbose 'File activity invoked.'
    Write-ActivityLog -Message 'Starting file activity with file operations.' -Level 'Information'

    try {
        $tempPath = Join-Path $env:TEMP 'synthetic-activity'
        if (-not (Test-Path $tempPath)) {
            New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
        }

        foreach ($operation in $Operations) {
            Write-Verbose "Processing file operation: $($operation.operation)"
            
            switch ($operation.operation) {
                'CreateTempFile' {
                    $filePath = Join-Path $tempPath $operation.target
                    $operation.content | Out-File -FilePath $filePath -Encoding utf8 -Force
                    Write-ActivityLog -Message "Created temp file: $($operation.target)" -Level 'Information'
                    Start-Sleep -Seconds $operation.durationSeconds
                }
                'ModifyTempFile' {
                    $filePath = Join-Path $tempPath $operation.target
                    if (Test-Path $filePath) {
                        $operation.content | Out-File -FilePath $filePath -Encoding utf8 -Append
                        Write-ActivityLog -Message "Modified temp file: $($operation.target)" -Level 'Information'
                        Start-Sleep -Seconds $operation.durationSeconds
                    }
                    else {
                        Write-ActivityLog -Message "File not found: $($operation.target)" -Level 'Warning'
                    }
                }
                'CopyTempFile' {
                    $sourcePath = Join-Path $tempPath $operation.source
                    $targetPath = Join-Path $tempPath $operation.target
                    if (Test-Path $sourcePath) {
                        Copy-Item -Path $sourcePath -Destination $targetPath -Force
                        Write-ActivityLog -Message "Copied file from $($operation.source) to $($operation.target)" -Level 'Information'
                        Start-Sleep -Seconds $operation.durationSeconds
                    }
                    else {
                        Write-ActivityLog -Message "Source file not found: $($operation.source)" -Level 'Warning'
                    }
                }
                default {
                    Write-ActivityLog -Message "Unknown file operation: $($operation.operation)" -Level 'Warning'
                }
            }
        }
    }
    catch {
        Write-ActivityLog -Message "File activity error: $_" -Level 'Error'
    }
}

Export-ModuleMember -Function Start-FileActivity
