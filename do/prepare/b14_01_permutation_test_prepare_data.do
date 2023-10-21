*------------------------------------------------------------------------
* Automation
* permutation_test_prepare.do
* 5/6/2019
* Wiljan van den Berge
* Purpose: prepare permutation samples with placebo treatments
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
*--------------------------------------------------------------------------


/*
// Permutation test

// Steps:
1. Start with the 36K firms
2. Draw random sample of treated until we have the same nr of treated firms; with restriction that we need to observe the firm in the window
3. Draw random sample of controls (with replacement) with restriction that treated/control don't overlap and that we observe the firm in the relevant window
4. Merge this firm sample to worker_baseline_sample_autom
5. Apply some restrictions, etc. (can we not do those earlier?) that are in worker_panel.do
6. Matching (but very simple)
*/

//include both the sampleyear and the sampleyear-1 in the data. We merge on the sampleyear-1, so keep if year==sampleyear-1, but also keep sampleyear so that we know the actual treatment year

/* RUN ONLY ONCE: data preperation */

describe using dta/intermediate/worker_baseline_sample_autom.dta

// Prepare worker data
{
	use dta/intermediate/worker_baseline_sample_autom.dta, clear

	gen dailywage = wage/days
	replace dailywage = 0 if missing(dailywage) | dailywage < 0
	gen lnwage = ln(dailywage)
	gen age2 = age^2
					
	keep rinpersoons rinpersoon beid year earnings totaldays wage days female foreign age age2 dailywage lnwage totalbenefits nonemp secm educ

	sort beid year // have to sort by firm and year to later use joinby
	compress
	save dta/intermediate/permutation_workersample.dta, replace

	
	
	// Prepare main sample for comparison with permutation sample on treatment status and treatment year
	use beid sampleyear treat time using dta/analysis/worker_analysis_drop7_autom.dta if time==-1, clear

	keep beid sampleyear treat
	bys beid sampleyear treat: keep if _n==1
	rename sampleyear sampleyear_main
	rename treat treat_main

	sort beid
	compress
	save dta/intermediate/permutation_mainsample.dta, replace
}

// Select firms that we observe at least 8 consecutive years in the admin data, and that are at least 3 times in the PS data
** This is the firm_level_data from create_samples
{
	use dta/intermediate/firm_level_data_autom.dta , clear

	gegen firmid=group(beid)
	** Determine max run per firm, should be at least 8 consecutive years 
	tsset firmid year
	sort firmid year
	tsspell, f(L.year==.)
	bys firmid: gegen maxrun = max(_seq)	
	keep if maxrun>=8
	drop _spell _seq _end maxrun
	distinct beid

	keep beid year gk_manual sbi2008_1dig nr_workers_mar
	compress
	save dta/intermediate/firms_permutation.dta, replace
	keep beid
	duplicates drop
	save dta/intermediate/beid_permutation.dta, replace
}

// Expand the sample X-fold with X at 100
{
	use dta/intermediate/firms_permutation.dta, clear
	bys beid: gen n=1 if _n==1
	expand 100 // X = 100
	bys beid year: gen q=_n // identifier for each 'expanded sample'
	gegen firmid = group(beid q)
	drop q n
	bys firmid: gen byte n=1 if _n==1
	compress
	save dta/intermediate/firms_expanded.dta, replace
}

