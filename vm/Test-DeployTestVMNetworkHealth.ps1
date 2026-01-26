function Test-DeployTestVMNetworkHealth {
    [CmdletBinding()]
    param(
        [string]$VMName = 'DeployTestVM',
        [string]$UplinkSwitchHome = 'External-Ethernet',
        [string]$UplinkSwitchCorp = 'External-WiFi',
        [string]$InternalSwitch = 'InternalSwitch'
    )

    Write-Host "=== DeployTestVM Network Health ===" -ForegroundColor Cyan

    # --- Host: switches ---
    Write-Host "`n[Host] VMSwitches" -ForegroundColor Yellow
    $switches = Get-VMSwitch | Select-Object Name,SwitchType,NetAdapterInterfaceDescription
    $switches | Format-Table -AutoSize

    # --- Host: vEthernet adapters for external switches ---
    Write-Host "`n[Host] vEthernet adapters for external switches" -ForegroundColor Yellow
    $vNics = Get-NetAdapter -Name 'vEthernet*' -ErrorAction SilentlyContinue |
             Select-Object Name,Status,MacAddress,LinkSpeed,ifIndex
    $vNics | Format-Table -AutoSize

    # --- Host: IPs on vEthernet adapters ---
    Write-Host "`n[Host] IP addresses on vEthernet adapters" -ForegroundColor Yellow
    $vNicIps = Get-NetIPAddress -InterfaceAlias 'vEthernet*' -ErrorAction SilentlyContinue |
               Select-Object InterfaceAlias,IPAddress,PrefixLength,AddressFamily
    $vNicIps | Format-Table -AutoSize

    # --- VM: NIC layout ---
    Write-Host "`n[VM] Network adapters" -ForegroundColor Yellow
    $vmNics = Get-VMNetworkAdapter -VMName $VMName |
              Select-Object Name,SwitchName,Status,IPAddresses
    $vmNics | Format-Table -AutoSize

    # --- VM: basic reachability (if running) ---
    $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
    if ($vm -and $vm.State -eq 'Running') {
        Write-Host "`n[VM] Basic connectivity tests (from host perspective)" -ForegroundColor Yellow

        $vmIp = $vmNics.IPAddresses |
                Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' } |
                Select-Object -First 1

        if ($vmIp) {
            Write-Host "VM IPv4 detected: $vmIp" -ForegroundColor Green

            # Ping from host to VM
            $ping = Test-NetConnection -ComputerName $vmIp -WarningAction SilentlyContinue
            [pscustomobject]@{
                Test          = 'Host → VM ping'
                ComputerName  = $vmIp
                PingSucceeded = $ping.PingSucceeded
            } | Format-Table -AutoSize
        }
        else {
            Write-Warning "No IPv4 address detected on VM NICs; DHCP may not have completed."
        }
    }
    else {
        Write-Host "`n[VM] $VMName is not running; skipping in-VM connectivity tests." -ForegroundColor DarkYellow
    }

    Write-Host "`n=== Summary hints ===" -ForegroundColor Cyan

    # Simple summary hints based on common failure modes
    $homeSwitch = $switches | Where-Object Name -eq $UplinkSwitchHome
    if (-not $homeSwitch) {
        Write-Warning "Home uplink switch '$UplinkSwitchHome' not found."
    }

    $corpSwitch = $switches | Where-Object Name -eq $UplinkSwitchCorp
    if (-not $corpSwitch) {
        Write-Host "Corp uplink switch '$UplinkSwitchCorp' not found (expected if not yet created)." -ForegroundColor DarkYellow
    }

    $internalSwitchObj = $switches | Where-Object Name -eq $InternalSwitch
    if (-not $internalSwitchObj) {
        Write-Warning "Internal switch '$InternalSwitch' not found."
    }

    if (-not $vNicIps) {
        Write-Warning "No IPs detected on vEthernet adapters; host may not have DHCP on external switches."
    }

    if (-not ($vmNics.IPAddresses | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' })) {
        Write-Host "VM has no IPv4 address yet; run 'ipconfig /renew' inside the VM if it is running." -ForegroundColor DarkYellow
    }

    Write-Host "`nHealth check complete." -ForegroundColor Cyan
}
