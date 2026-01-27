function Set-MicrotikSshConfig {
    $configPath = Join-Path $HOME ".ssh\config"

    if (-not (Test-Path $configPath)) {
        New-Item -ItemType File -Path $configPath -Force | Out-Null
    }

    $config = Get-Content $configPath -Raw

    # Remove existing block
    $cleaned = $config -replace "(?ms)Host microtik.*?(?=Host|\Z)", ""

    $microtikBlock = @"
Host microtik
    HostName 192.168.99.1
    User admin
    IdentityFile ~/.ssh/microtik_routeros

    PubkeyAuthentication yes
    PreferredAuthentications publickey

    # RouterOS 6 crypto compatibility
    HostKeyAlgorithms +ssh-rsa
    PubkeyAcceptedAlgorithms +ssh-rsa
    MACs hmac-sha1,hmac-md5
    KexAlgorithms +diffie-hellman-group1-sha1

    # Modern, stable, persistent host-key behavior
    StrictHostKeyChecking accept-new

"@

    ($cleaned.Trim() + "`n`n" + $microtikBlock) |
        Set-Content $configPath -Encoding ascii
}
