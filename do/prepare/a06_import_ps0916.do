*------------------------------------------------------------------------
* Automation
* import_ps0916.do
* 2/7/2018
* Wiljan van den Berge
* Purpose: Import and merge production statistics files
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
log using log/import_ps0916, text replace
*--------------------------------------------------------------------------

forval y=2009/2016{
	*Industrie
	{
		if `y'==2009{
			use "G:/Bedrijven/PS_INDUSTRIE/geconverteerde data/PS_Industrie_main `y'V4.dta", clear
		}
		if `y'==2010{
			use "G:/Bedrijven/PS_INDUSTRIE/geconverteerde data/PS_Industrie_main `y'V3.dta", clear
		}
		if inrange(`y',2011,2016){
			use "G:/Bedrijven/PS_INDUSTRIE/geconverteerde data/PS_Industrie_main `y'V1.dta", clear
		}
		if `y'==2017{
			use "G:/Bedrijven/PS_INDUSTRIE/geconverteerde data/PS_industrie_main_`y'V1.dta", clear
		}
		if inrange(`y',2018,2019){
			use "H:/Geconverteerde bestanden/PS/PS_industrie_main_`y'V1.dta", clear
		}			
		gen ps=1
	}

	*Bouwnijverheid
	{
		if `y'==2009{
			append using "G:/Bedrijven/PS_BOUWNIJVERHEID/geconverteerde data/PS_Bouwnijverheid_main `y'V4.dta"
		}
		if `y'==2010{
			append using "G:/Bedrijven/PS_BOUWNIJVERHEID/geconverteerde data/PS_Bouwnijverheid_main `y'V3.dta"
		}
		if inrange(`y',2011,2016){
			append using "G:/Bedrijven/PS_BOUWNIJVERHEID/geconverteerde data/PS_Bouwnijverheid_main `y'V1.dta"
		}
		if `y'==2017{
			append using "G:/Bedrijven/PS_BOUWNIJVERHEID/geconverteerde data/PS_Bouwnijverheid_main_`y'V1.dta"
		}
		if inrange(`y',2018,2019){
			append using "H:/Geconverteerde bestanden/PS/PS_Bouwnijverheid_main_`y'V1.dta"
		}			
		replace ps=2 if missing(ps)
	}
	*Commerciele diensten
	{
		if `y'==2009{
			append using "G:/Bedrijven/PS_COMMERCIELEDIENSTEN/geconverteerde data/PS_Commercielediensten_main `y'V4.dta"
		}
		if `y'==2010{
			append using "G:/Bedrijven/PS_COMMERCIELEDIENSTEN/geconverteerde data/PS_Commercielediensten_main `y'V3.dta"
		}
		if inrange(`y',2011,2016){
			append using "G:/Bedrijven/PS_COMMERCIELEDIENSTEN/geconverteerde data/PS_Commercielediensten_main `y'V1.dta"
		}
		if `y'==2017{
			append using "G:/Bedrijven/PS_COMMERCIELEDIENSTEN/geconverteerde data/PS_commercielediensten_main_`y'V1.dta"
		}
		if inrange(`y',2018,2019){
			append using "H:/Geconverteerde bestanden/PS/PS_commercielediensten_main_`y'V1.dta"
		}			
		replace ps=3 if missing(ps)
	}
	*Groothandel
	{
		if `y'==2009{
			append using "G:/Bedrijven/PS_GROOTHANDEL/geconverteerde data/PS_Groothandel_main `y'V4.dta"
		}
		if `y'==2010{
			append using "G:/Bedrijven/PS_GROOTHANDEL/geconverteerde data/PS_Groothandel_main `y'V3.dta"
		}
		if inrange(`y',2011,2016){
			append using "G:/Bedrijven/PS_GROOTHANDEL/geconverteerde data/PS_Groothandel_main `y'V1.dta"
		}
		if `y'==2017{
			append using "G:/Bedrijven/PS_GROOTHANDEL/geconverteerde data/PS_groothandel_main_`y'V1.dta"
		}
		if inrange(`y',2018,2019){
			append using "H:/Geconverteerde bestanden/PS/PS_groothandel_main_`y'V1.dta"
		}			
		replace ps=4 if missing(ps)
	}
	*Detailhandel
	{
		if `y'==2009{
			append using "G:/Bedrijven/PS_DETAILHANDEL/geconverteerde data/PS_Detailhandel_main `y'V4.dta"
		}
		if `y'==2010{
			append using "G:/Bedrijven/PS_DETAILHANDEL/geconverteerde data/PS_Detailhandel_main `y'V3.dta"
		}
		if inrange(`y',2011,2016){
			append using "G:/Bedrijven/PS_DETAILHANDEL/geconverteerde data/PS_Detailhandel_main `y'V1.dta"
		}
		if `y'==2017{
			append using "G:/Bedrijven/PS_DETAILHANDEL/geconverteerde data/PS_detailhandel_main_`y'V1.dta"
		}
		if inrange(`y',2018,2019){
			append using "H:/Geconverteerde bestanden/PS/PS_detailhandel_main_`y'V1.dta"
		}		
		replace ps=5 if missing(ps)
	}
	*Transport
	{
		if `y'==2009{
			append using "G:/Bedrijven/PS_TRANSPORT/geconverteerde data/PS_Transport_main `y'V4.dta"
		}
		if `y'==2010{
			append using "G:/Bedrijven/PS_TRANSPORT/geconverteerde data/PS_Transport_main `y'V3.dta"
		}
		if inrange(`y',2011,2016){
			append using "G:/Bedrijven/PS_TRANSPORT/geconverteerde data/PS_Transport_main `y'V1.dta"
		}
		if `y'==2017{
			append using "G:/Bedrijven/PS_TRANSPORT/geconverteerde data/PS_transport_main_`y'V1.dta"
		}
		if inrange(`y',2018,2019){
			append using "H:/Geconverteerde bestanden/PS/PS_transport_main_`y'V1.dta"
		}		
		replace ps=6 if missing(ps)
	}

	label define PS 1 "Industrie" 2 "Bouwnijverheid" 3 "Commerciele diensten" 4 "Groothandel" 5 "Detailhandel" 6 "Transport"
	label values ps PS
	label var ps "Source in PS"

	rename *, lower

	cap rename bedrlst347000 out_bedrlst347000 // This variable has a different name in 2014 & 2015
	keep 	be_id statjaar sbi kerncelcode rechtsvormid gk_sbs eindgewicht correctiegewicht imputatiegebruiken iscongo isdummy isgeblokkeerd isnullteller isuitbijter ps ///
		bedrlst310000 bedrlst348400 finrest100000 omzetph210000 omzetps210000 opbreng000000 ///
		perslst100000 perslst100009 personh111000 persons100000 persons110000 persons110100 persons111000 persons111005 persons113000 persons121000 ///
		persons121010 persons122000 persons122010 persons123000 persons130000 persons940000 persons940110 persons940120 persons941000 persons942000 persons943000 ///
		persons944000 out_brutotw200000 ///
		results120000 results130000 bedrlst344100 bedrlst344900 bedrlst345500 bedrlst345509 bedrlst349100 imports113000 inkwrde132000 ///
		loonsom110002 loonsom110012 loonsom110029 out_bedrlst345991 out_bedrlst347000 out_imports100000 ///
		inkwrde100000 bedrlst340900 opbreng100000 bedrlst345100 bedrlst345200 inkwrde13200 bedrlst341000

	generate str8 beid = string(be_id,"%08.0f") // For some weird reason, tostring gives an error in 2012. This works fine and gives the same results.
	drop be_id
	destring statjaar, force replace
	compress

	save dta/intermediate/ps_`y'_tmp.dta, replace
}




/* Append all years and make variables consistent */

clear all
forvalues y=2009/2016{
	append using dta/intermediate/ps_`y'_tmp.dta
}
save dta/intermediate/ps_new_tmp.dta, replace

