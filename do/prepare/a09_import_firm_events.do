*------------------------------------------------------------------------
* Automation
* import_firm_events.do
* 16/4/2020
* Wiljan van den Berge
* Purpose: determine events for the firms in our sample based on administrative firm data
*-------------------------------------------------------------------------
*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close
sysdir set PLUS M:\Stata\Ado\Plus 

cd H:/automation/
log using log/import_firm_events, text replace
*--------------------------------------------------------------------------

forvalues y=2006/2016{
	use dta/intermediate/beid.dta, clear
	
	if `y'==2006 | `y'==2007{
		gen rbe_identificatie=beid
		destring rbe_identificatie, replace
		merge 1:m rbe_identificatie using "G:/Bedrijven/ABR/`y'/geconverteerde data/110525 BE_eventbijdragen_ABR `y'V3.dta", keep(match) nogen
	}
	if `y'==2008{
		gen rbe_identificatie=beid
		destring rbe_identificatie, replace
		merge 1:m rbe_identificatie using "G:/Bedrijven/ABR/`y'/geconverteerde data/110525 BE_eventbijdragen_ABR `y'V2.dta", keep(match) nogen
	}
	if `y'==2009{
		gen be_id=beid
		destring be_id, replace
		merge 1:m be_id using "G:/Bedrijven/ABR/`y'/geconverteerde data/120626 BE_eventbijdragen_ABR `y'V3.dta", keep(match) nogen
	}
	if `y'==2010{
		gen be_id=beid
		destring be_id, replace
		merge 1:m be_id using "G:/Bedrijven/ABR/`y'/geconverteerde data/120329 BE_eventbijdragen_ABR `y'V3.dta", keep(match) nogen
	}	
	if `y'==2011{
		gen be_id=beid
		destring be_id, replace
		merge 1:m be_id using "G:/Bedrijven/ABR/`y'/geconverteerde data/120402 BE_eventbijdragen_ABR `y'V1.dta", keep(match) nogen
	}
	if `y'==2012{
		gen BE_ID=beid
		destring BE_ID, replace
		merge 1:m BE_ID using "G:/Bedrijven/ABR/`y'/geconverteerde data/130311 BE_eventbijdragen_ABR `y'V1.dta", keep(match) nogen
	}
	if `y'==2013{
		gen BE_ID=beid
		destring BE_ID, replace
		merge 1:m BE_ID using "G:/Bedrijven/ABR/`y'/geconverteerde data/140313 BE_eventbijdragen_ABR `y'V1.dta", keep(match) nogen
	}
	if `y'==2014{
		gen BE_ID=beid
		destring BE_ID, replace
		merge 1:m BE_ID using "G:/Bedrijven/ABR/`y'/geconverteerde data/BE_eventbijdragen_ABR `y'V1.dta", keep(match) nogen
	}	
	if `y'>=2015{
		gen BE_ID=beid
		destring BE_ID, replace
		merge 1:m BE_ID using "G:/Bedrijven/ABR/`y'/geconverteerde data/BE_eventbijdragen_ABR`y'V1.dta", keep(match) nogen
	}	
	rename *, lower

	gen year=`y'
	label define ebd 1 "birth" 3 "birth and death combination" 4 "split" 5 "break up" ///
	6 "take-over" 7 "merger" 8 "restructuring" 9 "death" 10 "other"
	label values ebd_type ebd
	label define eac 1 "addition" 2 "removal" 3 "continuation"
	label values eac_type eac

	gen eventlevel = 1 if vev_type>=1 & vev_type<=3
	replace eventlevel = 2 if vev_type >=4 & vev_type<=13
	replace eventlevel = 3 if vev_type>=14 & vev_type<=21
	replace eventlevel = 4 if vev_type==22
	label define level 1 "Local unit" 2 "Firm" 3 "Corporation" 4 "Other"
	label values eventlevel level

	tostring vev_datumtoepassing, replace
	gen date_event = date(vev_datumtoepassing,"YMD")
	format date_event %td

	keep beid eac_type ebd_type eventlevel date_event year
	label var eac_type "Type of firm event action"
	label var ebd_type "Type of firm event"
	label var eventlevel "Level at which firm event takes place - local unit, firm or corporation"
	label var date_event "Date of firm event"

	compress
	save dta/intermediate/firm_event`y'.dta, replace
}

