function Get-FirewallSecurityHoles {
    [CmdletBinding()]
    param()

    Write-Host "=== Firewall Security Holes Audit ===" -ForegroundColor Cyan

    # Load all rules once
    $rules = Get-NetFirewallRule
    $portFilter = Get-NetFirewallPortFilter
    $appFilter  = Get-NetFirewallApplicationFilter

    $portByRule = $portFilter | Group-Object InstanceID -AsHashTable
    $appByRule  = $appFilter  | Group-Object InstanceID -AsHashTable

    # Helper to build objects
    function Build-Obj($r) {
        $id = $r.InstanceID
        [pscustomobject]@{
            DisplayName = $r.DisplayName
            Enabled     = $r.Enabled
            Action      = $r.Action
            Profile     = $r.Profile
            Ports       = ($portByRule[$id].LocalPort -join ',')
            Program     = ($appByRule[$id].Program -join ',')
        }
    }

    # --- 1. Inbound ANY/ANY rules ---
    Write-Host "`n[1] Inbound ANY/ANY Rules (High Risk)" -ForegroundColor Yellow
    $anyAny = $rules |
        Where-Object {
            $_.Direction -eq 'Inbound' -and
            $_.Action -eq 'Allow' -and
            ($portByRule[$_.InstanceID].LocalPort -contains 'Any')
        } |
        ForEach-Object { Build-Obj $_ }

    $anyAny | Format-Table -AutoSize

    # --- 2. Inbound rules on Public profile ---
    Write-Host "`n[2] Inbound Rules Allowed on Public Profile" -ForegroundColor Yellow
    $publicInbound = $rules |
        Where-Object {
            $_.Direction -eq 'Inbound' -and
            $_.Action -eq 'Allow' -and
            $_.Profile -match 'Public'
        } |
        ForEach-Object { Build-Obj $_ }

    $publicInbound | Format-Table -AutoSize

    # --- 3. Remote management surfaces (WinRM, SSH, WMI, RPC) ---
    Write-Host "`n[3] Remote Management Surfaces (WinRM, SSH, WMI, RPC)" -ForegroundColor Yellow
    $remoteMgmt = $rules |
        Where-Object {
            $_.Direction -eq 'Inbound' -and
            $_.Action -eq 'Allow' -and
            $_.DisplayName -match 'WinRM|SSH|WMI|RPC|Remote'
        } |
        ForEach-Object { Build-Obj $_ }

    $remoteMgmt | Format-Table -AutoSize

    # --- 4. Rules tied to executables that no longer exist ---
    Write-Host "`n[4] Rules Pointing to Missing Executables" -ForegroundColor Yellow
    $missingExe = $rules |
        Where-Object {
            $exe = ($appByRule[$_.InstanceID].Program)
            $exe -and -not (Test-Path $exe)
        } |
        ForEach-Object { Build-Obj $_ }

    $missingExe | Format-Table -AutoSize

    # --- 5. Rules created by apps you probably don’t use anymore ---
    Write-Host "`n[5] Suspicious or Legacy App Rules" -ForegroundColor Yellow
    $legacy = $rules |
        Where-Object {
            $_.DisplayName -match 'Media Player|Cast|UPnP|qWave|AllJoyn|Xbox|WSD|SSDP'
        } |
        ForEach-Object { Build-Obj $_ }

    $legacy | Format-Table -AutoSize

    # --- Summary ---
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan

    if ($anyAny.Count -gt 0) {
        Write-Host "⚠ ANY/ANY inbound rules detected." -ForegroundColor DarkYellow
    }

    if ($publicInbound.Count -gt 0) {
        Write-Host "⚠ Inbound rules allowed on Public profile." -ForegroundColor DarkYellow
    }

    if ($remoteMgmt.Count -gt 0) {
        Write-Host "⚠ Remote management surfaces exposed." -ForegroundColor DarkYellow
    }

    if ($missingExe.Count -gt 0) {
        Write-Host "⚠ Rules referencing missing executables." -ForegroundColor DarkYellow
    }

    Write-Host "`nSecurity holes audit complete." -ForegroundColor Cyan
}
