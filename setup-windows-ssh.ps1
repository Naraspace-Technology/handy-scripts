# setup-windows-ssh.ps1 - Enable OpenSSH Server on Windows 10/11 (idempotent)
#
# Run in an elevated PowerShell (Run as Administrator).
#
# Usage:
#   Basic (install/start sshd, open firewall, default shell = Windows PowerShell):
#     irm https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/setup-windows-ssh.ps1 | iex
#
#   With options (register a public key, enable RDP, set network profile to Private):
#     & ([scriptblock]::Create((irm https://raw.githubusercontent.com/Naraspace-Technology/handy-scripts/refs/heads/master/setup-windows-ssh.ps1))) -PublicKey "ssh-ed25519 AAAA... user@host" -EnableRdp -SetPrivateNetwork
#
# Options:
#   -PublicKey "<key>"     Add an SSH public key for the current user.
#                          Administrators -> %ProgramData%\ssh\administrators_authorized_keys
#                          Others         -> %USERPROFILE%\.ssh\authorized_keys
#   -EnableRdp             Enable Remote Desktop and its firewall rules (Pro/Enterprise only)
#   -SetPrivateNetwork     Change Public network profiles to Private
#   -DefaultShell <name>   powershell (default) | pwsh | cmd | keep
#   -Log                   Write a full transcript to %TEMP%\setup-windows-ssh_<timestamp>.log (for troubleshooting)
#   -LogFile "<path>"      Write the transcript to an explicit path (implies -Log)
#
# Every step checks the current state first, so running it again is safe.
# Without -Log / -LogFile nothing is logged: behavior is exactly the same.

[CmdletBinding()]
param(
    [string]$PublicKey = "",
    [switch]$EnableRdp,
    [switch]$SetPrivateNetwork,
    [ValidateSet("powershell", "pwsh", "cmd", "keep")]
    [string]$DefaultShell = "powershell",
    [switch]$Log,
    [string]$LogFile = ""
)

############################################
# Output helpers
############################################
function Write-Info([string]$Message) { Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Stop-WithError([string]$Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    throw $Message
}

# Well-known SIDs (locale independent: works on Korean/other language Windows)
$SidAdministrators = "S-1-5-32-544"
$SidSystem = "S-1-5-18"
$RdpFirewallGroup = "@FirewallAPI.dll,-28752"   # "Remote Desktop" rule group
$SshFirewallRuleName = "OpenSSH-Server-In-TCP"  # same name Windows uses

############################################
# 0. Preconditions
############################################
function Test-Preconditions {
    Write-Step "Checking preconditions"

    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Stop-WithError "Run this script in an elevated PowerShell (right-click > Run as administrator)."
    }

    $build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
    if ($build -lt 17763) {
        Stop-WithError "Windows build $build is too old. OpenSSH Server needs Windows 10 1809 (build 17763) or later."
    }
    $caption = (Get-CimInstance Win32_OperatingSystem).Caption
    Write-Info "$caption (build $build), running as administrator"
}

############################################
# 1. OpenSSH Server capability
############################################
function Install-OpenSshServer {
    Write-Step "OpenSSH Server"

    $cap = Get-WindowsCapability -Online -Name "OpenSSH.Server*" | Select-Object -First 1
    if ($null -eq $cap) {
        Stop-WithError "OpenSSH.Server capability not found on this Windows image."
    }
    if ($cap.State -eq "Installed") {
        Write-Info "Already installed ($($cap.Name))"
        return
    }

    Write-Info "Installing $($cap.Name) ... (downloads from Windows Update, may take several minutes)"
    try {
        Add-WindowsCapability -Online -Name $cap.Name | Out-Null
    } catch {
        Stop-WithError ("Install failed: {0}`n        Check internet/Windows Update, or install 'OpenSSH Server' from Settings > System > Optional features." -f $_.Exception.Message)
    }

    $cap = Get-WindowsCapability -Online -Name $cap.Name
    if ($cap.State -ne "Installed") {
        Stop-WithError "Install did not finish (state: $($cap.State)). Wait for Windows Update to finish and run again."
    }
    Write-Info "Installed"
}

############################################
# 2. sshd service
############################################
function Enable-SshdService {
    Write-Step "sshd service"

    $svc = Get-Service -Name sshd -ErrorAction SilentlyContinue
    if ($null -eq $svc) {
        Stop-WithError "Service 'sshd' not found after installation. Reboot and run again."
    }
    if ($svc.StartType -ne "Automatic") {
        Set-Service -Name sshd -StartupType Automatic
        Write-Info "Startup type set to Automatic"
    } else {
        Write-Info "Startup type already Automatic"
    }
    if ($svc.Status -ne "Running") {
        Start-Service -Name sshd
        Write-Info "Started"
    } else {
        Write-Info "Already running"
    }
}

