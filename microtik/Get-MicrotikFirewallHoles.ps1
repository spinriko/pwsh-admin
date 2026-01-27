function Get-MicrotikFirewallHoles {
    param(
        [string]$RouterHost = "192.168.99.1",
        [switch]$VerboseRules  # optional: show each rule as it's evaluated
    )

    Write-Host "=== Fetching firewall rules from $RouterHost ==="
    $rules = Invoke-MicrotikCommand -RouterHost $RouterHost -Command "/ip firewall filter print terse"

    if (-not $rules) {
        Write-Warning "No firewall rules returned from router"
        return
    }

    Write-Host "Retrieved $($rules.Count) rules"
    Write-Host "Beginning hole detection..."
    Write-Host ""

    $holes = @()

    foreach ($line in $rules) {

        if ($VerboseRules) {
            Write-Host "Evaluating: $line"
        }

        # --- INPUT chain: accept with no constraints ---
        Write-Host "Checking INPUT chain unconstrained accept..."
        if ($line -match "chain=input" -and
            $line -match "action=accept" -and
            $line -notmatch "connection-state=established" -and
            $line -notmatch "connection-state=related" -and
            $line -notmatch "in-interface" -and
            $line -notmatch "src-address" -and
            $line -notmatch "disabled=yes") {

            Write-Warning "Hole detected (INPUT): $line"
            $holes += $line
            continue
        }

        # --- FORWARD chain: accept with no constraints ---
        Write-Host "Checking FORWARD chain unconstrained accept..."
        if ($line -match "chain=forward" -and
            $line -match "action=accept" -and
            $line -notmatch "connection-state=established" -and
            $line -notmatch "connection-state=related" -and
            $line -notmatch "in-interface" -and
            $line -notmatch "out-interface" -and
            $line -notmatch "src-address" -and
            $line -notmatch "dst-address" -and
            $line -notmatch "disabled=yes") {

            Write-Warning "Hole detected (FORWARD): $line"
            $holes += $line
            continue
        }

        # --- WAN → router exposure ---
        Write-Host "Checking WAN exposure..."
        if ($line -match "chain=input" -and
            $line -match "action=accept" -and
            $line -match "in-interface-list=WAN") {

            Write-Warning "Hole detected (WAN exposure): $line"
            $holes += $line
            continue
        }
    }

    Write-Host ""
    Write-Host "=== Detection complete ==="
    Write-Host "Total holes found: $($holes.Count)"

    return $holes
}
