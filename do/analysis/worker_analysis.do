*------------------------------------------------------------------------
* Automation
* worker_analysis.do
* Last updated: 2/7/2020
* Wiljan van den Berge
* Purpose: descriptives and analysis for workers. 
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
log using log/worker_analysis, t replace

cd H:/automation/
*--------------------------------------------------------------------------

foreach sample in $samplelist{ 
	if  "`sample'"!= "autom"{
		global droplist "7"
	}
	else{
		global droplist "1 7 9 11"
	}
	foreach d in $droplist{ // Different sample selections for robustness checks
		if "`d'" == "7" & "`sample'" == "autom"{
			global weightlist "weight1 firmw tenurew sizew nowght" 
			global felist "0 1"
		}
		else{
			global weightlist "weight1"
			global felist "1"
		}
		foreach weight in $weightlist{ // Use matching weights or not [wght, nowght] or weights based on firm-level matching [firmw], tenure matching [tenurew] or firm size class [sizew]
			foreach fe in $felist{

				* Save empty files to store coefficients in
				clear 
				save output/coeff_drop`d'_`sample'_`weight'_fe`fe'.dta, replace emptyok
				save output/coeff_c_drop`d'_`sample'_`weight'_fe`fe'.dta, replace emptyok


				use dta/analysis/worker_analysis_drop`d'_`sample'.dta, clear


				gen hours_t1 = hours if time==-1
				bys id: ereplace hours_t1 = max(hours_t1)
				gen rel_hours = hours / hours_t1


				gen weight=.

				if "`weight'" == "weight1"{
					replace weight=weight1 // weight = earnings, year and sector (baseline)
				}
				else if "`weight'" == "nowght"{
					keep if !missing(weight1) // Drop if main matching weights are missing
					replace weight=1 // everyone gets the same weight (or should we weight so that treated and controls add up to the same weihgt?)
				}
				else if "`weight'" == "firmw"{
					replace weight = weight9 // Weight include matching on firm-level characteristics0
				}
				else if "`weight'" == "tenurew"{
					replace weight = weight8 // also match on tenure quantiles
				}
				else if "`weight'" == "sizew"{
					replace weight = weight7 // also match on firm size class
				}
				else{
					replace weight = `weight'
				}


				* Set varlist for otucomes. Only full set of outcomes for main sample, otherwhise only the 4 main outcomes for incumbents
				if "`sample'" == "autom" & "`weight'" == "weight1" & "`d'" == "7" & "`fe'" == "1"{
					local outcomelist "hourlywage rel_hours earnings relearn leave2 nonemp lnwage tbenefits early relwage selfemp ub di welfare"
					local grouplist "inc rh"
				}
				else{
					local outcomelist "relearn leave2 nonemp lnwage"
					local grouplist "inc"
					keep if inc == 1
				}

				// Time relative to treatment has to be positive
				replace time = time+3
				keep if time>=0


				// Label variables so that ytitle looks nice
				label var leave "Probability to leave spiking firm"
				label var leave2 "Probability to leave spiking firm (hazard like)"				
				label var earnings "Total earnings (euros)"
				label var relearn "Earnings relative to t-1"
				label var lnwage "Log of daily wage"
				label var selfemp "Probability of self-employment"
				label var tbenefits "Total benefits (euros)"
				label var nonemp "Non-employment duration (days)"
				label var early "Probability of early retirement"
				label var ub "Unemployment benefits" 
				label var di "Disability benefits"
				label var welfare "Welfare"
				label var hourlywage "Log of hourly wage"
				label var rel_hours "Hours in main job relative to t-1"



				// Shrink file size
				keep firmid* id sampleyear /// ID variables
					female foreign age age2 sector_treatyr gk_treatyr year /// Control variables
					time treat weight `grouplist' /// Main regression variables and matching weight
					`outcomelist'

				qui tab time, gen(t)

				local tmax = 5 + 3
				compress

				global x female foreign age age2 i.sector_treatyr i.gk_treatyr i.year // Global with control variables


				// Run regressions
				// FE for every var except leave2, which is hazard

				foreach var of varlist  `outcomelist'{ 
					foreach group in `grouplist'{
						* For outcomes using hours we only have data from 2006 onwards, so sampleyear from 2009 onwards. Other years from 2003 onwards
						local min_sample = 2003
						if "`var'"=="rel_hours" | "`var'"=="hourlywage"{
							local min_sample = 2009
						}		
						if `fe'==0 | "`var'"=="leave2"{
							reg `var' 1.(t1-t2)#1.treat 1.(t4-t`tmax')#1.treat 1.(t1-t2) 1.(t4-t`tmax') $x [aweight=weight] if `group'==1 & sampleyear>=`min_sample', cluster(firmid_`group')
							gen n_`group' = `e(N)'
							est sto `group'_`var'
						}
						if `fe'==1 & "`var'"!="leave2"{
							reghdfe `var' 1.(t1-t2)#1.treat 1.(t4-t`tmax')#1.treat 1.(t1-t2) 1.(t4-t`tmax') age age2 i.year [aweight=weight] if `group'==1 & sampleyear>=`min_sample', cluster(firmid_`group') absorb(id)	
							gen n_`group' = `e(N)'
							est sto `group'_`var'
						}

						* Define locals for graphs
						// y-label values so y-axes for variables correspond with different samples
						if "`var'"=="earnings"{
							local y_min=-3000
							local y_max=1000
							local y_step=1000
						}
						if "`var'"=="relearn" | "`var'"=="relearndisp" | "`var'"=="rel_hours"{
							local y_min=-0.1
							local y_max=0.05
							local y_step=0.05
						}
						if "`var'"=="leave" | "`var'"=="leave2"{
							local y_min=-0.05
							local y_max=0.1
							local y_step=0.05
						}
						if "`var'"=="nonemp"{
							local y_min=-5
							local y_max=10
							local y_step=5
						}
						if "`var'"=="nonempdisp"{
							local y_min=-30
							local y_max=50
							local y_step=10
						}
						if "`var'"=="tbenefits"{
							local y_min=-200
							local y_max=800
							local y_step=200
						}
						if "`var'"=="selfemp"{
							local y_min=-0.015
							local y_max=0.005
							local y_step=0.01
						}
						if "`var'"=="early"{
							local y_min=-0.01
							local y_max=0.02
							local y_step=0.005
						}	
						if "`var'"=="lnwage" | "`var'"=="lnwagest" | "`var'"=="lnwagele" | "`var'"=="lnwagedisp" | "`var'"=="hourlywage"{
							local y_min=-0.1
							local y_max=0.1
							local y_step=0.05
						}	
						if "`var'"=="ub" | "`var'"=="di" | "`var'"=="welfare"{
							local y_min=-50
							local y_max=250
							local y_step=50
						}

						local x_max = 5-1 // local for maximum value of X in graphs, which depends on the window post-treatment that we include

						// main plot
						coefplot, vertical omitted baselevels keep(1.t*#1.treat) ///
							relocate(1.t1#1.treat=-3 1.t2#1.treat=-2 1.t4#1.treat=0 1.t5#1.treat=1 1.t6#1.treat=2 1.t7#1.treat=3 1.t8#1.treat=4 1.t9#1.treat=5 1.t10#1.treat=6 1.t11#1.treat=7 1.t12#1.treat=8) ///
							xline(0, lcolor(black) lpattern(dash)) yline(0, lcolor(black) lpattern(dash)) xlabel(-3(1)`x_max') ylabel(`y_min'(`y_step')`y_max')  ///
							xtitle("Year relative to year of first spike (ref category = -1)") ytitle(`: variable label `var'') ///
							/*recast(connected)*/ ciopts(recast(rcap)) graphregion(color(white)) ///
							offset(0) legend(off) generate(v`var') replace
						graph export output/`var'_drop`d'_`sample'_`weight'_`group'.pdf, replace


						// save output control dummies
						coefplot, nodraw omitted baselevels keep(1.t1 1.t2 1.t4 1.t5 1.t6 1.t7 1.t8)  ///
							relocate(1.t1=-3 1.t2=-2 1.t4=0 1.t5=1 1.t6=2 1.t7=3 1.t8=4 1.t9=5 1.t10=6 1.t11=7 1.t12=8) ///
							offset(0) generate(c`var') replace

						* Save output to file
						preserve
						keep v`var'* n_*
						rename v`var'* *
						drop if missing(by)
						keep plot at b se df pval ll1 ul1 n_*
						gen var="`var'"
						compress
						save output/coeff_temp.dta, replace
						use output/coeff_drop`d'_`sample'_`weight'_fe`fe'.dta, clear
						append using output/coeff_temp.dta
						save output/coeff_drop`d'_`sample'_`weight'_fe`fe'.dta, replace
						restore

						preserve
						keep c`var'*  n_*
						rename c`var'* *
						drop if missing(by)
						keep plot at b se n_*
						rename b b_c
						rename se se_c
						gen var="`var'"
						compress
						save output/coeff_temp.dta, replace
						use output/coeff_c_drop`d'_`sample'_`weight'_fe`fe'.dta, clear
						append using output/coeff_temp.dta
						save output/coeff_c_drop`d'_`sample'_`weight'_fe`fe'.dta, replace	
						restore	

						drop v`var'* c`var'* n_*							
					} // End of regression loop (loops over recent hires and incumbents)
				} // End of var-loop					
			} // End of sample loop
		}
	}
}