use dta/intermediate/firm_event2006.dta, clear
forvalues y=2007/2016{
	append using dta/intermediate/firm_event`y'.dta
}
sort beid date_event
save dta/intermediate/firm_event0616.dta, replace

// 2000 - 2005: no event data, have to construct it ourselves
forvalues y=2000/2005{
	use dta/intermediate/beid.dta, clear	
	if `y'==2000{
		gen BE_ID = beid
		destring BE_ID, force replace
		merge 1:m BE_ID using "G:/Bedrijven/ABR/`y'/geconverteerde data/080213 ABR-Bedrijfseenheden `y'V1.dta", ///
		keep(match) keepusing(MUTCODE_ULT_JAAR DATUM_ONTSTAAN_MUT REG_DATUM_ONTSTAAN_MUT) nogen
	}
	if `y'==2001{
		gen BE_ID = beid
		destring BE_ID, force replace
		merge 1:m BE_ID using "G:/Bedrijven/ABR/`y'/geconverteerde data/080214 ABR-Bedrijfseenheden `y'V1.dta", ///
		keep(match) keepusing(MUTCODE_ULT_JAAR DATUM_ONTSTAAN_MUT REG_DATUM_ONTSTAAN_MUT) nogen
	}
	if `y'==2002{
		gen BE_ID = beid
		destring BE_ID, force replace
		merge 1:m BE_ID using "G:/Bedrijven/ABR/`y'/geconverteerde data/080201 ABR-Bedrijfseenheden `y'V1.dta", ///
		keep(match) keepusing(MUTCODE_ULT_JAAR DATUM_ONTSTAAN_MUT REG_DATUM_ONTSTAAN_MUT) nogen
	}		
	if `y'==2003{
		gen be_id = beid
		destring be_id, force replace
		merge 1:m be_id using "G:/Bedrijven/ABR/`y'/geconverteerde data/080130 ABR-Bedrijfseenheden `y'V1.dta", ///
		keep(match) keepusing(mutcode_ult_jaar datum_ontstaan_mut reg_datum_ontstaan_mut) nogen
	}		
	if `y'==2004{
		gen be_id = beid
		destring be_id, force replace
		merge 1:m be_id using "G:/Bedrijven/ABR/`y'/geconverteerde data/080110 ABR-Bedrijfseenheden `y'V1.dta", ///
		keep(match) keepusing(mutcode_ult_jaar datum_ontstaan_mut reg_datum_ontstaan_mut) nogen
	}
	if `y'==2005{
		gen be_id = beid
		destring be_id, force replace
		merge 1:m be_id using "G:/Bedrijven/ABR/`y'/geconverteerde data/071005 ABR-Bedrijfseenheden `y'V1.dta", ///
		keep(match) keepusing(mutcode_ult_jaar datum_ontstaan_mut reg_datum_ontstaan_mut) nogen
	}	
	rename *, lower

	keep if !missing(mutcode_ult_jaar)

	tostring datum_ontstaan_mut reg_datum_ontstaan_mut, replace
	gen jaar_ontstaan=substr(datum_ontstaan_mut,1,4)
	gen maand_ontstaan = substr(datum_ontstaan_mut,5,2)
	gen jaar_reg=substr(reg_datum_ontstaan_mut,1,4)
	gen maand_reg = substr(reg_datum_ontstaan_mut,5,2)
	destring jaar_ontstaan maand_ontstaan jaar_reg maand_reg, replace
	gen date_event = mdy(maand_ontstaan,1,jaar_ontstaan)
	replace date_event = mdy(maand_reg,1,jaar_reg) if missing(date_event)
	format date_event %td

	gen eac_type = 1 if (mutcode_ult_jaar>=11 & mutcode_ult_jaar<=17) | ///
	(mutcode_ult_jaar>=74 & mutcode_ult_jaar<=77) //addition / opvoering
	replace eac_type = 2 if (mutcode_ult_jaar>=22 & mutcode_ult_jaar<=27) | ///
	(mutcode_ult_jaar>=82 & mutcode_ult_jaar<=87)
	replace eac_type = 3 if (mutcode_ult_jaar>=33 & mutcode_ult_jaar<=37) | ///
	(mutcode_ult_jaar==71 | mutcode_ult_jaar>=93 & mutcode_ult_jaar<=97)
	label define eac 1 "addition" 2 "removal" 3 "continuation"
	label values eac_type eac

	//1 = birth
	gen ebd_type = 1 if  mutcode_ult_jaar==11
	*replace ebd_type = 3 if //birth and death combination??
	replace ebd_type = 4 if mutcode_ult_jaar==15 | mutcode_ult_jaar==35 ///
	| mutcode_ult_jaar==75 | mutcode_ult_jaar==86 | mutcode_ult_jaar==95
	replace ebd_type = 5 if mutcode_ult_jaar==16 | mutcode_ult_jaar==26 ///
	| mutcode_ult_jaar==76
	replace ebd_type = 6 if mutcode_ult_jaar==23 | mutcode_ult_jaar==33
	replace ebd_type = 7 if mutcode_ult_jaar==14 | mutcode_ult_jaar==24
	replace ebd_type = 8 if mutcode_ult_jaar==17 | mutcode_ult_jaar==27 | mutcode_ult_jaar==37 ///
	| mutcode_ult_jaar==77 | mutcode_ult_jaar==87 | mutcode_ult_jaar==97
	replace ebd_type = 9 if mutcode_ult_jaar==22 

	replace ebd_type = 10 if missing(ebd_type) // OTHER, other is mostly samenvoeging
	// 71, 74, 82, 83, 84, 93
	label define ebd 1 "birth" 3 "birth and death combination" 4 "split" 5 "break up" ///
	6 "take-over" 7 "merger" 8 "restructuring" 9 "death" 10 "other"
	label values ebd_type ebd

	gen year =`y'
	//event level is unknown
	keep beid mutcode_ult_jaar date_event eac_type ebd_type year
	label var eac_type "Type of firm event action"
	label var ebd_type "Type of firm event"
	label var date_event "Date of firm event"

	compress
	save dta/intermediate/firm_event`y'.dta, replace
}

use dta/intermediate/firm_event2000.dta, clear
forvalues y=2001/2016{
	append using dta/intermediate/firm_event`y'.dta
}
compress
sort beid date_event
save dta/intermediate/firm_event0016.dta, replace

// Reshape to wide data

use dta/intermediate/firm_event0016.dta, clear

sort beid year date_event
by beid year: gen n=_n
keep beid year eac_type ebd_type eventlevel n
reshape wide eac_type ebd_type eventlevel, i(beid year) j(n)
compress
save dta/intermediate/firm_event0016_wide.dta, replace

forval y=2000/2016{
	rm dta/intermediate/firm_event`y'.dta
}
rm dta/intermediate/firm_event0616.dta
