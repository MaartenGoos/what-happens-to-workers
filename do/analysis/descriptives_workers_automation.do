*------------------------------------------------------------------------
* Automation
* descriptives.do
* 25/10/2018
* 28/5/2019: Updated using new data
* 5/7/2020 (v2):	Removed recent hires
* Wiljan van den Berge
* Purpose: descriptives for worker sample
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
log using log/descriptives_workers_automation, text replace
*--------------------------------------------------------------------------


foreach group in inc rh{
	* Load data
	use dta/analysis/worker_analysis_drop7_autom.dta if `group' == 1, clear

	tab sector_treatyr, gen(sec)
	tab gk_treatyr, gen(size)
	tab educ, gen(edu)

	gen wage_emp=exp(lnwage) if !missing(lnwage)

	label var female "Share female"
	label var earnings "Total earnings"
	label var wage_emp "Daily wage if employed"
	label var lnwage "Ln(daily wage)"
	label var nonemp "Non-employment duration"
	label var tbenefits "Total benefits"
	label var early "Early retirement"
	label var selfemp "Self-employed"
	label var foreign "Foreign born or foreign-born parents"
	label var age "Age"
	label var age2 "Age^2"
	label var year "Calendar year"
	label var sec1 "Manufacturing"
	label var sec2 "Construction"
	label var sec3 "Wholesale and retail trade"
	label var sec4 "Transportation and storage"
	label var sec5 "Accommodation and food serv"
	label var sec6 "Information and communication"
	label var sec7 "Prof scientific techn act"
	label var sec8 "Admin and support act"
	label var leave "Leaves the spiking firm"
	label var size1 "0-19 employees"
	label var size2 "20-49 employees"
	label var size3 "50-99 employees"
	label var size4 "100-199 employees"
	label var size5 "200-499 employees"
	label var size6 ">=500 employees"
	label var edu1 "Missing education"
	label var edu2 "Low education"
	label var edu3 "Middle education"
	label var edu4 "High education"

	est clear

	global varlist "earnings wage_emp nonemp leave2 tbenefits early selfemp female foreign age age2 year sec1-sec8 size1-size6 edu1-edu4"

	// All observations, all periods, unweighted [Column 1 of Table E.2]
	estpost summarize $varlist 
	est sto des

	esttab des using output/des_fullsample_`group'.csv, replace nogaps nolines nostar ///
		main(mean 2) aux(sd 2) label  ///
		note("Unweighted means for the full regression sample. Standard deviations in parentheses")

	est clear

	// Weighted [regression sample]	at t=-1 [Columns 2 and 3 of Table E.2]
	forvalues t=0/1{
		estpost summarize $varlist ///
			[aweight=weight1] if treat==`t' & time==-1
		est sto des_`t'
	}

	esttab des_1 des_0 using output/des_sample_weighted_`group'.csv, replace nogaps nolines nostar ///
		main(mean 2) aux(sd 2) label mtitle("Treated" "Control") ///
		note("Weighted means for the full regression sample at time=-1. Standard deviations in parentheses")

	est clear
}
