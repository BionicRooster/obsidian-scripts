#Requires -RunAsAdministrator
# Uses appcmd.exe directly (most reliable) + full iisreset + writes diagnostic log.

$siteName = "Dashboard"
$logFile  = "C:\Users\awt\iis_diag.txt"   # written here so non-admin can read it
$appcmd   = "C:\Windows\System32\inetsrv\appcmd.exe"

"=== IIS Diagnostic + Fix $(Get-Date) ===" | Out-File $logFile

# ── Show current auth state before changes ───────────────────────────────────
"--- Current auth config (before) ---" | Out-File $logFile -Append
& $appcmd list config $siteName /section:system.webServer/security/authentication 2>&1 |
    Out-File $logFile -Append

# ── Enable anonymous authentication via appcmd (writes to applicationHost.config)
"--- Enabling anonymous authentication ---" | Out-File $logFile -Append
& $appcmd set config $siteName `
    /section:system.webServer/security/authentication/anonymousAuthentication `
    /enabled:true /commit:apphost 2>&1 | Tee-Object -Append $logFile

# ── Disable windows authentication via appcmd ────────────────────────────────
"--- Disabling windows authentication ---" | Out-File $logFile -Append
& $appcmd set config $siteName `
    /section:system.webServer/security/authentication/windowsAuthentication `
    /enabled:false /commit:apphost 2>&1 | Tee-Object -Append $logFile

# ── Grant IUSR + app pool identity filesystem access ─────────────────────────
"--- Granting filesystem access ---" | Out-File $logFile -Append
$acl     = Get-Acl "C:\Users\awt"
$inherit = "ContainerInherit,ObjectInherit"
$prop    = "None"
$allow   = "Allow"
foreach ($id in @("IUSR", "IIS AppPool\$siteName", "BUILTIN\IIS_IUSRS")) {
    try {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $id, "ReadAndExecute", $inherit, $prop, $allow)
        $acl.SetAccessRule($rule)
        "  Granted $id" | Out-File $logFile -Append
    } catch { "  Failed $id : $_" | Out-File $logFile -Append }
}
Set-Acl "C:\Users\awt" $acl

# ── Full IIS restart (more thorough than Stop/Start-WebSite) ─────────────────
"--- Running iisreset ---" | Out-File $logFile -Append
& iisreset /restart 2>&1 | Tee-Object -Append $logFile

# ── Show auth state after changes ────────────────────────────────────────────
Start-Sleep -Seconds 3
"--- Auth config (after) ---" | Out-File $logFile -Append
& $appcmd list config $siteName /section:system.webServer/security/authentication 2>&1 |
    Out-File $logFile -Append

"--- Done ---" | Out-File $logFile -Append
Write-Host "Finished. Log written to $logFile" -ForegroundColor Green