use dta/intermediate/ps_industrie_1993-2008.dta, clear
gen ps = 1
append using dta/intermediate/ps_bouw_1993-2008.dta
replace ps = 2 if missing(ps)
append using dta/intermediate/ps_commercieel_1995-2008.dta
replace ps = 3 if missing(ps)
append using dta/intermediate/ps_groothandel_1993-2008.dta
replace ps = 4 if missing(ps)
append using dta/intermediate/ps_detailhandel_1993-2008.dta
replace ps = 5 if missing(ps)
append using dta/intermediate/ps_transport_2000-2008.dta
replace ps = 6 if missing(ps)

label define PS 1 "Industrie" 2 "Bouwnijverheid" 3 "Commerciele diensten" 4 "Groothandel" 5 "Detailhandel" 6 "Transport"
label values ps PS
label var ps "Source in PS"

* Define imputed values	
gen imputatie=.
replace imputatie = 0 if kw_1 == "A" & missing(imputatie)
replace imputatie = 1 if (kw_1 == "E" | kw_1 == "F" | kw_1 == "G") & missing(imputatie)
* Drop observations with weight zero or missing weight [Should be dropped according to CBS]
drop if kw_1 == "B" // nullteller
drop if ophoogfactor==0 | ophoogfactor==.


drop kw_1 kw_2
destring statjaar gksbs gk_1d, force replace
compress
save dta/intermediate/ps_9308_tmp.dta, replace

