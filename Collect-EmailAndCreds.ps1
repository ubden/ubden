# Wazuh E-posta ve Kimlik Bilgisi Toplama Script'i - Geliştirilmiş Versiyon
# Yönetici hakları kontrolü ve kendini doğrulama mekanizması ile

param(
    [switch]$Force,
    [switch]$Uninstall
)

# Global değişkenler
$LogFile = "C:\ProgramData\Wazuh\Logs\email_cred_log.log"
$ScriptPath = "C:\ProgramData\Wazuh\Logs\Collect-EmailAndCreds.ps1" 
$TaskName = "Wazuh_Email_Cred_Collector"
$TimeNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

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
        Write-Host "Yonetici haklari gerekli. Script yonetici olarak yeniden baslatiliyor..." -ForegroundColor Yellow
        try {
            $arguments = ""
            if ($Force) { $arguments += " -Force" }
            if ($Uninstall) { $arguments += " -Uninstall" }
            
            Start-Process PowerShell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"$arguments" -Verb RunAs -Wait
            exit 0
        }
        catch {
            Write-Error "Yonetici haklariyla calistirilamadi: $_"
            exit 1
        }
    }
}

# Güvenli dizin oluşturma
function New-SecureDirectory {
    param([string]$Path)
    
    try {
        if (-not (Test-Path $Path)) {
            $null = New-Item -ItemType Directory -Path $Path -Force
            Write-Host "Dizin olusturuldu: $Path" -ForegroundColor Green
        }
        
        # Dizin izinlerini kontrol et ve güvenli hale getir
        $acl = Get-Acl $Path
        $acl.SetAccessRuleProtection($true, $false)
        
        # Sadece SYSTEM ve Administrators erişimi
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        
        $acl.SetAccessRule($systemRule)
        $acl.SetAccessRule($adminRule)
        Set-Acl -Path $Path -AclObject $acl
        
        return $true
    }
    catch {
        Write-Error "Dizin olusturulamadi $Path : $_"
        return $false
    }
}

# Güvenli log yazma
function Write-SecureLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
        Write-Host $logEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "WARN"){"Yellow"}else{"White"})
    }
    catch {
        Write-Error "Log yazilamadi: $_"
    }
}

# Script'i hedef konuma kopyala
function Copy-ScriptToTarget {
    try {
        $currentScript = $MyInvocation.MyCommand.Path
        if ($currentScript -ne $ScriptPath) {
            if (Test-Path $ScriptPath) {
                Remove-Item $ScriptPath -Force -ErrorAction SilentlyContinue
            }
            Copy-Item $currentScript $ScriptPath -Force
            Write-SecureLog "Script hedef konuma kopyalandi: $ScriptPath"
            return $true
        }
        return $true
    }
    catch {
        Write-SecureLog "Script kopyalanamadi: $_" "ERROR"
        return $false
    }
}

# Outlook e-posta adreslerini tara
function Get-OutlookEmails {
    Write-SecureLog "Outlook e-posta adresleri taranıyor..."
    
    try {
        $emailCount = 0
        $ProfilesPath = "HKCU:\Software\Microsoft\Office"
        
        if (-not (Test-Path $ProfilesPath)) {
            Write-SecureLog "Office registry yolu bulunamadi" "WARN"
            return
        }
        
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
                                if ($prop.Value -match "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}") {
                                    Write-SecureLog "[OUTLOOK_EMAIL] Registry: $($_.PSPath) Email: $($prop.Value)"
                                    $emailCount++
                                }
                            }
                        }
                    }
                    catch {
                        Write-SecureLog "Registry anahtari okunamadi: $($_.PSPath) - $_" "WARN"
                    }
                }
            }
        }
        
        Write-SecureLog "Toplam $emailCount e-posta adresi bulundu"
    }
    catch {
        Write-SecureLog "Outlook e-posta taramasinda hata: $_" "ERROR"
    }
}

# Credential Manager tarama
function Get-StoredCredentials {
    Write-SecureLog "Kaydedilmis kimlik bilgileri taranıyor..."
    
    try {
        $credCount = 0
        $entries = cmdkey /list 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-SecureLog "cmdkey komutu basarisiz oldu" "ERROR"
            return
        }
        
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
            
            # Suspicious targets (RDP, VPN, NAS, cloud services, IP addresses)
            if ($target -and $user -and ($target -match "TERMSRV|nas|vpn|rdp|cloud|ftp|ssh|sftp|\d+\.\d+\.\d+\.\d+|\.com|\.net|\.org")) {
                Write-SecureLog "[STORED_CREDENTIAL] Target: $target User: $user"
                $credCount++
            }
        }
        
        Write-SecureLog "Toplam $credCount kimlik bilgisi bulundu"
    }
    catch {
        Write-SecureLog "Credential Manager taramasinda hata: $_" "ERROR"
    }
}

