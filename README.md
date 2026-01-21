# pwsh-admin

Administrative PowerShell utilities for managing development environment services on Windows.

## Overview

`pwsh-admin` is a PowerShell module that provides convenient cmdlets for managing common development environment services, virtual machines, and system diagnostics. It's designed to streamline the management of SQL Server, IIS, Azure DevOps Pipelines agents, and other development-related Windows services.

## Installation

### Automatic Deployment

Run the included deployment script to install the module to your PowerShell modules folder:

```powershell
.\deploy.ps1
```

This will copy the module to `$env:USERPROFILE\OneDrive\Documents\PowerShell\Modules\pwsh-admin` and make it available for import.

### Manual Installation

Alternatively, copy the module folder to any directory in your `$env:PSModulePath`.

## Usage

After installation, import the module:

```powershell
Import-Module pwsh-admin
```

## Available Commands

### Service Management

#### `Start-WebDevelopmentServices`

Starts all services required for local Azure DevOps Server and IIS development environment in the correct dependency order.

**Managed Services:**
- SQL Server (MSSQLSERVER)
- SQL Server Agent
- IIS (WAS, W3SVC, WMSVC)
- Azure DevOps SSH Service
- Azure Pipelines Agent services

**Usage:**
```powershell
Start-WebDevelopmentServices
Start-WebDevelopmentServices -Verbose
```

#### `Stop-WebDevelopmentServices`

Stops all development environment services in the correct reverse dependency order.

**Parameters:**
- `-Force` - Forcefully stops services without waiting for dependent services
- `-Verbose` - Shows detailed output

**Usage:**
```powershell
Stop-WebDevelopmentServices
Stop-WebDevelopmentServices -Force
```

#### `Set-ServiceStartupAutomatic`

Configures all development environment services to start automatically when the machine boots.

**Usage:**
```powershell
Set-ServiceStartupAutomatic
```

#### `Set-ServiceStartupManual`

Configures all development environment services to manual startup to save resources when not developing.

**Usage:**
```powershell
Set-ServiceStartupManual
```

### Virtual Machine Management

#### `Get-VMAddress`

Retrieves the IPv4 address of a specified Hyper-V virtual machine.

**Parameters:**
- `-VMName` - Name of the VM (default: "DeployTestVM")

**Usage:**
```powershell
Get-VMAddress
Get-VMAddress -VMName "MyVM"
```

### Utilities

#### `Clear-AgentCache`

Cleans up Azure DevOps agent work directories and optionally clears NuGet and npm caches.

**Parameters:**
- `-WorkRoot` - Path to agent work directory (default: `C:\azdo-agent\_work`)
- `-Days` - Delete folders older than this many days (default: 7)
- `-ClearNuGet` - Also clear NuGet cache
- `-ClearNpm` - Also clear npm cache
- `-WhatIf` - Preview what would be deleted without actually deleting
- `-Verbose` - Show detailed output

**Usage:**
```powershell
Clear-AgentCache
Clear-AgentCache -Days 14 -ClearNuGet -ClearNpm
Clear-AgentCache -WhatIf
```

#### `Get-SystemPerformance`

Comprehensive system performance and health diagnostics tool that displays:
- CPU configuration and utilization
- Memory (RAM) usage and page file status
- Disk space across all drives
- Network adapter information
- Top CPU-consuming processes
- Top memory-consuming processes
- Optional high-frequency metrics (when elevated)

**Parameters:**
- `-HighFreq` - Include high-frequency performance counters (requires elevation)
- `-Verbose` - Show detailed diagnostic output

**Usage:**
```powershell
Get-SystemPerformance
Get-SystemPerformance -HighFreq -Verbose
```

**Note:** Some metrics require running PowerShell as Administrator. The tool will display a warning if not elevated.

## Module Structure

```
pwsh-admin/
├── deploy.ps1                              # Deployment script
├── pwsh-admin.psd1                         # Module manifest
├── pwsh-admin.psm1                         # Module loader
├── services/                               # Service management functions
│   ├── Set-ServiceStartupAutomatic.ps1
│   ├── Set-ServiceStartupManual.ps1
│   ├── Start-WebDevelopmentServices.ps1
│   └── Stop-WebDevelopmentServices.ps1
├── util/                                   # Utility functions
│   ├── Clear-AgentCache.ps1
│   └── Get-SystemPerformance.ps1
└── vm/                                     # VM management functions
    └── Get-VMAddress.ps1
```

## Requirements

- PowerShell 5.1 or higher
- Windows operating system
- Administrator privileges recommended (required for some service operations and system diagnostics)

## Module Information

- **Version:** 1.0.0
- **Author:** Timothy Little
- **Company:** Personal
- **GUID:** 11111111-2222-3333-4444-555555555555

## Common Workflows

### Starting Your Development Environment

```powershell
# Start all services
Start-WebDevelopmentServices

# Verify system performance
Get-SystemPerformance
```

### Ending Your Development Session

```powershell
# Stop all services to save resources
Stop-WebDevelopmentServices

# Set services to manual startup
Set-ServiceStartupManual
```

### Cleaning Up Development Artifacts

```powershell
# Clean agent caches and build artifacts
Clear-AgentCache -Days 14 -ClearNuGet -ClearNpm

# Preview what would be cleaned
Clear-AgentCache -WhatIf
```

### Getting VM Information

```powershell
# Get IP address of a VM
$ip = Get-VMAddress -VMName "MyDevVM"
```

## Troubleshooting

### Services Not Starting

1. Ensure you're running PowerShell as Administrator
2. Check service dependencies with `Get-Service -Name <ServiceName> | Select-Object -ExpandProperty DependentServices`
3. Review Windows Event Logs for service-specific errors

### Module Not Found After Installation

1. Verify the module path: `$env:PSModulePath -split ';'`
2. Re-run `.\deploy.ps1`
3. Restart your PowerShell session
4. Try: `Import-Module pwsh-admin -Force`

## License

Personal use.

## Contributing

This is a personal utility module. Contributions are welcome for bug fixes and enhancements.
