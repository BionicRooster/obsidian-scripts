#Requires -RunAsAdministrator
# Moves the Dashboard IIS site out of the user home folder into C:\inetpub\dashboard,
# which already has the correct IIS filesystem permissions.

$src     = "C:\Users\awt\dashboard.html"        # current file location
$destDir = "C:\inetpub\dashboard"               # new IIS-friendly location
$dest    = "$destDir\dashboard.html"            # full destination path
$appcmd  = "C:\Windows\System32\inetsrv\appcmd.exe"  # IIS command-line tool
$site    = "Dashboard"                          # IIS site name

Write-Host "Step 1: Creating $destDir ..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Write-Host "  Done." -ForegroundColor Green

Write-Host "Step 2: Copying dashboard.html ..." -ForegroundColor Cyan
Copy-Item $src $dest -Force
Write-Host "  Copied to $dest" -ForegroundColor Green

Write-Host "Step 3: Updating IIS site physical path ..." -ForegroundColor Cyan
& $appcmd set site $site /physicalPath:$destDir
Write-Host "  Physical path set to $destDir" -ForegroundColor Green

Write-Host "Step 4: Restarting IIS ..." -ForegroundColor Cyan
iisreset /restart
Write-Host "  Done." -ForegroundColor Green

Write-Host ""
Write-Host "Complete. Test: http://localhost:8080/" -ForegroundColor White
Write-Host "Future edits go to: $dest" -ForegroundColor Yellow
