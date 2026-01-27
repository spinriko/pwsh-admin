function Get-FirewallLandscape {
    [CmdletBinding()]
    param()

    Write-Host "=== Windows Firewall Landscape ===" -ForegroundColor Cyan

    # --- Profiles ---
    Write-Host "`n[Profiles]" -ForegroundColor Yellow
    $profiles = Get-NetFirewallProfile |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
    $profiles | Format-Table -AutoSize

    # --- Preload all rules and filters (FAST) ---
    Write-Host "`n[Inbound Rules]" -ForegroundColor Yellow

    $allRules   = Get-NetFirewallRule
    $portFilter = Get-NetFirewallPortFilter
    $appFilter  = Get-NetFirewallApplicationFilter
    $svcFilter  = Get-NetFirewallServiceFilter

    # Build lookup tables
    $portByRule = $portFilter | Group-Object InstanceID -AsHashTable
    $appByRule  = $appFilter  | Group-Object InstanceID -AsHashTable
    $svcByRule  = $svcFilter  | Group-Object InstanceID -AsHashTable

    # Join everything in memory
    $inbound = $allRules |
        Where-Object Direction -eq Inbound |
        ForEach-Object {
            $id = $_.InstanceID

            [pscustomobject]@{
                DisplayName = $_.DisplayName
                Enabled     = $_.Enabled
                Action      = $_.Action
                Profile     = $_.Profile
                Ports       = ($portByRule[$id].LocalPort -join ',')
                Protocol    = ($portByRule[$id].Protocol -join ',')
                Program     = ($appByRule[$id].Program -join ',')
                Service     = ($svcByRule[$id].Service -join ',')
            }
        }

    $inbound | Format-Table -AutoSize

    # --- Outbound Rules ---
    Write-Host "`n[Outbound Rules]" -ForegroundColor Yellow

    $outbound = $allRules |
        Where-Object Direction -eq Outbound |
        ForEach-Object {
            $id = $_.InstanceID

            [pscustomobject]@{
                DisplayName = $_.DisplayName
                Enabled     = $_.Enabled
                Action      = $_.Action
                Profile     = $_.Profile
                Ports       = ($portByRule[$id].LocalPort -join ',')
                Protocol    = ($portByRule[$id].Protocol -join ',')
                Program     = ($appByRule[$id].Program -join ',')
                Service     = ($svcByRule[$id].Service -join ',')
            }
        }

    $outbound | Format-Table -AutoSize

    # --- Hyper-V Related Rules ---
    Write-Host "`n[Hyper-V Related Rules]" -ForegroundColor Yellow
    $hyperv = $allRules |
        Where-Object DisplayName -Match 'Hyper-V|VM|DHCP|DNS|NAT' |
        Select-Object DisplayName, Enabled, Action, Profile
    $hyperv | Format-Table -AutoSize

    # --- Disabled but Important Rules ---
    Write-Host "`n[Disabled but Potentially Important Rules]" -ForegroundColor Yellow
    $disabledImportant = $allRules |
        Where-Object {
            $_.Enabled -eq 'False' -and
            ($_.DisplayName -match 'RDP|Remote Desktop|File and Printer Sharing|SMB|Hyper-V|DHCP|DNS')
        } |
        Select-Object DisplayName, Profile, Action
    $disabledImportant | Format-Table -AutoSize

    # --- Open Ports (Inbound Allow) ---
    Write-Host "`n[Open Inbound Ports]" -ForegroundColor Yellow
    $openPorts = $inbound |
        Where-Object { $_.Enabled -eq 'True' -and $_.Action -eq 'Allow' -and $_.Ports } |
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
