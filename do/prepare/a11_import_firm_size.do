*------------------------------------------------------------------------
* Automation
* import_firm_size.do
* 26/4/2019: Updated to use all firms in PS/Investments data
* v2: Use only workers at the firm on Dec 1 (same as CBS definitions)
* v3: Workers at the firm on Mar 1
* 17/5/2019: Combine categories at the bottom to create 1-19
* Wiljan van den Berge
* Purpose: Calculate firm size class (GK) based on number of workers in admin data
*-------------------------------------------------------------------------
*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close

cd H:/automation/
log using log/import_firm_size, text replace
*--------------------------------------------------------------------------

global baanvarlist "rinpersoons rinpersoon aanvangbaanid eindebaanid beidbaanid"
global polisvarlist "rinpersoons rinpersoon sdatumaanvangiko sdatumeindeiko sbeid"

forvalues y=1999/2016{

	if `y'>=1999 & `y'<=2006 | `y'>=2008 & `y'<=2011{
		use $baanvarlist using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/140930 BAANKENMERKENBUS `y'V3.dta", clear
	}
	if `y'==2007 | `y'==2012{
		use $baanvarlist using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/140930 BAANKENMERKENBUS `y'V2.dta", clear
	}
	if `y'==2013{
		use $baanvarlist using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/BAANKENMERKENBUS`y'V2.dta", clear
	}
	if `y'==2014{
		use $baanvarlist using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/BAANKENMERKEN`y'BUSV2.dta", clear
	}
	if `y'==2015{
		use $baanvarlist using "G:/Arbeid/BAANKENMERKENBUS/`y'/geconverteerde data/BAANKENMERKENBUS`y'V2.dta", clear
	}
	if `y'==2016{
		use $baanvarlist using "G:/Arbeid/BAANKENMERKENBUS/geconverteerde data/BAANKENMERKENBUS`y'V1.dta", clear
	}

	rename beidbaanid beid

	gen date_start=date(aanvangbaanid,"YMD")
	gen date_end=date(eindebaanid,"YMD")
	format date_start date_end %td

	drop if date_end<mdy(3,1,`y')
	drop if date_start>mdy(3,1,`y')


	gen int year=`y'
	keep beid rinpersoon rinpersoons year
	duplicates drop
	save dta\intermediate\beid_job_mar`y'.dta, replace
}

use dta\intermediate\beid_job_mar1999.dta, clear
forvalues y=2000/2016{
	append using dta\intermediate\beid_job_mar`y'.dta
}

gen byte i=1
collapse (sum) i, by(beid year)
rename i nr_workers
recode nr_workers (0=0) (1/19=1) (20/49=2) (50/99=3) (100/199=4) (200/499=5) (500/9999999999=6), gen(gk_manual)
label define g_man 1 "1-19 employees" 2 "20-49 employees" 3 "50-99 employees" ///
	4 "100-199 employees" 5 "200-499 employees" 6 ">=500 employees"
label values gk_manual g_man
compress

rename nr_workers nr_workers_mar

save dta/intermediate/beid_manual_gk_mar_all.dta, replace

forval y=1999/2016{
	rm dta\intermediate\beid_job_mar`y'.dta
}
