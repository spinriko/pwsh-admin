<#
.SYNOPSIS
Starts all services required for local Azure DevOps Server + IIS dev environment.

.DESCRIPTION
Starts SQL Server, IIS core services, Azure DevOps SSH service,
and Azure Pipelines Agent services in the correct dependency order.
#>
function Start-WebDevelopmentServices {
    param([switch]$Verbose)


    $ErrorActionPreference = "Stop"

    # Define services in startup order
    $services = @(
        @{ Name = "MSSQLSERVER"; DisplayName = "SQL Server (MSSQLSERVER)" },
        @{ Name = "SQLSERVERAGENT"; DisplayName = "SQL Server Agent (MSSQLSERVER)" },
        @{ Name = "WAS"; DisplayName = "Windows Process Activation Service" },
        @{ Name = "W3SVC"; DisplayName = "IIS World Wide Web Publishing Service" },
        @{ Name = "WMSVC"; DisplayName = "IIS Web Management Service" },

        # Azure DevOps SSH service (optional but included)
        @{ Name = "TeamFoundationSshService"; DisplayName = "Azure DevOps SSH Service" },

        # Azure DevOps Agent services (updater first)
        @{ Name = "vstsagent.quantum.DVO.QUANTUM.updater"; DisplayName = "Azure Pipelines Agent Updater (quantum)" },
        @{ Name = "vstsagent.quantum.DVO.QUANTUM"; DisplayName = "Azure Pipelines Agent (quantum)" }
    )

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Starting Dev Environment Services" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $startedCount = 0
    $skippedCount = 0
    $failedCount = 0

    foreach ($service in $services) {
        $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
    
        if ($null -eq $svc) {
            Write-Host "⚠ SKIP: $($service.DisplayName) (service not found)" -ForegroundColor Yellow
            $skippedCount++
            continue
        }
    
        if ($svc.Status -eq "Running") {
            Write-Host "✓ OK: $($service.DisplayName) (already running)" -ForegroundColor Green
            continue
        }
    
        try {
            Write-Host "→ Starting: $($service.DisplayName)..." -ForegroundColor Cyan
            Start-Service -Name $service.Name -ErrorAction Stop
        
            Start-Sleep -Milliseconds 500
        
            $svc.Refresh()
            if ($svc.Status -eq "Running") {
                Write-Host "✓ SUCCESS: $($service.DisplayName) started" -ForegroundColor Green
                $startedCount++
            }
            else {
                Write-Host "✗ FAILED: $($service.DisplayName) did not start (status: $($svc.Status))" -ForegroundColor Red
                $failedCount++
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
    Write-Host "Started:  $startedCount" -ForegroundColor Green
    Write-Host "Skipped:  $skippedCount" -ForegroundColor Yellow
    if ($failedCount -gt 0) {
        Write-Host "Failed:   $failedCount" -ForegroundColor Red
    }
    Write-Host ""

    if ($failedCount -gt 0) {
        exit 1
    }
}