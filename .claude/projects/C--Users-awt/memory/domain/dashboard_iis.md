---
name: dashboard-iis
description: "Georgetown weather/air quality dashboard — IIS setup, URL, physical path, and fix history"
metadata: 
  node_type: memory
  type: project
  originSessionId: 98f2f962-a26d-4d4a-b722-d19143689005
---

## Dashboard URL
- **http://192.168.68.65:8080** (LAN access)
- **http://localhost:8080** (local access)
- Default document: `dashboard.html` (no filename needed in URL)

## IIS Site Config
- Site name: `Dashboard`
- Port: 8080
- Physical path: `C:\Users\awt` (where IIS serves from; web.config lives here)
- File Claude edits: `C:\Users\awt\dashboard.html`
- File IIS serves: `C:\inetpub\dashboard\dashboard.html` (copied by watcher)
- Watcher script: `C:\Users\awt\dashboard_watcher.ps1` — runs as scheduled task at login, copies dashboard.html to inetpub on save

## Known Fix — 500.19 Error
**Why:** IIS can't read `C:\Users\awt\web.config` because the user home folder blocks IIS worker accounts by default.

**Fix (no admin needed):**
```powershell
icacls "C:\Users\awt" /grant "IIS_IUSRS:(OI)(CI)R"
icacls "C:\Users\awt" /grant "IUSR:(OI)(CI)R"
```
No IIS restart required — takes effect on next request.

**Note:** `applicationHost.config` physical path still points to `C:\Users\awt` (move to `C:\inetpub\dashboard` was scripted but requires admin to apply via appcmd).
