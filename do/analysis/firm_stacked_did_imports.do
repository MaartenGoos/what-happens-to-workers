*-----------------------------------------------------------------------------------------------------------------------------------
* Automation
* Anna Salomons & Wiljan van den Berge
* Purpose: Compare firms with automation spikes and firms with automation imports
* Output: reg_imports_lnsize; pp_imports_table_weight3; firmdid_imports_coeff
*-----------------------------------------------------------------------------------------------------------------------------------


*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16
set more off
clear all
capture log close
sysdir set PLUS M:\Stata\Ado\Plus 

cd H:/automation/
log using log/firm_stacked_did_imports, text replace
*--------------------------------------------------------------------------

*-----------------------------------------------------------------------------------
* 1. Prepare data
*-----------------------------------------------------------------------------------

use dta/intermediate/firmsample_autom.dta, clear 

// Define ever-treated status
sort beid year
by beid: egen t_spike = total(spike_firm)
gen treat_spike= t_spike>0

// Merge in firms' automation importer status
merge m:1 beid using dta/intermediate/beid_import_dummies
assert _merge!=2
drop if _merge!=3 // drop firms whose data ends before 2010
drop _merge

// 3 outcomes: employment, daily wage, wagebill
gen ln_emp = ln(nr_workers_mar)
gen ln_wage = ln(mn_dwage)
gen ln_wb = ln(nr_workers_mar*mn_dwage)

egen firmid=group(beid)
tsset firmid year

gen manuf=sbi2008_1dig==1
egen sec2dig=group(sbi2008_2dig)

* generate number of obs per firm
local i=1
bys beid: egen t_i=total(`i')

gen weight2=1/t_i
gen weight3=weight2*nr_workers_mar

bys firmid: egen max_year=max(year)
bys firmid: egen min_year=min(year)

gen ln_emp1 = ln_emp if year==min_year
gen ln_wage1 = ln_wage if year==min_year
gen ln_wb1 = ln_wb if year==min_year

foreach var of varlist ln_emp1 ln_wage1 {
	gsort firmid -`var'
	by firmid: replace `var'=`var'[_n-1] if missing(`var')
}
global x i.sec2dig ln_emp1 ln_wage1 // defining controls (sector dummies, initial employment and wage levels)

gen drop=1 if missing(ln_wage1) | missing(ln_emp1) | missing(sec2dig)
gsort firmid -drop
by firmid: replace drop=drop[_n-1] if missing(drop)
drop if drop==1

drop if missing(ln_emp)
drop if missing(ln_wage)
drop if missing(weight2)
drop if missing(weight3)


*-----------------------------------------------------------------------------------
* 2. Firm-level descriptives on importer status & firm size
*-----------------------------------------------------------------------------------

preserve 

collapse (mean) aut_imp aut_nimp aut_imp2 aut_nimp2 bot_imp bot_nimp bot_imp2 bot_nimp2 nr_workers_mar treat_spike (max) spike_firm, by(beid sbi2008_1dig sec2dig)
assert treat_spike == spike_firm

foreach var in treat_spike aut_imp aut_nimp {
	table `var', c(mean nr_workers_mar med nr_workers_mar sd nr_workers_mar min nr_workers_mar max nr_workers_mar)
}


foreach var in treat_spike aut_imp {
	estpost sum nr_workers_mar if `var'==0, det
	esttab using output/des_imports_size.csv, append nogaps compress nolines  ///
			cells("mean p50 sd count") noobs title("Firm size for `var'==0") ///
			addnote("Count is number of observations.")
	estpost sum nr_workers_mar if `var'==1, det
	esttab using output/des_imports_size.csv, append nogaps compress nolines  ///
			cells("mean p50 sd count") noobs title("Firm size for `var'==1") ///
			addnote("Count is number of observations.")
}
		
gen lnemp = ln(nr_workers_mar)

