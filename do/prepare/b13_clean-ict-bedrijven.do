*------------------------------------------------------------------------
* Automation
* 2021/03/31, updated 2021/08/13 
* Anna Salomons
* Purpose: Import ICT firm survey data, merge with firm-level automation data
* Output:  dta/intermediate/firm_ict_survey
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
log using log/clean-ict-bedrijven, text replace
*--------------------------------------------------------------------------

*-------------------------------------------------------------------------
* Define paths
*-------------------------------------------------------------------------
global path_in "G:\Bedrijven\ICTBEDRIJVEN\"


*-------------------------------------------------------------------------
* Append data from all years (note, no 2012 data)
*-------------------------------------------------------------------------

use "$path_in\1995-2008\geconverteerde data\100913 ICTbedrijven1995-2008V1", clear
	rename jaar year
	gen version = "V1"
	renvars _all, lower
save dta/temp/tempict, replace
	
use "$path_in\2006\geconverteerde data\100708 ICTbedrijven2006V2", clear
	gen year = 2006
	gen version = "V2"
	renvars _all, lower
append using dta/temp/tempict
	duplicates report beid if year==2006	
save dta/temp/tempict, replace
	
	
use "$path_in\2007\geconverteerde data\100708 ICTbedrijven2007V4", clear
	gen year = 2007 
	gen version = "V4" 
	*tostring sbsgk, gen(tempsbsgk)
	*drop sbsgk
	*rename tempsbsgk sbsgk
	renvars _all, lower
append using dta/temp/tempict
save dta/temp/tempict, replace	
	
use "$path_in\2008\geconverteerde data\100709 ICTbedrijven2008V1", clear
	gen year = 2008 
	gen version = "V1b" 
	renvars _all, lower
	destring sbsgk, replace
append using dta/temp/tempict
save dta/temp/tempict, replace		

use "$path_in\2009\geconverteerde data\101207 ICTbedrijven 2009V1", clear
	gen year = 2009
	gen version = "V1" 
	renvars _all, lower
	destring sbsgk, replace
append using dta/temp/tempict
save dta/temp/tempict, replace	
	
use "$path_in\2010\geconverteerde data\111227 ICTbedrijven 2010V1", clear
	gen year = 2010 
	gen version = "V1" 
	renvars _all, lower
	destring sbsgk, replace
append using dta/temp/tempict
save dta/temp/tempict, replace			

use "$path_in\2011\geconverteerde data\130211 ICTbedrijven 2011V1", clear
	gen year = 2011 
	gen version = "V1" 
	renvars _all, lower
append using dta/temp/tempict
save dta/temp/tempict, replace	
	
use "$path_in\2013\geconverteerde data\140305 ICTbedrijven 2013V1", clear
	gen year = 2013 
	gen version = "V1" 
	renvars _all, lower
	destring gk, replace
append using dta/temp/tempict
save dta/temp/tempict, replace			

use "$path_in\2014\geconverteerde data\ICTbedrijven 2014V1", clear
	gen year = 2014 
	gen version = "V1" 
	renvars _all, lower
	destring gk, replace
append using dta/temp/tempict
save dta/temp/tempict, replace	
	
use "$path_in\2015\geconverteerde data\ICTbedrijven 2015V1", clear
	gen year = 2015 
	gen version = "V1" 
	renvars _all, lower
	destring be_id, replace
	rename be_id beid
append using dta/temp/tempict
save dta/temp/tempict, replace	
		
use "$path_in\2016\geconverteerde data\ICTbedrijven 2016V1", clear
	gen year = 2016 
	gen version = "V1" 
	renvars _all, lower
append using dta/temp/tempict

	* Keeping most recent version for 2006-2008
	duplicates tag beid year, gen(dup)
	table year, c(mean dup) // duplicates for 2006-2008, as expected
	drop if beid==. // 1 observation
	drop if dup==1 & version=="V1"
	drop dup
	duplicates tag beid year, gen(dup)
	assert dup==0 // no more duplicates
	drop dup
	
	table year, c(count beid)
	order _all, alpha
	order beid year

	*Add CPI to deflate
merge m:1 year using H:/cpi9619.dta, keep(match master) nogen
	replace cpi=68.94 if year==1995 	// no 1995 cpi data, set to 1996 value 
save dta/temp/tempict, replace	
	
	tab year
	compress
	
	save dta/temp/tempict1.dta, replace	 
	
	table year, c(count ict_pers count ict_soft count aant_pc)
	table year, c(count gebrcomp count automat)
	
	* Collapse to beid level, take most recent non-imputed values
		
		* Remove imputed values
		order f*
		foreach var of varlist aanbesteed_info-xdsl {
			cap replace `var' = . if f`var' == 1
			cap replace `var' = . if f`var' == 1

		}
	order _all, alpha
	
	drop gk_sbs pgp_str sbi* version
	order beid year
	gsort beid year
	gcollapse (lastnm) aanbesteed_info-xdsl year, by(beid)
save dta/temp/tempict2, replace	
	
*-------------------------------------------------------------------------
* Merge beid with automation data to check for overlap (not using beid-year since many variables are only measured for a few years)
*-------------------------------------------------------------------------
		*Collapse automation data to firm-level, save temporary dataset
		use dta/intermediate/firmsample_autom, clear
		rename sbi2008_1dig sbi08_1dig
		gcollapse (mean) automation_real totalcosts_real automation_tocosts nr_workers (max) spike_firm spike_firm_large spike_firm_first, by(beid sbi08_1dig)
		drop automation_tocosts 
		gen automation_tocosts = automation_real / totalcosts_real 
		compress
		destring beid, replace
		
		merge 1:1 beid using dta/temp/tempict2
		drop if _merge==2 // drop ICT data not merged to automation sample
		
		save dta/intermediate/firm_ict_survey, replace


	
cap erase dta/temp/tempict.dta	
cap erase dta/temp/tempict1.dta	
cap erase dta/temp/tempict2.dta		

cap log close

