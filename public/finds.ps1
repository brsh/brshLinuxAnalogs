function Find-Commands {
	Get-Command $args"*"
}

New-Alias -name which -value Find-Commands -Description "Lists/finds commands with specified text" -Force
