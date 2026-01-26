function New-DeployTestVMWifiSwitch {
    [CmdletBinding()]
    param(
        [string]$SwitchName = 'External-WiFi',
        [string]$WifiAdapterName = 'Wi-Fi'
    )

    Write-Host "=== Creating Wi-Fi External VMSwitch ===" -ForegroundColor Cyan

    # --- Check 1: Does the switch already exist? ---
    $existing = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Switch '$SwitchName' already exists. Nothing to do." -ForegroundColor Green
        return
    }

    # --- Check 2: Confirm Wi-Fi adapter exists ---
    $wifi = Get-NetAdapter -Name $WifiAdapterName -ErrorAction SilentlyContinue
    if (-not $wifi) {
        Write-Warning "Wi-Fi adapter '$WifiAdapterName' not found."
        return
    }

    # --- Check 3: Confirm Wi-Fi is connected to an SSID ---
    $wifiStatus = netsh wlan show interfaces |
                  Select-String 'State|SSID' |
                  ForEach-Object { $_.ToString().Trim() }

    $state = ($wifiStatus | Where-Object { $_ -like 'State*' }) -replace 'State\s*:\s*',''
    $ssid  = ($wifiStatus | Where-Object { $_ -like 'SSID*'  }) -replace 'SSID\s*:\s*',''

    if ($state -ne 'connected' -or [string]::IsNullOrWhiteSpace($ssid)) {
        Write-Warning "Wi-Fi is not connected to an SSID. Hyper-V cannot bind a Wi-Fi switch unless connected."
        Write-Warning "Current state: '$state'  SSID: '$ssid'"
        return
    }

    Write-Host "Wi-Fi is connected to SSID '$ssid'. Proceeding..." -ForegroundColor Green

    # --- Check 4: Create the switch ---
    try {
        New-VMSwitch -Name $SwitchName `
                     -NetAdapterName $WifiAdapterName `
                     -AllowManagementOS $true `
                     -ErrorAction Stop

        Write-Host "Successfully created Wi-Fi switch '$SwitchName'." -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to create Wi-Fi switch '$SwitchName'."
        Write-Warning "Reason: $($_.Exception.Message)"
    }

    Write-Host "=== Wi-Fi switch creation complete ===" -ForegroundColor Cyan
}
