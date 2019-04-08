Function Remove-InvalidFileNameChars {
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[String] $Text
	)
	#Remove invalid filesystem characters and ones we just do not like in filenames
	$invalidChars = ([IO.Path]::GetInvalidFileNameChars() + ',' + ';') -join ''
	$re = "[{0}]" -f [RegEx]::Escape($invalidChars)
	$Text = $Text -replace $re
	$Text
}
