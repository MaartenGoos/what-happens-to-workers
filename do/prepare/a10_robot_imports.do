*------------------------------------------------------------------------
* Automation
* robot_imports.do
* 15/4/2020
* Wiljan van den Berge & Anna Salomons
* Purpose: Import data on robot imports
* Output: dta/intermediate/robotimports_1016_selected.dta
*-------------------------------------------------------------------------

*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close
sysdir set PLUS M:\Stata\Ado\Plus 

cd H:/automation/
log using log/robot_imports, text replace
*--------------------------------------------------------------------------


forval y=2010/2016{
	if `y'==2010{
		use "G:/Internationalehandel/IHG/geconverteerde bestanden/130620 IHG per BE_ID `y'V1.dta", clear
	}
	if `y'==2011{
		use "G:/Internationalehandel/IHG/geconverteerde bestanden/130620 IHG per BE_ID `y'V1.dta", clear
	}
	if `y'==2012{
		use "G:/Internationalehandel/IHG/geconverteerde bestanden/131018 IHG per BE_ID `y'V1.dta", clear
	}
	if `y'==2013{
		use "G:/Internationalehandel/IHG/geconverteerde bestanden/141117 IH per BE `y'V1.dta", clear
	}
	if `y'>=2014 & `y'<=2015 | `y'==2017{
		use "G:/Internationalehandel/IHG/geconverteerde bestanden/IHG_per_BE_ID`y'V1.dta", clear
	}
	if `y'==2016{
		use "G:/Internationalehandel/IHG/geconverteerde bestanden/IHG_per_BE_ID`y'V2.dta", clear
	}	
	if `y'==2018{
		use "G:/Internationalehandel/IHG/geconverteerde bestanden/IHG_per_BE_ID`y'V1.dta", clear
	}
	if `y'==2019{
	    use "G:/Internationalehandel/IHG/2019/geconverteerde data/IHG_per_BE_ID`y'V1.dta", clear
	}
	rename *, lower

	// Keep only robots
	destring gsrt, gen(cn8)

	tostring be_id, replace
	rename invoer import
	rename uitvoer export
	rename wederuitvoer reexport
	rename land_hb country
	rename be_id beid

	gen byte impute=respons=="I" | respons=="B"
	drop respons

	destring country, replace
	do do/prepare/a10_01_label_country_tradedata.do
	label values country cntr
	gen year=`y'
	compress
	save dta/intermediate/robotimports_`y'.dta, replace
}

use dta/intermediate/robotimports_2010.dta, clear
forval y=2011/2016{
	append using dta/intermediate/robotimports_`y'.dta
}
drop if impute==1
drop if country>=900 // country unknown
drop if missing(beid)
drop if beid=="."

// Apply Anna's code to create product codes for imports based on Acemoglu-Restrepo
quietly do do/prepare/a10_02_product-codes-forCBSserver.do

// Add CPI to deflate
merge m:1 year using H:/cpi9619.dta, keep(match master) nogen

// drop other and tl, not included in categories
drop if cat=="other" | cat=="tl"

// create real values
foreach var in import export reexport{
	replace `var'=(`var'/cpi)*100
}

drop impute cpi hicp

label var import "Value of imports (real euros, 2015=100)"
label var export "Value of exports (real euros, 2015=100)"
label var reexport "Value of reexports (real euros, 2015=100)"
label var cn8 "Numberical goods code"
label var gsrt "String goods code"
label var country "Country of import/export"
label var year "Calendar year"
label var cat "Classification of intermediate goods"

save dta/intermediate/robotimports_1016_selected.dta, replace


* erase temporary files
forval y=2010/2016{
	erase dta/intermediate/robotimports_`y'.dta
}

cap log close

