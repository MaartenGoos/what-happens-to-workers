*------------------------------------------------------------------------
* Automation
* firm_events_drop.do
* 25/11/2018
* 14/5/2019: Added additional selection on employment changes in the two years after the window
* Wiljan van den Berge
* Purpose: determine which firms to drop based on events data
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
log using log/firm_events_drop, text replace
*--------------------------------------------------------------------------


foreach sample in $samplelist{ //[ .... ]autom comp emp_autom empf_autom empt0_autom
	use dta/intermediate/firm_analysis_`sample'.dta, clear 
	
	merge m:1 beid year using dta/intermediate/firm_event0016_wide.dta, keep(match master) gen(merge_abr)

	// First: don't allow large employment changes in the two years after the window either as additional check
	keep if time>=-3 & time<=5+1
	sort firmid year
	by firmid: gen diff = nr_workers_mar - nr_workers_mar[_n-1]
	gen perc_diff = diff / nr_workers_mar[_n-1]

	gen drop_diffk1 = 1 if (perc_diff>0.9 & perc_diff!=.) | perc_diff<-.9

	local i=1
	bys firmid: egen t_i = total(`i')
	tab t_i
	replace drop_diffk1 = 1 if t_i<10 & treatyr!=(2016-5) // Also drop if firms don't have observations in later time periods (but not for 2011!)
	replace drop_diffk1 = 1 if missing(nr_workers_mar) // also drop missings on nr_workers_mar


	gsort firmid -drop_diffk1
	by firmid: replace drop_diffk1 = drop_diffk1[_n-1] if missing(drop_diffk1)
	drop diff perc_diff t_i

	// Then only within the main observation window
	keep if time>=-3 & time<=5-1
	sort firmid year
	by firmid: gen diff = nr_workers_mar - nr_workers_mar[_n-1]
	gen perc_diff = diff / nr_workers_mar[_n-1]

	gen drop_diff = 1 if (perc_diff>0.9 & perc_diff!=.) | perc_diff<-.9
	replace drop_diff = 1 if missing(nr_workers_mar) // also drop missings
	gsort firmid -drop_diff
	by firmid: replace drop_diff = drop_diff[_n-1] if missing(drop_diff)


	// Define different drop scenario's for different events
	// 1: all events, except for birth at t=-3
	gen drop1=.
	forval i=1/11{
		replace drop1 = 1 if eac_type`i'!=. 
		replace drop1 = . if eac_type`i'==1 & time==-3
	}

	// 2: only splits and break-ups
	gen drop2=.
	forval i=1/11{
		replace drop2 = 1 if (ebd_type`i'==4 | ebd_type`i'==5) & eac_type`i'==3
	}

	// 3: take-overs and mergers
	gen drop3=.
	forval i=1/11{
		replace drop3=1 if (ebd_type`i'==6 | ebd_type`i'==7) & eac_type`i'==3
	}
	// 4: restructuring
	gen drop4=.
	forval i=1/11{
		replace drop4=1 if (ebd_type`i'==8) & eac_type`i'==3
	}

	// 5: all events at t<=0 (except for birth if t=-3)
	gen drop5=.
	forval i=1/11{
		replace drop5=1 if eac_type`i'!=. & time<=0
		replace drop5=. if eac_type`i'==1 & time==-3
	}

	// 6: All events at t=-2 and t=-1 and t=0, not t=-3
	gen drop6=.
	forval i=1/11{
		replace drop6=1 if eac_type`i'!=. & time<=0 & time>-3
	}

	forval d=1/6{
		gsort firmid -drop`d'
		by firmid: replace drop`d' = drop`d'[_n-1] if missing(drop`d')
	}

	// now you can merge this on the BEID - YEAR combination to the worker data
	// Firmid's (beid - sampleyear combinations) are dropped when they have an event in the period
	// but BEID is kept when they don't have an event in that period

	compress

	label var drop_diff "Firm changes employment by >90% in obs window"
	label var drop_diffk1 "Firm changes employment by >90% in time until k+1"
	label var drop1 "Firm has any event in obs window"
	label var drop2 "Firm has split or break-up in obs window"
	label var drop3 "Firm has take-over or merger in obs window"
	label var drop4 "Firm has restructuring in obs window"
	label var drop5 "Firm has any event between t=-3 & t=0 (except birth at -3)"
	label var drop6 "Firm has any event between t=-2 and t=0"

	save dta/analysis/firm_analysis_`sample'_drop.dta, replace
}

