*------------------------------------------------------------------------
* Automation
* descriptives_firms_around_events.do
* 11/8/2021
* Wiljan van den Berge
* Purpose: Create descriptives of costs for firms around events (Figure C1)
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
log using log/descriptives_firms_around_events, text replace
*--------------------------------------------------------------------------
use dta\intermediate\firmsample_autom_end2016, clear

gen spikeyear = year if spike_firm_first == 1
bys beid: ereplace spikeyear = max(spikeyear)

gen time = year - spikeyear
drop if missing(time)

* Balance data
keep if time >= -3 & time <=4
local n=1
bys beid: gegen n = total(`n')
keep if n==8
drop n

preserve
distinct beid
gen n=1
collapse (mean) automation_real costs (sum) n, by(time)

label var costs "Real total costs excl. automation costs (right axis)"
label var automation_real "Real automation costs (left)"

tw conn automation_real time, yaxis(1) || conn costs time, yaxis(2) xlabel(-3(1)4) legend(position(6)) ylabel(60000(5000)80000, axis(2)) ylabel(0(200)1000, axis(1)) ytitle("", axis(1)) ytitle("", axis(2))

xmlsave output/costs_around_event_balanced.xml, doctype(excel) replace
restore
