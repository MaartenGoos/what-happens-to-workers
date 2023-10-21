*------------------------------------------------------------------------
* Automation
* worker_panel.do
* 9/5/2018
* Last updated: 14/5/2020
* Wiljan van den Berge
* Purpose: create stacked panel at worker level
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
log using log/worker_panel, text replace
*--------------------------------------------------------------------------
* Prepare firm analysis datasets to only keep one observation per firm; so we can merge to worker data 
foreach sample in $samplelist{ 
	forval y=2003/2011{
		use dta/analysis/firm_analysis_`sample'_drop.dta, clear
		keep if treatyr==`y'
		keep if year==`y'-1 // keep only the year before treatment, this is where we merge workers
		keep beid year treat treatyr sbi2008_1dig sbi2008 gk_manual nr_workers_mar spike* psadmin drop_diff drop_diffk1 drop1-drop6  
		compress
		save dta/temp/firm_`y'_`sample'.dta, replace
	}

	* Create a worker panel around the treatment event for each year 
	*		This includes all workers who are at the firm at t=-1
	forvalues y=2003/2011{		
		// Load worker data for the years around treatment
		if "`sample'"!= "overl_autom1" & "`sample'"!="overl_autom2" & "`sample'"!="overl_comp1" & "`sample'"!="overl_comp2"{
			use dta/intermediate/worker_baseline_sample_`sample'.dta if year >= `y'-3 & year <= `y'+(5-1), clear
		}
		if "`sample'"== "overl_autom1" | "`sample'"=="overl_autom2" | "`sample'"=="overl_comp1" | "`sample'"=="overl_comp2"{
			use dta/intermediate/worker_baseline_sample_overl.dta if year >= `y'-3 & year <= `y'+(5-1), clear
		}

		merge m:1 beid year using dta/temp/firm_`y'_`sample'.dta, gen(merge_firm) keep(match master)


		* Keep only workers who are at the treatment/control firm at t=-1
		gen byte keep=1 if merge_firm==3 & year==`y'-1
		gsort rinpersoons rinpersoon -keep
		by rinpersoons rinpersoon: replace keep=keep[_n-1] if missing(keep)
		keep if keep==1
		drop keep

		foreach var of varlist treat drop_diff drop1 drop2 drop3 drop4 drop5 drop6{
			gsort rinpersoons rinpersoon -`var'
			by rinpersoons rinpersoon: replace `var'=`var'[_n-1] if missing(`var')
		}

		gen treat_beid = beid if merge_firm==3 // beid of treatment/control firm; helps in identifying status of workers
		gen int sampleyear=`y'
		label var sampleyear "Year in which treatment/placebo firm spikes"

		compress

		save dta/temp/workers_y`y'_`sample'.dta, replace
	}

	* Then stack all individual cohorts
	clear all
	forvalues y=2003/2011{
		append using dta/temp/workers_y`y'_`sample'.dta
	}
	* Define new ID based on person id and sample year, because controls can figure as controls more than once
	gegen id = group(rinpersoons rinpersoon sampleyear)

	* Create a balanced panel
	gen x = 1
	bys id: ereplace x = total(x)
	keep if x==5+3
	drop x

	* Per worker: when do they first show up as treated in a cohort?
	gen first_treat = year if treat==1 & year == sampleyear
	bys rinpersoons rinpersoon: ereplace first_treat = min(first_treat) 

	* Leave out controls who are earlier treated
	* Leave out treated who are treated again		
	* [Note that this is per "ID": we only want to drop the events AFTER a first treatment, if workers are included again in a different period]
	gen drop = 1 if sampleyear > first_treat

	tab first_treat sampleyear if drop==1, miss
	tab treat drop, miss row // 1% of controls; 1.2% of treated for the main sample
	* Drop earlier treated
	bys id: ereplace drop = max(drop)
	drop if drop == 1
	drop drop first_treat

	* Define relative time
	gen byte time = year - sampleyear
	label var time "Time relative to when treatment/placebo firm spikes"

	gsort id -treat_beid
	by id: replace treat_beid = treat_beid[_n-1] if missing(treat_beid)
	bys id: ereplace treatyr = max(treatyr)	

	sort id time
	
	* Define time in the spiking firm
	gen time_spiking = year - treatyr if beid == treat_beid
	drop treatyr 

	* Incumbents are workers only workers for whom we observe them at t=-3, t=-2 and t=-1 at the spiking firm/control firm
	gen keep = 1 if time_spiking>=-3 & time_spiking<=-1 
	by id: gegen total_keep = total(keep)
	tab total_keep
	gen byte inc = 1 if total_keep==3
	replace inc = 0 if missing(inc)

	* Generate non-incumbent (recent hire) indicator	[at the firm before treatment, at least in year t=-1]
	gen byte rh = 1 if inc==0 & time_spiking==-1
	gsort id -rh
	by id: replace rh = rh[_n-1] if missing(rh)
	replace rh = 0 if missing(rh)	

	tab time_spiking if inc==0 & rh==0

	* Drop observations only at the firm at t==-3 or t==-2
	drop if inc==0 & rh==0
	drop total_keep keep time_spiking

	* cluster standard errors at the level of the treat/control firm at t=-1
	* need separate beid's for each type of worker
	gen treatbeid_incumbent = treat_beid if inc==1
	gen treatbeid_nonincumbent = treat_beid if rh==1
	foreach var of varlist  treatbeid_incumbent treatbeid_nonincumbent{
		gsort id -`var' 
		by id: replace `var'=`var'[_n-1] if missing(`var')
	}
	drop treat_beid

	* Generate control variables age2
	gen int age2 = age^2


	* Define probability to leave treated/control firm for incumbents and non-incumbents [only defined in periods post t=-1]
	sort id time
	gen byte leave=.

	local max=4 
	local min=0
	forvalues j=`min'/`max'{
		local i=`j'+1
		by id: replace leave = 1 if time==`j' & ((beid!=treatbeid_incumbent & inc==1) | (beid!=treatbeid_nonincumbent & rh==1))
	}
	replace leave=0 if missing(leave) & (inc==1 | rh==1)

	* Change definition of leave variable: only 1 in year that worker is definitely gone and not in any later years [would prefer to change it to 1 in year of leaving, but that requires 
	* much more data work, because we don't observe that for the final year currently]
	rename leave leave_old
	* Fix leave_old: can't leave again after having left once
	sort id time
	by id: replace leave_old = 1 if leave_old[_n-1]==1

	sort id time
	* Leave is leave probability by year
	gen byte leave = 1 if leave_old==1 & leave_old[_n-1]==0
	replace leave = 0 if missing(leave)
	* Leave2 is hazard-like
	gen byte leave2 = leave
	by id: replace leave2 = . if leave2[_n-1]==1
	by id: replace leave2 = . if leave2[_n-1]==. & time>0


	* Sector and firm size in the year before treatment
	gen sector_treatyr = sbi2008_1dig if year==(sampleyear-1) & (inc==1 | rh==1)
	gen gk_treatyr = gk_manual if year==(sampleyear-1) & (inc==1 | rh==1)

	foreach var of varlist sector_treatyr gk_treatyr{
		bys id: ereplace `var'=max(`var')
	}

	* Generate additional outcome variables
	replace earnings = 		0 if missing(earnings) | earnings < 0
	replace totaldays = 	0 if missing(totaldays) | totaldays < 0
	replace wage = 			0 if missing(wage) | wage < 0
	replace days = 			0 if missing(days) | days < 0
	replace hours = 		0 if missing(hours) | hours < 0
	replace totalhours = 	0 if missing(totalhours) | totalhours < 0

	gen dailywage = wage/days
	replace dailywage = 0 if missing(dailywage)
	gen ln_wage = ln(dailywage)
	gen emp = earnings>0 & earnings!=.
	gen wage_emp = dailywage if dailywage>0 & dailywage!=. // daily wage conditional on employment

	rename unemploymentbenefits ub
	rename sickness di

	foreach var in ub di welfare totalbenefits{
		replace `var' = 0 if missing(`var') | `var'<0
	}
	gen totalincome = earnings + totalbenefits
	gen byte earlyretirement = secm==25 & emp==0 & age<65 // Early retirement = Not employed, younger than 65 and most improtant source of income = pension

	* labels
	label var nonemp "Non-employment duration (days, max=262)"
	label var wage_emp "Daily wage conditional on employment"
	label var totalincome "Income from wages and benefits"
	label var earlyretirement "Pension income, not employed and younger than 65"
	label var ub "Amount of unemployment benefits"
	label var welfare "Amount of welfare"
	label var di "Amount of disability benefits"
	label var totalbenefits "Total benefit receipt (UB, DI, welfare)"
	label var emp "Year-round employment status"
	label var id "Person ID"
	label var inc "1 if worker is at firm from t-3 until t-1"
	label var rh "1 if worker is at firm at t=-1"
	label var leave "Leaves the spike firm [only incumbent and nonincumbent]"
	label var secm "Most important source of income on Jan 1"
	label var treat "Treatment status"
	label var foreign "Foreign born or foreign born parents" 
	label var age "Age"
	label var age2 "Age squared" 
	label var sector_treatyr "Sector in the year of treatment"
	label var gk_treatyr "Size class in the year of treatment"
	label var dailywage "Daily wage in levels"
	label var selfemp "Self-employed or director major shareholder on Jan 1"
	label var ln_wage "Log of daily wage"
	cap label var spike_large_year "Year in which treatment/control firm has largest spike"
	cap label var spike_first "Year in which treatment/control firm has first spike"

	compress
	save dta/intermediate/worker_analysis_`sample'.dta, replace
}


