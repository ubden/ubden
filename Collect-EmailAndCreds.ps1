$LogFile = "C:\ProgramData\Wazuh\Logs\email_cred_log.log"
$ScriptPath = "C:\ProgramData\Wazuh\Logs\Collect-EmailAndCreds.ps1"
$TaskName = "Wazuh_Email_Cred_Collector"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# KlasÃ¶r oluÅŸtur
if (-not (Test-Path (Split-Path $LogFile))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
}

# Log baÅŸlÄ±ÄŸÄ±
Add-Content -Path $LogFile -Value "`n[$TimeNow] --- GÃ¼nlÃ¼k e-posta ve kimlik bilgisi taramasÄ± baÅŸlatÄ±ldÄ± ---"

# 1ï¸âƒ£ Outlook POP/IMAP e-posta adresleri
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
    Add-Content -Path $LogFile -Value "[ERROR] Outlook e-posta taramasÄ±nda hata: $_"
}

# 2ï¸âƒ£ Credential Manager (cmdkey target + username eÅŸleÅŸtirmesi)
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
    Add-Content -Path $LogFile -Value "[ERROR] cmdkey Credential taramasÄ±nda hata: $_"
}


# 4ï¸âƒ£ GÃ¶rev zamanlayÄ±cÄ±ya kendini ekle
try {
    $existing = schtasks /Query /TN $TaskName 2>&1 | Out-String
    if ($existing -match "ERROR:") {
        $action = 'powershell.exe -ExecutionPolicy Bypass -File "' + $ScriptPath + '"'
        schtasks /Create /SC DAILY /TN $TaskName /TR "$action" /ST 09:00 /RL HIGHEST /F | Out-Null
        Add-Content -Path $LogFile -Value "[âœ“] GÃ¶rev zamanlayÄ±cÄ±ya eklendi: $TaskName"
    } else {
        Add-Content -Path $LogFile -Value "[âœ“] Zaten gÃ¶rev zamanlayÄ±cÄ±da mevcut: $TaskName"
    }
} catch {
    Add-Content -Path $LogFile -Value "[ERROR] GÃ¶rev zamanlayÄ±cÄ±ya eklenemedi: $_"
}

# BitiÅŸ
Add-Content -Path $LogFile -Value "--- Tarama tamamlandÄ± ---"
