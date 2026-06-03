#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Sets up IIS to serve the Georgetown dashboard persistently on port 8080.
    Run once as Administrator. The site will start automatically on every boot.

.WHAT THIS DOES
    1. Enables IIS with static-content and default-document features
    2. Creates a new IIS site called "Dashboard" bound to port 8080
    3. Points it at C:\Users\awt (where dashboard.html lives)
    4. Grants IIS the read access it needs on that folder
    5. Adds dashboard.html as the default document so the URL needs no filename
    6. Confirms the site is running and prints the access URL
#>

$ErrorActionPreference = "Stop"   # treat any error as fatal so we see it clearly
$siteName     = "Dashboard"        # IIS site name
$sitePort     = 8080               # HTTP port — matches the URL you've been using
$sitePath     = "C:\Users\awt"     # physical folder to serve
$defaultDoc   = "dashboard.html"   # file served when you browse to just /

Write-Host "`n=== Step 1: Enabling IIS features ===" -ForegroundColor Cyan

# Enable the minimal IIS feature set needed for serving static HTML files.
# -All pulls in dependent features automatically.
# -NoRestart prevents an automatic reboot (you will NOT need to reboot).
$features = @(
    "IIS-WebServerRole",      # core IIS role
    "IIS-WebServer",          # web server container
    "IIS-CommonHttpFeatures", # groups the features below
    "IIS-StaticContent",      # serve .html, .js, .css files
    "IIS-DefaultDocument",    # serve index/default doc when no filename given
    "IIS-HttpErrors",         # friendly error pages
    "IIS-ManagementConsole"   # IIS Manager GUI (optional but handy)
)

foreach ($f in $features) {
    $state = (Get-WindowsOptionalFeature -Online -FeatureName $f).State
    if ($state -ne "Enabled") {
        Write-Host "  Enabling $f ..." -NoNewline
        Enable-WindowsOptionalFeature -Online -FeatureName $f -All -NoRestart | Out-Null
        Write-Host " done." -ForegroundColor Green
    } else {
        Write-Host "  $f already enabled." -ForegroundColor DarkGray
    }
}

Write-Host "`n=== Step 2: Importing IIS management module ===" -ForegroundColor Cyan
# WebAdministration is the PowerShell module for managing IIS sites and bindings.
Import-Module WebAdministration -ErrorAction Stop
Write-Host "  Module loaded." -ForegroundColor Green

Write-Host "`n=== Step 3: Removing any existing '$siteName' site ===" -ForegroundColor Cyan
# Clean slate — remove any prior attempt so this script is safely re-runnable.
if (Test-Path "IIS:\Sites\$siteName") {
    Remove-WebSite -Name $siteName
    Write-Host "  Removed existing site." -ForegroundColor Yellow
} else {
    Write-Host "  No existing site found." -ForegroundColor DarkGray
}

Write-Host "`n=== Step 4: Creating IIS site '$siteName' on port $sitePort ===" -ForegroundColor Cyan
# New-WebSite creates the site and binds it to all local interfaces on the given port.
# IIS service (W3SVC) will start this site automatically on every boot.
New-WebSite -Name $siteName -Port $sitePort -PhysicalPath $sitePath -Force | Out-Null
Write-Host "  Site created: $sitePath -> http://localhost:$sitePort/" -ForegroundColor Green

Write-Host "`n=== Step 5: Granting IIS read access to $sitePath ===" -ForegroundColor Cyan
# IIS worker processes run as the IIS_IUSRS built-in group.
# That group needs at least ReadAndExecute on the physical path and its children.
$acl        = Get-Acl $sitePath
$identity   = "IIS_IUSRS"                                    # built-in IIS worker identity
$permission = "ReadAndExecute"                               # read files + list directory
$inherit    = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
$propagate  = [System.Security.AccessControl.PropagationFlags]"None"
$type       = [System.Security.AccessControl.AccessControlType]"Allow"

$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $identity, $permission, $inherit, $propagate, $type
)
$acl.SetAccessRule($rule)
Set-Acl -Path $sitePath -AclObject $acl
Write-Host "  IIS_IUSRS granted ReadAndExecute on $sitePath" -ForegroundColor Green

Write-Host "`n=== Step 6: Setting '$defaultDoc' as the default document ===" -ForegroundColor Cyan
# Default documents are served when the browser requests just "/" with no filename.
# We prepend dashboard.html so it's tried before index.html.
$docFilter = "system.webServer/defaultDocument/files"
$existing  = Get-WebConfiguration -Filter "$docFilter/add" -PSPath "IIS:\Sites\$siteName" |
             Select-Object -ExpandProperty value

if ($existing -notcontains $defaultDoc) {
    Add-WebConfiguration -Filter $docFilter `
        -PSPath "IIS:\Sites\$siteName" `
        -Value @{ value = $defaultDoc }
    Write-Host "  Added '$defaultDoc' to default documents." -ForegroundColor Green
} else {
    Write-Host "  '$defaultDoc' already in default documents." -ForegroundColor DarkGray
}

Write-Host "`n=== Step 7: Ensuring IIS service (W3SVC) is running ===" -ForegroundColor Cyan
# W3SVC is the Windows Web Server service. It is set to Automatic start by default
# once IIS is installed, so it will survive reboots without any extra configuration.
$svc = Get-Service -Name W3SVC
if ($svc.Status -ne "Running") {
    Start-Service W3SVC
    Write-Host "  W3SVC started." -ForegroundColor Green
} else {
    Write-Host "  W3SVC already running." -ForegroundColor DarkGray
}

Write-Host "`n=== Step 8: Starting site and verifying ===" -ForegroundColor Cyan
Start-WebSite -Name $siteName
$site   = Get-WebSite -Name $siteName   # fetch site object to confirm state
$status = $site.State                   # should be "Started"

Write-Host ""
Write-Host "==========================================" -ForegroundColor White
Write-Host "  IIS Dashboard site status: $status"      -ForegroundColor $(if ($status -eq "Started") {"Green"} else {"Red"})
Write-Host "  URL: http://localhost:$sitePort/"         -ForegroundColor White
Write-Host "  Default page: $defaultDoc"               -ForegroundColor White
Write-Host "  Starts automatically on every reboot."   -ForegroundColor White
Write-Host "==========================================" -ForegroundColor White

if ($status -ne "Started") {
    Write-Warning "Site did not start. Check IIS Manager or the Windows Event Log for details."
}
