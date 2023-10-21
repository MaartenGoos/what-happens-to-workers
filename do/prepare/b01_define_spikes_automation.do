*------------------------------------------------------------------------
* Automation
* define_spikes_automation.do
* Last updated: 11/6/2020
* Wiljan van den Berge
* Purpose: clean PS data and define spikes. Restrict to firms we observe at least 3 times in PS
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
log using log/define_spikes_automation, text replace
*--------------------------------------------------------------------------

use dta\intermediate\inv_ps_9316_merged.dta if year>=2000 & year<=2016, clear

// Drop one firm with data problems
qui drop if beid=="13514466"


qui distinct beid
display "Start with `r(ndistinct)' distinct firms and `r(N)' observations for 2016 sample in the full PS-INV data"

quietly{
	* Merge GK manual
	merge m:1 beid year using dta/intermediate/beid_manual_gk_mar_all.dta, gen(merge_gk) 

	* merge wagebill
	merge m:1 beid year using dta/intermediate/beid_wagebill.dta, gen(merge_wagebill) 

	* Merge firm age
	merge m:1 beid using dta/intermediate/beid_firmstart.dta, keep(match master) gen(merge_firmstart) 
	* Calculate lagged employment
	sort beid year
	by beid: gen emp_t1 = nr_workers_mar[_n-1]
	by beid: gen wagebill_t1 = wagebill[_n-1]

	* Drop missings on wagebill, number of workers [basically dropping firms that don't employ any workers in that year]
	drop if missing(wagebill)
	drop if missing(gk_manual)
	drop if missing(nr_workers_mar)

	** keep only firms in PS
	keep if merge_ps_inv==2 | merge_ps_inv==3


	* Drop very small sectors that shouldn't be in the data anyways, since PS is sector based
	drop if sbi2008_letter=="A" | sbi2008_letter=="B" | sbi2008_letter=="D" | sbi2008_letter=="E" | sbi2008_letter=="L" | sbi2008_letter=="R" | sbi2008_letter=="S"
}
qui distinct beid
display "After keeping only PS data, dropping missings on admin data and dropping small sectors, we have `r(ndistinct)' distinct firms and `r(N)' observations left for 2016 sample"


*Keep only relevant variables
keep beid year gk aloeu01nr6 aloeu01nr57 bedrlst310000 bedrlst348400 opbreng000000 sbi2008_2dig sbi2008_letter sbi2008 merge_ps_inv persons110000 omzet_final p_output p_addedvalue loonsom110000 loonsom100000 ///
	opbreng100000 bedrlst345100 bedrlst345200 inkwrde13200 inkwrde100000 othercosts persons110100 gk_manual nr_workers_mar wagebill firm_startyr emp_t1 wagebill_t1 med_wage med_dwage mn_wage mn_dwage totaldays ophoogfactor results120000 results130000

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
rename opbreng100000 otherrevenue
rename inkwrde100000 costofsales
rename inkwrde132000 costofoutsourcing
rename results130000 ebt
rename results120000 result

* Generate real variables
gen automation_real = automation
gen totalcosts_real = totalcosts
gen costofsales_real = costofsales
gen othercosts_real = othercosts
gen costofoutsourcing_real = costofoutsourcing
gen wagebill_svy = loonsom110000
gen revenue_real = revenue
gen opinc_real = operatingincome
gen otherrev_real = otherrevenue
gen ebt_real = ebt
gen result_real = result

* Deflate by CPI
merge m:1 year using H:/cpi9619.dta, nogen keep(match master)
foreach var in automation_real totalcosts_real wagebill_svy costofsales_real costofoutsourcing_real othercosts_real revenue_real opinc_real otherrev_real result_real ebt_real{
	replace `var'=(`var'/cpi)*100
}

* Construct revenue per total workers
gen revenue_worker = revenue_real / nr_workers_mar
gen result_worker = result_real / nr_workers_mar
gen ebt_worker = ebt_real / nr_workers_mar
gen income_worker = opinc_real/nr_workers_mar

* Sector labels
encode sbi2008_letter, gen(sbi2008_1dig)
label define s 1 "Manufacturing" 2 "Construction" 3 "Wholesale and retail trade" ///
	4 "Transportation and storage" 5 "Accommodation and food serv" 6 "Information and communication" ///
	7 "Prof, scientific, techn act" 8 "Admin and support act"
label values sbi2008_1dig s

// Drop missings on automation costs and total costs [Essentially only keeping firms that are in the survey in those years]
drop if missing(automation_real)
drop if missing(totalcosts_real)
drop if missing(sbi2008_1dig)
// Keep only firms where we have at least 3 observations
gen costs = totalcosts_real - automation_real
drop if costs<0 // Drop firms if costs are smaller than 0

gen i = 1
bys beid: egen total_i = total(i)
keep if total_i>=3
drop i total_i
distinct beid	

qui distinct beid
display "After dropping missings on automation costs, total costs and sector, and only keeping firms with at least 3 observations in PS, we have `r(ndistinct)' distinct firms and `r(N)' observations left for 2016 sample"
** 35,564 is the same as our last export!
save dta/intermediate/firm_prespike_autom2016.dta, replace

* Define spikes in 6 different ways [for robustness checks]

* 2: Scale automation costs relative to average number of workers over same period as we observe them in survey
* 3: Scale relative to average number of workers in the years before
* 4: Scale relative to average total costs (MAIN METHOD)
* 8: Scale relative to employment in all years firm exists
* 9: Spike = 4x instead of 3x
* 10: Spike = 2x instead of 3x

foreach m in 2 3 4 8 9 10{
	use dta/intermediate/firm_prespike_autom2016.dta, clear
	/* EMPLOYMENT SCALING METHODS */
	*Method 2 scale automation costs relative to average number of workers over same period we observe total costs
	if `m'==2{
		* Use the same years as the costs data to calculate average nr of workers
		forvalues y=2000/2016{
			bys beid: egen avg_nr_workers = mean(nr_workers) if !missing(costs)
			gen a_emp`y' = automation_real / avg_nr_workers if year==`y'
			drop avg_nr_workers 
		}

		gen a_emp=.
		forvalues y=2000/2016{
			replace a_emp = a_emp`y' if year==`y' & missing(a_emp)
		}
		drop a_emp2*
	}

	if `m'==8{
		* Method 8: average over all the years we observe the firm
		forvalues y=2000/2016{
			bys beid: egen avg_nr_workers = mean(nr_workers)
			gen a_emp`y' = automation_real / avg_nr_workers if year==`y'
			drop avg_nr_workers 
		}

		gen a_emp=.
		forvalues y=2000/2016{
			replace a_emp = a_emp`y' if year==`y' & missing(a_emp)
		}
		drop a_emp2*
	}

	* Method 3: scale relative to pre-period averaged employment
	if `m'==3{
		forvalues y=2000/2016{
			bys beid: egen avg_nr_workers = mean(nr_workers) if year<`y'
			gsort beid -avg_nr_workers
			by beid: replace avg_nr_workers=avg_nr_workers[_n-1] if missing(avg_nr_workers)
			gen a_emp`y' = automation_real / avg_nr_workers if year==`y'
			drop avg_nr_workers 
		}

		gen a_emp=.
		forvalues y=2000/2016{
			replace a_emp = a_emp`y' if year==`y' & missing(a_emp)
		}
		drop a_emp2*
	}

	if `m'==2 | `m'==3 | `m'==8{
		// Drop those with missings on automation/employment and then keep only firms where we have at least 3 observations
		drop if missing(a_emp)
		gen i = 1
		bys beid: egen total_i = total(i)
		keep if total_i>=3
		drop i total_i
		distinct beid

		sum a_emp if a_emp>0, det


		*Calculate for each year the automation cost relative to employment relative to the average automation cost rel to employment (over all other years, excluding the current year)
		gen help2=a_emp
		forvalues y=2000/2016{
			replace a_emp = . if year==`y'
			bys beid: egen firm_a_emp = mean(a_emp)
			replace a_emp=help2
			gen spike`y' = a_emp / firm_a_emp if year==`y'
			drop firm_a_emp
		}
	}


	/* COSTS METHODS */
	if `m'==4 |`m'==9 | `m'==10{
		* 2. Calculate for each year the automation cost share (automation / avg total cost) 
		forvalues y=2000/2016{
			bys beid: egen avg_costs = mean(costs)
			gen automation_tocosts`y' = automation_real / avg_costs if year==`y'
			drop avg_costs 
		}
	}
	if `m'==4 | `m'==9 | `m'==10{
		gen automation_tocosts=.
		forvalues y=2000/2016{
			replace automation_tocosts = automation_tocosts`y' if year==`y' & missing(automation_tocosts)
		}
		drop automation_tocosts2*
	}
	* 3. Calculate for each year the automation cost share relative to average automation cost share excluding the current year in the average
	if `m'==4 | `m'==9 | `m'==10{
		gen help2=automation_tocosts
		forvalues y=2000/2016{
			replace automation_tocosts = . if year==`y'
			bys beid: egen firm_automation_tocosts = mean(automation_tocosts)
			replace automation_tocosts=help2
			gen spike`y' = automation_tocosts / firm_automation_tocosts if year==`y'
			drop firm_automation_tocosts
		}
	}

	/* DEFINE SPIKES FOR ALL METHODS OF SCALING */
	gen spike=.
	forvalues y=2000/2016{
		replace spike = spike`y' if year==`y' & missing(spike)
	}
	drop spike20*

	* Spike = three times the firm average of automation relative to some scaling
	if (`m'>=1 & `m'<=8){
		gen spike_firm = spike>=3 & spike!=.
	}
	if `m'==9{
		gen spike_firm = spike>=4 & spike!=.
	}
	if `m'==10{
		gen spike_firm = spike>=2 & spike!=.
	}
	* Drop spikes if spending per worker is less than 25th percentile of the non-zero automation/worker distr
	if `m'==2 | `m'==3 | `m'==8{
		sum a_emp if a_emp>0, det
		replace spike_firm=0 if a_emp<`r(p25)'
	}

	if `m'==4 | `m'==9 | `m'==10{
		sum automation_tocosts if automation_tocosts>0, det
		replace spike_firm=0 if automation_tocosts<`r(p25)'
	}
	* Drop spikes if absolute level of spending must be higher than in other years
	by beid: egen min_spending=min(automation_real)
	replace spike_firm=0 if automation_real<=min_spending
	* Define largest spike for firms with >1 spike
	gsort beid -spike_firm -spike
	by beid: gen spike_firm_large = 1 if spike_firm==1 & _n==1
	replace spike_firm_large=0 if missing(spike_firm_large)

	* Define first spike
	bys beid: gen x = year if spike_firm==1
	by beid: ereplace x = min(x)
	gen spike_firm_first = 1 if year == x & spike_firm==1
	replace spike_firm_first = 0 if missing(spike_firm_first)
	drop x

	label var spike_firm "Any spike (3x)" 
	label var spike_firm_large "Largest spike (3x)"
	label var spike_firm_first "First spike (3x)"

	compress

	* Save dataset to compare different scalings
	/*
		   preserve
		   keep beid year spike_firm spike_firm_large spike_firm_first automation_real nr_workers
		   rename * *_`m'
		   rename beid_`m' beid
		   rename year_`m' year
		   compress

		   save dta/intermediate/compare_spike`m'.dta, replace
		   restore
	*/
	* Save datasets for robustness checks
	if `m'==4{ // main method
		//Also keep firms that never spike - because we need this data for descriptives on which firms spike etc.
		preserve
		keep beid year spike*
		save dta/intermediate/firm_spikes_autom.dta, replace
		keep if spike_firm_large==1 & year==2016
		gen spike_2016=1
		keep beid spike_2016
		duplicates drop
		save dta/intermediate/firm_spikes_2016_autom.dta, replace
		restore

		save dta/intermediate/firmsample_autom.dta, replace
		keep beid
		duplicates drop
		save dta/intermediate/firmsample_beid_autom.dta, replace
	}
	if `m'==2{ // method using average number of workers over years we also observe total costs
		//Also keep firms that never spike - because we need this data for descriptives on which firms spike etc.
		preserve
		keep beid year spike*
		save dta/intermediate/firm_spikes_emp_autom.dta, replace
		keep if spike_firm_large==1 & year==2016
		gen spike_2016=1
		keep beid spike_2016
		duplicates drop
		save dta/intermediate/firm_spikes_2016_emp_autom.dta, replace
		restore

		save dta/intermediate/firmsample_emp_autom.dta, replace
		keep beid
		duplicates drop
		save dta/intermediate/firmsample_beid_emp_autom.dta, replace
	}	
	if `m'==8{ // method using average number of workers over entire period we observe them in admin data
		//Also keep firms that never spike - because we need this data for descriptives on which firms spike etc.
		preserve
		keep beid year spike*
		save dta/intermediate/firm_spikes_empf_autom.dta, replace
		keep if spike_firm_large==1 & year==2016
		gen spike_2016=1
		keep beid spike_2016
		duplicates drop
		save dta/intermediate/firm_spikes_2016_empf_autom.dta, replace
		restore

		save dta/intermediate/firmsample_empf_autom.dta, replace
		keep beid
		duplicates drop
		save dta/intermediate/firmsample_beid_empf_autom.dta, replace
	}	
	if `m'==3{ // using average number of workers over pre-period
		//Also keep firms that never spike - because we need this data for descriptives on which firms spike etc.
		preserve
		keep beid year spike*
		save dta/intermediate/firm_spikes_empt0_autom.dta, replace
		keep if spike_firm_large==1 & year==2016
		gen spike_2016=1
		keep beid spike_2016
		duplicates drop
		save dta/intermediate/firm_spikes_2016_empt0_autom.dta, replace
		restore

		save dta/intermediate/firmsample_empt0_autom.dta, replace
		keep beid
		duplicates drop
		save dta/intermediate/firmsample_beid_empt0_autom.dta, replace
	}
	if `m'==9{ // spike = 4x instead of 3x
		//Also keep firms that never spike - because we need this data for descriptives on which firms spike etc.
		preserve
		keep beid year spike*
		save dta/intermediate/firm_spikes_spike4_autom.dta, replace
		keep if spike_firm_large==1 & year==2016
		gen spike_2016=1
		keep beid spike_2016
		duplicates drop
		save dta/intermediate/firm_spikes_2016_spike4_autom.dta, replace
		restore

		save dta/intermediate/firmsample_spike4_autom.dta, replace
		keep beid
		duplicates drop
		save dta/intermediate/firmsample_beid_spike4_autom.dta, replace
	}
	if `m'==10{ // spike = 2x instead of 3x
		//Also keep firms that never spike - because we need this data for descriptives on which firms spike etc.
		preserve
		keep beid year spike*
		save dta/intermediate/firm_spikes_spike2_autom.dta, replace
		keep if spike_firm_large==1 & year==2016
		gen spike_2016=1
		keep beid spike_2016
		duplicates drop
		save dta/intermediate/firm_spikes_2016_spike2_autom.dta, replace
		restore

		save dta/intermediate/firmsample_spike2_autom.dta, replace
		keep beid
		duplicates drop
		save dta/intermediate/firmsample_beid_spike2_autom.dta, replace
	}
} // End m-loop
