$LogFile = "C:\ProgramData\Wazuh\Logs\email_cred_log.log"
$ScriptPath = "C:\ProgramData\Wazuh\Logs\Collect-EmailAndCreds.ps1"
$TaskName = "Wazuh_Email_Cred_Collector"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Klasör oluştur
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

# 2️⃣ Credential Manager (cmdkey ile hedefler - doğru şekilde)
try {
    $targets = cmdkey /list | Where-Object { $_ -match "^Target:" } | ForEach-Object {
        ($_ -split "Target:")[1].Trim()
    }

    foreach ($target in $targets) {
        if ($target -match "\d+\.\d+\.\d+\.\d+" -or $target -match "nas|term|cloud|vpn|rdp|file|srv|auth|sso|domain|host|TERMSRV") {
            Add-Content -Path $LogFile -Value "[CREDENTIAL] Target found: $target"
        }
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] cmdkey Credential taramasında hata: $_"
}

# 3️⃣ Credential Registry (TERMSRV/RDP gibi kayıtları registry'den al)
try {
    $RegPaths = Get-ChildItem -Path "HKCU:\Software\Microsoft\CredUI\CredPersisted" -ErrorAction SilentlyContinue
    foreach ($item in $RegPaths) {
        $keyName = $item.PSChildName
        if ($keyName -match "TERMSRV|nas|vpn|cloud|rdp|sso|domain|\d+\.\d+\.\d+\.\d+") {
            Add-Content -Path $LogFile -Value "[CREDENTIAL-RDP] Saved Key: $keyName"
        }
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] Registry Credential taramasında hata: $_"
}

# 4️⃣ Görev zamanlayıcıya kendini ekle
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
