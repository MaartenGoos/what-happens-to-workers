*------------------------------------------------------------------------
* Automation
* worker_job_polis.do
* 23/4/2021			: For 2006-2019 use POLIS files; added hours measure
* Wiljan van den Berge
* Purpose: read raw worker data and prepare for creating samples
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
log using log/worker_job_polis, text replace
*--------------------------------------------------------------------------

/* Step 1: identify all the workers who at some point work at firms in the PS data with a spike */

// Some preliminary processing to only identify firms that we will use 
use dta\intermediate\inv_ps_9316_merged.dta if year>=2000 & year<=2016, clear

** Drop very small sectors
drop if sbi2008_letter=="A" | sbi2008_letter=="B" | sbi2008_letter=="D" | sbi2008_letter=="E" | sbi2008_letter=="L" | sbi2008_letter=="R" | sbi2008_letter=="S"

*Drop if missing investments AND automation costs AND total costs
drop if missing(aloeu01nr6) & missing(bedrlst348400) & missing(aloeu01nr9)
keep beid
duplicates drop

save dta/intermediate/firm_sel.dta, replace

// Step 2: get the workers who are at the selected firms
forvalues y=1999/2016{
	use dta/intermediate/firm_sel.dta, clear // this is the full firm sample

	if inrange(`y',1999,2005){
		rename beid beidbaanid
		merge 1:m beidbaanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/140930 BAANKENMERKENBUS `y'V3.dta", ///
			keep(match master) keepusing(rinpersoons rinpersoon) nogen
		rename beidbaanid beid
	}
	if inrange(`y',2006,2009){
		local varlist "rinpersoons rinpersoon beid"
		local polisfolder "G:/Polis/POLISBUS/`y'/geconverteerde data/"
	}
	if inrange(`y',2010,2012){
		local varlist "RINPERSOONS RINPERSOON SBEID"
		local polisfolder "G:/Spolis/SPOLISBUS/`y'/geconverteerde data/"
	}	
	if inrange(`y',2013,2019){
		local varlist "rinpersoons rinpersoon sbeid"
		local polisfolder "G:/Spolis/SPOLISBUS/`y'/geconverteerde data/"
	}

	if `y'==2006{
		local filelist: dir "`polisfolder'" files "*.dta"
	}
	if `y'>2006{
		local filelist: dir "`polisfolder'" files "*.dta"
	}

	di `filelist'
	foreach f in `filelist'{
		di "`f'"
		if `y' == 2013{
			use `varlist' using "`polisfolder'/SPOLISBUS2013V3.dta", clear
		}
		else if strpos("`f'", "V2") | strpos("`f'", "v2"){
			di "`f'"
			use  `varlist' using  "`polisfolder'/`f'", clear		
		}
		else if `y'> 2013{
			di "`f'"
			use  `varlist' using  "`polisfolder'/`f'", clear			
		} 
	}	
	rename *, lower	
	if `y'>2009{
		rename s* *
	}

	bys rinpersoons rinpersoon beid: keep if _n==1

	merge m:1 beid using dta/intermediate/firm_sel.dta, keep(match using) nogen

	*Drop workers that can't be merged to other data (rinpersoons!="R")
	keep if rinpersoons=="R"

	*Drop duplicate persons within a firm
	bys beid rinpersoons rinpersoon: gen i = _n
	drop if i>1
	drop i

	gen int year=`y'

	save dta\intermediate\beid_rinpersoon`y'.dta, replace
}


* Keep only the person id's and merge with GBA (demographics from municipal registries) and 
* highest education level obtained
clear all
forvalues y=1999/2016{
	append using dta\intermediate\beid_rinpersoon`y'.dta
}
drop beid year

*Drop duplicates
bys rinpersoons rinpersoon: keep if _n==1
save dta\intermediate\rinpersoon.dta, replace

do do\prepare\a14_01_worker_demographics.do
do do\prepare\a14_02_worker_education.do

