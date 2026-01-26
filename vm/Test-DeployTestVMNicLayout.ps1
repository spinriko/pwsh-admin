function Test-DeployTestVMNicLayout {
    [CmdletBinding()]
    param(
        [string]$VMName = 'DeployTestVM',
        [string]$InternalSwitch = 'InternalSwitch',
        [string]$UplinkSwitchHome = 'External-Ethernet',
        [string]$UplinkSwitchCorp = 'External-WiFi',
        [string]$InternalNicName = 'InternalNIC',
        [string]$UplinkNicName = 'UplinkNIC'
    )

    Write-Host "=== Validating NIC layout for $VMName ===" -ForegroundColor Cyan

    # Pull NICs
    $vmNics = Get-VMNetworkAdapter -VMName $VMName

    # Expected NICs
    $internalNic = $vmNics | Where-Object Name -eq $InternalNicName
    $uplinkNic   = $vmNics | Where-Object Name -eq $UplinkNicName

    # --- Check 1: Internal NIC exists ---
    Write-Host "`n[Check] Internal NIC presence" -ForegroundColor Yellow
    if ($internalNic) {
        Write-Host "✓ InternalNIC exists" -ForegroundColor Green
    } else {
        Write-Warning "InternalNIC '$InternalNicName' is missing."
    }

    # --- Check 2: Internal NIC is on the correct switch ---
    Write-Host "`n[Check] Internal NIC switch binding" -ForegroundColor Yellow
    if ($internalNic -and $internalNic.SwitchName -eq $InternalSwitch) {
        Write-Host "✓ InternalNIC is attached to '$InternalSwitch'" -ForegroundColor Green
    } else {
        Write-Warning "InternalNIC is attached to '$($internalNic.SwitchName)' instead of '$InternalSwitch'."
    }

    # --- Check 3: Uplink NIC exists ---
    Write-Host "`n[Check] Uplink NIC presence" -ForegroundColor Yellow
    if ($uplinkNic) {
        Write-Host "✓ UplinkNIC exists" -ForegroundColor Green
    } else {
        Write-Warning "UplinkNIC '$UplinkNicName' is missing."
    }

    # --- Check 4: Uplink NIC is on one of the valid switches ---
    Write-Host "`n[Check] Uplink NIC switch binding" -ForegroundColor Yellow
    $validUplinkSwitches = @($UplinkSwitchHome, $UplinkSwitchCorp)

    if ($uplinkNic -and $validUplinkSwitches -contains $uplinkNic.SwitchName) {
        Write-Host "✓ UplinkNIC is attached to valid switch '$($uplinkNic.SwitchName)'" -ForegroundColor Green
    } else {
        Write-Warning "UplinkNIC is attached to '$($uplinkNic.SwitchName)', which is not a valid uplink switch."
    }

    # --- Check 5: No unexpected NICs ---
    Write-Host "`n[Check] Unexpected NICs" -ForegroundColor Yellow
    $expectedNames = @($InternalNicName, $UplinkNicName)
    $unexpected = $vmNics | Where-Object { $expectedNames -notcontains $_.Name }

    if ($unexpected) {
        Write-Warning "Unexpected NICs detected:"
        $unexpected | Format-Table Name,SwitchName -AutoSize
    } else {
        Write-Host "✓ No unexpected NICs found" -ForegroundColor Green
    }

    Write-Host "`nNIC layout validation complete." -ForegroundColor Cyan
}
