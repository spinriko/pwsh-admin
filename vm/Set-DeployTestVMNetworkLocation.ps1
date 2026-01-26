function Set-DeployTestVMNetworkLocation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Home','Corp')]
        [string]$Location,

        [string]$VMName = 'DeployTestVM',
        [string]$AdapterName = 'UplinkNIC'
    )

    # Map the location to the correct switch
    $switchName = switch ($Location) {
        'Home' { 'External-Ethernet' }
        'Corp' { 'External-WiFi' }
    }

    Write-Host "Switching '$VMName' adapter '$AdapterName' to '$switchName'..." -ForegroundColor Cyan

    try {
        Connect-VMNetworkAdapter -VMName $VMName -Name $AdapterName -SwitchName $switchName -ErrorAction Stop
        Write-Host "Successfully switched. Run 'ipconfig /renew' inside the VM if needed." -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to switch '$VMName' to '$switchName'."
        Write-Warning "Reason: $($_.Exception.Message)"
        Write-Warning "If you're at corp, ensure Wi-Fi is connected before using the 'Corp' location."
    }
}
