$otherboot = bcdedit /copy '{current}' /d 'Windows 10 Debugging' | Select-String -Pattern '{[-0-9A-F]+?}' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value
Write-Host "New boot entry guid is $($otherboot)"
bcdedit /debug "$($otherboot)" ON
bcdedit /set "$($otherboot)" debug on
bcdedit /set "$($otherboot)" debugtype net
bcdedit /set "$($otherboot)" port 50000
bcdedit /set "$($otherboot)" hostip 169.254.0.1 nodhcp
bcdedit /set "$($otherboot)" key a.b.c.d
bcdedit /set "$($otherboot)" busparams 0.8.0
bcdedit /default "$($otherboot)"

#bcdedit /debug ON
#bcdedit /dbgsettings NET HOSTIP:169.254.0.1 PORT:50000 KEY:a.b.c.d nodhcp
#bcdedit /set busparams 0.8.0
