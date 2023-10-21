*------------------------------------------------------------------------
* Automation
* merge_ps_inv.do
* 7/5/2018
* 20/11/2018: 	Use investments 2000-2017 instead of 2000-2015
* 23/4/2020: 	Added new SBI93-08 xwalk using a match for all sectors
* Wiljan van den Berge
* Purpose: merge PS and Investments data and add sector codes and sector-
* specific prices.
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
log using log/merge_ps_inv, text replace
*--------------------------------------------------------------------------
use dta/intermediate/inv_0016_merged.dta, clear
merge 1:m beid year using dta/intermediate/ps_9316_merged_final.dta, gen(merge_ps_inv)

drop if length(beid)<8 // no full firm identifier

* Make SBI sector codes for investments and PS consistent
replace sbi08_5d = sbi2008 if missing(sbi08_5d)
drop sbi2008

label def sr 1 "Only Investeringen" 2 "Only PS" 3 "PS and Investeringen"
label values merge_ps_inv sr
label var merge_ps_inv "Source of data"

* Merge sbi (sector) x-walks
rename sbi93_5d sbi1993
merge m:1 sbi1993 using dta/intermediate/sbi9308_crosswalk.dta, keep(match master) nogen

* Determine 1 sector for each firm, assuming that firms don't switch sector */
gsort beid -year
by beid: gen sbi2008_final=sbi08_5d if _n==1
by beid: replace sbi2008_final=sbi2008 if _n==1 & missing(sbi2008_final)
by beid: replace sbi2008_final=sbi2008_final[_n-1] if missing(sbi2008_final)

* If still missing, take SBI2008 code of another year if available
replace sbi2008_final = sbi2008 if missing(sbi2008_final) & !missing(sbi2008)
gsort beid -sbi2008_final
by beid: replace sbi2008_final=sbi2008_final[_n-1] if missing(sbi2008_final)

* If then still missing, use the x-walk with most common SBI2008 sector for each SBI1993 sector
rename sbi1993 sbi1993_5dig
merge m:1 sbi1993_5dig using dta\intermediate\sbi1993_maxsbi2008.dta, keep(match master) nogen
replace sbi2008_final = sbi1993_to_2008_5dig if missing(sbi2008_final) & !missing(sbi1993_to_2008_5dig)

drop sbi93_secties sbi93_2d sbi2008_letter sbi2008_2dig sbi2008 sbi1993_5dig sbi08_secties sbi08_5d sbi08_2d sbi1993_to_2008_5dig
rename sbi2008_final sbi2008
gen sbi2008_2dig = substr(sbi2008,1,2)
merge m:1 sbi2008_2dig using H:/import/sbi2008_letter_2dig, keep(match master) nogen keepusing(sbi2008_letter)

count if missing(sbi2008)

* Add sector-specific prices
merge m:1 sbi2008_letter year using dta/intermediate/sector_prices.dta, keep(match master) nogen
** Only the sector-year combinations which we don't use in the final sample don't have price data

compress
save dta/intermediate/inv_ps_9316_merged.dta, replace

keep beid
duplicates drop
save dta/intermediate/beid.dta, replace
