*------------------------------------------------------------------------
* Automation
* define_spikes_overlapping.do
* 1/3/2019
* Last updated: 18/5/2021
* Wiljan van den Berge
* Purpose: define spikes for overlapping sample of computer/automation data and clean data
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
log using log/define_spikes_overlapping, text replace
*--------------------------------------------------------------------------

* Load overlapping data (inv & PS)
use dta\intermediate\inv_ps_9316_merged.dta if year>=2000 & year<=2016, clear

quietly{
	* Drop one firm with weird data
	drop if beid=="13514466"

	// Merge GK manual
	merge m:1 beid year using dta/intermediate/beid_manual_gk_mar_all.dta, gen(merge_gk) 

	* merge wagebill
	merge m:1 beid year using dta/intermediate/beid_wagebill.dta, gen(merge_wagebill) 

	// Merge firm age
	merge m:1 beid using dta/intermediate/beid_firmstart.dta, keep(match master) gen(merge_firmstart)

	// Calculate lagged employment
	sort beid year
	by beid: gen emp_t1 = nr_workers_mar[_n-1]
	by beid: gen wagebill_t1 = wagebill[_n-1]
	drop if missing(wagebill)
	drop if missing(gk_manual)
	drop if missing(nr_workers_mar)

	** Drop observations with missings on computer investments
	drop if missing(aloeu01nr6) 
	** Drop observations with missings on automation costs
	drop if missing(bedrlst348400)

	** keep only overlapping firms
	keep if merge_ps_inv==3

	* Drop very small sectors that shouldn't be in the data anyways, since PS is sector based
	drop if sbi2008_letter=="A" | sbi2008_letter=="B" | sbi2008_letter=="D" | sbi2008_letter=="E" | sbi2008_letter=="L" | sbi2008_letter=="R" | sbi2008_letter=="S"
}

qui distinct beid
display "After keeping only merged PS & Investments data, dropping missings on admin data and dropping small sectors, we have `r(ndistinct)' distinct firms and `r(N)' observations left for 2016 sample"

*Keep only relevant variables for now
keep beid year gk aloeu01nr6 aloeu01nr57 bedrlst310000 bedrlst348400 opbreng000000 sbi2008_2dig sbi2008_letter sbi2008 merge_ps_inv persons110000 omzet_final p_output p_addedvalue loonsom110000 loonsom100000 ///
	opbreng100000 bedrlst345100 bedrlst345200 inkwrde13200 inkwrde100000 othercosts persons110100 c015004 aloeu01nr9 gk_manual nr_workers_mar wagebill firm_startyr emp_t1 wagebill_t1 ophoogfactor results120000 results130000


* Basic housekeeping

*Renaming some variables for convenience
rename aloeu01nr6 computers
rename aloeu01nr57 machines
rename persons110000 total_fte
rename persons110100 employee_fte
rename opbreng000000 operatingincome // totaal van de bedrijfsopbrengsten
rename omzet_final revenue
rename bedrlst348400 automation
rename bedrlst310000 totalcosts
rename loonsom110000 wagebill_svy // total of gross wages
rename opbreng100000 otherrevenue
rename inkwrde100000 costofsales
rename inkwrde132000 costofoutsourcing
rename c015004 software
rename aloeu01nr9 totalinvestments
rename results130000 ebt
rename results120000 result

* Deflate revenue, opinc and costs
gen automation_real = automation
gen totalcosts_real = totalcosts
gen costofsales_real = costofsales
gen othercosts_real = othercosts
gen costofoutsourcing_real = costofoutsourcing
gen wagebill_real = wagebill
gen computers_real = computers
gen machines_real = machines
gen software_real = software
gen totalinvestments_real = totalinvestments
gen revenue_real = revenue
gen opinc_real = operatingincome
gen otherrev_real = otherrevenue
gen ebt_real = ebt
gen result_real = result

* Deflate by CPI
merge m:1 year using H:/cpi9619.dta, nogen keep(match master)

foreach var in automation_real totalcosts_real wagebill_real costofsales_real costofoutsourcing_real othercosts_real ///
	computers_real machines_real software_real totalinvestments_real revenue_real opinc_real otherrev_real result_real ebt_real{
	replace `var' = (`var'/cpi)*100
}

* Construct revenue per total workers
gen revenue_worker = revenue_real / nr_workers_mar
gen result_worker = result_real / nr_workers_mar
gen ebt_worker = ebt_real / nr_workers_mar

* Construct operating income per total workers
gen income_worker = opinc_real/nr_workers_mar

* Sector labels
encode sbi2008_letter, gen(sbi2008_1dig)
label define s 1 "Manufacturing" 2 "Construction" 3 "Wholesale and retail trade" ///
	4 "Transportation and storage" 5 "Accommodation and food serv" 6 "Information and communication" ///
	7 "Prof, scientific, techn act" 8 "Admin and support act"
label values sbi2008_1dig s
*size labels
label define size 0 "0 employees" 1 "1 employee"  2 "2-4 employees"  3 "5-9 employees" 4 "10-19 employees" 5 "20-49 employees" 6 "50-99 employees" 7 "100-199 employees" ///
	8 "200-499 employees" 9 ">=500 employees"
label values gk size

