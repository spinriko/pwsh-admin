function Invoke-MicrotikCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string]$RouterHost = "192.168.99.1",
        [string]$User = "admin",
        [string]$KeyPath = "$env:USERPROFILE\.ssh\mikrotik-routeros"
    )

    $sshArgs = @(
        "-o", "IdentitiesOnly=yes"
        "-o", "PubkeyAcceptedAlgorithms=+ssh-rsa"
        "-o", "HostkeyAlgorithms=+ssh-rsa"
        "-o", "MACs=hmac-sha1,hmac-md5"
        "-i", $KeyPath
        "$User@$RouterHost"
        $Command
    )

    # Run SSH and capture all output
    $output = & ssh @sshArgs 2>&1
    $exit = $LASTEXITCODE

    if ($exit -ne 0) {
        Write-Warning "SSH exited with code $exit"
    }

    return $output
}
