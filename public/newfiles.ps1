function New-File {
	<#
	.SYNOPSIS
	Create a file and/or mod the access and modify times

	.DESCRIPTION
	A variation of the *nux 'touch' command. Creates a new, empty file if it doesn't exist
	or modifies the LastWrite and LastAccess timestamps of the file. You can pipe in a full
	directory list via Get-ChildItem (dir/ls) or use a string array for multiples.

	Naturally, non-filesystem-valid characters will be stripped from the name.

	DateTime will default to the current time if no date is specified.

	File arguments that do not exist are created empty, unless the -NoCreate (-C) switch
	is supplied.

	.PARAMETER FileName
	String Array of the name(s) of to create/modify

	.PARAMETER DateTime
	DateTime to set LastAccess and LastModified timestamps

	.PARAMETER Encoding
	Encoding of the file created: 'ASCII', 'BigEndianUnicode', 'BigEndianUTF32', 'Byte', 'OEM', 'String', 'Unicode', 'Unknown', 'UTF7', 'UTF8', 'UTF32'
	Default is ASCII

	.PARAMETER DateAccessed
	Only change the access time - aka -A

	.PARAMETER DateModified
	Only change the modification time - aka -M

	.PARAMETER NoCreate
	Do not create any files

	.PARAMETER TimeStampName
	Inserts a timestamp into the first part of the filename

	.EXAMPLE
	touch 'test.txt'

	If it does not exist, this will create an empty file with current dates. If it does exist, will set the LastAccess and LastModified timestamps to current date

	.EXAMPLE
	"hello4.txt", "hello5.txt", "hello6.txt" | touch  -datetime $(get-date 'January 1')

	Creates and/or changes the dates on the files

	.EXAMPLE
	"hello4.txt", "hello5.txt", "hello6.txt" | touch  -datetime $(get-date 'January 1') -NoCreate

	Only changes the dates on the files, if they exist. Will not create a new file

	.EXAMPLE
	ls | touch  -datetime $(get-date 'January 2') -LastWriteTimeOnly

	Gets the files in current directory

	.EXAMPLE
	touch .txt -TimeStampName

	Creates 20190408-131406-0800.txt (assuming that's the current datetime)

	.EXAMPLE
	touch Hello.txt -TimeStampName

	Creates Hello_20190408-131406-0800.txt (assuming that's the current datetime)

	.NOTES
	General notes
	#>

	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
		[string[]] $FileName,
		[Parameter(Mandatory = $false, ParameterSetName = 'Default')]
		[Parameter(Mandatory = $false, ParameterSetName = 'LastWriteTimeOnly')]
		[Parameter(Mandatory = $false, ParameterSetName = 'LastAccessTimeOnly')]
		[Alias('D', 'Date', 'Time')]
		[datetime] $DateTime,
		[ValidateSet('ASCII', 'BigEndianUnicode', 'BigEndianUTF32', 'Byte', 'OEM', 'String', 'Unicode', 'Unknown', 'UTF7', 'UTF8', 'UTF32')]
		[string] $Encoding = 'ASCII',
		[Parameter(Mandatory = $false, ParameterSetName = 'LastAccessTimeOnly')]
		[Alias('A', 'LastAccessTimeOnly', 'AccessTime', 'Access')]
		[switch] $DateAccessed = $false,
		[Parameter(Mandatory = $false, ParameterSetName = 'LastWriteTimeOnly')]
		[Alias('M', 'LastWriteTimeOnly', 'ModifiedTime', 'Modified')]
		[switch] $DateModified = $false,
		[Alias('C')]
		[switch] $NoCreate = $false,
		[switch] $TimeStampName = $false
	)

	BEGIN {
		#[System.IO.FileInfo[]]
		$all = @()

		if (($PSCmdlet.ParameterSetName -ne 'LastWriteTimeOnly') -and ($PSCmdlet.ParameterSetName -ne 'LastAccessTimeOnly')) {
			$DateModified = $true
			$DateAccessed = $true
		}

		if ($TimeStampName) {
			if ($DateTime) {
				$x = $DateTime
			} else {
				$x = Get-Date
			}
		}
	}

	PROCESS {
		foreach ($File in $FileName) {
			$File = Remove-InvalidFileNameChars -Text "$File"
			if ($TimeStampName) {
				[string[]] $Temp = $File.Split('.')
				[string] $Prefix = $Temp[0]
				[string] $Type = ($Temp[1..$Temp.Length]) -Join '.'
				[string] $format = "{0}_{1}{2:d2}{3:d2}-{4:d2}{5:d2}{6:d2}-{7:d4}.{8}"
				if ($Prefix.Length -eq 0) {
					$format = "{0}{1}{2:d2}{3:d2}-{4:d2}{5:d2}{6:d2}-{7:d4}.{8}"
				}
				$File = [string]::format($format,
					$Prefix,
					$x.year, $x.month, $x.day, $x.hour, $x.minute, $x.second, $x.millisecond,
					$Type)
			}
			if (-not (Test-Path $File)) {
				if (-not $NoCreate) {
					Write-Verbose "Creating $File"
					try {

						$null | Out-File $File -Encoding $Encoding
					} catch {
						Write-Status -Message "Error creating $File" -Type 'Error' -E $_ -Level 0
					}
				}
			} else {
				if ($null -eq $DateTime) { $DateTime = Get-Date }
			}
			if ($DateTime) {
				if ($DateAccessed) {
					Write-Verbose "Updating LastAccessTime of $File to $DateTime"
					try {
						if (Test-Path $File) {
							(Get-Item $file -ErrorAction Stop).LastAccessTime = $DateTime
						} else {
							Write-Verbose "$File not found"
						}
					} catch {
						Write-Status -Message "Error updating LastAccessTime of $File" -Type 'Error' -E $_ -Level 0
					}
				}
				if ($DateModified) {
					Write-Verbose "Updating LastWriteTime of $File to $DateTime"
					try {
						if (Test-Path $File) {
							(Get-Item $file -ErrorAction Stop).LastWriteTime = $DateTime
						} else {
							Write-Verbose "$File not found"
						}
					} catch {
						Write-Status -Message "Error updating LastWriteTime of $File" -Type 'Error' -E $_ -Level 0
					}
				}
			}

			if (Test-Path $File) {
				try {
					$quick = Get-Item $file -ErrorAction Stop
					$hash = [ordered] @{
						FullName       = $quick.FullName
						LastWriteTime  = $quick.LastWriteTime
						LastAccessTime = $quick.LastAccessTime
					}
					if ($quick.GetType().Name -eq 'DirectoryInfo') {
						$hash.Type = 'Dir'
					} else {
						$hash.Type = 'File'
					}
					$all += New-Object -Property $hash -TypeName psobject
				} catch {
					Write-Status -Message "Error adding $file to Output Var" -Type 'Error' -E $_ -Level 0
				}
			}
		}
	}

	END {
		$all | Select-Object FullName, LastAccessTime, LastWriteTime, Type
	}
}

New-Alias -name touch -value New-File -Description "Create an empty file" -Force
