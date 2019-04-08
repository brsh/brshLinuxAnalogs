function Get-Indent {
	param (
		[int] $Level,
		[string] $Char = '  '
	)
	($Char * $Level)
}

function Write-Status {
	param (
		[Parameter(Position = 0)]
		[Alias('Text', 'Subject')]
		[string[]] $Message,
		[Parameter(Position = 1)]
		[string[]] $Type,
		[Parameter(Position = 2)]
		[int] $Level = 0,
		[Parameter(Position = 3)]
		[System.Management.Automation.ErrorRecord] $e
	)

	[System.ConsoleColor] $ColorInfo = [ConsoleColor]::White
	[System.ConsoleColor] $ColorGood = [ConsoleColor]::Green
	[System.ConsoleColor] $ColorError = [ConsoleColor]::Red
	[System.ConsoleColor] $ColorWarning = [ConsoleColor]::Yellow
	[System.ConsoleColor] $ColorDebug = [ConsoleColor]::Cyan

	[System.ConsoleColor] $FGColor = $ColorInfo
	[System.ConsoleColor] $DefaultBGColor = $Host.UI.RawUI.BackgroundColor
	[System.ConsoleColor] $BGColor = $DefaultBGColor

	[System.ConsoleColor] $ColorHighlight = [ConsoleColor]::DarkGray

	if ($BGColor -eq $ColorHighlight) {
		[System.ConsoleColor] $ColorHighlight = [ConsoleColor]::DarkMagenta
	}

	[string] $Space = Get-Indent -Level $Level

	if ($Message) {
		foreach ($txt in $Message) {
			$BGColor = $DefaultBGColor
			[int] $index = [array]::indexof($Message, $txt)
			Switch -regex ($Type[$index]) {
				'^G' {
					$FGColor = $ColorGood
					break
				}
				'^E' {
					$FGColor = $ColorError
					break
				}
				'^W' {
					$FGColor = $ColorWarning
					break
				}
				'^D' {
					$FGColor = $ColorDebug
					break
				}
				DEFAULT {
					$FGColor = $ColorInfo
					break
				}
			}
			if ($index -gt 0) {
				$space = ' '
			}
			Write-Host $Space  -ForegroundColor $FGColor -BackgroundColor $BGColor -NoNewline
			if ($Type[$index] -match 'High$') { $BGColor = $ColorHighlight }
			Write-Host $txt -ForegroundColor $FGColor -BackgroundColor $BGColor -NoNewline
		}
		write-host ''
	}

	if ($e) {
		$Level += 1
		$space = Get-Indent -Level $Level

		[string[]] $wrapped = Set-WordWrap -Message $($e.InvocationInfo.PositionMessage -split "`n") -Level $Level
		$wrapped | ForEach-Object {
			if ($_ -notmatch '^\+ \~') {
				Write-Status -Message $_ -Type 'Warning' -Level $Level
			}
		}

		$wrapped = Set-WordWrap -Message $e.Exception.Message -Level $Level
		$wrapped | ForEach-Object {
			Write-Status -Message $_ -Type 'Error' -Level $Level
		}
	}
}

<#
.SYNOPSIS
wraps a string or an array of strings at the console width without breaking within a word
.PARAMETER chunk
a string or an array of strings
.EXAMPLE
word-wrap -chunk $string
.EXAMPLE
$string | word-wrap
#>
function Set-WordWrap {
	[CmdletBinding()]
	Param(
		[string[]] $Message,
		[int] $Level = 0
	)

	BEGIN {
		[string] $Space = Get-Indent -Level $Level
		$Lines = @()
	}

	PROCESS {
		foreach ($line in $Message) {
			$words = ''
			$count = 0
			$line -split '\s+' | ForEach-Object {
				$count += $_.Length + 1
				if ($count -gt ($Host.UI.RawUI.WindowSize.Width - $Space.Length - 6)) {
					$Lines += , $words.trim()
					$words = ''
					$count = $_.Length + 1
				}
				$words = "$words$_ "
			}
			$Lines += , $words.trim()
		}
		# $Lines
	}

	END {
		$Lines
	}
}

