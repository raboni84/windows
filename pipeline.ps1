#!/usr/bin/env pwsh

$localpath = "win10.iso"
$hashsrc = (Get-FileHash $localpath -Algorithm "SHA256").Hash.ToLower()
Write-Host "$($hashsrc)  $($localpath)"

if (-Not (Test-Path($localpath))) {
	Write-Host "[!] no iso named $($localpath) in working directory"
	break
}

function Packer-BuildAppliance {
	param([Parameter()][string]$SearchFileName, [Parameter()][string]$Filter, [Parameter()][string]$ArgList)
	$runit = $false
	if ([System.String]::IsNullOrEmpty($SearchFileName)) {
		$runit = $true
	} else {
		$files = [System.IO.Directory]::GetFiles($PWD.ProviderPath, $SearchFileName, [System.IO.SearchOption]::AllDirectories)	
		if (-Not([System.String]::IsNullOrEmpty($Filter))) {
			$files = [Linq.Enumerable]::Where($files, [Func[string,bool]]{ param($x) $x -match $Filter })
		}
		$file = [Linq.Enumerable]::FirstOrDefault($files)
		Write-Host $file
		if ([System.String]::IsNullOrEmpty($file)) {
			$runit = $true
		}
	}
	if ($runit) {
		if ($IsWindows -or $env:OS) {
			$process = Start-Process -PassThru -Wait -NoNewWindow -FilePath "packer.exe" -ArgumentList $ArgList
			return $process.ExitCode
		} else {
			$process = Start-Process -PassThru -Wait -FilePath "packer" -ArgumentList $ArgList
			return $process.ExitCode
		}
	}
	return 0
}

if ((Packer-BuildAppliance -SearchFileName "*windows10-bootstrap*.ovf" -ArgList "build -force -only=virtualbox-iso.bootstrap win10.pkr.hcl") -ne 0) {
	break
}
if ((Packer-BuildAppliance -SearchFileName "*windows10-debuggee*.ovf" -ArgList "build -force -only=virtualbox-ovf.debuggee win10.pkr.hcl") -ne 0) {
	break
}
if ((Packer-BuildAppliance -SearchFileName "*windows10-debugger*.ovf" -ArgList "build -force -only=virtualbox-ovf.debugger win10.pkr.hcl") -ne 0) {
	break
}
