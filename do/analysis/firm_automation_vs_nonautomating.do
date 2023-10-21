*------------------------------------------------------------------------
* Automation
* firm_level_analyses.do
* 4/7/2020: Cleaned up code, added balancing on admin data in addition to balancing on revenue (PS) data for Figure 2
* 7/7/2020: Removed revenue from Table 1 (contrary to P&P)
* 17/7/2020: Added event study by firm size (at t=-1!). Also added event study with interaction with number of workers
* Wiljan van den Berge
* Purpose: Firm level analyses (originally done for P&P piece, then extended for main paper)
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
log using log/firm_level_analyses, text replace
*--------------------------------------------------------------------------

/* TABLE 4: Firm-level outcomes for automating vs non-automating firms */
use dta/intermediate/firmsample_autom.dta, clear 

/* Generate the necessary variables */

* Define ever-treated status [Firms with at least one spike]
sort beid year
by beid: egen t_spike = total(spike_firm)
gen treat= t_spike>0

* 4 outcomes: employment, daily wage, wagebill, revenue per worker
gen ln_emp=ln(nr_workers_mar)
gen ln_wage=ln(mn_dwage)	
gen ln_wb=ln(wagebill)
drop if missing(ln_emp) | missing(ln_wage) | missing(ln_wb)

* Generate numerical firm id 
egen firmid=group(beid)
tsset firmid year

* Generate manufacturing dummy
gen manuf=sbi2008_1dig==1

* Generate numerical 2-digit sector
egen sec2dig=group(sbi2008_2dig)

* Generate 2 types of weights: 1 over the total number of firm obs (weight2) and weight2 * firm size (weight3); we use the latter in the publication
local i=1
bys firmid: gegen t_i=total(`i')
gen weight2=1/t_i
sort firmid year
by firmid: gen base_size = nr_workers_mar if _n==1
by firmid: ereplace base_size = max(base_size)
bys firmid: egen avg_workers = mean(nr_workers_mar)
bys firmid: gen weight3=weight2*avg_workers

* Define the first and last year we observe the firm
bys firmid: gegen max_year=max(year)
bys firmid: gegen min_year=min(year)

* Define employment, revenue and wages in the first year we observe the firm
foreach var in ln_emp ln_wage{
	gen `var'1 = `var' if year == min_year
	bys firmid: ereplace `var'1=max(`var'1)		
}

* Drop firms where the data for the first year are missing
gen drop=1 if missing(ln_wage1) | missing(ln_emp1) | missing(sec2dig)
bys firmid: ereplace drop=max(drop)
drop if drop==1

* Drop observations where either revenue, employment, wage, or the weights are missing
assert !missing(ln_emp) & !missing(ln_wage) & !missing(weight2) & !missing(weight3) & !missing(ln_wb)

sort firmid year
est clear

local x i.sec2dig ln_emp1 ln_wage1
quietly{
	foreach weight in  weight3{
		foreach var of varlist ln_emp ln_wage ln_wb{

			reg D.`var' treat i.year [pweight=`weight'], cl(firmid) 
			est sto `var'_nox_`weight'
			reg D.`var' treat i.year `x' [pweight=`weight'], cl(firmid) 
			est sto `var'_x_`weight'
			reg D.`var' 1.treat##1.manuf i.year [pweight=`weight'], cl(firmid) 
			est sto `var'_nox_inter_`weight'
			reg D.`var' 1.treat##1.manuf i.year `x' [pweight=`weight'], cl(firmid)
			est sto `var'_x_inter_`weight'
		}

		esttab *_nox_`weight' *_x_`weight' using output/pp_table_`weight'.csv, replace nogaps compress nolines  ///
			keep(treat) indicate(Controls=ln_emp1) star(* 0.1 ** 0.05 *** 0.01) not main(b) aux(se) ///
			coeflabels(treat "Automating") mtitles("d ln(emp)" "d ln(daily wage)" "d ln(wagebill)" "d ln(emp)" "d ln(daily wage)" "d ln(wagebill)")

		esttab *_nox_inter_`weight' *_x_inter_`weight' using output/pp_table_`weight'.csv, append nogaps compress nolines ///
			keep(1.treat 1.treat#1.manuf) indicate(Controls=ln_emp1) ///
			star(* 0.1 ** 0.05 *** 0.01) not main(b) aux(se) ///
			coeflabels(1.treat "Automating" 1.treat#1.manuf "Automating x manufacturing") mtitles("d ln(emp)" "d ln(daily wage)" "d ln(wagebill)" "d ln(emp)" "d ln(daily wage)" "d ln(wagebill)")
	}
}