/* Merge date of birth to shrink sample size: only keep workers 18-65*/
clear all
forvalues y=1999/2016{
	append using dta\intermediate\beid_rinpersoon`y'.dta
}
drop beid
merge m:1 rinpersoons rinpersoon using dta\intermediate\rinpersoon_gba.dta, keep(match) keepusing(dateofbirth) nogen
gen int age=floor((mdy(1,1,year)-dateofbirth)/365.25)
keep if age>=18 & age<=65
drop age dateofbirth

keep rinpersoons rinpersoon
bys rinpersoons rinpersoon: keep if _n==1

save dta\intermediate\rinpersoon_selected.dta, replace



/* Step 2. Get for each worker who is at least once at one of the firms we're interested in their wage,
   number of days worked over the year. Calculate both the total for each year and the wage/days in the most important job */

/* First get the highest paying job, the wage and number of days worked */
forvalues y=1999/2005{
	use dta\intermediate\rinpersoon_selected.dta, clear

	* Wage and days worked
	if inrange(`y',1999,2005){
		merge 1:m rinpersoons rinpersoon using "G:/Arbeid/BAANSOMMENTAB/`y'/geconverteerde data/140930 BAANSOMMENTAB `y'V3.dta", keepusing(svdg blsv baanid) keep(match) nogen
	}


	* Job characteristics
	if inrange(`y',1999,2005){
		merge 1:m rinpersoons rinpersoon baanid using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/140930 BAANKENMERKENBUS `y'V3.dta", keepusing(beidbaanid baanid aanvangbaanid eindebaanid soortbaanid datumaanvangbaanid) keep(match master) nogen
	}

	gduplicates drop
	rename beidbaanid beid
	destring soortbaanid, replace

	// Problem with this data: we sometimes have >1 firm for the same job. Since we merge on job ID, this means we have the total wage for the job twice
	// In those cases, keep the FIRM-WORKER observation with the longest duration of the job (since we don't know where they earn the most, which would be preferred)
	gen date_start=date(aanvangbaanid,"YMD")
	gen date_end=date(eindebaanid,"YMD")
	gen date_start_first=date(datumaanvangbaanid,"YMD")
	gen duration=(date_end-date_start)+1 // Calculate duration
	format date_start date_end date_start_first %td

	// First calculate total duration by worker-job ID, this is the relevant job duration that we will use
	bys rinpersoons rinpersoon baanid: egen t_duration=total(duration) // max is 365, so OK.
	// Sort by duration within person-job ID
	gsort rinpersoons rinpersoon baanid -duration
	// Then keep the first Person-Job ID-Firm combination
	by rinpersoons rinpersoon baanid: keep if _n==1


	// Then calculate both total earnings for each individual within a firm [There are some people with >1 job per firm, but that's ok]
	// And total earnings over the year
	bys rinpersoons rinpersoon beid: egen wage=total(blsv)
	bys rinpersoons rinpersoon beid: egen days=total(t_duration)
	bys rinpersoons rinpersoon: egen earnings=total(blsv)
	bys rinpersoons rinpersoon: egen totaldays=total(t_duration)

	// Then keep the worker-firm combination with the highest wage in the year
	gsort rinpersoons rinpersoon -wage
	by rinpersoons rinpersoon: keep if _n==1

	gen year=`y'

	keep rinpersoons rinpersoon year days totaldays beid wage earnings soortbaanid date_start_first

	label var wage "Total earnings at the firm with the highest earning job"
	label var earnings "Total earnings over the year"
	label var days "Total calendar days at the firm with the highest earning job"
	label var totaldays "Total days worked over the year"
	label var date_start_first "First start of job data observed"

	compress
	save dta/intermediate/earnings_`y'.dta, replace
}


