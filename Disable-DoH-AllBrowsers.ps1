# PowerShell script to disable DoH in all common browsers

# Function to create registry key and value
function Set-DoHRegistryPolicy {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value,
        [string]$Type = "String"
    )
    try {
        New-Item -Path $Path -Force | Out-Null
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
        Write-Host "✅ $Path\$Name = $Value"
    } catch {
        Write-Host "❌ Failed to set $Path\$Name"
    }
}

Write-Host "`n📌 Starting DoH policy configuration for browsers...`n"

# 1. Chrome
Set-DoHRegistryPolicy -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "DnsOverHttpsMode" -Value "off"

# 2. Edge
Set-DoHRegistryPolicy -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BuiltInDnsClientEnabled" -Value 0 -Type "DWord"

# 3. Opera
Set-DoHRegistryPolicy -Path "HKLM:\SOFTWARE\Policies\Opera\Opera" -Name "DnsOverHttpsMode" -Value "off"

# 4. Brave
Set-DoHRegistryPolicy -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Name "DnsOverHttpsMode" -Value "off"

# 5. Vivaldi
Set-DoHRegistryPolicy -Path "HKLM:\SOFTWARE\Policies\Vivaldi" -Name "DnsOverHttpsMode" -Value "off"

# 6. Chromium
Set-DoHRegistryPolicy -Path "HKLM:\SOFTWARE\Policies\Chromium" -Name "DnsOverHttpsMode" -Value "off"

# 7. Firefox (via policies.json)
$firefoxDirs = @(
    "${env:ProgramFiles}\Mozilla Firefox",
    "${env:ProgramFiles(x86)}\Mozilla Firefox"
)

$policyJson = @"
{
  "policies": {
    "DNSOverHTTPS": {
      "Enabled": false
    }
  }
}
"@

foreach ($dir in $firefoxDirs) {
    $distPath = Join-Path $dir "distribution"
    $policyFile = Join-Path $distPath "policies.json"
    if (Test-Path $dir) {
        try {
            New-Item -Path $distPath -ItemType Directory -Force | Out-Null
            Set-Content -Path $policyFile -Value $policyJson -Encoding UTF8
            Write-Host "✅ Firefox policy set at: $policyFile"
        } catch {
            Write-Host "❌ Failed to set Firefox policy at: $policyFile"
        }
    }
}

Write-Host "`n🎉 Completed. Please restart browsers for changes to take effect.`n"
