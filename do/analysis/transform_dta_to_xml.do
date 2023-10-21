// Transform results files to XML files and remove original files

* Make sure that these are the only .dta files in the folder, as they will be removed after converting to XML

* Set export folder
cd H:\automation\export

local files : dir "H:\automation\export" files "*.dta"

foreach file in `files' {
	use `file', clear

	xmlsave `file'.xml, replace doctype(excel)
}

* Remove .dta files 
foreach file in `files' {
	rm `file'
}

