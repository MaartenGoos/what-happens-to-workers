*------------------------------------------------------------------------
* Automation
* sbi9308_crosswalk.do
* 2/7/2018
* 23/4/2020 (v2): Added additional sbi2008 codes for those still missing 5-digit codes using the most prevalent sbi2008 for each sbi1993	
* Wiljan van den Berge
* Purpose: create a crosswalk for the two sector codes: SBI1993 and SBI2008
*-------------------------------------------------------------------------


*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16
set more off
clear all
capture log close

cd H:/automation/
log using log/import_crosswalk_sbi9308, text replace
*--------------------------------------------------------------------------

/* 5-digit SBI1993 to 5-digit SBI2008 */	
use import\sbi9308.dta, clear

rename sbi93 sbi1993
rename sbi08 sbi2008

replace sbi1993 = sbi1993[_n-1] if missing(sbi1993)

*Replace empty names with empty strings
foreach var of varlist sbi1993 sbi2008{
	replace `var' = "" if `var' == "leeg1"
	replace `var' = "" if `var' == "leeg"
	replace `var' = "" if `var' == "divers"
	replace `var' = "" if `var' == "Leeg1"
	drop if missing(`var')
}

*Add zero if length is too short
replace sbi1993 = sbi1993+"0" if length(sbi1993)==4

*Same for SBI2008
replace sbi2008 = "" if sbi2008=="leeg"
replace sbi2008 = sbi2008+"0" if length(sbi2008)==4

*Generate 5-digit SBI2008
gen sbi2008_5dig = substr(sbi2008,1,5)
drop sbi2008
duplicates drop

bys sbi1993: gen n = _n
sum n

*Reshape
reshape wide sbi2008_5dig, i(sbi1993) j(n)

// Merge matrix with most prevalent sbi2008 code per sbi1993
rename sbi1993 sbi1993_5dig
merge 1:1 sbi1993_5dig using dta/intermediate/sbi1993_maxsbi2008.dta, keep(match master)
rename sbi1993_to_2008_5dig sbi2008_max
rename sbi1993_5dig sbi1993
drop _merge

// Create 5-digit sbi2008 
gen sbi2008=sbi2008_5dig1 if missing(sbi2008_5dig2)
replace sbi2008=sbi2008_max if missing(sbi2008)

// 
keep sbi1993 sbi2008

gen sbi2008_2dig = substr(sbi2008,1,2)
merge m:1 sbi2008_2dig using import/sbi2008_letter_2dig, keep(match master) nogen keepusing(sbi2008_letter)

save dta/intermediate/sbi9308_crosswalk.dta, replace

