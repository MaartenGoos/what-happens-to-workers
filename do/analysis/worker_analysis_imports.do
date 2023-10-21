*------------------------------------------------------------------------
* Automation
* worker_analysis_imports.do
* 5/7/2020
* Wiljan van den Berge
* Purpose: worker-level analysis of robot/automation importers vs non-importers 
*			non-dynamic: only 1 post coefficient
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
log using log/worker_analysis_imports, text replace
*--------------------------------------------------------------------------

* Load data [baseline dataset] for incumbents
use dta/analysis/worker_analysis_drop7_autom.dta if inc==1, clear

* Merge firm - import status [merge it to firm that worker is at when treated]
rename beid beid_help
rename treatbeid_incumbent beid
merge m:1 beid using dta/intermediate/beid_import_dummies.dta
rename beid treatbeid_incument
rename beid_help beid
keep if _merge==3
drop _merge 

* Use baseline weights
gen weight=weight1
drop if missing(weight)
								
* Shrink file size
keep firmid_inc id /// ID variables
female foreign age age2 sector_treatyr gk_treatyr year /// Control variables
time treat weight /// Main regression variables and matching weight
earnings relearn relwage leave2 nonemp tbenefits selfemp early lnwage /// Main outcomes
ub di welfare /// benefits
aut_imp aut_nimp bot_imp bot_nimp aut_imp2 aut_nimp2 bot_imp2 bot_nimp2 // import variables
				
global x female foreign age age2 i.sector_treatyr i.gk_treatyr i.year // Global with control variables

gen byte post=time>=0
compress

* Regressions separately for each variable, store regressions
global outcome "relearn leave2 nonemp lnwage early"
foreach imp in aut_imp2 /*aut_imp aut_nimp bot_imp bot_nimp aut_imp2 aut_nimp2 bot_imp2 bot_nimp2*/{
	foreach y of varlist $outcome{
		if "`y'"!="`leave2'"{
			areg `y' 1.treat##1.post $x [aweight=weight] if `imp'==1, cluster(firmid_inc) absorb(id)
			est sto inc_`imp'_`y'
		}
		if "`y'"=="`leave2'"{
			reg `y' 1.treat##1.post##1.`imp' $x [aweight=weight] if `imp'==1, cluster(firmid_inc)
			est sto inc_`imp'_`y'
		}
	}
}

* Regression tables
* Extensive version with SE, stars etc.
esttab inc_aut_imp2_*  using output/analysis_imports.csv, replace not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2) ///
keep(1.treat#1.post) label nogaps nolines nonotes title("Non-zero automation-related imports") ///
transform(1.treat#1.post 100*@ 100, pattern(1 1 0 1 0 1 1)) ///
mtitles("Relative earnings" "Leave" ///
"Nonemployment duration" "ln(daily wage)" "Total benefits" "Self emp" "Early retirement") ///
coeflabels(1.treat#1.post "Automation event")

foreach var in aut_nimp bot_imp bot_nimp aut_imp2 aut_nimp2 bot_imp2 bot_nimp2{
	esttab inc_`var'_* using output/analysis_imports.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2) ///
	keep(1.treat#1.post) label nogaps nolines nonotes title(`: variable label `var'') ///
	transform(1.treat#1.post 100*@ 100, pattern(1 1 0 1 0 1 1)) ///
	coeflabels(1.treat#1.post "Automation event")
}
