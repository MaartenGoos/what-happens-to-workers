*------------------------------------------------------------------------
* Automation
* firm_stacked_did.do
* 30/7/2021
* Wiljan van den Berge

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

foreach wght in weight{ // Weighting by firm size or not weighting
	clear all
	save output/firm_stacked_did_`wght'_never.dta, replace emptyok
		use dta/analysis/firm_analysis_never_autom_drop.dta, clear

		* Create outcome variables
		gen ln_emp=ln(nr_workers_mar)
		gen ln_wage=ln(mn_dwage)	
		gen ln_wb=ln(wagebill)

		* Calculate weight: number of workers at t=-1

		sort firmid time
		gen base_size = nr_workers_mar if time == -1
		bys firmid: ereplace base_size = max(base_size)

		if "`wght'" == "weight"{
			gen weight=base_size
		}
		if "`wght'" == "noweight"{
			gen weight = 1
		}

		* Prepare for regressions
		replace time=time+3
		tab time, gen(t)

		est clear

		label var ln_emp "Log employment"
		label var ln_wage "Log daily wage"
		label var ln_wb "Log wagebill"
		
			est clear
			foreach var of varlist ln_emp ln_wage ln_wb{
				reghdfe `var' 1.(t1-t2)#1.treat 1.(t4-t8)#1.treat [aweight=weight], absorb(firmid year time)
				est sto `var'
			}
			gen n_size=`e(N)'


			coefplot *, vertical omitted baselevels  keep(1.t*#1.treat) ///
				relocate(1.t1#1.treat=-3 1.t2#1.treat=-2 1.t4#1.treat=0 1.t5#1.treat=1 1.t6#1.treat=2 1.t7#1.treat=3 1.t8#1.treat=4 1.t9#1.treat=5 1.t10#1.treat=6 1.t11#1.treat=7 1.t12#1.treat=8) ///
				xline(0, lcolor(black) lpattern(dash)) yline(0, lcolor(black) lpattern(dash)) xlabel(-3(1)4)  ///
				xtitle("Year relative to year of first spike (ref category = -1)") ytitle() ///
				/*recast(connected)*/ ciopts(recast(rcap)) graphregion(color(white)) ///
				offset(0) legend(rows(3) order(2 "ln(employment)" 4 "ln(daily wage)" 6 "ln(wagebill)")) generate(v_) replace 
			graph export output/firm_stacked_did_`wght'_never.pdf, replace	

			preserve
			keep v_* n_* 
			rename v_* *
			drop if missing(by)
			keep plot at b se df pval ll1 ul1 n_*
			decode plot, gen(var)
			compress
			save output/coeff_temp.dta, replace
			use output/firm_stacked_did_`wght'_never.dta, clear
			append using output/coeff_temp.dta
			save output/firm_stacked_did_`wght'_never.dta, replace
			restore
			drop n_*
} // END WEIGHT LOOP