# Zamanlanmış görev oluştur
function New-ScheduledTask {
    try {
        Write-SecureLog "Zamanlanmis gorev kontrol ediliyor..."
        
        # Mevcut görevi kontrol et
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        
        if ($existingTask) {
            Write-SecureLog "Zamanlanmis gorev zaten mevcut: $TaskName"
            return $true
        }
        
        # Yeni görev oluştur
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
        $trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Wazuh Email and Credential Monitoring"
        
        Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null
        
        Write-SecureLog "Zamanlanmis gorev basariyla olusturuldu: $TaskName"
        return $true
    }
    catch {
        Write-SecureLog "Zamanlanmis gorev olusturulamadi: $_" "ERROR"
        return $false
    }
}

# Zamanlanmış görevi kaldır
function Remove-ScheduledTask {
    try {
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-SecureLog "Zamanlanmis gorev kaldirild: $TaskName"
        } else {
            Write-SecureLog "Kaldirılacak zamanlanmis gorev bulunamadi"
        }
        
        if (Test-Path $ScriptPath) {
            Remove-Item $ScriptPath -Force
            Write-SecureLog "Script dosyası silindi: $ScriptPath"
        }
        
        return $true
    }
    catch {
        Write-SecureLog "Zamanlanmis gorev kaldirilamadi: $_" "ERROR"
        return $false
    }
}

# Sistem bilgilerini topla
function Get-SystemInfo {
    try {
        $computerName = $env:COMPUTERNAME
        $userName = $env:USERNAME
        $domain = $env:USERDOMAIN
        $osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        
        Write-SecureLog "=== SISTEM BILGILERI ==="
        Write-SecureLog "Bilgisayar: $computerName"
        Write-SecureLog "Kullanici: $domain\$userName"
        Write-SecureLog "Isletim Sistemi: $osVersion"
        Write-SecureLog "Script Versiyonu: 2.0"
        Write-SecureLog "========================"
    }
    catch {
        Write-SecureLog "Sistem bilgileri alinamadi: $_" "ERROR"
    }
}

# Ana fonksiyon
function Main {
    # Yönetici hakları kontrolü
    Restart-AsAdmin
    
    Write-Host "Wazuh E-posta ve Kimlik Bilgisi Collector v2.0" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    # Kaldırma modu
    if ($Uninstall) {
        Write-Host "Kaldirma modu aktif..." -ForegroundColor Yellow
        Remove-ScheduledTask
        Write-Host "Kaldirma islemi tamamlandi." -ForegroundColor Green
        return
    }
    
    # Dizin oluştur
    $logDir = Split-Path $LogFile -Parent
    if (-not (New-SecureDirectory $logDir)) {
        Write-Error "Kritik hata: Log dizini olusturulamadi"
        exit 1
    }
    
    # Script'i hedef konuma kopyala
    if (-not (Copy-ScriptToTarget)) {
        Write-Error "Kritik hata: Script kopyalanamadi"
        exit 1
    }
    
    # Log başlat
    Write-SecureLog "=== WAZUH EMAIL VE CREDENTIAL TARAMASI BASLADI ==="
    
    # Sistem bilgilerini topla
    Get-SystemInfo
    
    # E-posta tarama
    Get-OutlookEmails
    
    # Credential tarama
    Get-StoredCredentials
    
    # Zamanlanmış görev oluştur
    New-ScheduledTask
    
    # Kendini doğrula
    if (Test-Path $ScriptPath) {
        Write-SecureLog "[DOGRULAMA] Script dosyasi mevcut: $ScriptPath"
    } else {
        Write-SecureLog "[DOGRULAMA] HATA: Script dosyasi bulunamadi!" "ERROR"
    }
    
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        Write-SecureLog "[DOGRULAMA] Zamanlanmis gorev mevcut: $TaskName"
        Write-SecureLog "[DOGRULAMA] Gorev durumu: $($task.State)"
    } else {
        Write-SecureLog "[DOGRULAMA] HATA: Zamanlanmis gorev bulunamadi!" "ERROR"
    }
    
    Write-SecureLog "=== TARAMA TAMAMLANDI ==="
    Write-Host "`nTarama tamamlandi. Log dosyasi: $LogFile" -ForegroundColor Green
    Write-Host "Zamanlanmis gorev: $TaskName (her gun 09:00)" -ForegroundColor Green
    Write-Host "`nKaldirmak icin: PowerShell -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" -Uninstall" -ForegroundColor Yellow
}

# Script'i çalıştır
try {
    Main
}
catch {
    Write-Error "Kritik hata: $_"
    if (Test-Path $LogFile) {
        Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [FATAL] Kritik hata: $_"
    }
    exit 1
}
