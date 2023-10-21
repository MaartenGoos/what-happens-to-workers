*-----------------------------------------------------------------------------------------------------------------------------------
* Automation
* 20200618
* Anna Salomons
* Purpose: Create dataset with firm-level indicator for being an importer of robots or other automation-related intermediates
* Output: dta/intermediate/beid_import_dummies
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
log using log/beid_imports_indicator, text replace
*--------------------------------------------------------------------------

*--------------------------------------------------------------------------		
* 1. Prepare data
*--------------------------------------------------------------------------
* Create firm-level indicator for firm not existing after 2009 (since these firms need to be dropped), save temporary dataset	
	use beid year using dta\intermediate\jobdata9916_polis.dta, clear 
	duplicates drop
	bysort beid: egen maxyear = max(year)
	label var maxyear "Last year the firm is observed"
	keep beid maxyear
	duplicates drop beid, force
	merge 1:m beid using "H:\automation\dta\intermediate\firmsample_autom.dta"
	keep if _merge==3
	drop _merge
		
* Collapse automation data to firm-level, save temporary dataset	
	gcollapse (mean) automation_real totalcosts_real automation_tocosts maxyear (max) spike_firm, by(beid sbi2008_1dig)
	replace automation_tocosts = automation_real / totalcosts_real 
	compress
save dta\temp\temp_firmaut, replace

*--------------------------------------------------------------------------		
* 2. Clean importer/exporter dataset	
*--------------------------------------------------------------------------
use dta/intermediate/robotimports_1016_selected.dta, clear

	* get rid of source country dimension
	gcollapse (sum) import export reexport, by(beid year AR AR_aut AR_aut2 AR_robot)
	
	* calculate robot, automation, and AR imports by firm-year
	foreach var in AR AR_aut AR_aut2 AR_robot {
		bysort beid year: egen imp_`var' = sum(import / (`var'==1) )
		bysort beid year: egen exp_`var' = sum(export / (`var'==1) )
		bysort beid year: egen reexp_`var' = sum(reexport / (`var'==1) )
	}
	
	*remove firm-year duplicates
	drop AR AR_aut AR_aut2 AR_robot import export reexport
	duplicates drop beid year, force
	
	* calculate mean robot, automation, and AR imports by firm
	foreach var in AR AR_aut AR_aut2 AR_robot {
		bysort beid: egen mimp_`var' = mean(imp_`var')
		bysort beid: egen mexp_`var' = mean(exp_`var')
		bysort beid: egen mreexp_`var' = mean(reexp_`var')
	}
	* calculate net imports, as difference between imports and re-exports
	foreach var in AR AR_aut AR_aut2 AR_robot {
		gen netimp_`var' = imp_`var' - reexp_`var'
		bysort beid: egen mnetimp_`var' = mean(netimp_`var')
	}
	save dta\temp\temp_firmimport, replace
	
