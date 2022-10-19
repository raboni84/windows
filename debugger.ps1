# WinDbg Preview
Write-Host "Trying to find appx url for windbg preview"
$WebResponse = Invoke-WebRequest -Method 'POST' -Uri 'https://store.rg-adguard.net/api/GetFiles' -Body "type=PackageFamilyName&url=Microsoft.WinDbg_8wekyb3d8bbwe&ring=Retail" -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:99.0) Gecko/20100101 Firefox/99.0"
$LinkMatch = $WebResponse.Links | where { $_ -like '*_neutral*.appx*' } | Select-String -Pattern '(?<=a href=").+(?=" r)' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value -First 1
Write-Host "Downloading from $($LinkMatch)"
Invoke-WebRequest -Uri $LinkMatch -OutFile "$ENV:USERPROFILE/Desktop/windbg.appx" -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:99.0) Gecko/20100101 Firefox/99.0"
Write-Host "Installing $ENV:USERPROFILE/Desktop/windbg.appx"
Start-Process -NoNewWindow -Wait -FilePath "$ENV:WINDIR/System32/dism.exe" -WorkingDirectory "$ENV:WINDIR/System32" -ArgumentList "/Online","/Add-ProvisionedAppxPackage","/PackagePath:`"$ENV:USERPROFILE/Desktop/windbg.appx`"","/SkipLicense"

# Rizin
Write-Host "Downloading vcruntime140"
Invoke-WebRequest -Uri "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe" -OutFile "$ENV:USERPROFILE/Desktop/vc_installer.exe" -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:99.0) Gecko/20100101 Firefox/99.0"
Write-Host "Start installing vcruntime140"
Start-Process -NoNewWindow -Wait -FilePath "$ENV:USERPROFILE/Desktop/vc_installer.exe" -WorkingDirectory "$ENV:USERPROFILE/Desktop" -ArgumentList "/SILENT","/ALLUSERS","/NORESTART"

Write-Host "Downloading rizin"
Invoke-WebRequest -Uri "https://github.com/rizinorg/rizin/releases/download/v0.4.1/rizin_installer-v0.4.1-x86_64.exe" -OutFile "$ENV:USERPROFILE/Desktop/rizin_installer.exe" -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:99.0) Gecko/20100101 Firefox/99.0"
Write-Host "Start installing rizin"
Start-Process -NoNewWindow -Wait -FilePath "$ENV:USERPROFILE/Desktop/rizin_installer.exe" -WorkingDirectory "$ENV:USERPROFILE/Desktop" -ArgumentList "/SILENT","/ALLUSERS","/NORESTART"

# Symbols for Windows 10 (this'll take a freaking long time)
New-Item -Path "$ENV:WINDIR" -Name "SYMBOLS" -ItemType "directory" -Force | Out-Null
$syspaths = "$ENV:WINDIR","$ENV:WINDIR/System32","$ENV:WINDIR/System32/Drivers","$ENV:WINDIR/SysWOW64"
$files = Get-ChildItem $syspaths | Where { $_.Extension -in ".exe",".dll",".sys" } | Select-Object -ExpandProperty FullName
$filecnt = $files.Count
$jobs = @()
$idx = 0
foreach ($file in $files) {
  $idx += 1
  $jobs += Start-ThreadJob -ScriptBlock {
    $jobfile = $using:file
    $jobidx = $using:idx
    $jobcnt = $using:filecnt
    $pdb = & "C:\Program Files\Rizin\bin\rz-bin.exe" -I $jobfile | Select-String -Pattern 'dbg_file +([^$]+)' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Select-Object -ExpandProperty Value -Skip 1
    $guid = & "C:\Program Files\Rizin\bin\rz-bin.exe" -I $jobfile | Select-String -Pattern 'guid +([0-9a-fA-F]+)' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Select-Object -ExpandProperty Value -Skip 1
    if ($pdb -And $guid) {
      $pdb = Split-Path $pdb -Leaf
      $linktodbg = "http://msdl.microsoft.com/download/symbols/$($pdb)/$($guid)/$($pdb)"
      $locallink = "$($ENV:WINDIR)/SYMBOLS/$($pdb)/$($guid)/$($pdb)"
      if (-Not(Test-Path -Path $locallink -PathType Leaf)) {
        $StatusCode = ""
        try {
          $Response = Invoke-WebRequest -Uri $linktodbg -Method "Head" -UseBasicParsing -UserAgent "Microsoft-Symbol-Server/10.0.10240.9"
          $StatusCode = $Response.StatusCode
        } catch {
          $StatusCode = $_.Exception.Response.StatusCode.value__
        }
        if ($StatusCode -eq 200) {
          Write-Host "[$($jobidx)/$($jobcnt)] $($jobfile) => $($locallink)"
          New-Item -Path "$ENV:WINDIR/SYMBOLS" -Name $pdb -ItemType "directory" -Force | Out-Null
          New-Item -Path "$ENV:WINDIR/SYMBOLS/$($pdb)" -Name $guid -ItemType "directory" -Force | Out-Null
          # ask again because of multithreading and filename changes
          if (-Not(Test-Path -Path $locallink -PathType Leaf)) {
            #Invoke-WebRequest -Uri $linktodbg -OutFile $locallink -UseBasicParsing -UserAgent "Microsoft-Symbol-Server/10.0.10240.9"
            Add-Content "$ENV:USERPROFILE/Desktop/symbols_success.txt" "$($jobfile),$($pdb),$($guid),$($linktodbg)"
          }
        } else {
          Add-Content "$ENV:USERPROFILE/Desktop/symbols_failure.txt" "$($jobfile),#$($StatusCode)"
        }
      }
    } else {
      Add-Content "$ENV:USERPROFILE/Desktop/symbols_failure.txt" "$($jobfile),#nopdborguid"
    }
  } -StreamingHost $Host
}

Write-Host "Processing..."
Wait-Job -Job $jobs

$adapter = Get-NetAdapter -Name "Ethernet 2"
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
 $adapter | Remove-NetIPAddress -AddressFamily "IPv4" -Confirm:$false
}
If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
 $adapter | Remove-NetRoute -AddressFamily "IPv4" -Confirm:$false
}
$adapter | New-NetIPAddress -AddressFamily "IPv4" -IPAddress "169.254.0.1" -PrefixLength 24
