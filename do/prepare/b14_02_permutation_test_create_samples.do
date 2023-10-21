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
*--------------------------------------------------------------------------

forvalues p=$p_min/$p_max{
	set seed `p' // Set a seed each random draw in one p

	// Then draw a random sample WITHOUT replacement (so it's not entirely random, because firms can be there at most 100 times)
	use dta/intermediate/firms_expanded.dta if n==1, clear
	sample 20000, count
	keep firmid
	save dta/intermediate/firms_sampled`p'.dta, replace

	// Then assign a random year to each firm
	use dta/intermediate/firms_sampled`p'.dta, clear
	gen random=runiform(0,17)
	replace random=floor(random)
	gen spikeyr=2000+random
	drop random
	merge 1:m firmid using dta/intermediate/firms_expanded.dta, keep(match master) nogen // [This merge requires no duplicates in firmid, that is why we sample without replacement above (though of course there can be duplicates in beid, the actual firm)
	save dta/intermediate/perm_spikeyr_p`p'.dta, replace

	// Can firms function as treated? I.e. do we observe enough years around the assigned year so that firms can be treated in each assigned spike year?
	use dta/intermediate/perm_spikeyr_p`p'.dta, clear
	gen byte treat=.
	forvalues y=2003/2011{ // Since we require 3 years before, we only use spike years from 2003 - 2011
		gen t`y' = 1 if spikeyr==`y' & year>=`y'-3 & year<=`y'+5
		bys firmid: egen t_t`y' = total(t`y')
		replace treat = 1 if t_t`y'==9 // Firms have to be observed in each year
		drop t`y' t_t`y'
	}
	drop if missing(treat)
	gen sampleyear=spikeyr
	drop spikeyr
	save dta/intermediate/perm_p`p'_treat.dta, replace

	// For which year(s) can firms function as control? Potentially more than once.
	forvalues y=2003/2011{
		use dta/intermediate/perm_spikeyr_p`p'.dta, clear
		gen spikeyrc=`y'+5
		gen c`y' = 1 if spikeyr>=spikeyrc & year>=`y'-3 & year<=`y'+5 // Firms are potential controls if they spike in year t+5 or later, and if they are observed around the treatment spike
		bys firmid: egen t_c`y' = total(c`y')
		gen control = 1 if t_c`y'==9 // Firms have to be observed in each year
		drop if missing(control)
		drop c`y' t_c`y' spikeyrc
		gen sampleyear=`y'
		save dta/intermediate/perm_p`p'_control`y'.dta, replace
	}

	// Append the treated and control firms
	use dta/intermediate/perm_p`p'_treat.dta, clear
	forvalues y=2003/2011{
		append using dta/intermediate/perm_p`p'_control`y'.dta
	}

	replace treat=0 if control==1

	replace sampleyear=sampleyear-1 // Sampleyear - 1 is the year where we merge worker data
	keep if year==sampleyear 

	/* As a check we can define a new firmid using treatment status and sampleyear; there are no duplicates in this one */
	gegen firmid2=group(firmid treat sampleyear)
	duplicates report firmid2

	// Now randomly limit the sample to 3,000 treated firms and 6,000 control firms [ultimately end up with 2446 and 4587, slightly oversample because we drop some due to sample selections]
	sample 3000 if treat==1, count
	sample 6000 if treat==0, count

	// And keep only the variables we need
	keep beid sampleyear gk_manual sbi2008_1dig treat firmid2
	rename sampleyear year
	sort beid year
	compress
	save dta/intermediate/perm_p`p'_tcfirms.dta, replace

	// Create yearly samples for the year t=-1 (year where we merge workers)
	forvalues y=2003/2011{
		use dta/intermediate/perm_p`p'_tcfirms.dta, clear
		keep if year==`y'-1
		bys beid: gen n=_n // Number of times the firm is observed in this year; use that to expand the worker data?
		save dta/intermediate/perm_p`p'_tcfirms`y'.dta, replace
	}


	// Merge workers to firms	
	forvalues y=2003/2011{

		use dta/intermediate/permutation_workersample.dta if year>=`y'-3 & year<=`y'+4, clear

		joinby beid year using dta/intermediate/perm_p`p'_tcfirms`y'.dta, _merge(merge_firm) unmatched(master)

		// Keep only workers who are at the treatment/control firm at t=-1 
		gen int sampleyear=`y'

		bys rinpersoons rinpersoon: egen max_n = max(n)
		keep if max_n!=.

		expand max_n if year!=`y'-1, gen(expand)

		sort rinpersoons rinpersoon year

		by rinpersoons rinpersoon year: gen n2=_n
		replace n = n2 if missing(n)

		gsort rinpersoons rinpersoon n -firmid2
		by rinpersoons rinpersoon n: replace firmid2 = firmid2[_n-1] if missing(firmid2)

		drop n2 expand max_n


		// Define new ID based on person id and sample year, because controls can figure as controls more than once
		gegen id = group(rinpersoons rinpersoon sampleyear n)

		gen treatbeid = beid if merge_firm==3 // beid of treatment/control firm
		gsort id -treatbeid
		by id: replace treatbeid = treatbeid[_n-1] if missing(treatbeid)

		gen byte time = year - sampleyear
		label var time "Time relative to when treatment/placebo firm spikes"

		// Keep only incumbents			
		sort id time
		// time in the spiking firm
		gen time_spiking = year - sampleyear if beid == treatbeid

		* Incumbents are workers only workers for whom we observe them at t=-3, t=-2 and t=-1 at the spiking firm/control firm
		gen keep = 1 if time_spiking>=-3 & time_spiking<=-1 
		by id: gegen total_keep = total(keep)
		keep if total_keep==3 // Keep only incumbents
		drop total_keep time_spiking

		// sample selections on age: we want workers older than 18 and younger than 65
		gen byte drop_age=1 if age<18 
		replace drop_age=1 if age>65 
		gsort id -drop_age
		by id: replace drop_age=drop_age[_n-1] if missing(drop_age)
		drop if drop_age==1
		drop drop_age

		// Sector and firm size in the year before treatment
		gen sector_treatyr = sbi2008_1dig if year==(sampleyear-1)
		gen gk_treatyr = gk_manual if year==(sampleyear-1)

		foreach var of varlist sector_treatyr gk_treatyr treat{
			bys id: ereplace `var' = max(`var')
		}

		// Define probability to leave treated/control firm 
		sort id time
		gen byte leave_old=.

		forvalues j=0/4{
			local i=`j'+1
			by id: replace leave_old = 1 if time==`j' & beid!=treatbeid
		}
		replace leave_old=0 if missing(leave_old)
		by id: replace leave_old = 1 if leave_old[_n-1]==1

		// Leave2 is hazard-like
		gen byte leave2 = 1 if leave_old==1 & leave_old[_n-1]==0
		replace leave2 = 0 if missing(leave2)
		by id: replace leave2 = . if leave2[_n-1]==1
		by id: replace leave2 = . if leave2[_n-1]==. & time>0

		gen drop = 1 if secm ==26 | secm == 27
		bys id: ereplace drop = max(drop)
		display "Drop students"		
		drop if drop == 1
		drop drop

		gen outlier = .
		replace outlier = 1 if earnings >= 500000 & !missing(earnings) // drop crazy high total wages
		replace outlier = 1 if dailywage >= 2000 & !missing(dailywage) // drop crazy high daily wages

		// Selection on outliers in relative earnings
		gen earnings_t1 = earnings if time==-1
		gen dailywage_t1 = dailywage if time==-1

		gsort id -earnings_t1
		by id: replace earnings_t1 = earnings_t1[_n-1] if missing(earnings_t1)
		by id: replace dailywage_t1 = dailywage_t1[_n-1] if missing(dailywage_t1)

		gen relearn = earnings / earnings_t1
		replace dailywage = 0 if missing(dailywage)
		gen relwage = dailywage / dailywage_t1

		replace outlier = 1 if relearn>10
		replace outlier = 1 if relwage>10

		// Also drop those with income from benefits in pre-period
		replace outlier = 1 if totalbenefits>0 & time<0

		bys id: ereplace outlier = max(outlier)
		display "Drop outliers in earnings"
		drop if outlier==1
		drop outlier

		// Make sure we have a balanced panel for each worker
		local t=1
		bys id: gegen t = total(`t')
		keep if t == 8 

		// Define pre-treatment values of total earnings (main matching variable)
		gen totalearnings3 = earnings if time==-3
		gen totalearnings2 = earnings if time==-2
		gen totalearnings1 = earnings if time==-1


		foreach var of varlist totalearnings1 totalearnings2 totalearnings3{
			bys id: ereplace `var'=max(`var')
		}

		// For incumbents, should be no obs with no income at t=-1, t=-2 and t=-3
		drop if totalearnings1<=0 
		drop if totalearnings2<=0 
		drop if totalearnings3<=0 

		gen drop = .
		// Drop missings on variables we need for matching
		replace drop = 1 if missing(sector_treatyr) & time == -1
		replace drop = 1 if missing(gk_treatyr) & time == -1
		replace drop = 1 if  missing(totalearnings1) & time == -1

		keep id sampleyear firmid2 treat year lnwage time beid ///
			female foreign age age2 sbi2008_1dig sector_treatyr gk_treatyr totalearnings* leave2 nonemp relearn

		compress

		save dta/intermediate/prematching`y'_perm`p'.dta, replace
	}

	// Append all files
	clear all
	forvalues y=2003/2011{
		append using dta/intermediate/prematching`y'_perm`p'.dta
	}

	// Create new ID (ID numbers will overlap, because created within years)
	rename id old_id
	gegen id = group(old_id sampleyear)

	/// Randomly draw the number of treated and control firms that we want [based on the number of unique firms in the main automation sample]
		preserve
	keep firmid2 treat
	bys firmid2: keep if _n==1
	sample 3002 if treat==1, count 
	sample 4511 if treat==0, count 
	save dta/intermediate/perm`p'_finalselection.dta, replace
	restore

	merge m:1 firmid2 using dta/intermediate/perm`p'_finalselection.dta, keep(match) nogen

	compress
	save dta/intermediate/worker_prematching_perm`p'.dta, replace

	// Calculate overlap in treatment and control firms with the main sample
	use beid sampleyear treat time firmid2 using dta/intermediate/worker_prematching_perm`p'.dta if time==-1, clear
	drop time

	duplicates drop
	sort beid

	// Merge main sample (joinby because we have duplicates)
	joinby beid using dta/intermediate/permutation_mainsample.dta, unmatched(master)

	// How many observations overlap in treatment status? [Firms are sampleyear-beid combinations for the permutation sample]
	bys firmid2: gegen t_treat=total(treat_main)
	gen control_main = 1 if treat_main==0 & _merge==3
	replace control_main = 0 if treat_main==1 & _merge==3
	bys firmid2: gegen t_control=total(control_main)

	gen overlap_t = 1 if treat==1 & t_treat==1
	gen overlap_c = 1 if treat==0 & t_control==0

	gen overlap_ty = 1 if treat==1 & treat_main==1 & sampleyear==sampleyear_main
	gen overlap_cy = 1 if treat==0 & treat_main==0 & sampleyear==sampleyear_main

	collapse (mean) overlap_t overlap_c overlap_ty overlap_cy, by(firmid) // First collapse by original observation ID
	foreach var of varlist overlap_t overlap_c overlap_ty overlap_cy{
		replace `var'=0 if missing(`var')
	}
	collapse (mean) overlap_t overlap_c overlap_ty overlap_cy // Then take means, and save them
	gen byte p=`p'
	compress
	save dta/intermediate/overlap_p`p'.dta, replace


	/////////////////////////

	/// MATCHING ////

	//////////////		
		* Load data at time==-1

	use dta/intermediate/worker_prematching_perm`p'.dta if time==-1, clear


	display "Calculate quantiles for earnings in t=-3, t=-2 and t=-1"
	forval i=1/3{
		// 10 quantiles for those with earnings
		xtile q_earn`i'=totalearnings`i'  if totalearnings`i'>0, nquantiles(10)
		// 99th percentile of those with earnings 

		qui sum totalearnings`i' if totalearnings`i'>0, det
		replace q_earn`i'=21 if totalearnings`i'>=`r(p99)'
		// Calcualte 99.9th percentile of those with earnings

		pctile perc_earn`i' = totalearnings`i'  if totalearnings`i'>0, nquantiles(1000)
		qui sum perc_earn`i'
		replace q_earn`i'=22 if totalearnings`i'>=`r(max)' 
	}

	// Coarsened exact matching on different sets of variables
	local x1  	"year q_earn1 q_earn2 q_earn3 sbi2008_1dig"

	gen c = 1 if treat == 0
	foreach i in 1{
		display "Working on matching set `i' using variables `x`i''"
		* Define strata for each combination of x's
		gegen strata`i' = group(`x`i'') // different strata

		bys strata`i': egen strata_c`i' = total(c)
		bys strata`i': egen strata_t`i' = total(treat)

		* Drop strata where we only have controls or treated
		*drop if strata_c`i' == 0 | strata_t`i' == 0 

		display "Treated that can be matched in set `i'"
		count if treat == 1 &  (strata_c`i' > 0 & strata_t`i' > 0)
		gen n_t`i' = `r(N)'
		display "Controls that can be matched in set `i'"							
		count if treat == 0 &  (strata_c`i' > 0 & strata_t`i' > 0)
		gen n_c`i' = `r(N)'

		gen double weight`i' = (n_c`i' / n_t`i') * (strata_t`i' / strata_c`i') 
		replace weight`i' = 1 if treat == 1
		replace weight`i' = . if (strata_c`i' == 0 | strata_t`i' == 0)

		* Mean weight should be 1
		sum weight`i'
	} // End weight loop


	// Only keep weights 
	keep id weight1 treat
	drop if missing(weight1) | weight1 == 0

	compress
	save dta/intermediate/weights_perm`p'.dta, replace

	* MERGE WEIGHTS TO WORKER DATA
	* Load data	
	use dta/intermediate/worker_prematching_perm`p'.dta, clear

	merge m:1 id treat using dta/intermediate/weights_perm`p'.dta, keep(match master)

	// Shrink file size
	keep firmid2 id /// ID variables
		female foreign age age2 sector_treatyr gk_treatyr year /// Control variables
		time treat weight1 /// Main regression variables and matching weight
		relearn leave2 nonemp lnwage /// Main outcomes

	label var relearn "relearn"
	label var leave2 "leave2"
	label var nonemp "nonemp"
	label var lnwage "lnwage"

	compress
	save dta/analysis/worker_analysis_perm`p'.dta, replace

	// Clean up temporary files
	rm dta/intermediate/perm_p`p'_tcfirms.dta
	rm dta/intermediate/worker_prematching_perm`p'.dta
	rm dta/intermediate/perm`p'_finalselection.dta
	rm dta/intermediate/perm_p`p'_treat.dta
	rm dta/intermediate/firms_sampled`p'.dta
	rm dta/intermediate/perm_spikeyr_p`p'.dta
	rm dta/intermediate/overlap_p`p'.dta
	rm dta/intermediate/weights_perm`p'.dta

	forval y=2003/2011{
		rm dta/intermediate/perm_p`p'_tcfirms`y'.dta
		rm dta/intermediate/prematching`y'_perm`p'.dta
		rm dta/intermediate/perm_p`p'_control`y'.dta
	}
}

