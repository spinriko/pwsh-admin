
<#
.SYNOPSIS
    Executes a RouterOS command on the MikroTik router using a deterministic,
    non-interactive SSH invocation. This function is designed for automation,
    monitoring, and reproducible command execution without prompts, paging,
    or interactive shells.

.DESCRIPTION
    Invoke-MicrotikCommand provides a stable wrapper around the OpenSSH client
    to execute RouterOS commands in a fully non-interactive mode. It uses
    STDIN-based command delivery and disables PTY allocation to avoid paging,
    shell fallback, and RouterOS interactive behavior.

    This function is intentionally minimal: it does not manage SSH keys,
    host-key persistence, or crypto negotiation. All of that is delegated to
    the user's SSH configuration, which MUST be present and correct for this
    function to work.

    If the SSH configuration is missing, incomplete, or misconfigured,
    Invoke-MicrotikCommand will fail with errors such as:
        - "Could not resolve hostname microtik"
        - "Permission denied (publickey)"
        - Repeated 'Permanently added...' warnings
        - Crypto negotiation failures

    The function depends entirely on the SSH host block named 'microtik'
    being defined in ~/.ssh/config with RouterOS‑6‑compatible crypto settings
    and persistent host-key behavior.

    REQUIRED SSH CONFIGURATION (must exist in ~/.ssh/config):

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

    Without this SSH configuration, Invoke-MicrotikCommand WILL NOT WORK.

    This separation of concerns ensures deterministic behavior:
        - PowerShell handles command execution
        - SSH config handles identity, crypto, and host-key persistence
        - RouterOS receives clean, non-interactive commands
#>
function Invoke-MicrotikCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [string]$RouterHost = "microtik"
    )

    # -T = no TTY, no interactive shell, clean exit
    $sshArgs = @(
        "-T",
        $RouterHost,
        $Command
    )

    & ssh @sshArgs
}
