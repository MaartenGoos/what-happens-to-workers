*------------------------------------------------------------------------
* Automation
* 20200706, updated 20210615, 20210809, 20211203 and 20211228
* Anna Salomons
* Purpose: Create sumstats on imports of robots and other automation-related intermediates, and correlate with automation costs
* Output: des_imports_tot; des_imports_ind; des_imports_firmspike; des_imports_firmyear; des_imports_firmspike_year
*-------------------------------------------------------------------------

*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16
set more off
clear all
capture log close
sysdir set PLUS M:\Stata\Ado\Plus 

cd H:/automation/
log using log/descriptives_imports, text replace
*--------------------------------------------------------------------------

		*preliminaries: collapse automation data to firm-level, save temporary dataset
		use dta/intermediate/firmsample_autom, clear
		gcollapse (mean) automation_real totalcosts_real automation_tocosts nr_workers_mar (max) spike_firm, by(beid sbi2008_1dig)
		drop automation_tocosts 
		gen automation_tocosts = automation_real / totalcosts_real 
		compress
		save dta\temp\temp_firmaut, replace
		
*--------------------------------------------------------------------------		
* 1. Create firm-year level importer/exporter dataset	
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
	
	* remove firm-year duplicates
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
	
	* Total imports, export, re-exports by year; and nr of firm observations
	preserve
		gen n = 1
		gcollapse (sum) n imp_AR_aut2 exp_AR_aut2 reexp_AR_aut2, by(year)
		save output\des_imports_tot, replace
	restore
	save dta\temp\temp_firmimport, replace

	
	
*----------------------------------------------------------------------------------------------------		
*2. Merge with automation data at firm level
*----------------------------------------------------------------------------------------------------
use dta\temp\temp_firmimport, clear		
	
	*remove firm duplicates	
	keep beid year m* /**_nonzero	*/ 
	duplicates drop beid, force
	drop year
	
	merge 1:m beid using dta\temp\temp_firmaut // firms with automation expenditures & spikes 
	drop if _merge==1 // drop firms not in automation data 
	tab _merge // about 60% of firm observations of automation firms are not importers/exporters
	gen merge=1 if _==3 // mark overlapping sample of automation data and import data, years 2010-2019 for firms observed in both import & automation data
	drop _
	recode merge (.=0)
	sum merge // around 40% of firm automation observations are in the importer/exporter database

	// Merge in firms' automation importer status, in order to remove firms which cease operations before 2010
	merge 1:1 beid using dta/intermediate/beid_import_dummies	
		drop if _merge==1 // drop firms not in import data which cease to operate before 2010
		assert _merge!=2 
		drop _merge	
	sum merge // around 48% of firm automation observations are in the importer/exporter database
	drop impexp - bot_nimp3
	
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
	
	* rescale automation & total costs (they are in 1000s)
	replace automation_real  = automation_real *1000
	replace totalcosts_real = totalcosts_real *1000
	
	*scale imports by costs, same as for automation; multiply by 100
	foreach var in AR AR_aut AR_aut2 AR_robot {
		gen `var'_tocosts = (mimp_`var' / totalcosts_real) *100
		gen `var'_nettocosts = (mnetimp_`var' / totalcosts_real) *100
	}	
	replace automation_tocosts = (automation_real/totalcosts_real) *100
	
	*****************************************************************************
	* Mean firm-level automation expenditures and imports by one-digit industry *
	*****************************************************************************

	table sbi2008, c(mean automation_tocost mean AR_aut2_tocosts mean AR_aut2_nettocosts) format(%9.5f)
		
	preserve
		gen n = 1
		collapse (sum) n (mean) automation_tocosts AR_aut2_tocosts  AR_aut2_nettocosts, by(sbi2008)
	save output\des_imports_ind, replace
	restore
	
	*******************************************************
	* Models relating automation spike to importer status *
	*******************************************************
	gen lntotalcosts_real = ln(totalcosts_real)
	
	est clear
		reg spike_firm impAR_aut2_nonzero, robust  
			est store est1_AR_aut2
		xi:reg spike_firm impAR_aut2_nonzero lntotalcosts_real i.sb, robust  
			est store est2_AR_aut2
		reg spike_firm netimpAR_aut2_nonzero, robust   
			est store est3_AR_aut2
		xi:reg spike_firm netimpAR_aut2_nonzero lntotalcosts_real i.sb, robust  
			est store est4_AR_aut2		
	
	esttab est1_AR_aut2 est2_AR_aut2 est3_AR_aut2 est4_AR_aut2, ///
		keep(impAR_aut2_nonzero netimpAR_aut2_nonzero)  ///
		order(impAR_aut2_nonzero netimpAR_aut2_nonzero) /// 
		stats(N r2) se indicate(Controls =_Isbi2008_1_2) ///
		title("Dep var =  automation spike dummy;" "Models with AR_aut2 importer or net importer dummy as indep var") ///
		 coeflabels(impAR_aut2_nonzero "Imp dummy" netimpAR_aut2_nonzero "NetImp dummy") ///
		 addnotes("(Net) Importer dummy defined as having positive average firm-level (net) imports for AR_aut2. Controls are log total costs and industry fixed effects.")
			
			
	cap erase output/des_imports_firmspike.csv		
		esttab est1_AR_aut2 est2_AR_aut2 est3_AR_aut2 est4_AR_aut2 using output/des_imports_firmspike.csv, append  nogaps compress nolines ///
		keep(impAR_aut2_nonzero netimpAR_aut2_nonzero) ///
		order(impAR_aut2_nonzero netimpAR_aut2_nonzero) /// 
		stats(N r2) se indicate(Controls =_Isbi2008_1_2) ///
		title("Dep var =  automation spike dummy;" "Models with AR_aut2 importer or net importer dummy as indep var") ///
		 coeflabels(impAR_aut2_nonzero "Imp dummy" netimpAR_aut2_nonzero "NetImp dummy") ///
		 addnotes("(Net) Importer dummy defined as having positive average firm-level (net) imports for AR_aut2. Controls are log total costs and industry fixed effects.")
			
	
	
