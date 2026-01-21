<#
.SYNOPSIS
Stops all services required for local Azure DevOps Server + IIS dev environment.

.DESCRIPTION
Stops Azure Pipelines Agent, Azure DevOps SSH service, IIS services,
and SQL Server services in the correct reverse dependency order.
#>
function Stop-WebDevelopmentServices {
    param(
        [switch]$Force,
        [switch]$Verbose
    )

    $ErrorActionPreference = "Stop"

    # Define services in shutdown order (reverse of startup)
    $services = @(
        # Azure DevOps Agent services (agent first, then updater)
        @{ Name = "vstsagent.quantum.DVO.QUANTUM"; DisplayName = "Azure Pipelines Agent (quantum)" },
        @{ Name = "vstsagent.quantum.DVO.QUANTUM.updater"; DisplayName = "Azure Pipelines Agent Updater (quantum)" },

        # Azure DevOps SSH service
        @{ Name = "TeamFoundationSshService"; DisplayName = "Azure DevOps SSH Service" },

        # IIS services (reverse order)
        @{ Name = "WMSVC"; DisplayName = "IIS Web Management Service" },
        @{ Name = "W3SVC"; DisplayName = "IIS World Wide Web Publishing Service" },
        @{ Name = "WAS"; DisplayName = "Windows Process Activation Service" },

        # SQL services (reverse order)
        @{ Name = "SQLSERVERAGENT"; DisplayName = "SQL Server Agent (MSSQLSERVER)" },
        @{ Name = "MSSQLSERVER"; DisplayName = "SQL Server (MSSQLSERVER)" }
    )

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Stopping Dev Environment Services" -ForegroundColor Cyan
    if ($Force) { Write-Host "(FORCE mode: will forcefully stop)" -ForegroundColor Yellow }
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $stoppedCount = 0
    $skippedCount = 0
    $failedCount = 0

    foreach ($service in $services) {
        $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
    
        if ($null -eq $svc) {
            Write-Host "⚠ SKIP: $($service.DisplayName) (service not found)" -ForegroundColor Yellow
            $skippedCount++
            continue
        }
    
        if ($svc.Status -eq "Stopped") {
            Write-Host "✓ OK: $($service.DisplayName) (already stopped)" -ForegroundColor Green
            continue
        }
    
        try {
            if ($Force) {
                Write-Host "→ Force stopping: $($service.DisplayName)..." -ForegroundColor Cyan
                Stop-Service -Name $service.Name -Force -ErrorAction Stop
            }
            else {
                # Stop dependent services first
                $dependentServices = $svc.DependentServices
                if ($dependentServices) {
                    Write-Host "→ Stopping dependent services for: $($service.DisplayName)..." -ForegroundColor Cyan
                    foreach ($dependent in $dependentServices) {
                        if ($dependent.Status -ne "Stopped") {
                            Write-Host "  → Stopping dependent: $($dependent.DisplayName)..." -ForegroundColor Cyan
                            Stop-Service -Name $dependent.Name -ErrorAction Stop
                        }
                    }
                }

                Write-Host "→ Stopping: $($service.DisplayName)..." -ForegroundColor Cyan
                Stop-Service -Name $service.Name -ErrorAction Stop
            }
        
            Start-Sleep -Milliseconds 500
        
            $svc.Refresh()
            if ($svc.Status -eq "Stopped") {
                Write-Host "✓ SUCCESS: $($service.DisplayName) stopped" -ForegroundColor Green
                $stoppedCount++
            }
            else {
                Write-Host "⚠ WARNING: $($service.DisplayName) did not stop cleanly (status: $($svc.Status))" -ForegroundColor Yellow
                if (-not $Force) {
                    Write-Host "  → Retry with -Force flag if needed" -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Host "✗ ERROR: $($service.DisplayName) - $_" -ForegroundColor Red
            $failedCount++
        }
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Stopped:  $stoppedCount" -ForegroundColor Green
    Write-Host "Skipped:  $skippedCount" -ForegroundColor Yellow
    if ($failedCount -gt 0) {
        Write-Host "Failed:   $failedCount" -ForegroundColor Red
    }
    Write-Host ""

    if ($failedCount -gt 0) {
        exit 1
    }
}