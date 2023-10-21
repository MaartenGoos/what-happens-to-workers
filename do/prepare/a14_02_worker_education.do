*------------------------------------------------------------------------
* Automation
* worker_education.do
* 2/5/2018
* Wiljan van den Berge
* Purpose: merge highest level of education for each person in our sample
*-------------------------------------------------------------------------


*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16
set more off
clear all
* No separate log, this is part of worker_job_polis.do

cd H:/automation/
*--------------------------------------------------------------------------


forvalues y=1999/2016{
	use dta\intermediate\rinpersoon.dta, clear
	if `y'>=1999 & `y'<=2005{
		merge 1:1 rinpersoons rinpersoon using "G:/Onderwijs/HOOGSTEOPLTAB/`y'/geconverteerde data/120726 HOOGSTEOPLTAB `y'V1.dta", keep(match master) keepusing(oplnrhb) nogen
	}

	if `y'>=2006 & `y'<=2009{
		merge 1:1 rinpersoons rinpersoon using "G:/Onderwijs/HOOGSTEOPLTAB/`y'/geconverteerde data/120619 HOOGSTEOPLTAB `y'V1.dta", keep(match master) keepusing(oplnrhb) nogen
	}

	if `y'==2010{
		merge 1:1 rinpersoons rinpersoon using "G:/Onderwijs/HOOGSTEOPLTAB/`y'/geconverteerde data/120918 HOOGSTEOPLTAB `y'V1.dta", keep(match master) keepusing(oplnrhb) nogen
	}

	if `y'==2011{
		merge 1:1 rinpersoons rinpersoon using "G:/Onderwijs/HOOGSTEOPLTAB/`y'/geconverteerde data/130924 HOOGSTEOPLTAB `y'V1.dta", keep(match master) keepusing(oplnrhb) nogen
	}

	if `y'==2012{
		rename *, upper
		merge 1:1 RINPERSOONS RINPERSOON using "G:/Onderwijs/HOOGSTEOPLTAB/`y'/geconverteerde data/141020 HOOGSTEOPLTAB `y'V1.dta", keep(match master) keepusing(OPLNRHB) nogen
		rename *, lower
	}
	if `y'>=2013 & `y'<=2015{
		merge 1:1 rinpersoons rinpersoon using "G:/Onderwijs/HOOGSTEOPLTAB/`y'/geconverteerde data/HOOGSTEOPL`y'TABV3.dta", keep(match master) keepusing(oplnrhb) nogen
	}
	if `y'==2016{
		merge 1:1 rinpersoons rinpersoon using "G:/Onderwijs/HOOGSTEOPLTAB/`y'/geconverteerde data/HOOGSTEOPL`y'TABV2.DTA", keep(match master) keepusing(oplnrhb) nogen
	}
			
	gen year=`y'
	rename oplnrhb oplnr
	merge m:1 oplnr using "K:\Utilities\Code_Listings\SSBreferentiebestanden\Geconverteerde data\OPLEIDINGSNRREFV28.dta", keep(match master) keepusing(SOI2016NIVEAU) nogen

	rename *, lower
	destring soi2016niveau, force replace
	drop oplnr
	compress
	save dta\intermediate\rin_education`y'.dta, replace
}

use dta\intermediate\rin_education1999.dta, clear
forvalues y=2000/2016{
	append using dta\intermediate\rin_education`y'.dta
}


compress
save dta\intermediate\rin_education9916.dta, replace

*Drop temp files
forvalues y=1999/2016{
	rm dta\intermediate\rin_education`y'.dta
}
