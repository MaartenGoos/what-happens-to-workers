*------------------------------------------------------------------------
* Automation
* worker_secm.do
* 20/7/2018
* Wiljan van den Berge
* Purpose: merge socio-economic status for each person in our sample on Jan 1
* The data are a panel where each new observation is added when someone's status changes
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
log using log/worker_secm, t replace
*--------------------------------------------------------------------------
use rinpersoons rinpersoon using dta/intermediate/jobdata9916_polis.dta, clear
bys rinpersoons rinpersoon: keep if _n==1

rename *, upper
merge 1:m RINPERSOONS RINPERSOON using "G:\InkomenBestedingen\SECMBUS\geconverteerde data\SECMBUS2020V1.DTA", keep(match) nogenerate
rename *, lower

gen secm_start = date(aanvsecm,"YMD")
drop aanvsecm
gen secm_end = date(eindsecm,"YMD")
drop eindsecm

label var secm_start "SECM start date"
label var secm_end "SECM end date"
format secm_start secm_end %td

rename xkoppel* *
rename secm secmx
rename *secm *
rename secmx secm

destring werkn dga zelfst ovactief werkluitk bijstand socvoorzov ziekteao ///
	pensioen scholstud secm meewerkend, force replace

compress
save dta\temp\temp_secm.dta, replace

// Keep status on Jan 1
forval y=1999/2016{
	use dta\temp\temp_secm.dta, clear

	drop if secm_end<mdy(1,1,`y')
	drop if secm_start>mdy(1,1,`y')

	gen year=`y'

	// There are a few duplicates; keep the status that lasts the longest
	duplicates drop
	duplicates tag rinpersoon year, gen(dup)
	tab dup
	gsort rinpersoon -secm_end
	by rinpersoon: keep if _n==1
	drop dup

	compress
	save dta/temp/rin_secm`y'.dta, replace
}

clear all
forvalues y=2000/2016{
	append using dta\temp\rin_secm`y'.dta
}

label define sec 11 "Employee" 12 "Director major shareholder" 13 "Self-employed" ///
	14 "Other self-employed" 21 "Unemployment benefits" 22 "Welfare" ///
	23 "Other social benefits" 24 "Disability / sickness" ///
	25 "Pension" 26 "Student with income" 31 "Student without income" ///
	32 "Other without income"  15 "Working family member"
label values secm sec
compress
label var secm "Most important source of income on Jan 1"

foreach var of varlist werkn dga zelfst ovactief werkluitk bijstand socvoorzov ziekteao pensioen scholstud meewerkend{
	replace `var' =0 if missing(`var')
}

drop secm_start secm_end
save dta\intermediate\rin_secm9916.dta, replace


*Drop temp files
forvalues y=1999/2016{
	rm dta\temp\rin_secm`y'.dta
}
rm dta\temp\temp_secm.dta
