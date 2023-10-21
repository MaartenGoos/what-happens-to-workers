*------------------------------------------------------------------------
* Automation
* sbi9308_crosswalk_maxsector.do
* 2/7/2018
* Wiljan van den Berge
* Purpose: For the years 2006-2009 we observe both SBI1993 and SBI2008 for each firm. Use these years to determine the most predominant SBI2008 code for each SBI1993
*-------------------------------------------------------------------------


*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close

cd H:/automation/
log using log/import_crosswalk_sbi9308_maxsector, text replace
*--------------------------------------------------------------------------

forval y=2006/2009{
	use SBI1993V`y' SBI2008V`y' using "G:/Arbeid/BETAB/`y'/geconverteerde data/140707 BETAB `y'V1.dta", clear

	// rename, so we assume sector classifications remain the same over these 4 years
	rename SBI1993V`y' sbi1993_5dig
	rename SBI2008V`y' sbi2008_5dig
	
	// Count number of firms in each combination
	bys sbi1993_5dig sbi2008_5dig: egen count=count(sbi1993)
	
	// Keep all unique combinations
	duplicates drop
	
	save dta/intermediate/temp_sbi9308_`y'.dta, replace
}

use dta/intermediate/temp_sbi9308_2006.dta, clear
forval y=2007/2009{
	append using dta/intermediate/temp_sbi9308_`y'.dta
}

collapse (sum) count, by(sbi1993_5dig sbi2008_5dig)
// save the max code per sbi1993
gsort sbi1993 -count
by sbi1993: keep if _n==1
drop count

// Rename sbi2008_5dig to show that it was translated from sbi1993_5dig
rename sbi2008_5dig sbi1993_to_2008_5dig

// Save dataset
compress
save dta/intermediate/sbi1993_maxsbi2008.dta, replace

// Remove temp datasets
forval y=2006/2009{
	rm dta/intermediate/temp_sbi9308_`y'.dta
}

