# Install-Sysmon.ps1
# Yazan: ChatGPT, @Cyb3rWard0g yapılandırmasıyla
# Amaç: Sysmon kurulumu ve yapılandırmasını Windows makinelerde otomatize etmek

# Hedef dizinler
$TempDir = "$env:TEMP\SysmonInstall"
$SysmonZip = "$TempDir\Sysmon.zip"
$SysmonDir = "$TempDir\Sysmon"
$SysmonConfig = "$TempDir\sysmonconfig.xml"

# Bağlantılar
$SysmonURL = "https://download.sysinternals.com/files/Sysmon.zip"
$ConfigURL = "https://raw.githubusercontent.com/OTRF/Blacksmith/main/artifacts/sysmonconfig.xml"

# Temizlik
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir | Out-Null

Write-Host "`n[*] Sysmon indiriliyor..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $SysmonURL -OutFile $SysmonZip

Write-Host "[*] Sysmon arşivi açılıyor..." -ForegroundColor Cyan
Expand-Archive -Path $SysmonZip -DestinationPath $SysmonDir -Force

Write-Host "[*] Yapılandırma dosyası indiriliyor..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $ConfigURL -OutFile $SysmonConfig

# Sysmon binary yolu
$SysmonExe = Join-Path $SysmonDir "Sysmon64.exe"
if (-not (Test-Path $SysmonExe)) {
    $SysmonExe = Join-Path $SysmonDir "Sysmon.exe"  # 32-bit fallback
}

# Varsa kaldır
Write-Host "[*] Önceki kurulum kontrol ediliyor..." -ForegroundColor Cyan
$existing = Get-Process -Name "Sysmon" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[!] Var olan Sysmon kaldırılıyor..." -ForegroundColor Yellow
    Start-Process -FilePath $SysmonExe -ArgumentList "-u force" -Wait
    Start-Sleep -Seconds 2
}

# Yeni kurulum
Write-Host "[*] Sysmon kuruluyor..." -ForegroundColor Cyan
Start-Process -FilePath $SysmonExe -ArgumentList "-accepteula -i `"$SysmonConfig`"" -Wait

# Kontrol
Start-Sleep -Seconds 3
if (Get-WinEvent -ListLog "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue) {
    Write-Host "`n[✓] Sysmon başarıyla kuruldu ve etkinleştirildi." -ForegroundColor Green
} else {
    Write-Host "`n[!] Sysmon log kanalı bulunamadı veya etkinleştirilemedi!" -ForegroundColor Red
}


# Temizlik isteğe bağlı
# Remove-Item $TempDir -Recurse -Force