// Merge 2006-2016 samples to SPOLIS
forval y=2006/2016{
	if `y'>=2006 & `y'<=2009{
		local varlist "rinpersoons rinpersoon beid lnsv aantverlu soortbaan baandagen datumaanvangikvorg"
		local polisfolder "G:/Polis/POLISBUS/`y'/geconverteerde data/"
	}
	if `y'>=2010 & `y'<=2012{
		local varlist "RINPERSOON RINPERSOONS SBEID SLNSV SAANTVERLU SSOORTBAAN SBAANDAGEN SDATUMAANVANGIKVORG"
		local polisfolder "G:/Spolis/SPOLISBUS/`y'/geconverteerde data/"
	}
	if `y'>=2013 & `y'<=2019{
		local varlist "rinpersoons rinpersoon sbeid slnsv saantverlu ssoortbaan sbaandagen sdatumaanvangikvorg"
		local polisfolder "G:/Spolis/SPOLISBUS/`y'/geconverteerde data/"	
	}

	if `y'==2006{
		local filelist: dir "`polisfolder'" files "*.dta"
	}
	if `y'>2006{
		local filelist: dir "`polisfolder'" files "*.dta"
	}

	di `filelist'
	foreach f in `filelist'{
		di "`f'"
		if `y' == 2013{
			use `varlist' using "`polisfolder'/SPOLISBUS2013V3.dta", clear
		}
		else if strpos("`f'", "V2") | strpos("`f'", "v2"){
			di "`f'"
			use  `varlist' using  "`polisfolder'/`f'", clear		
		}
		else if `y'> 2013{
			di "`f'"
			use  `varlist' using  "`polisfolder'/`f'", clear			
		} 
	}	
	rename *, lower	
	if `y'<=2009{
		gen date_start_first=date(datumaanvangikvorg,"YMD")		
		drop datumaanvangikvorg
	}
	if `y'>2009{
		rename s* *
		gen date_start_first=date(datumaanvangikvorg,"YMD")
		drop datumaanvangikvorg
	}
	destring soortbaan, replace

	merge m:1 rinpersoons rinpersoon using dta/intermediate/rinpersoon_selected.dta, keep(match) nogen


	// generate total earnings and days per firm-individual and per individual
	bys rinpersoons rinpersoon beid: gegen wage=total(lnsv)
	bys rinpersoons rinpersoon beid: gegen days=total(baandagen)
	bys rinpersoons rinpersoon beid: gegen hours=total(aantverlu)
	bys rinpersoons rinpersoon: gegen earnings=total(lnsv)
	bys rinpersoons rinpersoon: gegen totaldays=total(baandagen)
	bys rinpersoons rinpersoon: gegen totalhours=total(aantverlu)
	drop lnsv baandagen aantverlu

	gsort rinpersoons rinpersoon -wage
	by rinpersoons rinpersoon: keep if _n==1

	gen year=`y'

	label var wage "Total earnings at the firm with the highest earning job"
	label var earnings "Total earnings over the year"
	label var days "Total calendar days at the firm with the highest earning job"
	label var totaldays "Total days worked over the year"
	label var hours "Total hours at firm with the highest earning job"
	label var totalhours "Total hours worked in the year"
	label var date_start_first "First start of job data observed"

	compress
	save dta/intermediate/earnings_`y'.dta, replace
}	


* Append all files
clear all
forval y=1999/2016{
	append using dta/intermediate/earnings_`y'.dta
}

save dta/temp/temp_worker_job.dta, replace

keep rinpersoons rinpersoon year
* Balance the sample
gegen id=group(rinpersoons rinpersoon)
tsset id year
tsfill, f

gsort id -rinpersoon
by id: replace rinpersoon=rinpersoon[_n-1] if missing(rinpersoon)
replace rinpersoons="R" if missing(rinpersoons)
drop id

*Merge to demographics and keep only 18-65
merge m:1 rinpersoons rinpersoon using dta\intermediate/rinpersoon_gba.dta, keepusing(female dateofbirth generation) keep(match master) nogen

* Calculate age and select on 18-65;; note that this makes the panel not fully balanced anymore
gen int age=floor((mdy(1,1,year)-dateofbirth)/365.25)
keep if age>=18 & age<=65
drop dateofbirth

merge 1:1 rinpersoons rinpersoon year using dta/temp/temp_worker_job.dta, keep(match master) nogen



merge m:1 year using H:/cpi9619.dta, keep(match master) nogen keepusing(cpi)

foreach var in wage earnings{
	replace `var'=(`var'/cpi)*100
}
drop cpi