* Drop missings on automation costs, total costs and investments
drop if missing(automation_real)
drop if missing(totalcosts_real)
drop if missing(computers_real)
drop if missing(sbi2008_1dig)


* Remove automation costs from total costs
gen costs = totalcosts_real - automation_real
drop if costs<0

* Remove computer investments from total investments
gen investments_ex = totalinvestments_real - computers_real
sum investments_ex, det // we have zeros, two observations <0
gen comp_worker=computers_real/nr_workers_mar
* Drop large outliers
drop if comp_worker>=3000
drop comp_worker

// Keep only firms where we have at least 3 observations
gen i = 1
bys beid: egen total_i = total(i)
keep if total_i>=3
drop i total_i
distinct beid

compress
save dta/intermediate/firm_prespike_overlapping2016.dta, replace

* Defining spikes

use dta/intermediate/firm_prespike_overlapping2016.dta, clear

** COMPUTER SPIKES **
* 2. Calculate for each year the computer investment share (computer / avg number of workers, or total costs)
* Note that we cannot use total investments, because it is not defined the in the same way across years
* We can also use total costs for the overlapping sample
gen computer_share=.
forvalues y=2000/2016{
	bys beid: gegen avg_workers = mean(nr_workers_mar) if !missing(totalinvestments_real)
	*bys beid: egen avg_costs = mean(costs) if !missing(totalinvestments_real)	
	replace computer_share = computers_real / avg_workers if year==`y' & missing(computer_share)
	drop avg_workers 
}

* 3. Calculate for each year the automation cost share relative to average automation cost share excluding the current year in the average
gen help2=computer_share
gen spike=.
forvalues y=2000/2016{
	replace computer_share = . if year==`y' // First set the current year to missing, so it is not included in the average
	bys beid: egen firm_computer_share = mean(computer_share) // Then calculate average
	replace computer_share=help2
	replace spike = computer_share / firm_computer_share if year==`y' & missing(spike) // Calculate "spike" computer share relative to average computer share
	drop firm_computer_share
}
drop help2

// If spike >= 3, we call this a computer spike
gen spike_comp = spike>=3 & spike!=.
// Exclude spikes if absolute level of spending is smaller than 25th percentile or smaller than minimum of other years by firm
sum computer_share if computer_share>0, det
replace spike_comp = 0 if computer_share<`r(p25)'
by beid: egen min_spending=min(computer_share)
replace spike_comp=0 if computer_share<=min_spending
drop min_spending

* Largest spike
gsort beid -spike_comp -spike
by beid: gen spike_comp_large = 1 if spike_comp==1 & _n==1
replace spike_comp_large=0 if missing(spike_comp_large)
drop spike

* Define first spike
bys beid: gen x = year if spike_comp==1
by beid: ereplace x = min(x)
gen spike_comp_first = 1 if year == x & spike_comp==1
replace spike_comp_first = 0 if missing(spike_comp_first)
drop x

label var spike_comp "Any computer spike (3x)" 
label var spike_comp_large "Largest computer spike (3x)"
label var spike_comp_first "First computer spike (3x)"

/* 2. Automation spike */

* Calculate for each year the automation cost share (automation / avg total cost) 
gen automation_tocosts=.
forvalues y=2000/2016{
	bys beid: egen avg_costs = mean(costs)
	replace automation_tocosts = automation_real / avg_costs if year==`y' & missing(automation_tocosts)
	drop avg_costs 
}

* Calculate for each year the automation cost share relative to average automation cost share excluding the current year in the average

gen help2=automation_tocosts
gen spike=.
forvalues y=2000/2016{
	replace automation_tocosts = . if year==`y'
	bys beid: egen firm_automation_tocosts = mean(automation_tocosts)
	replace automation_tocosts=help2
	replace spike = automation_tocosts / firm_automation_tocosts if year==`y'
	drop firm_automation_tocosts
}
drop help2

gen spike_autom = spike>=3 & spike!=.

// Exclude spikes if absolute level of spending is smaller than 25th percentile or smaller than minimum of other years by firm
sum automation_tocosts if automation_tocosts>0, det
replace spike_autom=0 if automation_tocosts<`r(p25)'
// 10-5-2019 also absolute level of spending must be higher than in other years
by beid: egen min_spending=min(automation_real)
replace spike_autom=0 if automation_real<=min_spending
drop min_spending

* Largest spike
gsort beid -spike_autom -spike
by beid: gen spike_autom_large = 1 if spike_autom==1 & _n==1
replace spike_autom_large=0 if missing(spike_autom_large)
drop spike

* Define first spike
bys beid: gen x = year if spike_autom==1
by beid: ereplace x = min(x)
gen spike_autom_first = 1 if year == x & spike_autom==1
replace spike_autom_first = 0 if missing(spike_autom_first)
drop x

label var spike_autom "Any automation spike (3x)" 
label var spike_autom_large "Largest automation spike (3x)"
label var spike_autom_first "First automation spike (3x)"

compress

preserve
keep beid year spike*
save dta/intermediate/firm_spikes_overl.dta, replace
restore

save dta/intermediate/firmsample_overl.dta, replace
keep beid
duplicates drop
save dta/intermediate/firmsample_beid_overl.dta, replace

