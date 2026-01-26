@{
    RootModule        = 'pwsh-admin.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '11111111-2222-3333-4444-555555555555'
    Author            = 'Timothy Little'
    CompanyName       = 'Personal'
    Description       = 'Administrative PowerShell utilities for managing dev environment services.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Start-WebDevelopmentServices',
        'Stop-WebDevelopmentServices',
        'Set-ServiceStartupManual',
        'Set-ServiceStartupAutomatic',
        'Get-VMAddress',
        'Set-DeployTestVMNetworkLocation',
        'Clear-AgentCache',
        'Get-SystemPerformance'
    )




    FileList          = @()
}
