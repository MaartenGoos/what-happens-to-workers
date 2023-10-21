*------------------------------------------------------------------------
* Automation
* investeringen_merge.do
* 20/11/2018: Updated; added investments in 2016 and 2017
* 14/5/2019: Added new investments file version for 2016 (v3) and 2017 (v2)
* 6/1/2020: Added 2018 investments file
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
log using log/investeringen_merge, text replace
*--------------------------------------------------------------------------
* Add  (totals of)
* grond, water en wegenbouwkundig: c004004 = ALOEU01NR3
* Personenauto's: c005004 = part of ALOEU01NR4
* Overige materiele vaste activa: c013004 = ALOEU01NR8
* Overige immateriele vaste activa: c016004 = not observed, like software

forvalues y=2000/2016{
	if `y'>=2000 & `y'<=2006{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/090129 Investeringen_main `y'V1.dta", clear
	}
	if `y'==2007{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/091028 Investeringen_main `y'V1.dta", clear
	}	
	if `y'==2008{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/101018 Investeringen_main `y'V1.dta", clear
	}	
	if `y'==2009{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/111027 Investeringen_main `y'V1.dta", clear
	}	
	if `y'==2010{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/121010 Investeringen_main `y'V1.dta", clear
	}	
	if `y'==2011{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/Investeringen_main `y'V3.dta", clear
	}	
	if `y'==2012{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/Investeringen_nationaal`y'V2.dta", clear
	}	
	if `y'>=2013 & `y'<=2015{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/Investeringen_nationaal`y'V1.dta", clear
	}	
	if `y'==2016{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/Investeringen_nationaal`y'V3.dta", clear
	}	
	if `y'==2017{
		use "G:/Bedrijven/INVESTERINGEN/`y'/geconverteerde data/Investeringen_nationaal`y'V2.dta", clear
	}	
	if `y'==2018{
		use "H:/Geconverteerde bestanden/Investeringen/Investeringen_nationaal`y'V3.dta", clear
	}
	if `y'==2019{
		use "H:/Geconverteerde bestanden/Investeringen/Investeringen_nationaal`y'V2.dta", clear
	}		
	if `y'==2020{
		use "H:/Geconverteerde bestanden/Investeringen/Investeringen_nationaal`y'V1.dta", clear
	}	
	rename *, upper
	
	* Assume that missing means 0 
	if `y'>=2012{
		foreach var of varlist C012004 C010004 C011004 C012001 C012003 C010001 C011001 C010003 C011003 C012002 C010002 C011002 C010003 C011003 C012003 C014004 C015001 C015002 C015003 C015004 C005004 C004004 C013004 C016004 C006004 C007004 C008004 C009004{
			replace `var' = 0 if missing(`var')
		}
		do do/prepare/a07_01_investeringen_2012_correspondence_table.do
	}

	rename *, lower

	*2000 - 2011
	if `y'<2012{
		if `y'==2010{
			rename be_id beid
		}
		if `y'==2011{
			rename kwaliteit_1 kw_1
			rename kwaliteit_2 kw_2
			rename be_id beid
			rename verslagjaar statjaar
			rename gk_sbs gksbs
		}

		* Drop imputed
		drop if kw_1!="A"
		drop kw_1 kw_2

		tostring beid, replace
		destring statjaar, force replace
		rename statjaar jaar

		cap drop kern*
		cap rename gk_var02 gk
		destring gk gksbs, force replace

		* Keep: Totaal van investeringen in computers en machines, investeringen in bestaande en investeringen in nieuwe
		if `y'==2000{
			keep beid jaar gk gksbs alo00nr6 alo00nr57 alo00157 alo00257 alo0016 alo0026 alo00nr9 alo00nr3 alo00nr4 alo00nr8 sbi*
			rename alo00nr* aloeu01nr*

		}
		if `y'>=2001 & `y'<=2011{
			keep beid jaar gk gksbs aloeu01nr6 aloeu01nr57 aloeu01157 aloeu0116 aloeu01257 aloeu0126 aloeu01nr9 aloeu01nr3 aloeu01nr4 aloeu01nr8 sbi*
		}
	}
	* 2012-2016
	* Drop imputed
	if `y'>=2012{
		drop if kwaliteit_1!="A"
		drop kwaliteit_1 kwaliteit_2

		* Convert firm ID to string if necessary
		tostring beid, replace
		gen int jaar=`y'

		cap drop kern*
		destring gksbs, force replace

		keep beid jaar gksbs aloeu01nr6 aloeu01nr57 aloeu01157 aloeu01nr9 aloeu0116 aloeu01257 aloeu0126 aloeu01nr3 aloeu01nr4 aloeu01nr8 c010003 c011003 c012003 c015001 c015002 c015003 c015004 sbi*
		compress
	}
	save dta/intermediate/inv_`y'_tmp.dta, replace
}

clear all
forvalues y=2000/2016{
	append using dta/intermediate/inv_`y'_tmp.dta
}

* Make size class consistent
replace gk = 0 if gksbs==0
replace gk = 1 if gksbs==10
replace gk = 2 if gksbs==21 | gksbs==22
replace gk = 3 if gksbs==30
replace gk = 4 if gksbs==40
replace gk = 5 if gksbs==50
replace gk = 6 if gksbs==60
replace gk = 7 if gksbs==71 | gksbs==72
replace gk = 8 if gksbs==81 | gksbs==82
replace gk = 9 if gksbs==91 | gksbs==92 | gksbs==93
drop gksbs

gen sbi2008 = sbi08_5d
rename jaar year
compress
save dta/intermediate/inv_0016_merged.dta, replace

* Remove temporary files
forvalues y=2000/2016{
	rm dta/intermediate/inv_`y'_tmp.dta
}