*----------------------------------------------------------------------------------------------------	
*3. Merge with automation spike data at firm-year level: can only use overlapping years, 2010-2016
*----------------------------------------------------------------------------------------------------	
use dta\temp\temp_firmimport, clear
	
	*nr of firm-level observations
	table year, c(count imp_AR count imp_AR_aut2)
	
merge 1:1 beid year using dta/intermediate/firmsample_autom.dta // firms with automation expenditures & spikes by year
	tab year if _merge==3 // merged observations are 2010-2016, keep only those years
	keep if year>=2010 & year<=2016
	drop if _merge==1 // drop firm-year observations not in automation data as spikes may happen here but we don't necessarily know about it
	gen merge=1 if _==3 // mark overlapping sample of automation data and import data, years 2010-2016 for firms observed in both import & automation data
	drop _
	recode merge (.=0)
	sum merge // around 42% of firm-year automation observations are in the importer/exporter database
		
// Merge in firms' automation importer status, in order to remove firms which cease operations before 2010
	merge m:1 beid using dta/intermediate/beid_import_dummies	
		drop if _merge==1 // drop firms not in import data which cease to operate before 2010
		drop if _merge==2 // drop importing firms not in the automation data
		drop _merge	
	sum merge // around 42% of firm automation observations are in the importer/exporter database		
		
	*set imports & exports to zero for unmerged observations 
	foreach var in imp_AR exp_AR reexp_AR imp_AR_aut exp_AR_aut reexp_AR_aut imp_AR_aut2 exp_AR_aut2 reexp_AR_aut2 imp_AR_robot exp_AR_robot reexp_AR_robot netimp_AR netimp_AR_aut netimp_AR_aut2 netimp_AR_robot {
	assert  `var'==.  if merge==0
	replace `var' = 0 if merge==0
	}
	
	* mean imports etc by firm
	drop mimp* mexp* mreexp* mnetimp* 
	foreach var in AR AR_aut AR_aut2 AR_robot {
		bysort beid: egen mimp_`var' = mean(imp_`var')
		bysort beid: egen mexp_`var' = mean(exp_`var')
		bysort beid: egen mreexp_`var' = mean(reexp_`var')
		bysort beid: egen mnetimp_`var' = mean(netimp_`var')
	}
	* flag for non-zero robot, automation, and AR imports by firm
	foreach var in AR AR_aut AR_aut2 AR_robot {
		gen imp`var'_nonzero = 1 if (imp_`var'>0)
		gen exp`var'_nonzero = 1 if (exp_`var'>0)
		gen reexp`var'_nonzero = 1 if (reexp_`var'>0)
		gen netimp`var'_nonzero = 1 if (netimp_`var'>0)
		recode *`var'_nonzero (.=0)
	}
	
	*scale imports by costs, same as for automation
		foreach var in AR AR_aut AR_aut2 AR_robot {
		gen `var'_tocosts = imp_`var' / totalcosts_real / 1000
		}
	
	* Keep only firms with >1 observation
	gen id=1
	bysort beid: egen obs=sum(id)
	drop if obs==1
	sum obs, det
	
	* Keep only firms with non-zero total costs
	drop if totalcosts_real==0


	
	*************************************************************************************************
	* Regress inverse hyperbolic sine automation expenditure onto inverse hyperbolic sine imports,  *
	* and net imports, controlling for log total costs 												*
	*************************************************************************************************
	gen lntotalcosts_real = ln(totalcosts_real)
	gen lnemp=ln(nr_workers_mar)
	gen ihs_automation_real = asinh(automation_real)
	foreach var in AR AR_aut AR_aut2 AR_robot {
		gen ihs_imp_`var' = asinh(imp_`var')
		gen ihs_exp_`var' = asinh(exp_`var')
		gen ihs_netimp_`var' = asinh(netimp_`var')
	}	
	gen ihs_totalcosts = asinh(totalcosts_real)

	est clear
	reg ihs_automation_real ihs_imp_AR_aut2 lntotalcosts_real, clus(beid)   
		est store est1
	reghdfe ihs_automation_real ihs_imp_AR_aut2 lntotalcosts_real, clus(beid) absorb(year)
		est store est2
	reghdfe ihs_automation_real ihs_imp_AR_aut2 lntotalcosts_real, clus(beid) absorb(beid)  
		est store est3
	reghdfe ihs_automation_real ihs_imp_AR_aut2 lntotalcosts_real, clus(beid) absorb(beid year)
		est store est4
		
	reg ihs_automation_real ihs_netimp_AR_aut2 lntotalcosts_real, clus(beid)     
		est store est5
	reghdfe ihs_automation_real ihs_netimp_AR_aut2 lntotalcosts_real, clus(beid) absorb(year)
		est store est6
	reghdfe ihs_automation_real ihs_netimp_AR_aut2 lntotalcosts_real, clus(beid) absorb(beid)      
		est store est7
	reghdfe ihs_automation_real ihs_netimp_AR_aut2 lntotalcosts_real, clus(beid) absorb(beid year)
		est store est8			

	esttab est1 est2 est3 est4 est5 est6 est7 est8,  ///
		keep(ihs_imp_AR_aut2 ihs_netimp_AR_aut2 lntotalcosts_real) ///
		order(ihs_imp_AR_aut2 ihs_netimp_AR_aut2 lntotalcosts_real) ///
		stats(N r2) se ///
		title("			" "Dep var =  IHS automation costs, Indep var = IHS imports or net imports")
						
	cap erase output/des_imports_firmyear.csv
		esttab est1 est2 est3 est4 ///
		using output/des_imports_firmyear.csv, append  nogaps compress nolines ///
		keep(ihs_imp_AR_aut2 lntotalcosts_real) ///
		order(ihs_imp_AR_aut2 lntotalcosts_real) ///
		stats(N r2) se  ///
		title("			" "Dep var =  IHS automation costs, Indep var = IHS imports") ///
		coeflabels(ihs_imp_AR_aut2 "Imp AR_aut2") ///
		note("Col 2 has year FE; Col 3 has firm FE; Col 4 has firm & year FE" "Se's clustered by firm")
	
		esttab est5 est6 est7 est8 ///
		using output/des_imports_firmyear.csv, append  nogaps compress nolines ///
		keep(ihs_netimp_AR_aut2 lntotalcosts_real) ///
		order(ihs_netimp_AR_aut2 lntotalcosts_real) ///
		stats(N r2) se  ///
		title("			" "Dep var =  IHS automation costs, Indep var = IHS net imports") ///
		coeflabels(ihs_netimp_AR_aut2 "NetImp AR_aut2") ///
		note("Col 2 has year FE; Col 3 has firm FE; Col 4 has firm & year FE" "Se's clustered by firm")
	
	
	*******************************************************
	* Models relating automation spike to importer status *
	*******************************************************
	*Positive (net) import values as indicator
	sum impAR_aut2_nonzero netimpAR_aut2_nonzero
	sum impAR_robot_nonzero netimpAR_robot_nonzero
	cap erase output/des_imports_firmspike_year.csv		
	
	* With firm FE
	est clear		
	qui reghdfe spike_firm impAR_aut2_nonzero, clus(beid) absorb(beid)
		est store est1
	qui reghdfe spike_firm impAR_aut2_nonzero, clus(beid) absorb(beid year)
		est store est2
	qui reghdfe spike_firm impAR_aut2_nonzero lntotalcosts_real, clus(beid) absorb(beid) 
		est store est3		
	qui reghdfe spike_firm impAR_aut2_nonzero lntotalcosts_real, clus(beid)  absorb(beid year)
		est store est4		

	qui reghdfe spike_firm netimpAR_aut2_nonzero, clus(beid) absorb(beid) 
		est store est5
	qui reghdfe spike_firm netimpAR_aut2_nonzero, clus(beid) absorb(beid year)
		est store est6
	qui reghdfe spike_firm netimpAR_aut2_nonzero lntotalcosts_real, clus(beid) absorb(beid)  
		est store est7		
	qui reghdfe spike_firm netimpAR_aut2_nonzero lntotalcosts_real, clus(beid)  absorb(beid year)
		est store est8	
	
	esttab est1 est2 est3 est4 est5 est6 est7 est8

		
	esttab est1 est2 est3 est4 est5 est6 est7 est8 using output/des_imports_firmspike_year.csv, append  nogaps compress nolines ///
		keep(impAR_aut2_nonzero netimpAR_aut2_nonzero lntotalcosts_real) ///
		order(impAR_aut2_nonzero netimpAR_aut2_nonzero lntotalcosts_real) /// 
		stats(N r2) se  ///
		title("Dep var =  automation spike dummy;" "Models with AR_aut2 importer or net importer dummy as indep var") ///
		 coeflabels(impAR_aut2_nonzero "Imp dummy" netimpAR_aut2_nonzero "NetImp dummy") ///
		 addnotes("(Net) Importer dummy defined as having positive average firm-level (net) imports for AR_aut2. Controls are year fixed effects in even columns and firm fixed effects in all columns.")	
		
	clear
	erase dta\temp\temp_firmaut.dta
	erase dta\temp\temp_firmimport.dta
	cap log close