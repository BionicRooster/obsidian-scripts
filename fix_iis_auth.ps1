#Requires -RunAsAdministrator
# Fixes the 401 on the Dashboard IIS site by enabling Anonymous Authentication
# and disabling Windows Authentication. Run once as Administrator.

$siteName = "Dashboard"   # must match the name used in setup_iis_dashboard.ps1

Import-Module WebAdministration -ErrorAction Stop

$sitePath = "IIS:\Sites\$siteName"   # IIS provider path for this site

Write-Host "Configuring authentication for '$siteName'..." -ForegroundColor Cyan

# Enable Anonymous Authentication — allows any browser to load the page
# without being prompted for Windows credentials.
Set-WebConfigurationProperty `
    -Filter "system.webServer/security/authentication/anonymousAuthentication" `
    -PSPath $sitePath `
    -Name "enabled" -Value $true
Write-Host "  Anonymous Authentication: ENABLED" -ForegroundColor Green

# Disable Windows Authentication — stops IIS from issuing the 401 challenge
# that asks the browser for domain credentials.
Set-WebConfigurationProperty `
    -Filter "system.webServer/security/authentication/windowsAuthentication" `
    -PSPath $sitePath `
    -Name "enabled" -Value $false
Write-Host "  Windows Authentication:   DISABLED" -ForegroundColor Green

# Restart the site so the new auth settings take effect immediately.
Stop-WebSite  -Name $siteName
Start-WebSite -Name $siteName
Write-Host "  Site restarted." -ForegroundColor Green

Write-Host ""
Write-Host "Done. Open http://localhost:8080/ in your browser." -ForegroundColor White
