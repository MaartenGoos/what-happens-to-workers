*------------------------------------------------------------------------
* Automation
* import_firm_wagebill.do
* 6/5/2019
* 9/5/2019:		Added a drop of duplicates after merge to BAANKENMERKENBUS to drop duplicate person-firm-job observations
*				Also changed merge with BAANSOMMENTAB from m:1 to 1:1, because there should now be one job-person at each period
*						This does not work: there are people with the same job ID who are at different firms. About 1% of the sample
*						Now calculate the share of time in the year they spent at this firm, and use that to calculate their contribution to the yearly wagebill
*				ALso no more drop based on RINPERSOONS
* 13/6/2019:	Added median wage and median daily wage
* Wiljan van den Berge
* Purpose: Calculate total wages paid by firm in a year in admin data
*-------------------------------------------------------------------------
*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close

cd H:/automation/
log using log/import_firm_wagebill, text replace
*--------------------------------------------------------------------------

* First get all the workers at these firms
forvalues y=1999/2016{
use dta/intermediate/beid.dta, clear // all firms that are in PS/Investments data

rename beid beidbaanid
if `y'>=1999 & `y'<=2006 | `y'>=2008 & `y'<=2011{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/140930 BAANKENMERKENBUS `y'V3.dta", ///
			keep(match master) keepusing(rinpersoons rinpersoon baanid aanvangbaanid eindebaanid) nogen
	}
	if `y'==2007 | `y'==2012{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/140930 BAANKENMERKENBUS `y'V2.dta", ///
			keep(match master) keepusing(rinpersoons rinpersoon baanid aanvangbaanid eindebaanid) nogen
	}
	if `y'==2013{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/BAANKENMERKENBUS`y'V2.dta", ///
			keep(match master) keepusing(rinpersoons rinpersoon baanid aanvangbaanid eindebaanid) nogen
	}
	if `y'==2014{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/BAANKENMERKEN`y'BUSV2.dta", ///
			keep(match master) keepusing(rinpersoons rinpersoon baanid aanvangbaanid eindebaanid) nogen
	}
	if `y'==2015{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/BAANKENMERKENBUS`y'V2.dta", ///
			keep(match master) keepusing(rinpersoons rinpersoon baanid aanvangbaanid eindebaanid) nogen
	}
	if `y'==2016{
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/geconverteerde data/BAANKENMERKENBUS`y'V1.dta", ///
			keep(match master) keepusing(rinpersoons rinpersoon baanid aanvangbaanid eindebaanid) nogen
	}
	
	// We merge wage data using PERSON - JOB combination
	// So we want to collapse these data, which are PERSON - FIRM - JOB - START DATE, to that level
	// Unfortunately, some workers have the same JOB at multiple firms, so we have to calculate the share of time they spent
	// at each firm with the same JOB
	
	drop if missing(baanid) // can't merge them to wage data
	
	// Calculate the length of time a worker spends in a JOB and in a FIRM-JOB combination
	gen date_start=date(aanvangbaanid,"YMD")
	gen date_end=date(eindebaanid,"YMD")
	drop aanvangbaanid eindebaanid
	format date_start date_end %td
	sort rinpersoons rinpersoon beidbaanid baanid date_start

	gen length = (date_end - date_start)+1 // length in days of combination PERSON - FIRM - JOB - START DATE OF JOB
	bys rinpersoons rinpersoon beidbaanid baanid: egen firm_job_length=total(length) // length in days of PERSON - FIRM - JOB
	bys rinpersoons rinpersoon baanid: egen job_length=total(length) // length in days of PERSON - JOB
	
	// Calculate share of JOB accruing to each firm
	gen share = firm_job_length / job_length
	
	gen duration=(date_end-date_start)+1 // Calculate duration
	// First calculate total duration by worker-job ID, this is the relevant job duration that we will use
	bys rinpersoons rinpersoon baanid: egen t_duration=total(duration) // max is 365, so OK.
	// Sort by duration within person-job ID
	gsort rinpersoons rinpersoon baanid -duration
	// Then keep the first Person-Job ID-Firm combination
	by rinpersoons rinpersoon baanid: keep if _n==1
	
	gen int year=`y'
	keep beidbaanid rinpersoons rinpersoon year baanid share duration t_duration

	
	compress
	save dta\intermediate\beid_baanid_person`y'.dta, replace
}

forvalues y=1999/2016{
	use dta\intermediate\beid_baanid_person`y'.dta, clear
	
	if `y'>=1999 & `y'<=2005{
		merge m:1 rinpersoons rinpersoon baanid using "G:/Arbeid/BAANSOMMENTAB/`y'/geconverteerde data/140930 BAANSOMMENTAB `y'V3.dta", ///
			keep(match master) keepusing(blsv) nogenerate
	}
	if `y'>=2006 & `y'<=2012{
		merge m:1 rinpersoons rinpersoon baanid using "G:/Arbeid/BAANSOMMENTAB/`y'/geconverteerde data/140930 BAANSOMMENTAB `y'V2.dta", ///
			keep(match master) keepusing(blsv) nogenerate
	}
	if `y'>=2013 & `y'<=2013{
		merge m:1 rinpersoons rinpersoon baanid using "G:/Arbeid/BAANSOMMENTAB/`y'/geconverteerde data/BAANSOMMENTAB `y'V1.dta", ///
			keep(match master) keepusing(blsv) nogenerate
	}
	if `y'>=2014 & `y'<=2015{
		merge m:1 rinpersoons rinpersoon baanid using "G:/Arbeid/BAANSOMMENTAB/`y'/geconverteerde data/BAANSOMMEN`y'TABV1.dta", ///
			keep(match master) keepusing(blsv) nogenerate
	}
	if `y'>=2016 & `y'<=2016{
		merge m:1 rinpersoons rinpersoon baanid using "G:/Arbeid/BAANSOMMENTAB/geconverteerde data/BAANSOMMEN`y'TABV1.dta", ///
			keep(match master) keepusing(blsv) nogenerate
	}
	
	replace blsv = blsv*share if !missing(share)
	
	rename beidbaanid beid

	// And total earnings over the year per firm
	bys rinpersoons rinpersoon beid: egen wage=total(blsv)
	*bys rinpersoons rinpersoon beid: egen svdays=total(svdg)
	bys rinpersoons rinpersoon beid: egen days=total(t_duration)

	gen dailywage=wage/days
	collapse (sum) totaldays=days wagebill=wage (p50) med_wage=wage med_dwage=dailywage (mean) mn_wage=wage mn_dwage=dailywage, by(beid year)
	label var totaldays "Total days worked in a year"
	label var wagebill "Total gross wages in a year"
	label var med_wage "Median yearly wage"
	label var med_dwage "Median daily wage"
	label var mn_wage "Mean yearly wage"
	label var mn_dwage "Mean daily wage" 
	compress
	
	save dta\intermediate\beid_wagebill`y'.dta, replace
}


use dta\intermediate\beid_wagebill1999.dta, clear
forvalues y=2000/2016{
	append using dta\intermediate\beid_wagebill`y'.dta
}

merge m:1 year using H:/cpi9619.dta, keep(match master) nogen

foreach var in wagebill med_wage med_dwage mn_wage mn_dwage{
	replace `var' = (`var'/cpi)*100
}
compress
save dta\intermediate\beid_wagebill.dta, replace


forval y=1999/2016{
	rm dta\intermediate\beid_wagebill`y'.dta
	rm dta\intermediate\beid_baanid_person`y'.dta
}

