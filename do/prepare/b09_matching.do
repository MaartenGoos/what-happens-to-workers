*------------------------------------------------------------------------
* Automation
* matching.do
* 24/4/2019	
* Last updated: 14/4/2021
* Wiljan van den Berge
* Purpose: match workers on pre-treatment characteristics
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
log using log/matching, text replace
*--------------------------------------------------------------------------

foreach sample in $samplelist{ // Load the sample from samplelist
	if  "`sample'"!= "autom"{
		global droplist "7" // If sample is not the main automation sample, we only use the main sample restrctions
	}
	else{
		global droplist "7 1 9 11" // If sample is the automation sample, we create different samples with different restrictions
	}
	foreach d in $droplist{ // [d=0-10; 0 1 7 9 10: 1 (drop for any events in entire window EXCEPT firm births at t=-3), 7 [main sample], 9 [no large changes in emp until k+1], 11 [New manager]
		foreach worker in inc rh{ // incumbents and recent hires
			* Load data						
			use dta/intermediate/worker_analysis_`sample'.dta if `worker'==1, clear

			* Create variables for sample restrictions and matching

			* Worker growth at firm level *
			cap drop nr_workers 
			merge m:1 beid year using dta/intermediate/beid_manual_gk_mar_all.dta, keep(match master)


			gen ln_nrworkers = ln(nr_workers_mar)
			gen lnwork3 = ln_nrworkers if time==-3
			gen lnwork1 = ln_nrworkers if time==-1

			foreach var of varlist lnwork1 lnwork3{
				gsort beid -`var'
				by beid: replace `var' = `var'[_n-1] if missing(`var')
			}

			gen worker_growth = lnwork3 - lnwork1 if time==-1
			gsort id -worker_growth
			by id: replace worker_growth = worker_growth[_n-1] if missing(worker_growth)

			label var worker_growth "Log growth in nr of workers betw t=-3 and t=-1"
			drop nr_workers_mar lnwork3 lnwork1 ln_nrworkers


			* Proxy for new manager *
			if `d'==11{
				merge m:1 beid year using dta/intermediate/newmanager.dta, keep(match master) nogen
				// New manager
				gen drop11 = 1 if newmgr==1 & time>=-3 & time<=-1
			}

			* From the firm-events data we have two variables indicating whether firms have outlier employment growth
			rename drop_diff drop0
			rename drop_diffk1 drop9

			gen byte drop7 = 0 // 7 = full sample

			* Select the sample restriction we apply
			drop if drop`d'==1


			* Outlier selections *
			
			* Drop students
			gen drop = 1 if secm ==26 | secm == 27
			bys id: ereplace drop = max(drop)
			drop if drop == 1

			gen outlier = .
			replace outlier = 1 if earnings >= 500000 & !missing(earnings) // drop crazy high total wages
			replace outlier = 1 if dailywage >= 2000 & !missing(dailywage) // drop crazy high daily wages

			* Selection on outliers in relative earnings
			gen earnings_t1 = earnings if time==-1
			gen dailywage_t1 = dailywage if time==-1

			gsort id -earnings_t1
			by id: replace earnings_t1 = earnings_t1[_n-1] if missing(earnings_t1)
			by id: replace dailywage_t1 = dailywage_t1[_n-1] if missing(dailywage_t1)

			gen rel_earnings = earnings / earnings_t1
			replace dailywage = 0 if missing(dailywage)
			gen rel_wage = dailywage / dailywage_t1

			* Outlier: >1000% wage or earnings growth
			replace outlier = 1 if rel_earnings>10
			replace outlier = 1 if rel_wage>10

			* Drop workers with income from benefits in pre-period
			replace outlier = 1 if totalbenefits>0 & time<0

			bys id: ereplace outlier = max(outlier)
			drop if outlier==1
			drop outlier


			* Define pre-treatment values of total earnings (main matching variable)
			gen totalearnings3 = earnings if time==-3
			gen totalearnings2 = earnings if time==-2
			gen totalearnings1 = earnings if time==-1

			* Define pre-treatment values of non-employment duration
			gen nonemp3 = nonemp if time==-3
			gen nonemp2 = nonemp if time==-2
			gen nonemp1 = nonemp if time==-1

			foreach var of varlist totalearnings1 totalearnings2 totalearnings3 nonemp1 nonemp2 nonemp3{
				bys id: ereplace `var'=max(`var')
			}

			keep if time==-1

			* Drop missings on sector and firm size and earnings -- should be no one
			drop if missing(sbi2008_1dig)
			drop if missing(gk_manual)
			drop if missing(totalearnings1)

			* For incumbents, should be no obs with no income at t=-1, t=-2 and t=-3
			drop if totalearnings1<=0 & inc == 1
			drop if totalearnings2<=0 & inc == 1
			drop if totalearnings3<=0 & inc == 1


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


			* Firm employment growth: divide into 4 quantiles
			xtile q_growth=worker_growth, nquantiles(4)

			* Merge in worker tenure, divide into 4 quantiles
			merge m:1 rinpersoons rinpersoon year using dta/intermediate/workerdata9916.dta, keep(match master) keepusing(tenure) nogen
			xtile q_tenure=tenure, nquantiles(4)

			gen c = 1 if treat == 0

			gen sbi2008_2dig = substr(sbi2008,1,2)
			egen sec2dig = group(sbi2008_2dig)

			
			* Different sets of matching variables
			local x1  	"year q_earn1 q_earn2 q_earn3 sbi2008_1dig"
			local x7	"year q_earn1 q_earn2 q_earn3 sbi2008_1dig gk_manual"
			local x8	"year q_earn1 q_earn2 q_earn3 sbi2008_1dig q_tenure"
			local x9	"year q_earn1 q_earn2 q_earn3 sbi2008_1dig q_growth"

			* Perform matching on different sets of matching variables
			foreach i in 1 7 8 9{
				display "Working on matching set `i' using variables `x`i''"
				* Define strata for each combination of x's
				gegen strata`i' = group(`x`i'') // different strata

				bys strata`i': egen strata_c`i' = total(c)
				bys strata`i': egen strata_t`i' = total(treat)

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

			keep id weight* strata* strata_c* strata_t* n_t* n_c*

			quietly compress			
			save dta/intermediate/manual_cem_weights_`sample'_drop`d'_`worker'.dta, replace
		} // Ends incumbent/recent hire loop

		* Append the weights data for incumbents and recent hires
		clear all
		use dta/intermediate/manual_cem_weights_`sample'_drop`d'_inc.dta, clear
		append using dta/intermediate/manual_cem_weights_`sample'_drop`d'_rh.dta
		save dta/intermediate/manual_cem_weights_`sample'_drop`d'.dta, replace


		****************************************************************************************************************************************************
		* MERGE MATCHING WEIGHTS TO WORKER DATA
		* Load data	
		use dta/intermediate/worker_analysis_`sample'.dta, clear

		* Drop some useless variables to save space
		drop psadmin merge_firm drop* secm sbi2008_1dig rinpersoons rinpersoon

		sort id

		merge m:1 id using dta/intermediate/manual_cem_weights_`sample'_drop`d'.dta, keep(match) nogen keepusing(weight*)

		* Calculate relative earnings and relative wage
		gen earnings_t1 = earnings if time==-1
		gen dailywage_t1 = dailywage if time==-1

		foreach var in earnings_t1 dailywage_t1{
			bys id: ereplace `var' = max(`var')
		}

		gen rel_earnings = earnings / earnings_t1
		replace dailywage = 0 if missing(dailywage)
		gen rel_wage = dailywage / dailywage_t1	
		gen hourlywage = ln(wage / hours)

		* Create firm id's for clustering
		cap gegen firmid_inc = group(treatbeid_incumbent treat sampleyear)
		cap gegen firmid_rh = group(treatbeid_nonincumbent treat sampleyear)

		* Rename variables for convenience
		rename rel_earnings relearn
		rename totalbenefits tbenefits
		rename ln_wage lnwage
		rename earlyretirement early	
		rename rel_wage relwage

		label var weight1 "Matched on year, earnings and sector"
		label var weight7 "Matched on year, earnings, sector and firm size"
		label var weight8 "Matched on year, earnings, sector and tenure"
		label var weight9 "Matched on year, earnings, sector and firm employment growth"

		* Shrink file size
		keep firmid* id inc rh /// ID variables
			female foreign age age2 sector_treatyr gk_treatyr year sbi2008 /// Control variables
			time treat weight* /// Main regression variables and matching weight
			earnings relearn relwage leave leave2 leave_old nonemp tbenefits selfemp early lnwage ub di welfare hours totalhours hourlywage /// Main outcomes
			soortbaan educ sampleyear treatbeid* beid spike_first_year // variables needed for heterogeneity analysis or identifying firms
		compress

		* Save final analysis data
		save dta/analysis/worker_analysis_drop`d'_`sample'.dta, replace
		
		* Remove temporary files
		rm dta/intermediate/manual_cem_weights_`sample'_drop`d'_inc.dta
		rm dta/intermediate/manual_cem_weights_`sample'_drop`d'_rh.dta
		*rm dta/intermediate/manual_cem_weights_`sample'_drop`d'.dta
	}
}
