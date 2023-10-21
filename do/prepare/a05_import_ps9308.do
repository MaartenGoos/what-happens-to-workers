*------------------------------------------------------------------------
* Automation
* import_ps9308.do
* Wiljan van den Berge
* Purpose: Imports PS files for 1993-2008, creates variables that we also have in newer files and keep only variables we will use
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
log using log/import_ps9308, text replace
*--------------------------------------------------------------------------
use "G:\Bedrijven\PS_BOUWNIJVERHEID\geconverteerde data\100819 PS_F_Bouwnijverheid_1993-2008V1.dta", clear		

* Generate netto omzet for this data as well, so that it matches the data from 2009 onwards
foreach var of varlist verkoop211000 verkoph212000 exports210000{
replace `var' = 0 if missing(`var')
}
gen omzet = verkoop211000+ verkoph212000+exports210000
label var omzet "Omzet voor PS1993-2008"

gen othercosts = obk
label var othercosts "Totaal overige kosten voor PS93-08"

keep beid statjaar kw_1 kw_2 sbi93_5d sbi93_2d gksbs gk_1d ophoogfactor ///
bedrlst310000 bedrlst348400 ///
loonsom100000 loonsom110000 ///
finrest100000  opbreng000000 ///
persons100000 persons110100 persons110000  ///
bedrlst344100 bedrlst344900 bedrlst345500 bedrlst349100 inkwrde132000  bedrlst347000 bedrlst348400 omzet ///
bedrlst345100 bedrlst345200 inkwrde100000 opbreng100000 othercosts bedrlst341000

save dta/intermediate/ps_bouw_1993-2008.dta, replace

use "G:/Bedrijven/PS_INDUSTRIE/geconverteerde data/100902 PS_D_Industrie_1993-2008V2.dta", clear		
foreach var of varlist verkoop211000 verkoph212000 exports210000{
replace `var' = 0 if missing(`var')
}
gen omzet = verkoop211000+ verkoph212000+exports210000
label var omzet "Omzet voor PS1993-2008"

gen othercosts = obk
label var othercosts "Totaal overige kosten voor PS93-08"

keep beid statjaar kw_1 kw_2 sbi93_5d sbi93_2d gksbs gk_1d ophoogfactor  ///
bedrlst310000 bedrlst348400 ///
loonsom100000 loonsom110000 ///
finrest100000  opbreng000000 ///
persons100000 persons110100 persons110000  ///
bedrlst344100 bedrlst344900 bedrlst345500 bedrlst349100 inkwrde132000  bedrlst347000 bedrlst348400 omzet ///
bedrlst345100 bedrlst345200 inkwrde100000 opbreng100000 othercosts bedrlst341000

save dta/intermediate/ps_industrie_1993-2008.dta, replace


use "G:/Bedrijven/PS_DETAILHANDEL/geconverteerde data/101012 PS_G_Detailhandel_1993-2008V1.dta", clear
/*detailhandel heeft geen exports */
foreach var of varlist verkoop211000 verkoph212000{
replace `var' = 0 if missing(`var')
}
gen omzet = verkoop211000+ verkoph212000
label var omzet "Omzet voor PS1993-2008"

gen othercosts = obk
label var othercosts "Totaal overige kosten voor PS93-08"


keep beid statjaar kw_1 kw_2 sbi93_5d sbi93_2d gksbs gk_1d ophoogfactor  ///
bedrlst310000 bedrlst348400 ///
loonsom100000 loonsom110000 ///
finrest100000  opbreng000000 ///
persons100000 persons110100 persons110000  ///
bedrlst344100 bedrlst344900 bedrlst345500 bedrlst349100 inkwrde132000  bedrlst347000 bedrlst348400 omzet ///
bedrlst345100 bedrlst345200 inkwrde100000 opbreng100000 othercosts bedrlst341000

save dta/intermediate/ps_detailhandel_1993-2008.dta, replace

use "G:/Bedrijven/PS_GROOTHANDEL/geconverteerde data/101102 PS_G_Groothandel_1993-2008V2.dta", clear		
foreach var of varlist verkoop211000 verkoph212000 exports210000{
replace `var' = 0 if missing(`var')
}
gen omzet = verkoop211000+ verkoph212000+exports210000
label var omzet "Omzet voor PS1993-2008"

gen othercosts = obk
label var othercosts "Totaal overige kosten voor PS93-08"

keep beid statjaar kw_1 kw_2 sbi93_5d sbi93_2d gksbs gk_1d ophoogfactor  ///
bedrlst310000 bedrlst348400 ///
loonsom100000 loonsom110000 ///
finrest100000  opbreng000000 ///
persons100000 persons110100 persons110000  ///
bedrlst344100 bedrlst344900 bedrlst345500 bedrlst349100 inkwrde132000  bedrlst347000 bedrlst348400 omzet ///
bedrlst345100 bedrlst345200 inkwrde100000 opbreng100000 othercosts bedrlst341000

save dta/intermediate/ps_groothandel_1993-2008.dta, replace

use "G:/Bedrijven/PS_COMMERCIELEDIENSTEN/geconverteerde data/101109 PS_H_CommercieleDiensten_1995-2008V2.dta", clear		
foreach var of varlist verkoop211000 verkoph212000 exports210000{
replace `var' = 0 if missing(`var')
}
gen omzet = verkoop211000+ verkoph212000+exports210000
label var omzet "Omzet voor PS1993-2008"

gen othercosts = obk
label var othercosts "Totaal overige kosten voor PS93-08"

keep beid statjaar kw_1 kw_2 sbi93_5d sbi93_2d gksbs ophoogfactor ///
bedrlst310000 bedrlst348400 ///
loonsom100000 loonsom110000 ///
finrest100000  opbreng000000 ///
persons100000 persons110100 persons110000  ///
bedrlst344100 bedrlst344900 bedrlst345500 bedrlst349100 inkwrde132000  bedrlst347000 bedrlst348400 omzet ///
bedrlst345100 bedrlst345200 inkwrde100000 opbreng100000 othercosts bedrlst341000

save dta/intermediate/ps_commercieel_1995-2008.dta, replace

use "G:/Bedrijven/PS_TRANSPORT/geconverteerde data/101021 PS_I_Transport_2000-2008V1.dta", clear		
foreach var of varlist verkoop211000 verkoph212000 exports210000{
replace `var' = 0 if missing(`var')
}
gen omzet = verkoop211000+ verkoph212000+exports210000
label var omzet "Omzet voor PS1993-2008"

gen othercosts = obk
label var othercosts "Totaal overige kosten voor PS93-08"

keep beid statjaar kw_1 kw_2 sbi93_5d sbi93_2d gksbs gk_1d ophoogfactor ///
bedrlst310000 bedrlst348400 ///
loonsom100000 loonsom110000 ///
finrest100000  opbreng000000 ///
persons100000 persons110100 persons110000  ///
bedrlst344100 bedrlst344900 bedrlst345500 bedrlst349100 inkwrde132000  bedrlst347000 bedrlst348400 omzet ///
bedrlst345100 bedrlst345200 inkwrde100000 opbreng100000 othercosts bedrlst341000

save dta/intermediate/ps_transport_2000-2008.dta, replace
