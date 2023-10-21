*------------------------------------------------------------------------
* Automation
* managerswitch.do
* 25/6/2019
* Wiljan van den Berge
* Purpose: Identify "new managers" in the data, defined as hiring someone at a top decile
*-------------------------------------------------------------------------

*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close

cd H:/automation/
log using log/managerswitch, text replace
*--------------------------------------------------------------------------

* 1: get all firms in our main sample
* 2: get all workers at these firms, including their wages
* 3: within firms: did they hire someone at the 75th/85th/95th percentile?
* 4: did they both lose and hire someone at the same percentiles?

		
use rinpersoons rinpersoon year beid wage days soortbaan using dta\intermediate\workerdata9916.dta, clear
merge m:1 beid using dta/intermediate/firmsample_beid_autom.dta, keep(match master) gen(merge_firm)

gen dailywage = wage / days
replace dailywage = 0 if dailywage < 0
* Determine potential 'managers': workers above 90th percentile, and earning at least 150 euros a day and having a regular employment contract
bys beid year: gegen dist=pctile(dailywage), p(90)

gen byte manager= dailywage>dist & dailywage!=. & dist!=. 
replace manager=0 if dailywage<150 // cut-off of earning at least 150 a day (40,000 a year)
replace manager = 0 if soortbaan == 2 | soortbaan == 3 | soortbaan == 4 | soortbaan == 5 // Manager cannot be on-call, disabled, temp agency or intern contract type

* Is manager new?
sort beid rinpersoons rinpersoon year
by beid rinpersoons rinpersoon: gegen start=min(year)
gen byte new= year == start
replace new=. if year==1999

gen byte newmgr = 1 if new == 1 & manager == 1

* Collapse to the firm level
bys beid year: ereplace newmgr = max(newmgr)
bys beid year: keep if _n==1
replace newmgr = 0 if missing(newmgr)

keep beid year newmgr
compress
save dta/intermediate/newmanager.dta, replace

