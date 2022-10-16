# For reference:
# https://github.com/luciusbono/Packer-Windows10
# https://github.com/joefitzgerald/packer-windows

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
C:/Windows/SysWOW64/cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name ThreadJob -MinimumVersion 2.0.3 -Force

# ===
# Network
# ===

# Supress network location Prompt
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -Force

# Set network to private
$ifaceinfo = Get-NetConnectionProfile
Set-NetConnectionProfile -InterfaceIndex $ifaceinfo.InterfaceIndex -NetworkCategory Private 

# ===
# System settings
# ===

# disable hibernation
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\" -Name "HiberFileSizePercent" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\" -Name "HibernateEnabled" -Value 0 -Force

# disable password expiration
wmic useraccount where "name='user'" set PasswordExpires=FALSE

# disable windows updates
$Updates = (New-Object -ComObject "Microsoft.Update.AutoUpdate").Settings
if ($Updates.ReadOnly -eq $False) {
  $Updates.NotificationLevel = 1 #Disabled
  $Updates.Save()
  $Updates.Refresh()
  Write-Output "Automatic Windows Updates disabled."
}

# disable telemetry
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost\" -Name "EnableWebContentEvaluation" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\" -Name "Enabled" -Value 0 -Force
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\" -Name "Id" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\" -Name "AllowTelemetry" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection\" -Name "MaxTelemetryAllowed" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration\" -Name "Status" -Value 0 -Force

# install guest additions
Get-ChildItem "e:\cert\" *.cer | ForEach-Object {
  Start-Process -NoNewWindow -Wait -FilePath "E:\cert\VBoxCertUtil.exe" -ArgumentList "add-trusted-publisher $($_.FullName) --root $($_.FullName)"
}
Start-Process -NoNewWindow -Wait -FilePath "E:\VBoxWindowsAdditions.exe" -ArgumentList "/S"

# ===
# WinRM
# ===

# Set up WinRM and configure some things
winrm quickconfig -q
winrm s "winrm/config" '@{MaxTimeoutms="1800000"}'
winrm s "winrm/config/winrs" '@{MaxMemoryPerShellMB="2048"}'
winrm s "winrm/config/service" '@{AllowUnencrypted="true"}'
winrm s "winrm/config/service/auth" '@{Basic="true"}'

# Enable the WinRM Firewall rule, which will likely already be enabled due to the 'winrm quickconfig' command above
Enable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"

sc.exe config winrm start= auto

# ===
# Exit
# ===

exit 0
