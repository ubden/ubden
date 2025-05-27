# Wazuh E-posta ve Kimlik Bilgisi Collector - Sessiz Otomatik Versiyon
# Tamamen sessiz çalışır, kendini kurar ve tarama yapar

param(
    [switch]$Uninstall
)

# Global değişkenler
$LogFile = "C:\ProgramData\Wazuh\Logs\email_cred_log.log"
$ScriptPath = "C:\ProgramData\Wazuh\Logs\Collect-EmailAndCreds.ps1"
$TaskName = "Wazuh_Email_Cred_Collector"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Scheduled task tarafından çalıştırılıyor mu kontrol et
function Test-IsScheduledRun {
    try {
        $parentProcess = Get-WmiObject -Class Win32_Process -Filter "ProcessId = $((Get-WmiObject -Class Win32_Process -Filter "ProcessId = $PID").ParentProcessId)" -ErrorAction SilentlyContinue
        return ($parentProcess -and $parentProcess.Name -eq "svchost.exe")
    }
    catch {
        return $false
    }
}

# Yönetici hakları kontrolü
function Test-IsAdmin {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

# Script'i yönetici olarak sessizce yeniden başlat
function Restart-AsAdmin {
    if (-not (Test-IsAdmin)) {
        try {
            Start-Process PowerShell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -WindowStyle Hidden -Wait
            exit 0
        }
        catch {
            exit 1
        }
    }
}

# Sessiz log yazma - UTF-8 BOM ile Türkçe karakter desteği
function Write-CollectorLog {
    param(
        [string]$Message
    )
    
    try {
        # Klasör yoksa oluştur
        $logDir = Split-Path $LogFile -Parent
        if (-not (Test-Path $logDir)) {
            $null = New-Item -ItemType Directory -Path $logDir -Force
            
            # Wazuh Agent erişimi için izinler
            try {
                $acl = Get-Acl $logDir
                $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
                $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
                $usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
                
                $acl.SetAccessRule($systemRule)
                $acl.SetAccessRule($adminRule)
                $acl.SetAccessRule($usersRule)
                Set-Acl -Path $logDir -AclObject $acl
            }
            catch { }
        }
        
        # UTF-8 BOM ile yazma - Türkçe karakter desteği için
        [System.IO.File]::AppendAllText($LogFile, "$Message`r`n", [System.Text.Encoding]::UTF8)
    }
    catch { }
}

# Sessiz kurulum işlemi
function Install-Collector {
    try {
        Write-CollectorLog "[KURULUM] Collector sessiz kuruluyor..."
        
        # Script'i doğru konuma kopyala
        $currentScript = $MyInvocation.MyCommand.Path
        if ($currentScript -and $currentScript -ne $ScriptPath) {
            try {
                if (Test-Path $ScriptPath) {
                    Remove-Item $ScriptPath -Force -ErrorAction SilentlyContinue
                }
                Copy-Item $currentScript $ScriptPath -Force -ErrorAction Stop
                Write-CollectorLog "[KURULUM] Script kopyalandı: $ScriptPath"
            }
            catch {
                Write-CollectorLog "[ERROR] Script kopyalanamadı: $_"
                return $false
            }
        }
        
        # Scheduled task oluştur
        try {
            $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            
            if (-not $existingTask) {
                $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
                $trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
                $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
                $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
                
                $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Wazuh Email and Credential Monitoring"
                
                Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null
                Write-CollectorLog "[KURULUM] Zamanlanmış görev oluşturuldu: $TaskName"
            } else {
                Write-CollectorLog "[KURULUM] Zamanlanmış görev zaten mevcut: $TaskName"
            }
        }
        catch {
            Write-CollectorLog "[ERROR] Scheduled task oluşturulamadı: $_"
            return $false
        }
        
        Write-CollectorLog "[KURULUM] Kurulum sessizce tamamlandı"
        return $true
    }
    catch {
        Write-CollectorLog "[ERROR] Kurulum hatasi: $_"
        return $false
    }
}

# Sessiz kaldırma işlemi
function Uninstall-Collector {
    try {
        Write-CollectorLog "[KALDIRMA] Collector sessizce kaldırılıyor..."
        
        # Scheduled task kaldır
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
            Write-CollectorLog "[KALDIRMA] Zamanlanmış görev kaldırıldı: $TaskName"
        }
        
        # Script dosyasını sil
        if (Test-Path $ScriptPath) {
            Remove-Item $ScriptPath -Force -ErrorAction SilentlyContinue
            Write-CollectorLog "[KALDIRMA] Script dosyası silindi: $ScriptPath"
        }
        
        Write-CollectorLog "[KALDIRMA] Kaldırma sessizce tamamlandı"
        return $true
    }
    catch {
        Write-CollectorLog "[ERROR] Kaldirma hatasi: $_"
        return $false
    }
}

