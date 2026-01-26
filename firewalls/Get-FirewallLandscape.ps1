function Get-FirewallLandscape {
    [CmdletBinding()]
    param()

    Write-Host "=== Windows Firewall Landscape ===" -ForegroundColor Cyan

    # --- Profiles ---
    Write-Host "`n[Profiles]" -ForegroundColor Yellow
    $profiles = Get-NetFirewallProfile |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
    $profiles | Format-Table -AutoSize

    # --- Inbound Rules ---
    Write-Host "`n[Inbound Rules]" -ForegroundColor Yellow
    $inbound = Get-NetFirewallRule -Direction Inbound |
        Select-Object DisplayName, Enabled, Action, Profile, @{n='Ports';e={($_ | Get-NetFirewallPortFilter).LocalPort}},
                      @{n='Protocol';e={($_ | Get-NetFirewallPortFilter).Protocol}},
                      @{n='Program';e={($_ | Get-NetFirewallApplicationFilter).Program}},
                      @{n='Service';e={($_ | Get-NetFirewallServiceFilter).Service}}
    $inbound | Format-Table -AutoSize

    # --- Outbound Rules ---
    Write-Host "`n[Outbound Rules]" -ForegroundColor Yellow
    $outbound = Get-NetFirewallRule -Direction Outbound |
        Select-Object DisplayName, Enabled, Action, Profile, @{n='Ports';e={($_ | Get-NetFirewallPortFilter).LocalPort}},
                      @{n='Protocol';e={($_ | Get-NetFirewallPortFilter).Protocol}},
                      @{n='Program';e={($_ | Get-NetFirewallApplicationFilter).Program}},
                      @{n='Service';e={($_ | Get-NetFirewallServiceFilter).Service}}
    $outbound | Format-Table -AutoSize

    # --- Hyper-V Related Rules ---
    Write-Host "`n[Hyper-V Related Rules]" -ForegroundColor Yellow
    $hyperv = Get-NetFirewallRule |
        Where-Object DisplayName -Match 'Hyper-V|VM|DHCP|DNS|NAT' |
        Select-Object DisplayName, Enabled, Action, Profile
    $hyperv | Format-Table -AutoSize

    # --- Disabled but Important Rules ---
    Write-Host "`n[Disabled but Potentially Important Rules]" -ForegroundColor Yellow
    $disabledImportant = Get-NetFirewallRule |
        Where-Object {
            $_.Enabled -eq 'False' -and
            ($_.DisplayName -match 'RDP|Remote Desktop|File and Printer Sharing|SMB|Hyper-V|DHCP|DNS')
        } |
        Select-Object DisplayName, Profile, Action
    $disabledImportant | Format-Table -AutoSize

    # --- Open Ports (Inbound Allow) ---
    Write-Host "`n[Open Inbound Ports]" -ForegroundColor Yellow
    $openPorts = $inbound |
        Where-Object { $_.Enabled -eq 'True' -and $_.Action -eq 'Allow' -and $_.Ports -ne $null } |
        Select-Object DisplayName, Ports, Protocol, Profile
    $openPorts | Format-Table -AutoSize

    # --- Summary ---
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan

    if ($profiles.DefaultInboundAction -contains 'Allow') {
        Write-Warning "One or more profiles allow inbound traffic by default. This is a security risk."
    }

    if ($openPorts.Count -eq 0) {
        Write-Host "✓ No open inbound ports detected." -ForegroundColor Green
    } else {
        Write-Host "⚠ Open inbound ports detected. Review required." -ForegroundColor DarkYellow
    }

    if ($disabledImportant.Count -gt 0) {
        Write-Host "⚠ Important rules are disabled. Review recommended." -ForegroundColor DarkYellow
    }

    Write-Host "`nFirewall landscape report complete." -ForegroundColor Cyan
}
