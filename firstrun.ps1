# winget
Write-Host "Trying to find appxbundle url for winget"
$WebResponse = Invoke-WebRequest -Method 'POST' -Uri 'https://store.rg-adguard.net/api/GetFiles' -Body "type=PackageFamilyName&url=Microsoft.DesktopAppInstaller_8wekyb3d8bbwe&ring=Retail" -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:99.0) Gecko/20100101 Firefox/99.0"
$LinkMatch = $WebResponse.Links | where { $_ -like '*_neutral*.appxbundle*' } | Select-String -Pattern '(?<=a href=").+(?=" r)' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value -First 1
Write-Host "Downloading from $($LinkMatch)"
Invoke-WebRequest -Uri $LinkMatch -OutFile "$ENV:USERPROFILE/Desktop/winget.appxbundle" -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:99.0) Gecko/20100101 Firefox/99.0"
Write-Host "Installing $ENV:USERPROFILE/Desktop/winget.appxbundle"
Start-Process -NoNewWindow -Wait -FilePath "$ENV:WINDIR/System32/dism.exe" -WorkingDirectory "$ENV:WINDIR/System32" -ArgumentList "/Online","/Add-ProvisionedAppxPackage","/PackagePath:`"$ENV:USERPROFILE/Desktop/winget.appxbundle`"","/SkipLicense"
