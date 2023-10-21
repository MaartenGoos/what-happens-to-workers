*------------------------------------------------------------------------
* Automation
* create_samples.do
* 3/5/2018
* Last updated: 24/4/2022
* Wiljan van den Berge
* Purpose: use prepared worker data and create firm and worker samples
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
log using log/create_samples, text replace
*--------------------------------------------------------------------------

foreach sample in $samplelist{ // [...]
	* Load all firms that we used to calculate spikes on for this sample
	if "`sample'" == "never_autom"{ // For never-treated, use the regular automation sample as the starting point
		use dta\intermediate\firmsample_beid_autom.dta, clear
	}
	if "`sample'" == "overl_autom2" | "`sample'" == "overl_comp2" | "`sample'" == "overl_autom1" | "`sample'" == "overl_comp1"{
		use dta\intermediate\firmsample_beid_overl.dta, clear
	}
	if "`sample'" == "overl_other1" | "`sample'" == "overl_other2"{
		use dta/intermediate/firmsample_beid_placebo_overl.dta, clear
	}
	if "`sample'"== "import"{
		use beid using dta/intermediate/import_spikes.dta, clear
		bys beid: keep if _n==1
	}
	if "`sample'" != "never_autom" & "`sample'" !="overl_autom2" & "`sample'" != "overl_comp2" & "`sample'" !="overl_autom1" & "`sample'" != "overl_comp1" &  "`sample'" != "overl_energy1" & "`sample'" != "overl_energy2" &  "`sample'" != "overl_repairs1" &  "`sample'" != "overl_repairs2" & "`sample'" != "overl_other1" & "`sample'" != "overl_other2" & "`sample'" != "import"{ 
		use dta\intermediate\firmsample_beid_`sample'.dta, clear
	}


	* Merge to worker data
	merge 1:m beid using dta\intermediate\workerdata9916.dta, keep(match master) keepusing(rinpersoon year wage days soortbaan educ age female) gen(merge_check)

	* Prepare for firm-level characteristics of workers: age, tenure, wage, daily wage, women, education
	gen daily_wage = wage/days
	tab educ, gen(edu)
	tab soortbaan, gen(type)
	gen byte i = 1

	keep beid year i wage daily_wage age female edu* type*

	compress
	save dta/temp/pre_collapse_`sample'.dta, replace
	
	* Collapse at the year-firm level
	use dta/temp/pre_collapse_`sample'.dta, clear

	gcollapse (mean) mn_wage=wage mn_daily_wage=daily_wage mn_age=age female ///
		edu1 edu2 edu3 edu4 type1 type2 type3 type4 type5 type6	///	
		(p50) p50_wage=wage p50_daily_wage=daily_wage p50_age=age ///
		(p25) p25_wage=wage p25_daily_wage=daily_wage p25_age=age ///
		(p75) p75_wage=wage p75_daily_wage=daily_wage p75_age=age ///
		(count) nr_workers = i ///
		, by(beid year)

	* Merge to firm PS data [from define_spikes.do, also includes firms that only have a smaller spike at some point]	
	
		   if "`sample'" == "never_autom"{
		   merge 1:1 beid year using dta\intermediate\firmsample_autom.dta, gen(merge_firm) ///
		   keepusing(gk computers machines totalcosts_real automation opinc_real employee_fte total_fte revenue_real sbi2008_2dig sbi2008_letter sbi2008 sbi2008_1dig p_output p_addedvalue ///
			revenue_real opinc_real revenue_worker income_worker wagebill_svy  spike_firm spike_firm_large spike_firm_first spike ///
			costofsales_real costofoutsourcing_real costofsales_real totalcosts_real automation_real otherrev_real otherrev_real othercosts_real ///
			bedrlst345100 bedrlst345200 revenue ophoogfactor ebt_real ebt_worker result_real result_worker)
		   }
	if "`sample'" != "never_autom" & "`sample'" != "comp" & "`sample'" !="overl_autom2" & "`sample'" != "overl_comp2" & "`sample'" !="overl_autom1" & "`sample'" != "overl_comp1" & "`sample'" != "overl_other1" & "`sample'" != "overl_other2" & "`sample'" != "imports"{
		merge 1:1 beid year using dta\intermediate\firmsample_`sample'.dta, gen(merge_firm) ///
			keepusing(gk computers machines totalcosts_real automation opinc_real employee_fte total_fte revenue_real sbi2008_2dig sbi2008_letter sbi2008 sbi2008_1dig p_output p_addedvalue ///
			revenue_real opinc_real revenue_worker income_worker wagebill_svy spike_firm spike_firm_large spike_firm_first spike ///
			costofsales_real costofoutsourcing_real costofsales_real totalcosts_real automation_real otherrev_real otherrev_real othercosts_real ///
			bedrlst345100 bedrlst345200 revenue ophoogfactor ebt_real ebt_worker result_real result_worker)
	}	
	if "`sample'" == "overl_autom2" | "`sample'" == "overl_comp2" | "`sample'" == "overl_autom1" | "`sample'" == "overl_comp1"{	
		merge 1:1 beid year using dta\intermediate\firmsample_overl.dta, gen(merge_firm) ///
			keepusing(gk computers machines totalcosts_real automation opinc_real employee_fte total_fte revenue_real sbi2008_2dig sbi2008_letter sbi2008 sbi2008_1dig p_output p_addedvalue ///
			revenue_real opinc_real revenue_worker income_worker wagebill_real spike_autom* spike_comp*  ///
			costofsales_real costofoutsourcing_real costofsales_real costs totalcosts_real automation_real otherrev_real otherrev_real othercosts_real ///
			bedrlst345100 bedrlst345200 revenue computers_real computer_share totalinvestments totalinvestments_real investments_ex ophoogfactor ebt_real ebt_worker result_real result_worker)
	}
	if "`sample'" == "overl_other1" | "`sample'" == "overl_other2"{
		merge 1:1 beid year using dta\intermediate\firmsample_placebo_overl.dta, gen(merge_firm) ///
			keepusing(gk othermaterial othermaterial_real machines totalcosts_real automation opinc_real employee_fte total_fte revenue_real sbi2008_2dig sbi2008_letter sbi2008 sbi2008_1dig p_output p_addedvalue ///
			revenue_real opinc_real revenue_worker income_worker wagebill_real spike_autom* spike_othermaterial*  ///
			costofsales_real costofoutsourcing_real costofsales_real costs totalcosts_real automation_real otherrev_real otherrev_real othercosts_real ///
			bedrlst345100 bedrlst345200 revenue totalinvestments totalinvestments_real ophoogfactor ebt_real ebt_worker result_real result_worker)			
		
		rename spike_othermaterial spike_other
		rename spike_othermaterial_first spike_other_first
		rename spike_othermaterial_large spike_other_large
	}
	if "`sample'" == "import"{
		merge 1:1 beid year using dta/intermediate/import_spikes.dta, gen(merge_firm)
	}

	/* Merge manual GK, number of workers in dec, wagebill and firm start year */
	cap drop gk_manual nr_workers_mar wagebill 
	// Merge GK manual
	merge m:1 beid year using dta/intermediate/beid_manual_gk_mar_all.dta, keep(match master) gen(merge_gk)

	// merge wagebill
	merge m:1 beid year using dta/intermediate/beid_wagebill.dta, keep(match master) gen(merge_wagebill)

	// Merge firm age
	merge m:1 beid using dta/intermediate/beid_firmstart.dta, keep(match master) gen(merge_firmstart)


	drop if merge_gk==1 | merge_wagebill==1 | merge_firmstart==1
	drop merge_gk merge_wagebill merge_firmstart

	label define m 1 "Admin data, no PS data" 2 "PS data, no admin data" 3 "Both PS and admin data"
	label values merge_firm m

	* Keep if firms are only in the admin data or in both
	keep if merge_firm==3 | merge_firm==1
	distinct beid

	* Assign firm to time-constant sector
	foreach var of varlist sbi2008_1dig sbi2008_2dig sbi2008 sbi2008_letter{
		gsort beid -`var'
		by beid: replace `var' = `var'[_n-1] if missing(`var')
	}
	
	label var mn_wage "Mean yearly wage"
	label var mn_daily_wage "Mean dialy wage"
	label var mn_age "Mean age"
	label var female "Share female"
	label var p50_wage "Median yearly wage"
	label var p50_daily_wage "Median daily wage"
	label var p50_age "Median age"
	label var p25_wage "25th perc yearly wage"
	label var p25_daily_wage "25th perc daily wage"
	label var p25_age "25th perc age"
	label var p75_wage "75th perc yearly wage"
	label var p75_daily_wage "75th perc daily wage"
	label var p75_age "75th perc age"
	
	compress

	// For overlapping sample save only the separate files
	if "`sample'" == "overl_autom2" | "`sample'" == "overl_comp2" | "`sample'" == "overl_autom1" | "`sample'" == "overl_comp1"{
		save dta\intermediate\firm_level_data_overl.dta, replace
	}		
	else{ 
		save dta\intermediate\firm_level_data_`sample'.dta, replace
	}
	keep beid
	duplicates drop
	save dta\intermediate\beid_selected_`sample'.dta, replace


	* Now create a sample for worker level analyses
	use dta\intermediate\workerdata9916.dta, clear

	* Use only the firms in the firm level data derived above
	merge m:1 beid using dta\intermediate\beid_selected_`sample'.dta, keep(match master) gen(merge_firm)

	* Keep workers if they are observed at one of the firms selected above at least once
	bys rinpersoons rinpersoon: ereplace merge_firm = max(merge_firm)
	keep if merge_firm==3
	drop merge_firm

	compress

	if "`sample'" == "overl_autom2" | "`sample'" == "overl_comp2" | "`sample'" == "overl_autom1" | "`sample'" == "overl_comp1"{
		save dta\intermediate\worker_baseline_sample_overl.dta, replace
	}		
	else{
		save dta\intermediate\worker_baseline_sample_`sample'.dta, replace
	}
}

