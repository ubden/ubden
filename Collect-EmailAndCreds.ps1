$LogFile = "C:\ProgramData\Wazuh\Logs\email_cred_log.log"
$TaskName = "Wazuh_Email_Cred_Collector"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Klasörleri oluştur
if (-not (Test-Path "C:\ProgramData\Wazuh")) {
    New-Item -ItemType Directory -Path "C:\ProgramData\Wazuh" -Force | Out-Null
}

if (-not (Test-Path "C:\ProgramData\Wazuh\Logs")) {
    New-Item -ItemType Directory -Path "C:\ProgramData\Wazuh\Logs" -Force | Out-Null
}

# Log başlığı
Add-Content -Path $LogFile -Value "`n[$TimeNow] --- Günlük e-posta ve kimlik bilgisi taraması başlatıldı ---"

# 1️⃣ Outlook POP/IMAP e-posta adresleri
try {
    $ProfilesPath = "HKCU:\Software\Microsoft\Office"
    $OfficeVersions = Get-ChildItem $ProfilesPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '1[6-9]\.0|[2-9][0-9]\.0' }
    foreach ($Version in $OfficeVersions) {
        $ProfileRoot = "$($Version.PSPath)\Outlook\Profiles"
        if (Test-Path $ProfileRoot) {
            Get-ChildItem -Path $ProfileRoot -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
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
    $entries = cmdkey /list 2>$null
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
Add-Content -Path $LogFile -Value "[✓] Klasörler oluşturuldu: C:\ProgramData\Wazuh\Logs\"
