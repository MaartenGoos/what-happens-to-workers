*------------------------------------------------------------------------
* Automation
* worker_benefits.do
* 2/10/2018
* 3/3/2020:	Added 2017 and 2018
* 30/4/2021: Added 2019; take person IDs directly from jobdata; save temp files in temp folder
* Wiljan van den Berge
* Purpose: merge workers from baseline_worker_sample.dta to benefit data
*-------------------------------------------------------------------------


*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close
sysdir set PLUS "M:\Stata\Ado\Plus"
sysdir set PERSONAL "H:\Stata\"

cd H:/automation/
log using log/worker_benefits.do, text replace
*--------------------------------------------------------------------------

use rinpersoons rinpersoon using dta/intermediate/jobdata9916_polis.dta, clear
bys rinpersoons rinpersoon: keep if _n==1
save dta/temp/rinpersoon.dta, replace

*Unemployment benefits
forvalues y=1999/2016{
	use dta/temp/rinpersoon.dta, clear 

	if inrange(`y',1999,2006){
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/WWJAARBEDRAGTAB/`y'/geconverteerde data/120423 WWJAARBEDRAGTAB `y'V2.dta", keep(match)
	}
	if inrange(`y',2007,2009){
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/WWJAARBEDRAGTAB/`y'/geconverteerde data/111114 WWJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2010{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/WWJAARBEDRAGTAB/`y'/geconverteerde data/120625 WWJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2011{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/WWJAARBEDRAGTAB/`y'/geconverteerde data/130710 WWJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2012{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/WWJAARBEDRAGTAB/`y'/geconverteerde data/140422 WWJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if inrange(`y',2013,2015){
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/WWJAARBEDRAGTAB/`y'/geconverteerde data/WWJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2016{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/WWJAARBEDRAGTAB/`y'/geconverteerde data/WWJAARBEDRAG`y'TABV1.dta", keep(match)
	}
		gen unemploymentbenefits = fiscbedragpersww
	gen int year=`y'
	keep year unemploymentbenefits rinpersoon rinpersoons
	compress
	save dta/temp/worker_ub`y'.dta, replace
}

clear all
forvalues y=2000/2016{
	append using dta/temp/worker_ub`y'.dta
}
save dta/temp/worker_ub.dta, replace

forvalues y=1999/2016{
	rm dta/temp/worker_ub`y'.dta
}


// Welfare
forvalues y=1999/2016{
	use dta/temp/rinpersoon.dta, clear // From prepare_worker_datav4.do

	if inrange(`y',1999,2006){
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/BIJSTANDJAARBEDRAGTAB/`y'/geconverteerde data/120508 BIJSTANDJAARBEDRAGTAB `y'V2.dta", keep(match)
	}
	if inrange(`y',2007,2009){
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/BIJSTANDJAARBEDRAGTAB/`y'/geconverteerde data/111110 BIJSTANDJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2010{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/BIJSTANDJAARBEDRAGTAB/`y'/geconverteerde data/120625 BIJSTANDJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2011{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/BIJSTANDJAARBEDRAGTAB/`y'/geconverteerde data/130703 BIJSTANDJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2012{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/BIJSTANDJAARBEDRAGTAB/`y'/geconverteerde data/140404 BIJSTANDJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if inrange(`y',2013,2015){
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/BIJSTANDJAARBEDRAGTAB/`y'/geconverteerde data/BIJSTANDJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2016{
		rename rinpersoon RINPERSOON
		rename rinpersoons RINPERSOONS
		merge 1:1 RINPERSOON RINPERSOONS using "G:/Socialezekerheid/BIJSTANDJAARBEDRAGTAB/geconverteerde data/BIJSTANDJAARBEDRAG2016TABV1.dta", keep(match)
	}

	rename *, lower
	gen year=`y'
	gen welfare = fiscbedragpersbijstand
	
	keep year welfare rinpersoon rinpersoons
	compress
	save dta/temp/worker_welfare`y'.dta, replace
}


clear all
forvalues y=2000/2016{
	append using dta/temp/worker_welfare`y'.dta
}
save dta/temp/worker_welfare.dta, replace

forvalues y=1999/2016{
	rm dta/temp/worker_welfare`y'.dta
}



// Sickness benefits
forvalues y=1999/2016{
	use dta/temp/rinpersoon.dta, clear // From prepare_worker_datav4.do

	if inrange(`y',1999,2006){
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/AOTOTJAARBEDRAGTAB/`y'/geconverteerde data/120419 AOTOTJAARBEDRAGTAB `y'V2.dta", keep(match)
	}
	if inrange(`y',2007,2009){
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/AOTOTJAARBEDRAGTAB/`y'/geconverteerde data/111111 AOTOTJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2010{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/AOTOTJAARBEDRAGTAB/`y'/geconverteerde data/120620 AOTOTJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2011{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/AOTOTJAARBEDRAGTAB/`y'/geconverteerde data/130704 AOTOTJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2012{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/AOTOTJAARBEDRAGTAB/`y'/geconverteerde data/140424 AOTOTJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if inrange(`y',2013,2015){
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/AOTOTJAARBEDRAGTAB/`y'/geconverteerde data/AOTOTJAARBEDRAGTAB `y'V1.dta", keep(match)
	}
	if `y'==2016{
		merge 1:1 rinpersoon rinpersoons using "G:/Socialezekerheid/AOTOTJAARBEDRAGTAB/`y'/geconverteerde data/AOTOTJAARBEDRAG`y'TABV1.dta", keep(match)
	}

	rename *, lower
	gen year=`y'

	gen sickness = fiscbedragpersao
	
	keep year sickness rinpersoon rinpersoons
	compress

	save dta/temp/worker_sickness`y'.dta, replace
}

clear all
forvalues y=2000/2016{
	append using dta/temp/worker_sickness`y'.dta
}
save dta/temp/worker_sickness.dta, replace

forvalues y=1999/2016{
	rm dta/temp/worker_sickness`y'.dta
}

use dta/temp/worker_ub.dta, clear
merge 1:1 rinpersoon year using dta/temp/worker_welfare.dta, nogen
merge 1:1 rinpersoon year using dta/temp/worker_sickness.dta, nogen

drop if missing(unemploymentbenefits) & missing(welfare) & missing(sickness)

replace unemploymentbenefits=0 if missing(unemploymentbenefits)
replace welfare = 0 if missing(welfare)
replace sickness = 0 if missing(sickness)
gen totalbenefits = unemploymentbenefits+welfare+sickness

// Deflate benefits using CPI (2015=100)
merge m:1 year using H:/cpi9619.dta, keep(match master) nogen keepusing(cpi)
foreach var in unemploymentbenefits welfare sickness totalbenefits{
	replace `var' = (`var'/cpi)*100
}
drop cpi

compress
save dta/intermediate/worker_benefits.dta, replace

* Remove temporary files
rm dta/temp/worker_ub.dta
rm dta/temp/worker_welfare.dta
rm dta/temp/worker_sickness.dta

