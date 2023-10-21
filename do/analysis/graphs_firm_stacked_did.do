*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close
sysdir set PLUS "M:\Stata\Ado\Plus"
sysdir set PERSONAL "H:\Stata\"
cd H:/automation/
*-------------------------------------------------------------------------

* All firms, weighted by size
foreach y in emp wage wb{
	use "H:\automation\export\Rev3\firm_stacked_did_weight_cohortfe.dta", clear
	keep if size8==1
	keep if var == "ln_`y'_size81"

	* Then add observations
	set obs `=_N+1'

	replace at = -1 if missing(at)
	* And fill the observations correctly
	foreach var in b se pval ll1 ul1{
		replace `var' = 0 if missing(`var')
	}
	sort at

	tw scatter b at, color(dkorange) || rarea ll1 ul1 at, color(dkorange%20) ///
	xlabel(-3(1)4) legend(off) xtitle("Year relative to treatment") xline(0) title("All firms (size weighted)", position(11) size(medium)) yline(0)
	graph export output/firm_stacked_did_weight_allfirms_`y'_cohortfe.pdf, replace
}

* All firms, unweighted
foreach y in emp wage wb{
	use "H:\automation\export\Rev3\firm_stacked_did_noweight.dta", clear
	keep if size8==1
	keep if var == "ln_`y'_size81"

	* Then add observations
	set obs `=_N+1'

	replace at = -1 if missing(at)
	* And fill the observations correctly
	foreach var in b se pval ll1 ul1{
		replace `var' = 0 if missing(`var')
	}
	sort at

	tw scatter b at, color(dkorange) || rarea ll1 ul1 at, color(dkorange%20) ///
	xlabel(-3(1)4) legend(off) xtitle("Year relative to treatment") xline(0) title("All firms (not weighted)", position(11) size(medium))  yline(0)
	graph export output/firm_stacked_did_noweight_allfirms_`y'_cohortfe.pdf, replace
}



* Large vs other firms, weighted
foreach y in emp wage wb{
	use "H:\automation\export\Rev3\firm_stacked_did_weight.dta", clear
	keep if !missing(size7)
	keep if var == "ln_`y'_size71" | var == "ln_`y'_size72"

	* Then add observations
	set obs `=_N+2'

	replace at = -1 if missing(at)
	sort at
	
	sort at size7
	by at: replace size7 = _n if missing(size7)
	
	* And fill the observations correctly
	foreach var in b se pval ll1 ul1{
		replace `var' = 0 if missing(`var')
	}
	sort at

	tw scatter b at if size7==1, color(dkorange) || rarea ll1 ul1 at if size7==1, color(dkorange%20) || ///
	scatter b at if size7==2, color(maroon) || rarea ll1 ul1 at if size7==2, color(maroon%20) ///	
	xlabel(-3(1)4) xtitle("Year relative to treatment") xline(0) legend(order(1 "Firms with <500 workers" 3 "Firms with >500 workers") position(bottom)) yline(0)
	graph export output/firm_stacked_did_weight_500orless_`y'_cohortfe.pdf, replace
}