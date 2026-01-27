function Get-MicrotikFirewallLandscape {
    param(
        [string]$RouterHost = "192.168.99.1"
    )

    Invoke-MicrotikCommand -RouterHost $RouterHost -Command "/ip firewall filter print terse"
}