*----------------------------------------------------------------------------------------------------		
* 3. Store firm-ids with automation events, automation imports & robot imports
* Remove firms which are not observed in importer data because firm stops existing before 2010
*----------------------------------------------------------------------------------------------------
use dta\temp\temp_firmimport, clear		
	
	*remove firm duplicates	
	keep beid year m*
	duplicates drop beid, force
	drop year
	
	merge 1:m beid using dta\temp\temp_firmaut // firms with automation expenditures & spikes 
	drop if _merge==1 // drop firm observations not in automation data
	tab _merge // about 60% of firm observations of automation firms are not importers/exporters
	gen merge = 1 if _==3 // mark overlapping sample of automation data and import data, years 2010-2016 for firms observed in both import & automation data
	sum maxyear if _merge==2 // those not in import data 
	drop if _merge==2 & maxyear<2009 // drop firms not in import data and who cease to exist before 2010
	drop _
	recode merge (.=0)
	sum merge  // around 50% of firm automation observations are in the importer/exporter database
		
	*set imports & exports to zero for unmerged observations 
	foreach var in imp_AR exp_AR reexp_AR imp_AR_aut exp_AR_aut reexp_AR_aut imp_AR_aut2 exp_AR_aut2 reexp_AR_aut2 imp_AR_robot exp_AR_robot reexp_AR_robot netimp_AR netimp_AR_aut netimp_AR_aut2 netimp_AR_robot {
		assert  m`var'==.  if merge==0
		replace m`var' = 0 if merge==0
	}

	* flag for non-zero mean robot, automation, and AR imports by firm
	foreach var in AR AR_aut AR_aut2 AR_robot {
		gen imp`var'_nonzero = 1 if (mimp_`var'>0)
		gen exp`var'_nonzero = 1 if (mexp_`var'>0)
		gen reexp`var'_nonzero = 1 if (mreexp_`var'>0)
		gen netimp`var'_nonzero = 1 if (mnetimp_`var'>0)
		recode *`var'_nonzero (.=0)
	}
	 
	*Large (net) import values as indicator
	foreach var in AR_aut2 AR_robot {
		gen imp`var'_large = 1 if mimp_`var'>=10000
		recode imp`var'_large (.=0)
		gen netimp`var'_large = 1 if mnetimp_`var'>=10000
		recode netimp`var'_large (.=0)		
	}
	 
	*Non-zero net imports minus exports values as indicator
	foreach var in AR_aut2 AR_robot {
		gen imp`var'_exp = 1 if (mimp_`var' - mexp_`var'>0)
		recode imp`var'_exp (.=0)
		gen netimp`var'_exp = 1 if (mnetimp_`var' - mexp_`var'>0)
		recode netimp`var'_exp (.=0)		
	}
	
	rename merge impexp
	keep beid *nonzero *large *_exp *spike_firm impexp
	rename impAR_nonzero imp
	drop *AR_nonzero *AR_aut_* exp* reexp* // drop exports, re-exports, and the broader measures (AR, and AR_aut)
	
	label var impexp "=1 if firm exists in AR importer/exporter dataset"
	label var imp "=1 if firm has any AR imports"
	
	rename impAR_aut2_nonzero aut_imp
	rename netimpAR_aut2_nonzero aut_nimp
	rename impAR_robot_nonzero bot_imp
	rename netimpAR_robot_nonzero bot_nimp

	label var aut_imp "=1 if firm has non-zero automation-related imports"
	label var aut_nimp "=1 if firm has non-zero automation-related net imports"
	label var bot_imp "=1 if firm has non-zero robot imports"
	label var bot_nimp "=1 if firm has non-zero robot net imports"
	
	rename impAR_aut2_large aut_imp2
	rename netimpAR_aut2_large aut_nimp2
	rename impAR_robot_large bot_imp2
	rename netimpAR_robot_large bot_nimp2

	label var aut_imp2 "=1 if firm has annual average automation-related imports over 10,000 euros"
	label var aut_nimp2 "=1 if firm has annual average automation-related net imports over 10,000 euros"
	label var bot_imp2 "=1 if firm has annual average robot imports over 10,000 euros"
	label var bot_nimp2 "=1 if firm has annual average robot net imports over 10,000 euros"
	
	rename impAR_aut2_exp aut_imp3
	rename netimpAR_aut2_exp aut_nimp3
	rename impAR_robot_exp bot_imp3
	rename netimpAR_robot_exp bot_nimp3

	label var aut_imp3 "=1 if firm has non-zero automation-related imports minus exports"
	label var aut_nimp3 "=1 if firm has non-zero automation-related net imports minus exports"
	label var bot_imp3 "=1 if firm has non-zero robot imports minus exports"
	label var bot_nimp3 "=1 if firm has non-zero robot net imports minus exports"
	
	compress
	save dta/intermediate/beid_import_dummies, replace
	
	clear
	erase dta\temp\temp_firmaut.dta
	erase dta\temp\temp_firmimport.dta
	cap log close