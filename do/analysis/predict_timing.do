*------------------------------------------------------------------------
* Automation
* predict_timing.do
* 4/7/2020: Updated, cleaned up code
* Purpose: try to predict spike timing using observables
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
log using log/predict_timing, text replace
*--------------------------------------------------------------------------
*****************
*** TABLE E.3 ***
*****************

* Predict spike timing
/*
Steps:
1. Define k test and training samples by firm, without replacement
2. Run xtlogit on training sample, then predict on test sample
3. Calculate accuracy of predictions for each iteration using Brier skill scores
*/

use dta\intermediate\firm_level_data_autom.dta, clear

egen firmid=group(beid)
xtset firmid year



// ASSUME: no spike in years where we don't observe the firm in the PS
replace spike_firm_first = 0 if missing(spike_firm_first)
by firmid: egen tspike=total(spike_firm_first)
distinct firmid
drop if tspike==0 

// Define test samples: draw 10 test samples (10% random sample) without replacement
sort firmid year
by firmid: gen n=1 if _n==1
set seed 20011987

gen random=runiform(0,1) if n==1
by firmid: replace random=random[_n-1] if missing(random)

forval k=1/10{
	local j=`k'/10
	local i=(`k'-1)/10
	gen test`k'=random>`i' & random<=`j'
}

foreach var of varlist  mn_wage mn_age nr_workers_mar wagebill mn_dwage{
	replace `var'=ln(`var')
}

// Estimate three different fe models: a simple baseline model with only time-varying controls, a model containing lags, and a model with a full set of interactions
foreach model in base lag interact{
	forval k=1/10{
		if "`model'"=="base"{
			xtlogit spike_firm_first ///
			 mn_wage mn_age female nr_workers_mar wagebill mn_dwage if test`k'==0, fe 
		}
		
		if "`model'"=="lag"{
			xtlogit spike_firm_first ///
			 mn_wage mn_age female nr_workers_mar wagebill mn_dwage /// 
			L.mn_wage L.mn_age L.female L.nr_workers_mar L.wagebill L.mn_dwage ///
			L2.mn_wage L2.mn_age L2.female L2.nr_workers_mar L2.wagebill L2.mn_dwage if test`k'==0, fe 
		}
		
		if "`model'"=="interact"{
			xtlogit spike_firm_first ///
			mn_wage mn_age female nr_workers_mar wagebill mn_dwage  ///
			c.mn_wage#(c.mn_wage c.mn_age c.female c.nr_workers_mar c.wagebill c.mn_dwage) ///
			c.mn_age#(c.mn_wage c.mn_age c.female c.nr_workers_mar c.wagebill c.mn_dwage) ///
			c.female#(c.mn_wage c.mn_age c.female c.nr_workers_mar c.wagebill c.mn_dwage) ///
			c.nr_workers_mar#(c.mn_wage c.mn_age c.female c.nr_workers_mar c.wagebill c.mn_dwage) ///
			c.wagebill#(c.mn_wage c.mn_age c.female c.nr_workers_mar c.wagebill c.mn_dwage) ///
			c.mn_dwage#(c.mn_wage c.mn_age c.female c.nr_workers_mar c.wagebill c.mn_dwage) if test`k'==0, fe 
		}	
		predict pred`k' if test`k'==1, pc1
		gen n`k'=`e(N)'
		
		// Generate random prediction (using only observations that we also predict on using the model -- this is relevant for the model including lags //
		// where we can't predict for the included lags)
		gen byte c=1 if !missing(pred`k')
		bys firmid: egen total=total(c)
		gen testprob`k'=1/total if !missing(pred`k')
		drop c total
		
		// Brier scores
		brier spike_firm_first pred`k' if test`k'==1
		gen brier_pred`k'=r(brier)

		brier spike_firm_first testprob`k' if test`k'==1
		gen brier_rand`k'=r(brier)

		gen brier_skill`k'=1-(brier_pred`k'/brier_rand`k')
	}
	preserve
		keep brier* n1 n2 n3 n4 n5 n6 n7 n8 n9 n10
		duplicates drop
		gen i=1
		reshape long brier_pred brier_rand brier_skill n, i(i) j(k_sample)
		drop i
		label var n "observations"
		label var brier_pred "Brier score based on model"
		label var brier_rand "Brier score based on random"
		label var brier_skill "Brier skill score"
		label var k_sample "K-fold sample"
		save output/brier_skill_`model'.dta, replace
	restore
	drop pred* brier* testprob* n1 n2 n3 n4 n5 n6 n7 n8 n9 n10
}

****************
*** TABLE D1 ***
****************

/* Correlates of ever having an automation spike */
use dta\intermediate\firm_level_data_never_autom.dta, clear

gen ever_spike = 1 if spike_firm==1
gsort beid -ever_spike
by beid: replace ever_spike=ever_spike[_n-1] if missing(ever_spike)
replace ever_spike=0 if missing(ever_spike)

* Calculate time-invariant averages by firm
bys beid: egen mean_wage=mean(mn_wage)
bys beid: egen mean_nr_workers=mean(nr_workers_mar)
bys beid: egen mean_female=mean(female)
bys beid: egen mean_age=mean(mn_age)
bys beid: egen share_high = mean(edu4)

replace mean_wage = mn_wage/1000
replace mean_nr_workers =  nr_workers_mar/1000

* Keep one observation per firm
bys beid: keep if _n==1

reg ever_spike mean_wage mean_female mean_age share_high i.gk_manual i.sbi2008_1dig
est sto ever_spike1

esttab ever_spike1 using output/ever_spike_reg.csv, replace compress nolines nogaps not se(4) b(4) star(* 0.1 ** 0.05 *** 0.01) ///
coeflabels(mean_age "Mean age" mean_female "Share women" mean_wage "Mean real yearly wage / 1000" ///
mn_nr_workers "Mean number of workers / 1000" mn_nr_workers2 "Mean number of workers / 1000 squared" share_high "Share high educated") label mtitles("Baseline")