############################################
# 3. Firewall rule for TCP 22
############################################
function Enable-SshFirewallRule {
    Write-Step "Firewall (inbound TCP 22)"

    $rule = Get-NetFirewallRule -Name $SshFirewallRuleName -ErrorAction SilentlyContinue
    if ($null -eq $rule) {
        New-NetFirewallRule -Name $SshFirewallRuleName -DisplayName "OpenSSH Server (sshd)" `
            -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Any | Out-Null
        Write-Info "Created rule '$SshFirewallRuleName' (all profiles)"
        return
    }

    $changed = $false
    if ($rule.Enabled -ne "True") { $changed = $true }
    if ($rule.Profile -ne "Any") { $changed = $true }
    if ($changed) {
        Set-NetFirewallRule -Name $SshFirewallRuleName -Enabled True -Profile Any
        Write-Info "Rule '$SshFirewallRuleName' enabled for all profiles (was: Enabled=$($rule.Enabled), Profile=$($rule.Profile))"
    } else {
        Write-Info "Rule '$SshFirewallRuleName' already enabled for all profiles"
    }
}

############################################
# 4. Default shell for SSH sessions
############################################
function Set-SshDefaultShell {
    Write-Step "Default shell"

    if ($DefaultShell -eq "keep") {
        Write-Info "Kept as is (-DefaultShell keep)"
        return
    }

    switch ($DefaultShell) {
        "powershell" { $shellPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" }
        "cmd"        { $shellPath = "$env:SystemRoot\System32\cmd.exe" }
        "pwsh"       {
            $cmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
            if ($null -eq $cmd) {
                Write-Warn "pwsh.exe (PowerShell 7) not found. Default shell not changed."
                return
            }
            $shellPath = $cmd.Source
        }
    }

    $key = "HKLM:\SOFTWARE\OpenSSH"
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    $current = (Get-ItemProperty -Path $key -Name DefaultShell -ErrorAction SilentlyContinue).DefaultShell
    if ($current -eq $shellPath) {
        Write-Info "Already $shellPath"
        return
    }
    New-ItemProperty -Path $key -Name DefaultShell -Value $shellPath -PropertyType String -Force | Out-Null
    Write-Info "Set to $shellPath"
}

############################################
# 5. Public key (optional)
############################################
function Add-SshPublicKey {
    if ([string]::IsNullOrWhiteSpace($PublicKey)) { return }
    Write-Step "SSH public key"

    $key = $PublicKey.Trim()
    if ($key -notmatch '^(ssh-(rsa|ed25519|dss)|ecdsa-sha2-nistp(256|384|521)|sk-(ssh-ed25519|ecdsa-sha2-nistp256)@openssh\.com) [A-Za-z0-9+/=]+( .*)?$') {
        Stop-WithError "-PublicKey does not look like an OpenSSH public key (one line from ~/.ssh/*.pub)."
    }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdminMember = $false
    foreach ($group in $identity.Groups) {
        if ($group.Value -eq $SidAdministrators) { $isAdminMember = $true; break }
    }

    if ($isAdminMember) {
        $dir = Join-Path $env:ProgramData "ssh"
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $file = Join-Path $env:ProgramData "ssh\administrators_authorized_keys"
    } else {
        $dir = Join-Path $env:USERPROFILE ".ssh"
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        $file = Join-Path $dir "authorized_keys"
    }

    $existing = @()
    if (Test-Path $file) { $existing = Get-Content -Path $file -ErrorAction SilentlyContinue }
    $keyBody = ($key -split ' ')[0..1] -join ' '
    $already = $false
    foreach ($line in $existing) {
        if ($line.Trim().StartsWith($keyBody)) { $already = $true; break }
    }

    if ($already) {
        Write-Info "Key already present in $file"
    } else {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $prefix = ""
        if ((Test-Path $file) -and ((Get-Item $file).Length -gt 0)) {
            $raw = [System.IO.File]::ReadAllText($file)
            if (-not $raw.EndsWith("`n")) { $prefix = "`r`n" }
        }
        [System.IO.File]::AppendAllText($file, ($prefix + $key + "`r`n"), $utf8NoBom)
        Write-Info "Key added to $file"
    }

    if ($isAdminMember) {
        # sshd ignores administrators_authorized_keys unless only Administrators and SYSTEM can access it
        & icacls.exe $file /inheritance:r /grant "*${SidAdministrators}:F" /grant "*${SidSystem}:F" | Out-Null
        if ($LASTEXITCODE -ne 0) { Stop-WithError "icacls failed on $file" }
        Write-Info "Permissions set (Administrators, SYSTEM only)"
    }
}

