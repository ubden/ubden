$LogFile = "C:\ProgramData\Wazuh\Logs\email_cred_log.log"
$ScriptPath = "C:\ProgramData\Wazuh\Logs\Collect-EmailAndCreds.ps1"
$TaskName = "Wazuh_Email_Cred_Collector"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Gerekli dizinleri oluştur
if (-not (Test-Path (Split-Path $LogFile))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
}

if (-not (Test-Path (Split-Path $ScriptPath))) {
    New-Item -ItemType Directory -Path (Split-Path $ScriptPath) -Force | Out-Null
}

# Scripti hedef konuma oluştur (eğer mevcut değilse)
if (-not (Test-Path $ScriptPath)) {
    $ScriptContent = @'
$LogFile = "C:\ProgramData\Wazuh\Logs\email_cred_log.log"
$ScriptPath = "C:\ProgramData\Wazuh\Logs\Collect-EmailAndCreds.ps1"
$TaskName = "Wazuh_Email_Cred_Collector"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Gerekli dizinleri oluştur
if (-not (Test-Path (Split-Path $LogFile))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
}

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

# Bitiş
Add-Content -Path $LogFile -Value "--- Tarama tamamlandı ---"
'@
    
    Set-Content -Path $ScriptPath -Value $ScriptContent -Encoding UTF8
    Add-Content -Path $LogFile -Value "[✓] Script dosyası oluşturuldu: $ScriptPath"
}

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

# 4️⃣ Görev zamanlayıcıya kendini ekle
try {
    if (Test-Path $ScriptPath) {
        $existing = schtasks /Query /TN $TaskName 2>&1 | Out-String
        if ($existing -match "ERROR:") {
            $action = 'powershell.exe -ExecutionPolicy Bypass -File "' + $ScriptPath + '"'
            schtasks /Create /SC DAILY /TN $TaskName /TR "$action" /ST 09:00 /RL HIGHEST /F | Out-Null
            Add-Content -Path $LogFile -Value "[✓] Görev zamanlayıcıya eklendi: $TaskName"
        } else {
            Add-Content -Path $LogFile -Value "[✓] Zaten görev zamanlayıcıda mevcut: $TaskName"
        }
    } else {
        Add-Content -Path $LogFile -Value "[ERROR] Script dosyası bulunamadı: $ScriptPath"
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] Görev zamanlayıcıya eklenemedi: $_"
}

# Bitiş
Add-Content -Path $LogFile -Value "--- Tarama tamamlandı ---"