foreach var in treat_spike aut_imp {
	reg lnemp `var'
		est store est1_`var'
	areg lnemp `var', absorb(sec2dig)
		est store est2_`var'
}
	esttab est1_treat_spike est2_treat_spike est1_aut_imp est2_aut_imp
	
	* Exporting results
	cap erase output/reg_imports_lnsize.csv
		esttab est1_treat_spike est2_treat_spike est1_aut_imp est2_aut_imp using output/reg_imports_lnsize.csv, append nogaps compress nolines  ///
			title("Regression of log employment on importer dummies at the firm-level") ///
			keep(`var') star(* 0.1 ** 0.05 *** 0.01) not main(b) aux(se) ///
			coeflabels(`var' "Dummy for `var'") mtitles("No controls" "1-digit sector FE" "2-digit sector FE") ///
			addnote("Dep var is firm-level log employment.")

restore


*-----------------------------------------------------------------------------------
* 3. Firm-level cross-sectional comparisons of employment and wage
*-----------------------------------------------------------------------------------

* Annual differences; models for firms with and without automation spikes
est clear
tsset firmid year

foreach weight in weight3 {
	foreach var of varlist ln_emp ln_wage ln_wb {
			reg D.`var' treat_spike i.year $x [pweight=`weight'], cl(firmid) 
			est sto `var'_x_`weight'
		}
		esttab *_x_`weight', nogaps compress nolines  ///
			keep(treat_spike) indicate(Controls=ln_emp1) star(* 0.1 ** 0.05 *** 0.01) not main(b) aux(se) ///
			coeflabels(treat_spike "Automating") mtitles("d ln(emp)" "d ln(daily wage)" "d ln(wage bill)" "d ln(emp)" "d ln(daily wage)" "d ln(wage bill)")
	}

	
foreach weight in weight3 {
		* Displaying results
		esttab *_x_`weight', nogaps compress nolines  ///
			title("Results for firms with automation spikes") ///
			keep(treat_spike) indicate(Controls=ln_emp1) star(* 0.1 ** 0.05 *** 0.01) not main(b) aux(se) ///
			coeflabels(treat_spike "Automating") mtitles("d ln(emp)" "d ln(daily wage)" "d ln(wage bill)" "d ln(emp)" "d ln(daily wage)" "d ln(wage bill)") ///
			addnote("Weighted by 1/nr of firm-year observations * firm-level employment.")
		
		* Exporting results
		esttab *_x_`weight' using output/pp_imports_table_`weight'.csv, replace nogaps compress nolines  ///
			title("Results for firms with automation spikes") ///
			keep(treat_spike) indicate(Controls=ln_emp1) star(* 0.1 ** 0.05 *** 0.01) not main(b) aux(se) ///
			coeflabels(treat_spike "Automating") mtitles("d ln(emp)" "d ln(daily wage)" "d ln(wage bill)" "d ln(emp)" "d ln(daily wage)" "d ln(wage bill)") ///
			addnote("Weighted by 1/nr of firm-year observations * firm-level employment.")
	}


* Annual differences; models for firms with and without (net) automation imports 
est clear
rename aut_imp autimp
rename aut_nimp nautimp

foreach treat in aut naut { 

foreach weight in weight3 {
	foreach var of varlist ln_emp ln_wage ln_wb {
			reg D.`var' `treat'imp i.year $x [pweight=`weight'], cl(firmid) 
			est sto `treat'`var'_x_`weight'
		}
		esttab `treat'*_x_`weight', nogaps compress nolines  ///
			keep(`treat'imp ) indicate(Controls=ln_emp1) star(* 0.1 ** 0.05 *** 0.01) not main(b) aux(se) ///
			coeflabels(`treat'imp  "Importer") mtitles("d ln(emp)" "d ln(daily wage)" "d ln(wage bill)" "d ln(emp)" "d ln(daily wage)" "d ln(wage bill)") ///
			addnote("Importer defined as `treat' importer." ///
			"Weighted by 1/nr of firm-year observations * firm-level employment.")
	}
	}

foreach treat in aut naut { 
foreach weight in weight3 {
	* Displaying results
	esttab `treat'*_x_`weight', nogaps compress nolines  ///
			title("Results for firms with non-zero `treat' imports") ///
			keep(`treat'imp ) indicate(Controls=ln_emp1) star(* 0.1 ** 0.05 *** 0.01) not main(b) aux(se) ///
			coeflabels(`treat'imp  "Importer") mtitles("d ln(emp)" "d ln(daily wage)" "d ln(wage bill)" "d ln(emp)" "d ln(daily wage)" "d ln(wage bill)") ///
			addnote("Importer defined as `treat' importer." ///
			"Weighted by 1/nr of firm-year observations * firm-level employment.")
			
	* Exporting results
	esttab `treat'*_x_`weight' using output/pp_imports_table_`weight'.csv, append nogaps compress nolines ///
			title("				" "Results for firms with non-zero `treat' imports") ///  
			keep(`treat'imp ) indicate(Controls=ln_emp1) star(* 0.1 ** 0.05 *** 0.01) not main(b) aux(se) ///
			coeflabels(`treat'imp  "Importer") mtitles("d ln(emp)" "d ln(daily wage)" "d ln(wage bill)" "d ln(emp)" "d ln(daily wage)" "d ln(wage bill)") ///
			addnote("Importer defined as `treat' importer." ///
			"Weighted by 1/nr of firm-year observations * firm-level employment.")
	}
	}
	

*-----------------------------------------------------------------------------------
* 4. Prepare data for DiD event study 
*-----------------------------------------------------------------------------------

use dta/analysis/firm_analysis_autom_drop.dta, clear

// Merge in firms' automation importer status
merge m:1 beid using dta/intermediate/beid_import_dummies
drop if _merge==1 // firms that do not exist after 2009
keep if _merge==3
drop _merge

// Calculate weight: number of workers at t=-1
gen weight=nr_workers_mar if time==-1
gsort firmid -weight
by firmid: replace weight=weight[_n-1] if missing(weight)

// Generate outcome variables
gen emp = ln(nr_workers_mar)
gen wage = ln(mn_daily_wage)
gen wb = ln(nr_workers_mar*mn_daily_wage)

xtset firmid time
replace time=time+4



*-----------------------------------------------------------------------------------
* 5. Firm-level DiD event studies of employment, wage, and wagebill growth
*-----------------------------------------------------------------------------------

label var emp "Log employment"
label var wage "Log daily wage"
label var wb "Log wagebill"

* Baseline estimates for all firms with automation spikes (but for subsample of years where we also observe automation imports)
tab time, gen(t)
est clear 

	foreach var of varlist wage emp wb {
		reghdfe `var' 1.(t1-t2)#1.treat 1.(t4-t8)#1.treat [aweight=weight], absorb(firmid year time)
		gen n_`var'=`e(N)'
		est sto `var'
	}

coefplot *, vertical omitted baselevels  keep(1.t*#1.treat) ///
				relocate(1.t1#1.treat=-3 1.t2#1.treat=-2 1.t4#1.treat=0 1.t5#1.treat=1 1.t6#1.treat=2 1.t7#1.treat=3 1.t8#1.treat=4 1.t9#1.treat=5 1.t10#1.treat=6 1.t11#1.treat=7 1.t12#1.treat=8) ///
				xline(0, lcolor(black) lpattern(dash)) yline(0, lcolor(black) lpattern(dash)) xlabel(-3(1)4)  ///
				xtitle("Year relative to year of first spike (ref category = -1)") ytitle() ///
				recast(connected) ciopts(recast(rcap)) graphregion(color(white)) ///
				offset(0) generate(v_) replace 
	
		preserve
				keep v_* n_*
				rename v_* *
				drop if missing(by)
				keep plot at b se df pval ll1 ul1 n_*
				decode plot, gen(var)
				gen sample = "all spiking firms"
				compress
				save output/firmdid_imports_coeff.dta, replace
		restore				
	drop n_wage - v_ul1 				
				
				
* Estimates for subsamples of firms with automation spikes and also automation imports
est clear
foreach imp in aut_imp {
foreach var of varlist wage emp wb {
		reghdfe `var' 1.(t1-t2)#1.treat 1.(t4-t8)#1.treat [aweight=weight] if `imp'==1, absorb(firmid year time)
	gen n_`var'=`e(N)'
	est sto `var'
}

	coefplot *, vertical omitted baselevels  keep(1.t*#1.treat) ///
			relocate(1.t1#1.treat=-3 1.t2#1.treat=-2 1.t4#1.treat=0 1.t5#1.treat=1 1.t6#1.treat=2 1.t7#1.treat=3 1.t8#1.treat=4 1.t9#1.treat=5 1.t10#1.treat=6 1.t11#1.treat=7 1.t12#1.treat=8) ///
				xline(0, lcolor(black) lpattern(dash)) yline(0, lcolor(black) lpattern(dash)) xlabel(-3(1)4)  ///
				xtitle("Year relative to year of first spike (ref category = -1)") ytitle() ///
				recast(connected) ciopts(recast(rcap)) graphregion(color(white)) ///
				note("Treat = firms with automation spike and `imp'==1") ///
				offset(0) generate(v_) replace 
		
				preserve
					keep v_* n_*
					rename v_* *
					drop if missing(by)
					keep plot at b se df pval ll1 ul1 n_*
					decode plot, gen(var)
					gen sample = "`imp'"
					compress
					append using output/firmdid_imports_coeff.dta
					save output/firmdid_imports_coeff.dta, replace
				restore		
	est clear
	drop n_wage - v_ul1 
}

* Remove observations with fewer than 10 df from output (disclosure rules)
use output/firmdid_imports_coeff.dta, clear
	tab sample if df<10 
	drop if df<10 
	assert df>=10
save output/firmdid_imports_coeff.dta, replace				
				
* erase temp files 
cap erase output/coeff_temp.dta


cap log close