# Ana tarama fonksiyonu
function Start-EmailCredentialScan {
    Write-CollectorLog "`n[$TimeNow] --- Günlük e-posta ve kimlik bilgisi taraması başlatıldı ---"
    
    # Sistem bilgileri
    try {
        $computerName = $env:COMPUTERNAME
        $userName = $env:USERNAME
        $domain = $env:USERDOMAIN
        
        Write-CollectorLog "Bilgisayar: $computerName | Kullanici: $domain\$userName | Zaman: $TimeNow"
    }
    catch { }
    
    # 1️⃣ Outlook POP/IMAP e-posta adresleri
    try {
        $emailCount = 0
        $foundEmails = @()  # Tekrar önleme için
        $ProfilesPath = "HKCU:\Software\Microsoft\Office"
        
        if (Test-Path $ProfilesPath) {
            $OfficeVersions = Get-ChildItem $ProfilesPath -ErrorAction SilentlyContinue | 
                             Where-Object { $_.Name -match '1[6-9]\.0|[2-9][0-9]\.0' }
            
            foreach ($Version in $OfficeVersions) {
                $ProfileRoot = "$($Version.PSPath)\Outlook\Profiles"
                if (Test-Path $ProfileRoot) {
                    Get-ChildItem -Path $ProfileRoot -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                        try {
                            $values = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
                            if ($values) {
                                foreach ($prop in $values.PSObject.Properties) {
                                    # E-posta regex match
                                    if ($prop.Value -match "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}") {
                                        $emailAddress = $Matches[0]
                                        
                                        # İmza kontrolü - "imza" kelimesi içeren kayıtları atla
                                        if ($prop.Value -notmatch "imza|signature") {
                                            # Tekrar kontrolü
                                            if ($foundEmails -notcontains $emailAddress) {
                                                Write-CollectorLog "[POP/IMAP] : $emailAddress"
                                                $foundEmails += $emailAddress
                                                $emailCount++
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        catch { }
                    }
                }
            }
        }
        
        Write-CollectorLog "[SONUC] Toplam $emailCount e-posta adresi bulundu"
    } 
    catch {
        Write-CollectorLog "[ERROR] Outlook e-posta taramasında hata: $_"
    }
    
    # 2️⃣ Credential Manager tarama
    try {
        $credCount = 0
        $foundCreds = @()  # Tekrar önleme için
        $entries = cmdkey /list 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $entries) {
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
                
                # Şüpheli hedefler (RDP, VPN, NAS, cloud servisler, IP adresleri)
                if ($target -and $user -and ($target -match "TERMSRV|nas|vpn|rdp|cloud|\d+\.\d+\.\d+\.\d+")) {
                    $credEntry = "$target | $user"
                    
                    # Tekrar kontrolü
                    if ($foundCreds -notcontains $credEntry) {
                        # Target'ı temizle - "Domain:target=" kısmını kaldır
                        $cleanTarget = $target -replace "^Domain:target=", ""
                        Write-CollectorLog "[CREDENTIAL] $cleanTarget : $user"
                        $foundCreds += $credEntry
                        $credCount++
                    }
                }
            }
        }
        
        Write-CollectorLog "[SONUC] Toplam $credCount kimlik bilgisi bulundu"
    } 
    catch {
        Write-CollectorLog "[ERROR] cmdkey Credential taramasında hata: $_"
    }
    
    # Bitiş
    Write-CollectorLog "--- Tarama tamamlandı ---"
}

# Ana fonksiyon - Tamamen sessiz
function Main {
    # Kaldırma modu
    if ($Uninstall) {
        if (-not (Test-IsAdmin)) {
            Restart-AsAdmin
        }
        Uninstall-Collector
        exit 0
    }
    
    # Scheduled task tarafından çalıştırılıyor mu?
    $isScheduledRun = Test-IsScheduledRun
    
    if ($isScheduledRun) {
        # Scheduled task tarafından çalıştırılıyor - sadece tarama yap
        Start-EmailCredentialScan
    } else {
        # Manuel çalıştırılıyor - kurulum + tarama yap
        if (-not (Test-IsAdmin)) {
            Restart-AsAdmin
        }
        
        Write-CollectorLog "=== WAZUH COLLECTOR SESSIZ BAŞLADI ==="
        
        # Kurulum yap
        $installResult = Install-Collector
        
        # Tarama yap
        Start-EmailCredentialScan
        
        if ($installResult) {
            Write-CollectorLog "=== KURULUM VE TARAMA SESSIZCE TAMAMLANDI ==="
        } else {
            Write-CollectorLog "=== KURULUM HATALI, TARAMA YAPILDI ==="
        }
    }
    
    exit 0
}

# Sessiz çalıştırma
try {
    Main
}
catch {
    try {
        Write-CollectorLog "[FATAL] Kritik hata: $_"
    }
    catch { }
    exit 1
}
