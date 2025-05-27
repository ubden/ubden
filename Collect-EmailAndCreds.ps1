$LogFile = "C:\ProgramData\Wazuh\Logs\email_cred_log.log"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Klasör oluştur
if (-not (Test-Path (Split-Path $LogFile))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
}

# LOG BAŞLIĞI
Add-Content -Path $LogFile -Value "`n[$TimeNow] --- Günlük e-posta ve kimlik bilgisi taraması başlatıldı ---"

# 1️⃣ Outlook POP/IMAP adreslerini alma
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

# 2️⃣ Windows Credential Manager'dan IP/host + kullanıcı adı
try {
    $vaults = cmdkey /list | Select-String "Target" | ForEach-Object {
        $_.ToString().Split(":")[1].Trim()
    }

    foreach ($vault in $vaults) {
        if ($vault -match "^(http|https|ftp|ssh|rdp|ip|hostname|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|\\\\)") {
            Add-Content -Path $LogFile -Value "[CREDENTIAL] Found entry: $vault"
        }
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] Credential taramasında hata: $_"
}

# Bitiş
Add-Content -Path $LogFile -Value "--- Tarama tamamlandı ---"
