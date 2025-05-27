$LogFile = "C:\ProgramData\Wazuh\Logs\email_cred_log.log"
$ScriptPath = $MyInvocation.MyCommand.Path
$TaskName = "Wazuh_Email_Cred_Collector"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Klasör kontrolü
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

# 2️⃣ Credential Manager
try {
    $vaults = cmdkey /list | Select-String "Target" | ForEach-Object {
        $_.ToString().Split(":")[1].Trim()
    }

    foreach ($vault in $vaults) {
        if ($vault -match "\d+\.\d+\.\d+\.\d+" -or $vault -match "nas|term|cloud|vpn|rdp|file|srv|auth|sso|domain|host") {
            Add-Content -Path $LogFile -Value "[CREDENTIAL] Entry found: $vault"
        }
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] Credential taramasında hata: $_"
}

# 3️⃣ Görev zamanlayıcıya kendini ekle
try {
    $existingTask = schtasks /Query /TN $TaskName 2>$null
    if (-not $existingTask) {
        $action = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`""
        schtasks /Create /SC DAILY /TN $TaskName /TR "$action" /ST 09:00 /F | Out-Null
        Add-Content -Path $LogFile -Value "[✓] Görev zamanlayıcıya eklendi: $TaskName"
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] Görev zamanlayıcıya eklenemedi: $_"
}

# Bitiş
Add-Content -Path $LogFile -Value "--- Tarama tamamlandı ---"
