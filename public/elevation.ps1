function Start-ElevatedSession {
	<#
	.SYNOPSIS
	Starts a new PowerShell instance as Admin

	.DESCRIPTION
	This will open a new instance of PowerShell as Admin (complete with requisite UAC prompt if
	the system is config'd to prompt UAC). This is similar to the Linux 'su' command - except it
	will open a new window or a new tab (if using ConEmu) - rather than just an elevated prompt
	within the current shell window.

	If you specify an exe or a ps1 script file, the new shell will try to run it on start-up.
	Note that it will still spawn a separate PowerShell window/tab if you specify an exe....

	This is automatically aliased as 'su' for convenience-sake.

	.PARAMETER File
	A script or program to run as Admin

	.PARAMETER NoProfile
	Does not load the PowerShell profile files

	.EXAMPLE
	Start-ElevatedSession

	Starts a new PowerShell window (or tab) as Admin
	#>

	param (
		[string] $File = '',
		[switch] $NoProfile
	)
	# Open a new elevated powershell window (or tab if using ConEMU)
	if ( $Global:IsAdmin) {
		Write-Status -Message 'Session is already elevated' -Type 'Warning' -Level 0
	} else {
		Write-Host $File
		[string] $PowerShellExe = 'powershell.exe'
		if ($PSVersionTable.PSVersion.Major -ge 6) {
			$PowerShellExe = 'pwsh.exe'
		}
		$CurPath = $PWD
		if ($NoProfile) {
			$CurPath = $PWD.ProviderPath
		}
		[string] $CommandToRun = "& {Set-Location $CurPath"
		if ($File.Length -gt 0) {
			$CommandToRun = "${CommandToRun}; Write-Host -ForegroundColor Yellow `"Running: $File`"; Write-Host `" `"; $file"
		}
		$CommandToRun = "${CommandToRun}}"
		if ($env:ConEmuPID) {
			if ($NoProfile) {
				ConEmuC.exe /c $PowerShellExe -NoProfile -NoExit -Command "$CommandToRun" -new_console:a
			} else {
				ConEmuC.exe /c $PowerShellExe -NoExit -Command "$CommandToRun" -new_console:a
			}
		} elseif ($host.Name -match 'ISE') {
			Start-Process PowerShell_ISE.exe -Verb RunAs
		} else {
			if ($NoProfile) {
				$ArgumentList = "-NoExit -NoProfile -Command $CommandToRun"
			} else {
				$ArgumentList = "-NoExit -Command $CommandToRun"
			}
			Start-Process $PowerShellExe -Verb RunAs -ArgumentList $($ArgumentList)
		}
	}
}

Set-Alias -Name su -Value Start-ElevatedSession

function Start-ElevatedProcess {
	<#
	.SYNOPSIS
	Runs a program as admin

	.DESCRIPTION
	Similar to the Linux `sudo` command, this will run a program as Admin - complete with UAC prompt (if
	UAC is config'd to prompt).

	If you specify a .ps1 script, this will spawn a new PowerShell windows (or tab in ConEmu) to run
	that script as Admin (using Start-ElevatedSession, aka su). Otherwise, it will spawn only the app.

	This is automatically aliased as 'sudo' for convenience-sake.

	.PARAMETER File
	A script or program to run as admin

	.EXAMPLE
	Start-ElevatedProcess regedit

	Runs regedit as admin
	#>

	$File, [string] $Arguments = $args
	if ($File -match '.ps1$') {
		[System.IO.FileInfo] $PS1File = Get-Item $file
		Start-ElevatedSession -File $PS1File.FullName
	} else {
		$psi = New-Object System.Diagnostics.ProcessStartInfo $File
		$psi.Arguments = $Arguments
		$psi.Verb = 'RunAs'

		$psi.WorkingDirectory = Get-Location
		[System.Diagnostics.Process]::Start($psi)
	}
}

Set-Alias -Name sudo -Value Start-ElevatedProcess
