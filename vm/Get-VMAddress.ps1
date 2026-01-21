function Get-VMAddress {
    param(
        [string]$VMName = "DeployTestVM"
    )

    try {
        $vm = Get-VM -Name $VMName -ErrorAction Stop
    }
    catch {
        Write-Host "VM '$VMName' not found." -ForegroundColor Red
        return
    }

    $ip = $vm.NetworkAdapters |
        Select-Object -ExpandProperty IPAddresses |
        Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' -and $_ -notlike '169.*' } |
        Select-Object -First 1

    if (-not $ip) {
        Write-Host "No valid IPv4 address found for VM '$VMName'." -ForegroundColor Yellow
        return
    }

    Write-Host "VM '$VMName' IP Address: $ip" -ForegroundColor Cyan
    return $ip
}
