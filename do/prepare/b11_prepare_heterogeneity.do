*------------------------------------------------------------------------
* Automation
* prepare_heterogeneity
* 3/7/2020: split up preparation and analysis
* Wiljan van den Berge
* Purpose: Heterogeneity analysis for main sample
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
log using log/prepare_heterogeneity, text replace
*--------------------------------------------------------------------------

* Load main analysis data
use dta/analysis/worker_analysis_drop7_autom.dta if weight1!=0 & weight1!=. & inc==1, clear

* Merge quartiles
merge m:1 id using dta/intermediate/quartiles_autom.dta, keep(match master) nogen

gen post = time>=0

* Generate age groups
egen age_cat = cut(age) if time==-1, at(20,30,40,50,61)

* Generate sector and firm size categories
gen sector_cat = sector_treatyr 
gen size_cat = gk_treatyr

* Define flexible employment conditions
gen flex = 1 if (soortbaan==2 | soortbaan==4 | soortbaan==5) & time==-1
replace flex = 0 if (soortbaan==9 | soortbaan==1 | soortbaan==3) & time==-1
	
* Define maximum age so we can restrict sample to <55 yr old workers
bys id: egen max_age=max(age)

* Recession indicator: 2003, 2008, 2009, 2011, 2012
gen rec = sampleyear==2003 | sampleyear==2008 | sampleyear==2009 | sampleyear==2011 | sampleyear==2012

* Firm size indicator: top or not top quartile
rename beid beid_hlp
rename treatbeid_incumbent beid
merge m:1 beid year using dta/intermediate/beid_manual_gk_mar_all.dta, keep(match master) nogen
rename beid treatbeid_incumbent
rename beid_hlp beid

	preserve
		keep if time==-1
		keep treatbeid_incumbent year nr_workers_mar sector_treatyr
		duplicates drop
		gen firmsizequart=.
		forval i=1/8{
			sum nr_workers_mar if sector_treatyr==`i', det
			replace firmsizequart=1 if sector_treatyr==`i' & nr_workers_mar>=`r(p75)'
		}
		replace firmsizequart=0 if missing(firmsizequart)
		keep treatbeid_incumbent firmsizequart year
		duplicates drop
		save dta/intermediate/temp_heterogeneity_firmsize.dta, replace
	restore
merge m:1 year treatbeid_incumbent using dta/intermediate/temp_heterogeneity_firmsize.dta, keep(match master) nogen		


foreach var of varlist age_cat flex firmsizequart{
	bys id: ereplace `var' = max(`var')
}

		
// Keep only relevant variables
keep firmid_inc id /// ID variables
	age age2 sector_treatyr gk_treatyr year  /// Control variables
	time treat weight1 /// Main regression variables and matching weight
	earnings relearn leave leave2 leave_old nonemp tbenefits selfemp early lnwage /// Main outcomes
	age_cat flex rec max_age educ sector_cat size_cat post quart_res quart_age quart_age_firm female foreign firmsizequart // Heterogeneity variables

compress
save dta/analysis/worker_analysis_drop7_autom_heterogeneity.dta, replace

* Remove temporary files
rm dta/intermediate/temp_heterogeneity_firmsize.dta
rm dta/intermediate/quartiles_autom.dta