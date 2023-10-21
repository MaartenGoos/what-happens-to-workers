*------------------------------------------------------------------------
* Automation
* import_firm_age.do
* 6/5/2019
* Wiljan van den Berge
* Purpose: Calculate age of firm by first year of observed job
*-------------------------------------------------------------------------
*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close

cd H:/automation/
log using log/import_firm_age, text replace
*--------------------------------------------------------------------------

*[Note: firm start year is defined as the first year we observe a worker having a contract with the firm. If this is before 1999 (when the worker-level data starts), we can still observe the first contract. However, the start year is censored to the start year of the contract of the worker with the longest contract out of all workers observed at the firm in 1999. Hence, if the firm actually  started in e.g. 1950, but we only observe a worker in 1999 who started in 1964, then we falsely assume that the firm started in 1964.]


* First get all the workers at these firms
forvalues y=1999/2016{
use dta/intermediate/beid.dta, clear // all firms that are in PS/Investments data

duplicates drop 

rename beid beidbaanid
if `y'>=1999 & `y'<=2006 | `y'>=2008 & `y'<=2011{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/140930 BAANKENMERKENBUS `y'V3.dta", ///
			keep(match) keepusing(rinpersoon datumaanvangbaanid) nogen
	}
	if `y'==2007 | `y'==2012{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/140930 BAANKENMERKENBUS `y'V2.dta", ///
			keep(match) keepusing(rinpersoon datumaanvangbaanid) nogen
	}
	if `y'==2013{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/BAANKENMERKENBUS`y'V2.dta", ///
			keep(match) keepusing(rinpersoon datumaanvangbaanid) nogen
	}
	if `y'==2014{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/BAANKENMERKEN`y'BUSV2.dta", ///
			keep(match) keepusing(rinpersoon datumaanvangbaanid) nogen
	}
	if `y'==2015{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/BAANKENMERKENBUS`y'V2.dta", ///
			keep(match) keepusing(rinpersoon datumaanvangbaanid) nogen
	}
	if `y'==2016{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/geconverteerde data/BAANKENMERKENBUS`y'V1.dta", ///
			keep(match) keepusing(rinpersoon datumaanvangbaanid) nogen
	}
	gen int date_start = date(datumaanvangbaanid,"YMD")
	drop datumaanvangbaanid
	format date_start %td

	gen int year=`y'
	save dta\intermediate\beid_datestart`y'.dta, replace
}

use dta\intermediate\beid_datestart1999.dta, clear
forvalues y=2000/2016{
	append using dta\intermediate\beid_datestart`y'.dta
}
rename beidbaanid beid
drop if missing(date_start)
drop if missing(beid)
sort beid date_start
by beid: keep if _n==1
gen firm_startyr = year(date_start)
keep beid firm_startyr
compress
save dta\intermediate\beid_firmstart.dta, replace


forval y=1999/2016{
	rm dta\intermediate\beid_datestart`y'.dta
}