replace soortbaan=soortbaanid if missing(soortbaan)
drop soortbaanid


gen byte foreign = generation==1 | generation==2
drop generation

merge 1:1 rinpersoons rinpersoon year using dta\intermediate/rin_education9916.dta, keepusing(soi2016niveau) keep(match master) nogen

* Define education level
gen byte educ=1 if soi2016niveau<=33
replace educ=2 if soi2016niveau>=40 & soi2016niveau<=43
replace educ=3 if soi2016niveau>=51 & soi2016niveau<=70
replace educ=0 if missing(educ)
label define EDUC 0 "Missing" 1 "Low" 2 "Middle" 3 "High", replace
label values educ EDUC
label var educ "Education level"
drop soi2016niveau

* Set <0 and missings at zero; round variables to save space
foreach var in wage days earnings totaldays hours totalhours{
	replace `var' = 0 if missing(`var') | `var'<0
	replace `var' = round(`var')
}

// Define non-employment duration and censor number of days worked
gen int maxdays=366 if year==2020 | year==2016 | year==2012 | year==2008 | year==2004 | year==2000
replace maxdays=365 if missing(maxdays)

replace totaldays = maxdays if totaldays>maxdays & totaldays!=.
replace days = maxdays if days>maxdays & days!=.
gen int nonemp = maxdays - totaldays
drop maxdays

* Set hours worked at maximum of 3000 hours per year (that is 366 * 8 = 2928)
replace hours = 3000 if hours>3000 & hours!=.
replace totalhours = 3000 if totalhours>3000 & totalhours!=.


* Calculate tenure on Jun 30 of each year [Tenure is 0 if job started later in the year]
* Take into account that people might re-enter employment at a firm, so we cannot just take the minimum start date across rinpersoon - beid
bys rinpersoons rinpersoon beid: gegen date_start_first2 = min(date_start_first) // Doesn't take into account that people might re-enter employment at a firm
format date_start_first2 %td

sort rinpersoons rinpersoon beid year
* Create final start date
gen date_start = .
* Final start date is the minimum date for each worker-firm combination, unless there is a gap of at least one year
by rinpersoons rinpersoon beid: replace date_start = date_start_first2 if year - 1 == year[_n-1]
by rinpersoons rinpersoon beid: replace date_start = date_start_first2 if year + 1 == year[_n+1]
* If there is a gap of at least one year, or if there is only one observation, we take date_start_first as the starting point
by rinpersoons rinpersoon beid: replace date_start = date_start_first if missing(date_start) & year - 1 != year[_n-1]
* Define tenure on Jun 30 of each year; set at 0 if negative (e.g. if job starts after Jun 30)
gen tenure = max(((mdy(6,30,year) - date_start + 1) / 365.25),0)
replace tenure = . if beid == ""
drop date_start_first date_start date_start_first2


label define sbaan 1 "Director-major shareholder" 2 "Intern" 3 "Disabled" 4 "Temp agency" 5 "On call" 9 "Other", replace
label values soortbaan sbaan

label var rinpersoon "Person ID"
label var year "Calendar year"
label var wage "Wage in highest paying job"
label var days "Number of days in highest paying job"
label var beid "Firm ID"
label var age "Age on January 1"
label var female "Female"
label var nonemp "Non-employment duration (days)"
label var foreign "Is foreign born or has foreign-born parents"
label var tenure "Tenure in years on Jun 30"
compress
save dta\intermediate\jobdata9916_polis.dta, replace


forval y=1999/2016{
	rm dta/intermediate/beid_rinpersoon`y'.dta
	rm dta/intermediate/earnings_`y'.dta
}
rm dta/temp/temp_worker_job.dta


