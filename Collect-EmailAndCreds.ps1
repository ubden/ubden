# ============================================
# KLASÖR YAPISINI OLUŞTURMA VE DOĞRULAMA
# ============================================
$ProgramDataPath = $env:ProgramData
$WazuhPath = Join-Path $ProgramDataPath "Wazuh"
$LogsPath = Join-Path $WazuhPath "Logs"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "[$TimeNow] Klasör yapısı oluşturuluyor..." -ForegroundColor Yellow

# Ana Wazuh klasörünü oluştur
if (-not (Test-Path $WazuhPath)) {
    try {
        New-Item -ItemType Directory -Path $WazuhPath -Force | Out-Null
        Write-Host "✓ Wazuh klasörü oluşturuldu: $WazuhPath" -ForegroundColor Green
    } catch {
        Write-Host "✗ Wazuh klasörü oluşturulamadı: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ Wazuh klasörü zaten mevcut: $WazuhPath" -ForegroundColor Green
}

# Logs klasörünü oluştur
if (-not (Test-Path $LogsPath)) {
    try {
        New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
        Write-Host "✓ Logs klasörü oluşturuldu: $LogsPath" -ForegroundColor Green
    } catch {
        Write-Host "✗ Logs klasörü oluşturulamadı: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ Logs klasörü zaten mevcut: $LogsPath" -ForegroundColor Green
}

# Klasörlerin varlığını son kez doğrula
if ((Test-Path $WazuhPath) -and (Test-Path $LogsPath)) {
    Write-Host "✓ Tüm klasörler başarıyla oluşturuldu ve doğrulandı" -ForegroundColor Green
    
    # Klasör izinlerini kontrol et
    try {
        $testFile = Join-Path $LogsPath "test_write.tmp"
        "test" | Out-File -FilePath $testFile -Force
        Remove-Item $testFile -Force
        Write-Host "✓ Logs klasörüne yazma izni doğrulandı" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Logs klasörüne yazma izni yok: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Klasör oluşturma başarısız!" -ForegroundColor Red
    exit 1
}

Write-Host "[$TimeNow] Klasör yapısı hazırlandı, script devam ediyor..." -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Gray

# ============================================
# ANA SCRIPT
# ============================================
$LogFile = Join-Path $LogsPath "email_cred_log.log"
$ScriptPath = Join-Path $LogsPath "Collect-EmailAndCreds.ps1"
$TaskName = "Wazuh_Email_Cred_Collector"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Log başlığı
Add-Content -Path $LogFile -Value "`n[$TimeNow] --- Günlük e-posta ve kimlik bilgisi taraması başlatıldı ---"

# 1️⃣ Outlook POP/IMAP e-posta adresleri
try {
    $ProfilesPath = "HKCU:\Software\Microsoft\Office"
    $OfficeVersions = Get-ChildItem $ProfilesPath | Where-Object { $_.Name -match '1[6-9]\.0|[2-9][0-9]\.0' }
    foreach ($Version in $OfficeVersions) {
        $ProfileRoot = "$($Version.PSPath)\Outlook\Profiles"
        if (Test-Path $ProfileRoot) {
            Get-ChildItem -Path $ProfileRoot -Recurse | ForEach-Object {
                $values = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
                foreach ($prop in $values.PSObject.Properties) {
                    if ($prop.Value -match "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}") {
                        Add-Content -Path $LogFile -Value "[POP/IMAP] $($_.PSPath) : $($prop.Value)"
                    }
                }
            }
        }
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] Outlook e-posta taramasında hata: $_"
}

# 2️⃣ Credential Manager (cmdkey target + username eşleştirmesi)
try {
    $entries = cmdkey /list
    $blocks = @()
    $currentBlock = @()
    foreach ($line in $entries) {
        if ($line -match "^\s*$" -and $currentBlock.Count -gt 0) {
            $blocks += ,@($currentBlock)
            $currentBlock = @()
        } else {
            $currentBlock += $line
        }
    }
    if ($currentBlock.Count -gt 0) {
        $blocks += ,@($currentBlock)
    }
    foreach ($block in $blocks) {
        $target = $null
        $user = $null
        foreach ($line in $block) {
            if ($line -match "Target:\s*(.+)") {
                $target = $Matches[1].Trim()
            }
            if ($line -match "User:\s*(.+)") {
                $user = $Matches[1].Trim()
            }
        }
        if ($target -match "TERMSRV|nas|vpn|rdp|cloud|\d+\.\d+\.\d+\.\d+" -and $user) {
            Add-Content -Path $LogFile -Value "[CREDENTIAL] $target username: $user"
        }
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] cmdkey Credential taramasında hata: $_"
}

# 3️⃣ Görev zamanlayıcıya kendini ekle
try {
    $existing = schtasks /Query /TN $TaskName 2>&1 | Out-String
    if ($existing -match "ERROR:") {
        $action = 'powershell.exe -ExecutionPolicy Bypass -File "' + $ScriptPath + '"'
        schtasks /Create /SC DAILY /TN $TaskName /TR "$action" /ST 09:00 /RL HIGHEST /F | Out-Null
        Add-Content -Path $LogFile -Value "[✓] Görev zamanlayıcıya eklendi: $TaskName"
    } else {
        Add-Content -Path $LogFile -Value "[✓] Zaten görev zamanlayıcıda mevcut: $TaskName"
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] Görev zamanlayıcıya eklenemedi: $_"
}

# Bitiş
Add-Content -Path $LogFile -Value "--- Tarama tamamlandı ---"
