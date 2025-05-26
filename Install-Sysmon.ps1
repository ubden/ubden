# Sysmon kurulum ve yapılandırma scripti (Temiz sürüm)

$TempDir = "$env:TEMP\SysmonInstall"
$SysmonZip = "$TempDir\Sysmon.zip"
$SysmonDir = "$TempDir\Sysmon"
$SysmonConfig = "$TempDir\sysmonconfig.xml"

$SysmonURL = "https://download.sysinternals.com/files/Sysmon.zip"
$ConfigURL = "https://raw.githubusercontent.com/ubden/ubden/refs/heads/main/sysmon.xml"

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir | Out-Null

Invoke-WebRequest -Uri $SysmonURL -OutFile $SysmonZip
Expand-Archive -Path $SysmonZip -DestinationPath $SysmonDir -Force

Invoke-WebRequest -Uri $ConfigURL -OutFile $SysmonConfig

$SysmonExe = Join-Path $SysmonDir "Sysmon64.exe"
if (-not (Test-Path $SysmonExe)) {
    $SysmonExe = Join-Path $SysmonDir "Sysmon.exe"
}

Start-Process -FilePath $SysmonExe -ArgumentList "-accepteula -i `"$SysmonConfig`"" -Wait
