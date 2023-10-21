*------------------------------------------------------------------------
* Automation
* des_events_by_year
* 6/7/2020
* Wiljan van den Berge
* Purpose: Describe number of potential treatment and control events and workers, and other numbers needed for appendix text
*-------------------------------------------------------------------------

*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16
set more off
clear all
capture log close
sysdir set PLUS M:\Stata\Ado\Plus 

cd H:/automation/
log using log/des_events_by_year, text replace
*--------------------------------------------------------------------------

* Load data to determine potential number of treatment events
use dta\intermediate\firm_level_data_autom.dta, clear
gen spike_yr = year if spike_firm_first==1
bys beid: ereplace spike_yr = max(spike_yr)

* Potential treatment events occur between 2003 and 2011
keep if spike_yr>=2003 & spike_yr<=2011

* Do we observe the whole window around the spike? --> Now: firms have to survive the window + 1
gen i=1 if year>=spike_yr-3 & year<=spike_yr+5
bys beid: egen t_i=total(i)
keep if t_i==9

distinct beid
bys beid: keep if _n==1
tab spike_yr // Potential treatment events

keep beid
save dta/intermediate/treated_beid_temp.dta, replace

* Do the same to determine the potential number of control events
forval y=2003/2011{
	quietly{
		use dta\intermediate\firm_level_data_autom.dta, clear

		gen spike_yr_c = `y'+5 // controls spike in treatment year + 5 or later
		gen c`y' = 1 if year>=spike_yr_c & spike_firm_first==1 // Firms are controls in year t if they have their first spike in year t+5 or later
		//controls can't have any spike in observation window before t+5
		*gen noc`y' = 1 if year<spike_yr_c & year>=spike_yr_c-(8) & spike_firm==1 // spike_firm = any spike, cannot be observed between the control spike year and k+3 years before
		bys beid: ereplace c`y' = max(c`y')

		* Do we observe the whole window + 1 around the (treatment) spike?
		gen i=1 if year>=spike_yr_c-8 & year<=spike_yr_c
		bys beid: egen t_i=total(i)
		keep if t_i==9
	}
	display "Number of firms involved in potential control events in `y'"
	distinct beid if c`y'==1 // number of unique firms involved in potential control events
	keep if c`y'==1
	keep beid spike_yr_c
	bys beid: keep if _n==1
	save dta/intermediate/temp_events_by_year`y'.dta, replace
}
clear
forval y=2003/2011{
	append using dta/intermediate/temp_events_by_year`y'.dta
}
distinct beid
contract beid
count if _freq==1 // Number of potential control events used only once
sum _freq, det
// Average number and maximum of events potential controls are involved in
// Max number of potential events controls are involved in

merge 1:1 beid using dta/intermediate/treated_beid_temp.dta
// Potential treated also used as potential control events:
count if _merge==3
// Potential treated not used as potential control events
count if _merge==2
// Potentail controls not used as potential treated events
count if _merge==1

/* Number of events merged to incumbent workers and number of workers involved */
use dta/intermediate/worker_analysis_autom.dta if inc==1, clear

egen firmid = group(treatbeid_incumbent treat sampleyear)
distinct firmid 
distinct firmid if treat==1
distinct firmid if treat==0

distinct id if treat==1
distinct id if treat==0 


/* Number of treatment events after matching */
use dta/analysis/worker_analysis_drop7_autom.dta if !missing(weight1) & inc == 1, clear

distinct treatbeid_incumbent // Total number of unique firms in treated & control

keep if treat==1
distinct firmid_inc // Total number of unique events
bys sampleyear: distinct firmid_inc


/* Number of control events after matching */
use dta/analysis/worker_analysis_drop7_autom.dta if !missing(weight1) & inc == 1, clear
keep if treat==0
distinct firmid_inc // Total number of unique events
distinct treatbeid_incumbent // Total number of unique firms

bys sampleyear: distinct firmid_inc

keep treatbeid_incumbent sampleyear
bys treatbeid_incumbent sampleyear: keep if _n==1
contract treatbeid_incumbent
count if _freq==1 // Number of control events used only once

/* Number of unique workers we have before matching, but after selections */
use dta/analysis/worker_analysis_drop7_autom.dta if inc == 1, clear
distinct id
distinct id if treat==1
distinct id if treat==0



/* Number of unique workers we end up with, and how many are treated and control */
use dta/analysis/worker_analysis_drop7_autom.dta if !missing(weight1) & inc == 1, clear
distinct id
distinct id if treat==1
distinct id if treat==0

