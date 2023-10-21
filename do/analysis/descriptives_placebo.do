*------------------------------------------------------------------------
* Automation
* descriptives_placebo.do
* 26/11/2020
* Wiljan van den Berge
* Purpose: create descriptives of spikes and automation costs and other material investments (placebo)
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
log using log/descriptives_placebo, text replace
*--------------------------------------------------------------------------

* Provide descriptives on "other material investments" as placebo, and compare with automation costs

use dta/intermediate/firmsample_placebo_overl.dta, clear


*****************
*** Table E.6 ***
*****************
* Descriptives on automation cost share and other investment share
est clear
cap drop a_emp

// Calculate time-varying automation to costs instead of using the averaged scaling for descriptives
rename automation_tocosts automation_tocosts_avg
gen automation_tocosts = automation_real / (totalcosts_real - automation_real)
replace automation_tocosts=0 if automation_real==0
replace automation_tocosts = automation_tocosts * 100
replace automation_real = automation_real * 1000
gen a_emp=automation_real / nr_workers_mar

foreach inv in othermaterial{
	gen `inv'_toinv = `inv'_real / totalinvestments_real
	replace `inv'_toinv=0 if `inv'_real==0
	replace `inv'_toinv = `inv'_toinv * 100
	replace `inv'_real = `inv'_real * 1000
	gen `inv'_emp=`inv'_real / nr_workers_mar
}

eststo: estpost tabstat automation_tocosts automation_real a_emp othermaterial_toinv othermaterial_real othermaterial_emp, statistics(p5 p10 p25 p50 p75 p90 p95 mean)
count if automation_real<=0
gen zero_a = `r(N)'
sum zero_a
estadd r(max): est1
count if infrastructure_real<=0
gen zero_i = `r(N)'
sum zero_i
estadd r(min): est1
count if othermaterial_real<=0
gen zero_o = `r(N)'
sum zero_o
estadd r(mean): est1

eststo: estpost tabstat automation_tocosts automation_real a_emp othermaterial_toinv othermaterial_real othermaterial_emp if automation_real>0, statistics(p5 p10 p25 p50 p75 p90 p95 mean)
eststo: estpost tabstat automation_tocosts automation_real a_emp othermaterial_toinv othermaterial_real othermaterial_emp if othermaterial_real>0, statistics(p5 p10 p25 p50 p75 p90 p95 mean)

esttab est1 est2 est3 using output/des_overlapping_placebo.csv, cells("automation_real(fmt(0)) a_emp(fmt(0)) automation_tocosts(fmt(2)) othermaterial_real(fmt(0)) othermaterial_emp(fmt(0)) othermaterial_toinv(fmt(2))  ") ///
replace nonumber mtitles("All observations" "Observations with >0 automation costs" "Observations with >0 other material investments") ///
collabels("Autom level" "Autom by worker" "Autom share" "Other level" "Other by worker" "Other share") stats(N max, fmt(0 0) labels("N firms x years" "N with 0 costs")) title("Automation and other material investments distribution") plain

est clear

*****************
*** Table E.7 ***
*****************

* Automation and placebo spike frequency by firm 
est clear

label define sa 0 "No autom spike" 1 "Autom spike"
label define sc 0 "No other spike" 1 "Other spike"
label values spike_autom spike_autom_first sa
label values spike_othermaterial spike_othermaterial_first sc


bys beid: egen t_spikes_a = total(spike_autom)
bys beid: egen t_spikes_c = total(spike_othermaterial)
label var t_spikes_a "Automation spike frequency by firm"
label var t_spikes_c "Other spike frequency by firm"

eststo: estpost tab spike_autom spike_othermaterial
eststo: estpost tab spike_autom_first spike_othermaterial_first

eststo: estpost tab t_spikes_a
eststo: estpost tab t_spikes_c


esttab est1 est2 using output/des_overlapping_placebo.csv, cells("colpct(fmt(2))") label eqlabels(, lhs("Automation spike")) append nonumber mtitles("All spikes" "First spikes") title("Co-occurring automation and other spikes (all and first)")

esttab est3 est4 using output/des_overlapping_placebo.csv, cells("pct(fmt(2))") label eqlabels(, lhs("Number of spikes")) append nonumber mtitles("Automation" "Other materials") title("Automation and other spikes frequency")

******************
*** FIGURE E.3 ***
******************

gen spikeyr_a=year if spike_autom_first==1
gen spikeyr_c = year if spike_othermaterial_first==1
foreach var of varlist spikeyr_a spikeyr_c{
	gsort beid -`var'
	by beid: replace `var'=`var'[_n-1] if missing(`var')
}
gen time_a = year-spikeyr_a
gen time_c = year-spikeyr_c

/* Middlefinger graph, relative to first spike in other material investments */
preserve
	gen n=1
	collapse (mean) othermaterial_emp (sum) n, by(time_c)
	xmlsave output/des_mfgraph_overl_other.xml, replace doctype(excel)
restore