############################################
# 6. Remote Desktop (optional)
############################################
function Enable-RemoteDesktop {
    if (-not $EnableRdp) { return }
    Write-Step "Remote Desktop"

    $edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
    if ($edition -match "Core|Home") {
        Write-Warn "Edition '$edition' cannot accept Remote Desktop connections. Skipped."
        return
    }

    $tsKey = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
    if ((Get-ItemProperty -Path $tsKey).fDenyTSConnections -ne 0) {
        Set-ItemProperty -Path $tsKey -Name fDenyTSConnections -Value 0
        Write-Info "Remote Desktop enabled"
    } else {
        Write-Info "Remote Desktop already enabled"
    }
    Enable-NetFirewallRule -Group $RdpFirewallGroup
    Write-Info "Remote Desktop firewall rules enabled"
}

############################################
# 7. Network profile (optional)
############################################
function Set-PrivateNetworkProfile {
    if (-not $SetPrivateNetwork) { return }
    Write-Step "Network profile"

    foreach ($p in Get-NetConnectionProfile) {
        if ($p.NetworkCategory -eq "Public") {
            Set-NetConnectionProfile -InterfaceIndex $p.InterfaceIndex -NetworkCategory Private
            Write-Info "'$($p.InterfaceAlias)': Public -> Private"
        } else {
            Write-Info "'$($p.InterfaceAlias)': $($p.NetworkCategory) (unchanged)"
        }
    }
}

############################################
# 8. Verify and summarize
############################################
function Show-Summary {
    Write-Step "Verification"
    $ok = $true

    $svc = Get-Service -Name sshd -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-Info "sshd: Running ($($svc.StartType))"
    } else {
        Write-Warn "sshd: not running"; $ok = $false
    }

    $listen = Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue
    if ($listen) {
        Write-Info "Port 22: listening"
    } else {
        Write-Warn "Port 22: not listening"; $ok = $false
    }

    $rule = Get-NetFirewallRule -Name $SshFirewallRuleName -ErrorAction SilentlyContinue
    if ($rule -and $rule.Enabled -eq "True") {
        Write-Info "Firewall: '$SshFirewallRuleName' enabled (profile: $($rule.Profile))"
    } else {
        Write-Warn "Firewall: rule '$SshFirewallRuleName' missing or disabled"; $ok = $false
    }

    foreach ($p in Get-NetConnectionProfile) {
        Write-Info "Network '$($p.InterfaceAlias)': $($p.NetworkCategory)"
    }

    $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
        Select-Object -ExpandProperty IPAddress
    $user = $env:USERNAME

    Write-Host ""
    if ($ok) {
        Write-Host "SSH server is ready. From another machine:" -ForegroundColor Green
    } else {
        Write-Host "Some checks failed (see [WARN] above). After fixing, try from another machine:" -ForegroundColor Yellow
    }
    foreach ($ip in $ips) {
        Write-Host "  ssh $user@$ip"
    }
    Write-Host ""
    Write-Host "Notes:"
    Write-Host "  - Log in with the Windows account name above (for a Microsoft account, use its password, not the PIN)."
    Write-Host "  - If the connection times out, check the network path and any hypervisor/VM firewall in between."
    Write-Host "  - To copy a key from macOS/Linux: run this script again with -PublicKey `"<contents of ~/.ssh/id_ed25519.pub>`"."
    # No 'exit' here: with 'irm | iex' it would close the caller's PowerShell window.
}

############################################
# Main
############################################
# 'irm | iex' runs in the caller's scope, so restore the preference afterwards.
$previousErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Stop"

# Optional logging (-Log / -LogFile). Off by default: with neither switch,
# no transcript is started and the run behaves exactly as before.
$logPath = ""
if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
    $logPath = $LogFile
} elseif ($Log) {
    $logPath = Join-Path $env:TEMP ("setup-windows-ssh_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
}

$transcriptStarted = $false
if ($logPath -ne "") {
    try {
        $logDir = Split-Path -Path $logPath -Parent
        if ($logDir -and -not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        Start-Transcript -Path $logPath -Force | Out-Null
        $transcriptStarted = $true
        Write-Info "Logging this run to $logPath"
    } catch {
        Write-Warn ("Could not start logging ({0}). Continuing without a log file." -f $_.Exception.Message)
    }
}

try {
    Test-Preconditions
    Install-OpenSshServer
    Enable-SshdService
    Enable-SshFirewallRule
    Set-SshDefaultShell
    Add-SshPublicKey
    Enable-RemoteDesktop
    Set-PrivateNetworkProfile
    Show-Summary
} finally {
    $ErrorActionPreference = $previousErrorAction
    # Always stop a transcript we started, so 'irm | iex' does not leave logging
    # running in the caller's session.
    if ($transcriptStarted) {
        try { Stop-Transcript | Out-Null } catch { }
        Write-Host ""
        Write-Host "[INFO] Full log saved to: $logPath" -ForegroundColor Green
    }
}
