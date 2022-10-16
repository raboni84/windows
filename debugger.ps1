# WinDbg Preview
Write-Host "Trying to find msixbundle url for windbg preview"
$WebResponse = Invoke-WebRequest -Method 'POST' -Uri 'https://store.rg-adguard.net/api/GetFiles' -Body "type=PackageFamilyName&url=Microsoft.WinDbg_8wekyb3d8bbwe&ring=Retail" -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing
$LinkMatch = $WebResponse.Links | where { $_ -like '*_neutral*.msixbundle*' } | Select-String -Pattern '(?<=a href=").+(?=" r)' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value
Write-Host "Downloading from $($LinkMatch)"
Invoke-WebRequest -Uri $LinkMatch -OutFile "$ENV:USERPROFILE/Desktop/windbg.msixbundle" -UseBasicParsing
Write-Host "Installing $ENV:USERPROFILE/Desktop/windbg.msixbundle"
Add-AppxPackage -Path "$ENV:USERPROFILE/Desktop/windbg.msixbundle" -RequiredContentGroupOnly
Write-Host "Done"

# Windows 10 SDK
Start-Process -NoNewWindow -Wait -FilePath "E:/winsdksetup.exe" -WorkingDirectory "E:/" -ArgumentList "/features","+","/quiet","/norestart"

# Rizin
Write-Host "Downloading vcruntime140"
Invoke-WebRequest -Uri "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe" -OutFile "$ENV:USERPROFILE/Desktop/vc_installer.exe" -UseBasicParsing
Write-Host "Start installing vcruntime140"
Start-Process -NoNewWindow -Wait -FilePath "$ENV:USERPROFILE/Desktop/vc_installer.exe" -WorkingDirectory "$ENV:USERPROFILE/Desktop" -ArgumentList "/SILENT","/ALLUSERS","/NORESTART"

Write-Host "Downloading rizin"
Invoke-WebRequest -Uri "https://github.com/rizinorg/rizin/releases/download/v0.4.1/rizin_installer-v0.4.1-x86_64.exe" -OutFile "$ENV:USERPROFILE/Desktop/rizin_installer.exe" -UseBasicParsing
Write-Host "Start installing rizin"
Start-Process -NoNewWindow -Wait -FilePath "$ENV:USERPROFILE/Desktop/rizin_installer.exe" -WorkingDirectory "$ENV:USERPROFILE/Desktop" -ArgumentList "/SILENT","/ALLUSERS","/NORESTART"

# Symbols for Windows 10
New-Item -Path "$ENV:WINDIR" -Name "SYMBOLS" -ItemType "directory" -Force | Out-Null
$files = Get-ChildItem "$ENV:WINDIR" -recurse | Where { $_.extension -in ".exe",".dll",".sys" } | Select-Object -ExpandProperty FullName
$jobs = @()
foreach ($file in $files) {
  $jobs += Start-ThreadJob -ScriptBlock {
    $jobfile = $using:file
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
          Write-Host "$($pdb) => $($locallink)"
          New-Item -Path "$ENV:WINDIR/SYMBOLS" -Name $pdb -ItemType "directory" -Force | Out-Null
          New-Item -Path "$ENV:WINDIR/SYMBOLS/$($pdb)" -Name $guid -ItemType "directory" -Force | Out-Null
          # ask again because of multithreading
          if (-Not(Test-Path -Path $locallink -PathType Leaf)) {
            Invoke-WebRequest -Uri $linktodbg -OutFile $locallink -UseBasicParsing -UserAgent "Microsoft-Symbol-Server/10.0.10240.9"
            Add-Content "$ENV:USERPROFILE/Desktop/symbols_success.txt" "$($_.FullName),$($pdb),$($guid)"
          }
        } else {
          Add-Content "$ENV:USERPROFILE/Desktop/symbols_failure.txt" "$($_.FullName),#$($StatusCode)"
        }
      }
    } else {
      Add-Content "$ENV:USERPROFILE/Desktop/symbols_failure.txt" "$($_.FullName),#nopdborguid"
    }
  } -StreamingHost $Host
}

Write-Host "Processing..."
Wait-Job -Job $jobs

#Get-ChildItem $ENV:WINDIR -recurse | where {$_.extension -in ".exe",".dll",".sys"} | % {
#  Add-Content "$ENV:WINDIR\exe_dll.txt" "$($_.FullName)"
#}
#New-Item -Path "$ENV:WINDIR" -Name "SYMBOLS" -ItemType "directory"
#Start-Process -NoNewWindow -Wait -FilePath "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\symchk.exe" -WorkingDirectory "$ENV:WINDIR\SYMBOLS" -ArgumentList "/v","/om","$ENV:WINDIR\Manifest.txt","/it","$ENV:WINDIR\exe_dll.txt","/s","srv*$ENV:USERPROFILE\Desktop\symbols*http://msdl.microsoft.com/download/symbols"

$adapter = Get-NetAdapter -Name "Ethernet 2"
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
 $adapter | Remove-NetIPAddress -AddressFamily "IPv4" -Confirm:$false
}
If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
 $adapter | Remove-NetRoute -AddressFamily "IPv4" -Confirm:$false
}
$adapter | New-NetIPAddress -AddressFamily "IPv4" -IPAddress "169.254.0.1" -PrefixLength 24
