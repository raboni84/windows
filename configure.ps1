# For reference:
# https://github.com/luciusbono/Packer-Windows10
# https://github.com/joefitzgerald/packer-windows

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
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power\ -name HiberFileSizePercent -value 0
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power\ -name HibernateEnabled -value 0

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
