*------------------------------------------------------------------------
* Automation
* firm_panel.do
* 30/5/2018
* 26/06/2021:	Added overlapping samples
* Wiljan van den Berge
* Purpose: create stacked panels for cohorts 2003-2011
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
log using log/firm_panel, text replace
*--------------------------------------------------------------------------

* Here we create stacked panels of firms, where treated are those that have their first spike in year C and controls are those that have their first spike in year C+5 or later
* Do it separately for regular samples and overlapping samples

/* Control sample: all firms who have their first spike in year C + 5 or later */
foreach sample in $samplelist{ 
	if "`sample'"!= "overl_autom1" & "`sample'"!="overl_autom2" & "`sample'"!="overl_comp1" & "`sample'"!="overl_comp2" & "`sample'" != "overl_other1" & "`sample'" != "overl_other2"{	
		if "`sample'" != "never_autom"{
			forvalues y=2003/2011{
				use dta\intermediate\firm_level_data_`sample'.dta, clear
				gen spike_yr_c = `y'+5 // controls spike in treatment year + 5 or later
				gen c`y' = 1 if year>=spike_yr_c & spike_firm_first==1 // Firms are controls in year t if they have their largest spike between year t+k and year t+k+2
				bys beid: ereplace c`y'=max(c`y')
				keep if c`y'==1
				keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
				keep beid year
				save dta/temp/controlsample_firm_`y'_`sample'.dta, replace
			}
		}

		/* Never treated control sample: Select all firms who never have a spike we observe */
		if "`sample'" == "never_autom"{
			forvalues y=2003/2011{
				use dta\intermediate\firm_level_data_`sample'.dta, clear

				* Drop all firms who have a spike at some point
				bys beid: egen t_spike = total(spike_firm)
				drop if t_spike>0

				keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
				keep beid year
				save dta/temp/controlsample_firm_`y'_`sample'.dta, replace
			}
		}

		/* Treat sample: select all firms who spike in year C */
		forvalues y=2003/2011{
			use dta\intermediate\firm_level_data_`sample'.dta, clear
			gen spike_yr_t = `y'
			gen t`y' = 1 if spike_yr_t == year & spike_firm_first==1
			bys beid: ereplace t`y'=max(t`y')
			keep if t`y'==1
			keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
			keep beid year
			save dta/temp/treatsample_firm_`y'_`sample'.dta, replace
		}

		/* Select treated (spiking in C) and controls (working at firm which spikes at C+5)
		   Select workers who work at T=-1 at the spiking/control firm */
		forvalues y=2003/2011{
			use dta\intermediate\firm_level_data_`sample'.dta, clear

			* Find controls: all firms that spike in year C+5 or later
			* Or, in case of never-treated, firms that never spike, but do exist in this period
			merge m:1 beid year using dta/temp/controlsample_firm_`y'_`sample'.dta, keep(match master) gen(cfirm_match)

			* Control = 1 if firms spike in year C+5
			gen byte c = 1 if cfirm_match==3

			gsort beid -c
			by beid: replace c=c[_n-1] if missing(c)

			* Treated: all firms who spike at C [And are observed at C-1]
			merge m:1 beid year using dta/temp/treatsample_firm_`y'_`sample'.dta, keep(match master) gen(tfirm_match)

			* t=1 for firms that spike in year C and are observed at C-1
			gen byte t = 1 if tfirm_match==3

			gsort beid -t
			by beid: replace t=t[_n-1] if missing(t)

			keep if (t==1 | c==1)

			gen int treatyr = `y'

			* Both treatment and control firms have to survive the event window + 1
			gen time = year-treatyr
			gen x = 1 if time>=-3 & time<=(5)
			bys beid: ereplace x = total(x)
			keep if x == 9
			drop x

			* Balance the sample around event time t=[-3,k-1]
			gen keep = 1 if time>=-3 & time<=(4)
			bys beid: gegen total_keep=total(keep)
			keep if total_keep==8
			drop keep total_keep

			gegen firmid = group(beid)

			save dta/temp/treated_controls_firm_y`y'_`sample'.dta, replace
		}

		* Append the individual panels ("stack")
		clear all
		forvalues y=2003/2011{
			append using dta\temp/treated_controls_firm_y`y'_`sample'.dta
		}

		* Define a new firmid for the combination of FIRM and TREATYR [because controls can serve as controls more than once]
		gegen new_firmid = group(firmid treatyr)
		drop firmid
		rename new_firmid firmid
		compress

		gen byte treat = t==1
		drop t c

		* Redefine merge_firm to indicate when firm is during the OBS WINDOW (-3 until 4) observed only in PS and admin both
		gen psadmin = 1 if merge_firm==3 & time>=-3 & time<=4
		bys firmid: egen t = total(psadmin)
		replace psadmin = 1 if t==8
		replace psadmin = 0 if t!=8
		label define da 1 "Firm both in PS and admin in obs window" 0 "Firm sometimes only in admin in obs window"
		label values psadmin da
		drop merge_firm t
		compress

		* Add variable indicating when the firm does have its first spike
		gen int spike_first_year=year if spike_firm_first==1
		bys beid: ereplace spike_first_year = max(spike_first_year)

		compress
		save dta/intermediate/firm_analysis_`sample'.dta, replace
	} // end IF condition for excluding overlapping samples


	// OVERLAPPING SAMPLES COMPUTERS AND AUTOMATION

	if "`sample'"== "overl_autom1" | "`sample'"=="overl_autom2" | "`sample'"=="overl_comp1" | "`sample'"=="overl_comp2"{
		// Overlapping samples, 2 different types of samples
		// Type 1: no spikes of the same type --> No restrictions in this case
		// Type 2: no spikes of both types ---> No contemporaneous or spikes of the other type in the pre-period

		// First control samples, then treat samples of both types

		foreach type in autom comp{
			/* Control sample TYPE 1 */
			forvalues y=2003/2011{
				use dta\intermediate\firm_level_data_overl.dta, clear
				gen spike_yr_c = `y'+5 // controls spike in treatment year C+5 or later
				gen c`y' = 1 if year >= spike_yr_c & spike_`type'_first==1 // Firms are controls in year C if they have their largest spike in year C+5 or later
				bys beid: ereplace c`y'=max(c`y')
				keep if c`y'==1
				keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
				keep beid year
				save dta/temp/controlsample_firm_`y'_overl_`type'1.dta, replace
			} // end year loop
			/* END CONTROL SAMPLE TYPE 1 */

			/* CONTROL SAMPLE TYPE 2 */	
			forvalues y=2003/2011{
				use dta\intermediate\firm_level_data_overl.dta, clear
				gen spike_yr_c = `y'+5 // controls spike in treatment year C+5 or later
				gen c`y' = 1 if year >= spike_yr_c & spike_`type'_first==1 // Firms are controls in year C if they have their first spike in year C+5 or later

				// Controls can't have another type of spike in year C or the 3 years before (e.g. no automation spike if they have a computer spike and vv)
				if "`type'" == "comp"{
					gen noc`y' = 1 if year >= spike_yr_c-(5+3) & year <= spike_yr_c & spike_autom==1
				}
				if "`type'" == "autom"{
					gen noc`y' = 1 if year >= spike_yr_c-(5+3) & year <= spike_yr_c & spike_comp==1
				}
				bys beid: ereplace c`y'=max(c`y')
				bys beid: ereplace noc`y'=max(noc`y')
				keep if c`y'==1
				drop if noc`y'==1
				keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
				keep beid year
				save dta/temp/controlsample_firm_`y'_overl_`type'2.dta, replace
			} // end year loop
			/* END CONTROL SAMPLES */

			/* TREAT SAMPLE TYPE 1*/
			forvalues y=2003/2011{
				use dta\intermediate\firm_level_data_overl.dta, clear
				gen spike_yr_t = `y'
				gen t`y' = 1 if spike_yr_t == year & spike_`type'_first==1
				bys beid: ereplace t`y'=max(t`y')
				keep if t`y'==1
				keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
				keep beid year
				save dta/temp/treatsample_firm_`y'_overl_`type'1.dta, replace
			} // end year loop
			/* END TREAT SAMPLE TYPE 1 */

			/* TREAT SAMPLE TYPE 2 */
			forvalues y=2003/2011{
				use dta\intermediate\firm_level_data_overl.dta, clear
				gen spike_yr_t = `y'
				gen t`y' = 1 if spike_yr_t == year & spike_`type'_first==1
				* Treated cannot have a spike of the other type in the pre-period
				if "`type'" == "comp"{
					gen not`y' = 1 if year >= spike_yr_t - 3 & year <= spike_yr_t & spike_autom==1
				}
				if "`type'" == "autom"{
					gen not`y' = 1 if year >= spike_yr_t - 3 & year <= spike_yr_t & spike_comp==1
				}

				bys beid: ereplace t`y'=max(t`y')
				bys beid: ereplace not`y'=max(not`y')
				keep if t`y'==1
				drop if not`y'==1
				keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
				keep beid year
				save dta/temp/treatsample_firm_`y'_overl_`type'2.dta, replace
			} // End year loop
			/* END TREAT SAMPLES */

			/* MERGE TREAT AND CONTROL SAMPLES FOR EACH YEAR */
			forval t=1/2{
				forvalues y=2003/2011{
					use dta\intermediate\firm_level_data_overl.dta, clear

					* Find controls: all firms that spike in year C+5
					merge m:1 beid year using dta/temp/controlsample_firm_`y'_overl_`type'`t'.dta, keep(match master) gen(cfirm_match)

					* Control=1 if firms spike in year C+5
					gen byte c = 1 if cfirm_match==3

					gsort beid -c
					by beid: replace c=c[_n-1] if missing(c)

					* Treated=1 if firms spike first in year C [And are observed at T-1]
					merge m:1 beid year using dta/temp/treatsample_firm_`y'_overl_`type'`t'.dta, keep(match master) gen(tfirm_match)

					* t=1 for firms that spike in year T and are observed at T-1
					gen byte t = 1 if tfirm_match==3

					gsort beid -t
					by beid: replace t=t[_n-1] if missing(t)

					keep if (t==1 | c==1)

					gen int treatyr = `y'

					* Balance the sample
					* Both treatment and control firms have to survive the event window + 1
					gen time = year-treatyr
					gen x = 1 if time>=-3 & time<=(5)
					bys beid: ereplace x = total(x)
					keep if x == 3 + 5 + 1
					drop x

					gen keep = 1 if time>=-3 & time<=(5-1)
					bys beid: gegen total_keep=total(keep)
					keep if total_keep==3+5
					drop keep total_keep

					gegen firmid = group(beid)

					save dta/temp/treated_controls_firm_y`y'_overl_`type'`t'.dta, replace
				} // end year loop

				* Then stack the individual cohorts
				clear all
				forvalues y=2003/2011{
					append using dta\temp/treated_controls_firm_y`y'_overl_`type'`t'.dta
				} // end year loop

				* Define a new firmid for the combination of FIRM and TREATYR [because controls can serve as controls more than once]
				gegen new_firmid = group(firmid treatyr)
				drop firmid
				rename new_firmid firmid
				compress

				gen byte treat = t==1
				drop t c

				/* generate outcome variables */
				foreach var of varlist mn_wage mn_daily_wage p50_wage p50_daily_wage nr_workers revenue_worker{
					gen ln_`var' = ln(`var')
				}


				// Redefine merge_firm to indicate when firm is during the OBS WINDOW (-3 until 4) observed only in PS and admin both
				gen psadmin = 1 if merge_firm==3 & time>=-3 & time<=4
				bys firmid: egen t = total(psadmin)
				replace psadmin = 1 if t==8
				replace psadmin = 0 if t!=8
				label define da 1 "Firm both in PS and admin in obs window" 0 "Firm sometimes only in admin in obs window"
				label values psadmin da

				// Add variable indicating when the firm does have its largest/first spike
				gen int spike_first_year=year if spike_`type'_first==1
				bys beid: ereplace spike_first_year = min(spike_first_year)

				drop merge_firm t
				compress
				save dta/intermediate/firm_analysis_overl_`type'`t'.dta, replace
			} // end type1 / type2 loop
		} // end OVERLAP-sample loop
	}

	// OVERLAPPING SAMPLES PLACEBO WITH OTHER INVESTMENTS
	if "`sample'" == "overl_other1" | "`sample'" == "overl_other2"{
		// Overlapping samples, 2 different types of samples
		// Type 1: no spikes of the same type --> No restrictions in this case
		// Type 2: no spikes of both types ---> No contemporaneous or spikes of the other type in the pre-period

		local type "other"
		/* Control sample TYPE 1 */
		forvalues y=2003/2011{
			use dta\intermediate\firm_level_data_`sample'.dta, clear
			gen spike_yr_c = `y'+5 // controls spike in year C+5 or later
			gen c`y' = 1 if year >= spike_yr_c & spike_`type'_first==1 // Firms are controls in year t if they have their first spike in year C+5 or later
			bys beid: ereplace c`y'=max(c`y')
			keep if c`y'==1
			keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
			keep beid year
			save dta/temp/controlsample_firm_`y'_`type'1.dta, replace
		} // end year loop
		/* END CONTROL SAMPLE TYPE 1 */

		/* CONTROL SAMPLE TYPE 2 */	
		forvalues y=2003/2011{
			use dta\intermediate\firm_level_data_`sample'.dta, clear
			gen spike_yr_c = `y'+5 // controls spike in year C+5 or later
			gen c`y' = 1 if year >= spike_yr_c & spike_`type'_first==1 // Firms are controls in year C if they have their first spike in year C+5 or later

			* Controls can't have an automation spike in year C or the 3 years before
			gen noc`y' = 1 if year >= spike_yr_c-(5+3) & year <= spike_yr_c & spike_autom==1

			bys beid: ereplace c`y'=max(c`y')
			bys beid: ereplace noc`y'=max(noc`y')
			keep if c`y'==1
			drop if noc`y'==1
			keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
			keep beid year
			save dta/temp/controlsample_firm_`y'_`type'2.dta, replace
		} // end year loop
		/* END CONTROL SAMPLES */

		/* TREAT SAMPLE TYPE 1*/
		forvalues y=2003/2011{
			use dta\intermediate\firm_level_data_`sample'.dta, clear
			gen spike_yr_t = `y'
			gen t`y' = 1 if spike_yr_t == year & spike_`type'_first==1
			bys beid: ereplace t`y'=max(t`y')
			keep if t`y'==1
			keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
			keep beid year
			save dta/temp/treatsample_firm_`y'_`type'1.dta, replace
		} // end year loop
		/* END TREAT SAMPLE TYPE 1 */

		/* TREAT SAMPLE TYPE 2 */
		forvalues y=2003/2011{
			use dta\intermediate\firm_level_data_`sample'.dta, clear
			gen spike_yr_t = `y'
			gen t`y' = 1 if spike_yr_t == year & spike_`type'_first==1
			* Treated cannot have a spike of the other type in the pre-period
			gen not`y' = 1 if year >= spike_yr_t - 3 & year <= spike_yr_t & spike_autom==1

			bys beid: ereplace t`y'=max(t`y')
			bys beid: ereplace not`y'=max(not`y')
			keep if t`y'==1
			drop if not`y'==1
			keep if year==`y'-1 // y-1 because we want to merge workers on year t=-1 and not t=0
			keep beid year
			save dta/temp/treatsample_firm_`y'_`type'2.dta, replace
		} // End year loop
		/* END TREAT SAMPLES */

		/* MERGE TREAT AND CONTROL SAMPLES FOR EACH YEAR */
		forval t=1/2{
			forvalues y=2003/2011{
				use dta\intermediate\firm_level_data_`sample'.dta, clear

				* Find controls: all firms that spike in year C+5
				merge m:1 beid year using dta/temp/controlsample_firm_`y'_`type'`t'.dta, keep(match master) gen(cfirm_match)

				* Control=1 if firms spike in year C+5
				gen byte c = 1 if cfirm_match==3

				gsort beid -c
				by beid: replace c=c[_n-1] if missing(c)

				* Treated=1: all firms who spike at C [And are observed at C-1]
				merge m:1 beid year using dta/temp/treatsample_firm_`y'_`type'`t'.dta, keep(match master) gen(tfirm_match)

				* t=1 for firms that spike in year C and are observed at C-1
				gen byte t = 1 if tfirm_match==3

				gsort beid -t
				by beid: replace t=t[_n-1] if missing(t)

				keep if (t==1 | c==1)

				gen int treatyr = `y'

				* Balance the sample
				* Both treatment and control firms have to survive the event window + 1
				gen time = year-treatyr
				gen x = 1 if time>=-3 & time<=(5)
				bys beid: ereplace x = total(x)
				keep if x == 3 + 5 + 1
				drop x

				gen keep = 1 if time>=-3 & time<=(5-1)
				bys beid: gegen total_keep=total(keep)
				keep if total_keep==3+5
				drop keep total_keep

				gegen firmid = group(beid)

				save dta/temp/treated_controls_firm_y`y'_`type'`t'.dta, replace
			} // end year loop

			* Then stack the panels
			clear all
			forvalues y=2003/2011{
				append using dta\temp/treated_controls_firm_y`y'_`type'`t'.dta
			} // end year loop

			* Define a new firmid for the combination of FIRM and TREATYR [because controls can serve as controls more than once]
			gegen new_firmid = group(firmid treatyr)
			drop firmid
			rename new_firmid firmid
			compress

			gen byte treat = t==1
			drop t c

			* Generate outcome variables
			foreach var of varlist mn_wage mn_daily_wage p50_wage p50_daily_wage nr_workers revenue_worker{
				gen ln_`var' = ln(`var')
			}


			* Redefine merge_firm to indicate when firm is during the OBS WINDOW (-3 until 4) observed only in PS and admin both
			gen psadmin = 1 if merge_firm==3 & time>=-3 & time<=4
			bys firmid: egen t = total(psadmin)
			replace psadmin = 1 if t==8
			replace psadmin = 0 if t!=8
			label define da 1 "Firm both in PS and admin in obs window" 0 "Firm sometimes only in admin in obs window"
			label values psadmin da

			* Add variable indicating when the firm does have its largest/first spike
			gen int spike_first_year=year if spike_`type'_first==1
			bys beid: ereplace spike_first_year = min(spike_first_year)

			drop merge_firm t
			compress
			save dta/intermediate/firm_analysis_overl_`type'`t'.dta, replace
		} // end type1 / type2 loop
	} // end first/large spike loop
} //end sample loop
