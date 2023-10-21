*------------------------------------------------------------------------
* Automation
* worker_quantiles.do
* Last updated: 3/7/2020
* Wiljan van den Berge
* Purpose: calculate worker (residual) wage quantiles
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
log using log/worker_quantiles, text replace
*--------------------------------------------------------------------------

* Load data: only incumbents
use dta/analysis/worker_analysis_drop7_autom.dta if weight1!=0 & weight1!=. & inc==1, clear

// generate wage, sector and firm size at t=-1
keep if time==-1

assert !missing(lnwage)
assert !missing(sector_treatyr)
assert !missing(gk_treatyr)

// 1. Age-specific wage quartiles across the full population
egen age_cat = cut(age), at(20,30,40,50,61)

gen quart_age=.
forvalues a=20(10)50{
	xtile age_quart`a'=lnwage if age_cat==`a', nquantiles(4)
	replace quart_age=age_quart`a' if age_cat==`a'
	drop age_quart`a'
}


// 2. Firm age-specific wage quartiles

* First calculate quartiles by firm-age category
preserve
* Drop if firm-age group is <5 obs
	gen j=1
	bys firmid_inc age_cat: egen t = total(j)
	gen drop=1 if t<5
	bys firmid_inc: ereplace drop=max(drop)
	drop if drop==1
	gen byte i=1
	collapse (p25) firmw25=lnwage (p50) firmw50=lnwage (p75) firmw75=lnwage (sum) i=i, by(firmid_inc age_cat)
	save dta/intermediate/firm_age_quart.dta, replace
restore

merge m:1 firmid_inc age_cat using dta/intermediate/firm_age_quart.dta, keep(match master) nogen

gen quart_age_firm=.
replace quart_age_firm=1 if lnwage<firmw25 & !missing(firmw25)
replace quart_age_firm=2 if lnwage>=firmw25 & lnwage<firmw50 & !missing(firmw50)
replace quart_age_firm=3 if lnwage>=firmw50 & lnwage<firmw75 & !missing(firmw75)
replace quart_age_firm=4 if lnwage>=firmw75 & lnwage!=.


// 3. Residual wage quartiles after regressing on characteristics
reg lnwage female##foreign female##c.age female##c.age2 female##sector_treatyr ///
c.age##foreign c.age##sector_treatyr ///
foreign##sector_treatyr ///
i.year 

predict res, residuals

xtile quart_res = res, nquantiles(4)

label var quart_res "Residual wage quartile at t=-1"
label var quart_age "Wage quartile by age group at t=-1"
label var quart_age_firm "Within firm wage quartile by age group at t=-1"
keep id quart_res quart_age quart_age_firm
compress


save dta/intermediate/quartiles_autom.dta, replace

// Clean up temporary files
rm dta/intermediate/firm_age_quart.dta
