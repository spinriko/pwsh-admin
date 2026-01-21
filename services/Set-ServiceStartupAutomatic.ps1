<#
.SYNOPSIS
Sets all Azure DevOps Server–related services to Automatic startup.

.DESCRIPTION
Ensures SQL Server, IIS, Azure DevOps SSH, and Azure Pipelines Agent
services auto-start when the machine boots.

.EXAMPLE
.\Set-DevServicesToAutomatic.ps1
#>

function Set-ServiceStartupAutomatic {
    param([switch]$Verbose)



    $ErrorActionPreference = "Stop"

    # Same service list used in Start/Stop/Manual scripts
    $services = @(
        @{ Name = "vstsagent.quantum.DVO.QUANTUM"; DisplayName = "Azure Pipelines Agent (quantum)" },
        @{ Name = "vstsagent.quantum.DVO.QUANTUM.updater"; DisplayName = "Azure Pipelines Agent Updater (quantum)" },
        @{ Name = "TeamFoundationSshService"; DisplayName = "Azure DevOps SSH Service" },
        @{ Name = "WMSVC"; DisplayName = "IIS Web Management Service" },
        @{ Name = "W3SVC"; DisplayName = "IIS World Wide Web Publishing Service" },
        @{ Name = "WAS"; DisplayName = "Windows Process Activation Service" },
        @{ Name = "SQLSERVERAGENT"; DisplayName = "SQL Server Agent (MSSQLSERVER)" },
        @{ Name = "MSSQLSERVER"; DisplayName = "SQL Server (MSSQLSERVER)" }
    )

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Setting Dev Environment Services to AUTOMATIC" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $updatedCount = 0
    $skippedCount = 0
    $failedCount = 0

    foreach ($service in $services) {
        $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue

        if ($null -eq $svc) {
            Write-Host "⚠ SKIP: $($service.DisplayName) (service not found)" -ForegroundColor Yellow
            $skippedCount++
            continue
        }

        try {
            Write-Host "→ Setting startup type to Automatic: $($service.DisplayName)..." -ForegroundColor Cyan
            Set-Service -Name $service.Name -StartupType Automatic -ErrorAction Stop

            Write-Host "✓ SUCCESS: $($service.DisplayName) set to Automatic" -ForegroundColor Green
            $updatedCount++
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
    Write-Host "Updated:  $updatedCount" -ForegroundColor Green
    Write-Host "Skipped:  $skippedCount" -ForegroundColor Yellow
    if ($failedCount -gt 0) {
        Write-Host "Failed:   $failedCount" -ForegroundColor Red
    }
    Write-Host ""

    if ($failedCount -gt 0) {
        exit 1
    }
}