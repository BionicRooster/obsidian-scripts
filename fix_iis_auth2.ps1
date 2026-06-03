#Requires -RunAsAdministrator
# Comprehensive IIS anonymous-access fix.
# Installs the Anonymous Authentication feature, grants the correct
# accounts filesystem read access, and configures the site.

$siteName = "Dashboard"
$sitePath = "C:\Users\awt"

$ErrorActionPreference = "Stop"

# ── Step 1: Install Anonymous Authentication Windows feature ─────────────────
# This feature was not included in the original setup and is required before
# IIS can serve pages to unauthenticated (anonymous) browsers.
Write-Host "Installing IIS-AnonymousAuthentication feature..." -ForegroundColor Cyan
Enable-WindowsOptionalFeature -Online -FeatureName IIS-AnonymousAuthentication -NoRestart | Out-Null
Write-Host "  Done." -ForegroundColor Green

# ── Step 2: Import IIS PowerShell module ─────────────────────────────────────
Import-Module WebAdministration -ErrorAction Stop

# ── Step 3: Enable Anonymous Auth, disable Windows Auth on the site ──────────
Write-Host "Configuring site authentication..." -ForegroundColor Cyan

Set-WebConfigurationProperty `
    -Filter "system.webServer/security/authentication/anonymousAuthentication" `
    -PSPath "IIS:\Sites\$siteName" -Name "enabled" -Value $true
Write-Host "  Anonymous Authentication: ON" -ForegroundColor Green

# WindowsAuthentication may not be installed; wrap in try/catch to skip safely
try {
    Set-WebConfigurationProperty `
        -Filter "system.webServer/security/authentication/windowsAuthentication" `
        -PSPath "IIS:\Sites\$siteName" -Name "enabled" -Value $false
    Write-Host "  Windows Authentication:   OFF" -ForegroundColor Green
} catch {
    Write-Host "  Windows Authentication feature not present — skipping." -ForegroundColor DarkGray
}

# ── Step 4: Grant filesystem read access to IIS accounts ────────────────────
# IIS uses two identities for anonymous access:
#   IUSR          — the classic built-in anonymous account
#   IIS AppPool\Dashboard — the application pool identity (modern IIS default)
# Both need ReadAndExecute on the physical path.
Write-Host "Granting IIS accounts read access to $sitePath..." -ForegroundColor Cyan

$acl       = Get-Acl $sitePath
$inherit   = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
$propagate = [System.Security.AccessControl.PropagationFlags]"None"
$allow     = [System.Security.AccessControl.AccessControlType]"Allow"

foreach ($identity in @("IUSR", "IIS AppPool\$siteName")) {
    try {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $identity, "ReadAndExecute", $inherit, $propagate, $allow
        )
        $acl.SetAccessRule($rule)
        Write-Host "  Granted: $identity" -ForegroundColor Green
    } catch {
        Write-Host "  Could not add rule for ${identity}: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
Set-Acl -Path $sitePath -AclObject $acl

# ── Step 5: Restart the site ─────────────────────────────────────────────────
Write-Host "Restarting site..." -ForegroundColor Cyan
Stop-WebSite  -Name $siteName
Start-WebSite -Name $siteName
Write-Host "  Site restarted." -ForegroundColor Green

Write-Host ""
Write-Host "Complete. Test: http://localhost:8080/" -ForegroundColor White