use dta/intermediate/ps_new_tmp.dta, clear

// Drop dummy observations [Fake firms]
drop if isdummy=="True"

// Drop nulltellers [Observations with zero weight]
drop if isnullteller=="True"

// Drop observations without weight or zero weight [Should be dropped according to CBS]
drop if eindgewicht==0 | eindgewicht==.

// Generate final revenue 
gen omzet_final = omzetps210000

rename sbi sbi2008
rename gk_sbs gksbs
rename out_bedrlst347000 bedrlst347000
rename imputatiegebruiken imputatie
rename eindgewicht ophoogfactor
keep beid statjaar imputatie gksbs sbi2008 omzet_final ophoogfactor ///
	persons100000 persons110000 persons110100 loonsom110002 ///
	opbreng000000 finrest100000 inkwrde132000 bedrlst310000 bedrlst344100 bedrlst344900 ///
	bedrlst345500 bedrlst347000 bedrlst348400 bedrlst349100 ///
	inkwrde100000 inkwrde132000 bedrlst345100 bedrlst345200 results120000 results130000 bedrlst340900 opbreng100000 bedrlst341000

foreach var of varlist imputatie{
	replace `var' = "1"  if `var' == "True"
	replace `var' = "0" if `var' == "False"
	destring `var', force replace
}

rename loonsom110002 loonsom110000 // NOTE: Checked: loonsom110000 is the name for the same variable in the older files



* Append the 1993 - 2008 data
append using dta/intermediate/ps_9308_tmp.dta

replace omzet_final = omzet if missing(omzet_final)

rename statjaar jaar

* Drop imputed values
drop if imputatie==1 
drop imputatie

* Fix other costs variable
replace othercosts = bedrlst340900 if missing(othercosts)

* Make size class consistent for all years
destring gk_1d gksbs, force replace
replace gk_1d = 0 if gksbs==0
replace gk_1d = 1 if gksbs==10
replace gk_1d = 2 if gksbs==21 | gksbs==22
replace gk_1d = 3 if gksbs==30
replace gk_1d = 4 if gksbs==40
replace gk_1d = 5 if gksbs==50
replace gk_1d = 6 if gksbs==60
replace gk_1d = 7 if gksbs==71 | gksbs==72
replace gk_1d = 8 if gksbs==81 | gksbs==82
replace gk_1d = 9 if gksbs==91 | gksbs==92 | gksbs==93
drop gksbs
rename gk_1d gk

/* a few sector observations have leading spaces, replace these */
replace sbi2008="4752" if sbi2008=="  4752"
replace sbi2008="4741" if sbi2008=="  4741"
replace sbi2008="47528" if sbi2008==" 47528"

compress
save dta/intermediate/ps_9316_merged.dta, replace

/* In 2009 the firm definition changed. Some firms who were previously spread out across multiple firm ID's are now combined into one ID
   Here we drop all the firms observed post 2009 for whom we don't observe all the firm ID's pre-2009 */

* Most conservative: Drop all data pre-2008 for firms that are in the crosswalk, so for whom the firm definition changed
use dta/intermediate/ps_9316_merged.dta, clear
rename jaar year
keep if year<=2008
merge m:1 beid using dta/intermediate/crosswalk_beidold_2009.dta, keep(match master) gen(merge_xwalk2008) keepusing()
save dta/intermediate/ps_9316_mergedpre2008.dta, replace

use dta/intermediate/ps_9316_merged.dta, clear
rename jaar year
keep if year>2008
save dta/intermediate/ps_9316_mergedpost2008.dta, replace
append using dta/intermediate/ps_9316_mergedpre2008.dta 

gen drop = merge_xwalk2008==3
bys beid: egen t_drop = total(drop)
codebook beid
drop if t_drop>0
codebook beid
drop merge_xwalk2008 drop t_drop

compress
save dta/intermediate/ps_9316_merged_final.dta, replace

* Remove temporary files
forval y=2009/2016{
	rm dta/intermediate/ps_`y'_tmp.dta
}
rm dta/intermediate/ps_9316_mergedpre2008.dta
rm dta/intermediate/ps_9316_mergedpost2008.dta
rm dta/intermediate/ps_9316_merged.dta
rm dta/intermediate/ps_9308_tmp.dta
rm dta/intermediate/ps_new_tmp.dta
rm dta/intermediate/ps_transport_2000-2008.dta
rm dta/intermediate/ps_groothandel_1993-2008.dta
rm dta/intermediate/ps_detailhandel_1993-2008.dta
rm dta/intermediate/ps_industrie_1993-2008.dta
rm dta/intermediate/ps_bouw_1993-2008.dta
rm dta/intermediate/ps_commercieel_1995-2008.dta
