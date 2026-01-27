function Invoke-MicrotikCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,

        [Parameter(Mandatory=$false)]
        [string]$User = "admin",

        [Parameter(Mandatory=$false)]
        [string]$RouterHost = "192.168.99.1"
    )

    # Build SSH arguments
    $sshArgs = @(
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "$User@$RouterHost"
    )

    # Create a temp file to hold the exact RouterOS command
    $tempFile = New-TemporaryFile

    try {
        # Write the command EXACTLY as provided
        Set-Content -Path $tempFile -Value $Command -Encoding ASCII -NoNewline

        # Pipe the file into SSH so no quoting occurs
        $result = & ssh @sshArgs < $tempFile

        return $result
    }
    finally {
        # Always clean up
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}
