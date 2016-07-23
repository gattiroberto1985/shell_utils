#Powershell

Mini raccolta di utilità per la powershell.

##Snippet utili

Copia con esclusione:

	REM VERSIONE 1
	copy-item -recurse ./SRC/* -destination ./SRC3/ -exclude @("**/.dm/**", "**/.metadata/**")

	REM VERSIONE 2
    $source = '.\SRC'
    $dest = '.\SRC2'
    $exclude = @('*.dm', '*.metadata')
    Get-ChildItem $source -Recurse -Exclude $exclude | 
        Copy-Item -Destination {Join-Path $dest $_.FullName.Substring($source.length)}

	REM |  
        where-object {$_.lastwritetime -gt "8/24/2011 10:26 pm"} 
	