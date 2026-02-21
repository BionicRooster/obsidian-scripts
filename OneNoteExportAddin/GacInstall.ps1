# GacInstall.ps1  —  run as Administrator
# Signs the assembly with a strong name and installs it to the GAC.
# Updates HKLM InprocServer32 to use the GAC identity (no CodeBase needed).

$projDir  = "C:\Users\awt\OneNoteExportAddin"
$dllSrc   = "$projDir\bin\Release\net48\OneNoteExportAddin.dll"
$keyFile  = "$projDir\OneNoteExportAddin.snk"
$clsid    = "{C1E7A840-D4B5-4E8B-B63F-0A4E7C3A9E1F}"
$progId   = "OneNoteExportAddin.Connect"
$runtime  = "v4.0.30319"
$toolsDir = "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools"
$sn       = "$toolsDir\sn.exe"
$gacutil  = "$toolsDir\gacutil.exe"

# 1. Generate a strong-name key pair
Write-Host "Generating strong-name key pair..." -ForegroundColor Cyan
& $sn -k $keyFile
if (-not (Test-Path $keyFile)) { Write-Error "Key generation failed"; exit 1 }

# 2. Read the public key token
$pkToken = (& $sn -tp $keyFile | Select-String "Public key token is" | ForEach-Object { $_ -replace ".*Public key token is\s*", "" }).Trim()
Write-Host "Public key token: $pkToken"

# 3. Rebuild the project with signing (inject AssemblyKeyFile)
Write-Host "`nRebuilding signed assembly..." -ForegroundColor Cyan
$buildResult = & dotnet build "$projDir" -c Release `
    /p:AssemblyOriginatorKeyFile=$keyFile `
    /p:SignAssembly=true 2>&1
Write-Host $buildResult
if ($LASTEXITCODE -ne 0) { Write-Error "Build failed"; exit 1 }

# 4. Install to GAC (removes need for CodeBase registry value)
Write-Host "`nInstalling to GAC..." -ForegroundColor Cyan
& $gacutil /i $dllSrc
if ($LASTEXITCODE -ne 0) { Write-Error "GAC install failed"; exit 1 }
Write-Host "GAC install succeeded"

# 5. Update HKLM InprocServer32 — assembly identity now includes PublicKeyToken
$asmIdentity = "OneNoteExportAddin, Version=1.0.0.0, Culture=neutral, PublicKeyToken=$pkToken"
$inprocKey   = "HKLM:\Software\Classes\CLSID\$clsid\InprocServer32"
New-Item -Path $inprocKey -Force | Out-Null
Set-ItemProperty -Path $inprocKey -Name "(Default)"      -Value "mscoree.dll"
Set-ItemProperty -Path $inprocKey -Name "Class"          -Value $progId
Set-ItemProperty -Path $inprocKey -Name "Assembly"       -Value $asmIdentity
Set-ItemProperty -Path $inprocKey -Name "RuntimeVersion" -Value $runtime
Set-ItemProperty -Path $inprocKey -Name "ThreadingModel" -Value "Both"
# Remove CodeBase — GAC assemblies don't need it
Remove-ItemProperty -Path $inprocKey -Name "CodeBase" -ErrorAction SilentlyContinue
Write-Host "Updated HKLM InprocServer32: Assembly = $asmIdentity"

# 6. Reset LoadBehavior
Set-ItemProperty "HKCU:\Software\Microsoft\Office\OneNote\Addins\$progId" `
    -Name LoadBehavior -Value 3 -Type DWord

Write-Host "`nDone. Restart OneNote." -ForegroundColor Green
