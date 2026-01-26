# pwsh-admin.psm1

# Services
. $PSScriptRoot/services/Start-WebDevelopmentServices.ps1
. $PSScriptRoot/services/Stop-WebDevelopmentServices.ps1
. $PSScriptRoot/services/Set-ServiceStartupManual.ps1
. $PSScriptRoot/services/Set-ServiceStartupAutomatic.ps1

# VM
. $PSScriptRoot/vm/Get-VMAddress.ps1
. $PSScriptRoot/vm/Set-DeployTestVMNetworkLocation.ps1
. $PSScriptRoot/vm/TestDeployTestVMNetworkHealth.ps1
. $PSScriptRoot/vm/Test-DeployTestVMNicLayout

# Utilities
. $PSScriptRoot/util/Clear-AgentCache.ps1
. $PSScriptRoot/util/Get-SystemPerformance.ps1

# Exported functions
Export-ModuleMember -Function `
    Start-WebDevelopmentServices, `
    Stop-WebDevelopmentServices, `
    Set-ServiceStartupManual, `
    Set-ServiceStartupAutomatic, `
    Get-VMAddress, `
    Set-DeployTestVMNetworkLocation, `
    Test-DeployTestVMNetworkHealth, `
    Test-DeployTestVMNicLayout, `
    Clear-AgentCache, `
    Get-SystemPerformance
