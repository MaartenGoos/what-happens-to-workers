*------------------------------------------------------------------------
* Automation
* Anna Salomons
* Purpose: create graphs for paper using CBS server data exports (note that graphs cannot be exported directly from the remote server)
*-------------------------------------------------------------------------

*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
macro drop _all
set scheme s2mono
cd // Set path where figures are to be saved here
global path_in // Set path where server exports are saved here

*--------------------------------------------------------------------------


*--------------------------------------------------------------------------
*--------------------------------------------------------------------------
* Worker-level outcomes, baseline estimates
*--------------------------------------------------------------------------
*--------------------------------------------------------------------------

*--------------------------------------------------------------------------
* Fig 3; Fig 4; Apx Fig E1; Apx Fig E2 
*--------------------------------------------------------------------------

xmluse $path_in/coeff_drop7_autom_weight1_fe1.dta.xml, doctype(excel) allstring firstrow clear

	compress
	cap destring _all, replace
	rename *, lower

	rename plot inc
	replace inc=0 if n_rh!=. // inc=0 are recent hires, =1 are incumbents
	rename ll1 cil
	rename ul1 ciu
	rename at time
	rename b est

	foreach var in cil ciu est {
		replace `var'=`var'*100 if var=="lnwage"|var=="relearn"|var=="relwage"|var=="leave2"|var=="selfemp"|var=="early"|var=="hourlywage"|var=="rel_hours"
	}

	replace var = "lnhrwage" if var=="hourlywage"

** NOTE! t=-1 values missing, filling these in
preserve
	keep if t==0
	replace est = 0
	replace cil = 0
	replace ciu = 0
	replace t = -1
	keep t est cil ciu var inc n_inc
	save temp, replace
restore
	
	append using temp
	sort var time
	

// Fig 3A: Relative earnings, incumbents	
tw rcap cil ciu time if var=="relearn" & inc==1, color(black) || ///
connected est time if var=="relearn" & inc==1, lcolor(black) mcolor(black) msymbol(O) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("Annual wage income change (%)") yline(0, lcolor(black) lpattern(dash))  ///
	legend(off) graphregion(color(white)) bgcolor(white) ///
	ylabel(2(1)-4)
graph export w_relwage_inc_k5_d7.pdf, as(pdf) replace 

****

// Figure 3B: Leave hazard, incumbents
tw rcap cil ciu time if var=="leave2" & inc==1, color(black) || ///
connected est time if var=="leave2" & inc==1, lcolor(black) mcolor(black) msymbol(O)   ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("Hazard of firm separation, percentage points") yline(0, lcolor(black) lpattern(dash)) ylabel(-2(1)3) ///
	legend(off) graphregion(color(white)) bgcolor(white)
graph export w_leave_inc_k5_d7.pdf, as(pdf) replace

****

// Figure 3C: Non-employment days
tw rcap cil ciu time if var=="nonemp" & inc==1, color(black) || ///
connected est time if var=="nonemp" & inc==1, lcolor(black) mcolor(black) msymbol(O)  ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("Non-employment duration in days") yline(0, lcolor(black) lpattern(dash)) ylabel(-2(1)9) ///
	legend(off) graphregion(color(white)) bgcolor(white)
graph export w_nonemp_inc_k5_d7.pdf, as(pdf) replace

****

// Figure 3D: Log wage, incumbents
tw rcap cil ciu time if var=="lnwage" & inc==1, color(black) || ///
connected est time if var=="lnwage" & inc==1, lcolor(black) mcolor(black) msymbol(O)  ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("Log daily wage if employed, log points") yline(0, lcolor(black) lpattern(dash)) ylabel(-3(1)2) ///
	legend(off) graphregion(color(white)) bgcolor(white)
graph export w_lnwage_inc_k5_d7.pdf, as(pdf) replace


****

// Figure 4A: Benefits split
tw rcap cil ciu time if var=="di" & inc==1, color(gs8) || ///
connected est time if var=="di" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(Oh)  || ///
rcap cil ciu time if var=="welfare" & inc==1, color(gs8) || ///
connected est time if var=="welfare" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(D)  || ///
rcap cil ciu time if var=="ub" & inc==1, color(gs8) || ///
connected est time if var=="ub" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(T)  || ///
rcap cil ciu time if var=="tbenefits" & inc==1, color(black) || ///
connected est time if var=="tbenefits" & inc==1, lcolor(black) mcolor(black) msymbol(O)  ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("Annual benefit amount") yline(0, lcolor(black) lpattern(dash)) ylabel(-100(50)250) ///
	legend(order(8 6 4 2)label(2 "Disability benefits")label(4 "Welfare")label(6 "Unemployment benefits")label(8 "Total benefits")) graphregion(color(white)) bgcolor(white)
graph export w_benefits_inc_k5_d7.pdf, as(pdf) replace
	
****
	
// Figure 4B: Self-employment and early retirement
tw rcap cil ciu time if var=="selfemp" & inc==1, color(gs8) || ///
connected est time if var=="selfemp" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(T)  || ///
rcap cil ciu time if var=="early" & inc==1, color(black) || ///
connected est time if var=="early" & inc==1, lcolor(black) mcolor(black) msymbol(O)  ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("Probability of outcome, percentage points") yline(0, lcolor(black) lpattern(dash)) ylabel(-.2(.2)1) ///
	legend(order(4 2)label(2 "Self-employment")label(4 "Early retirement")) graphregion(color(white)) bgcolor(white)
graph export w_selfempretire_inc_k5_d7.pdf, as(pdf) replace

****

// Apx Figure E1: Log hourly wage & Relative hours worked, incumbents
tw rcap cil ciu time if var=="lnhrwage" & inc==1, color(black) || ///
connected est time if var=="lnhrwage" & inc==1, lcolor(black) mcolor(black) msymbol(O)  || ///
rcap cil ciu time if var=="rel_hours" & inc==1, color(gs8) || ///
connected est time if var=="rel_hours" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(T)  ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("Annual change (%)") yline(0, lcolor(black) lpattern(dash)) ylabel(-6(2)12) ///
	legend(order(2 4)label(2 "Log hourly wage")label(4 "Hours worked")) graphregion(color(white)) bgcolor(white)
graph export w_lnhrwagehrs_inc_k5_d7.pdf, as(pdf) replace
****

// Apx Fig E2: Relative earnings, incumbents & recent hires 
tw rcap cil ciu time if var=="relearn" & inc==0, color(gs8)  || ///
connected est time if var=="relearn" & inc==0, lcolor(gs8) mcolor(gs8) msymbol(T)  || ///
rcap cil ciu time if var=="relearn" & inc==1, color(black) || ///
connected est time if var=="relearn" & inc==1, lcolor(black) mcolor(black) msymbol(O) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("Annual wage income change (%)") yline(0, lcolor(black) lpattern(dash))  ///
	legend(order(4 2)label(4 "Incumbents")label(2 "Recent hires")) graphregion(color(white)) bgcolor(white) ///
	ylabel(8(2)-10)
graph export w_relwage_k5_d7.pdf, as(pdf) replace
	
clear
erase temp.dta


*--------------------------------------------------------------------------
*--------------------------------------------------------------------------
* 2. Worker-level outcomes, robustness checks
*--------------------------------------------------------------------------
*--------------------------------------------------------------------------

*--------------------------------------------------------------------------
* Data prep
*--------------------------------------------------------------------------

// Different model specifications (d1=excl. firm events (M&A etc.) ; d7=baseline; d9=excl. outliers in- & outside window ; d11=excl. management change)
foreach i in 1 7 9 11  { 
xmluse "$path_in/coeff_drop`i'_autom_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	cap destring _all, replace
	gen spec="d`i'" if _N!=0
	compress
	save "temp_coefficients_k5_d`i'.dta", replace
}

xmluse "$path_in/coeff_drop7_autom_firmw_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="firmw"
	cap destring _all, replace
	compress
save "temp_coeff1.dta", replace

xmluse "$path_in/coeff_drop7_autom_sizew_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="sizew"
	cap destring _all, replace
	compress
save "temp_coeff2.dta", replace

xmluse "$path_in/coeff_drop7_autom_tenurew_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="tenurew"
	cap destring _all, replace
	compress	
save "temp_coeff3.dta", replace

xmluse "$path_in/coeff_drop7_autom_weight1_fe0.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="fe0"
	cap destring _all, replace
	compress
save "temp_coeff4.dta", replace

xmluse "$path_in/coeff_drop7_emp_autom_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="emp"
	cap destring _all, replace
	compress	
save "temp_coeff5.dta", replace

xmluse "$path_in/coeff_drop7_empf_autom_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="empf"
	cap destring _all, replace
	compress	
save "temp_coeff6.dta", replace

xmluse "$path_in/coeff_drop7_empt0_autom_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="empt0"
	cap destring _all, replace
	compress	
save "temp_coeff7.dta", replace

// Computerization
xmluse "$path_in/coeff_drop7_overl_autom1_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="overl_autom1"
	cap destring _all, replace
	compress	
save "temp_coeff8.dta", replace

xmluse "$path_in/coeff_drop7_overl_autom2_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="overl_autom2"
	cap destring _all, replace
	compress	
save "temp_coeff9.dta", replace

xmluse "$path_in/coeff_drop7_overl_comp1_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="overl_comp1"
	cap destring _all, replace
	compress	
save "temp_coeff10.dta", replace

xmluse "$path_in/coeff_drop7_overl_comp2_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="overl_comp2"
	cap destring _all, replace
	compress	
save "temp_coeff11.dta", replace

// Placebo
cap xmluse "$path_in/coeff_drop7_overl_other1_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="overl_placebo1"
	cap destring _all, replace
	compress	
save "temp_coeff12.dta", replace

cap xmluse "$path_in/coeff_drop7_overl_other2_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="overl_placebo2"
	cap destring _all, replace
	compress	
save "temp_coeff13.dta", replace

// Never-treated as control
xmluse "$path_in/coeff_drop7_never_autom_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="never"
	cap destring _all, replace
	compress	
save "temp_coeff14.dta", replace

// Spike size
xmluse "$path_in/coeff_drop7_spike2_autom_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="spike2"
	cap destring _all, replace
	compress	
save "temp_spike2.dta", replace

xmluse "$path_in/coeff_drop7_spike4_autom_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="spike4"
	cap destring _all, replace
	compress	
save "temp_spike4.dta", replace

xmluse "$path_in/coeff_drop7_autom_weight1_fe1.dta.xml", doctype(excel) firstrow clear allstring
	gen spec="spike3"
	cap destring _all, replace
	compress	
append using "temp_spike2.dta"
append using "temp_spike4.dta"
save "temp_spike.dta", replace


// Putting all specifications together in a single dataset
clear
forvalues i=1(1)14 {
	append using "temp_coeff`i'.dta"
}
save "temp_coefficients_k5_all.dta", replace
clear

use "temp_coefficients_k5_all.dta", clear
foreach i in 1 7 9 11 {
	 append using "temp_coefficients_k5_d`i'.dta"
}
	append using "temp_spike.dta"
	
	compress
	
	rename *, lower

	rename plot inc
	replace inc=0 if n_rh!=. // inc=0 are recent hires, =1 are incumbents
	rename ll1 cil
	rename ul1 ciu
	rename at time
	rename b est
	
	foreach var in cil ciu est {
		replace `var'=`var'*100 if (var=="lnwage"|var=="relearn"|var=="relwage"|var=="leave2"|var=="selfemp"|var=="early")
	}
	
	
** NOTE! t=-1 values missing, filling these in
preserve
	keep if t==0
	replace est = 0
	replace cil = 0
	replace ciu = 0
	replace t = -1
	keep t est cil ciu var inc n_inc spec
	save temp, replace
restore
	
	append using temp
	sort var spec time
	
save "temp_coefficients_k5_all.dta", replace

erase temp.dta


*--------------------------------------------------------------------------
* Fig 5 (Comparison to computer spikes)
*--------------------------------------------------------------------------

use "temp_coefficients_k5_all.dta", clear
	
// Figure 5	
	tw rcap cil ciu time if var=="relearn" & spec=="overl_autom1"  & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="overl_autom1" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(Oh)  || ///
	rcap cil ciu time if var=="relearn" & spec=="overl_autom2" & inc==1, color(black) || ///
	connected est time if var=="relearn" & spec=="overl_autom2" & inc==1, lcolor(black) mcolor(black) msymbol(O)  || ///
	rcap cil ciu time if var=="relearn" & spec=="overl_comp1" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="overl_comp1" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(Dh)  || ///
	rcap cil ciu time if var=="relearn" & spec=="overl_comp2" & inc==1, color(black) || ///
	connected est time if var=="relearn" & spec=="overl_comp2" & inc==1, lcolor(black) mcolor(black) msymbol(D)   ///
		xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
		ytitle("Annual wage income change (%)") yline(0, lcolor(black) lpattern(dash))  ///
		legend(order(6 2 8 4)label(2 "All automation events")label(4 "Automation, no computerization")label(6 "All computerization events")label(8 "Computerization, no automation")) ///
		legend(span) graphregion(color(white)) bgcolor(white) 		
	graph export w_relwage_inc_k5_comp.pdf, as(pdf) replace	

		
*--------------------------------------------------------------------------
* Apx Fig E4-A (Robustness: Remove various firm-level events)
*--------------------------------------------------------------------------

use "temp_coefficients_k5_all.dta", clear

// Appendix Figure E4-A	
	tw rcap cil ciu time if var=="relearn" & spec=="d11"  & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="d11" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(Oh)  || ///
	rcap cil ciu time if var=="relearn" & spec=="d1" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="d1" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(D)  || ///
	rcap cil ciu time if var=="relearn" & spec=="d9" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="d9" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(T)  || ///
	rcap cil ciu time if var=="relearn" & spec=="firmw" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="firmw" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(X)  || ///
	rcap cil ciu time if var=="relearn" & spec=="d7" & inc==1, color(black) || ///
	connected est time if var=="relearn" & spec=="d7" & inc==1, lcolor(black) mcolor(black) msymbol(O)  ///
		xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
		ytitle("Annual wage income change (%)") yline(0, lcolor(black) lpattern(dash))  ///
		legend(order(10 8 6 4 2)label(2 "Excl. management change")label(4 "Excl. firm events")label(6 "Excl. outliers in- & outside window")label(8 "Firm-level matching")label(10 "Baseline results")) ///
		legend(hole(2)) graphregion(color(white)) bgcolor(white) ylabel(-4(1)2)
	graph export w_relwage_inc_k5_firmevents.pdf, as(pdf) replace		

	
*--------------------------------------------------------------------------
* Appendix Figure E3; Apx Fig E4-B (Placebo spikes)
*--------------------------------------------------------------------------

// Appendix Figure E3
xmluse "$path_in/des_mfgraph_overl_other", doctype(excel) firstrow clear 

	compress

tw bar othermaterial_emp time, scheme(s2mono) ///
	ytitle("Other material asset investments per worker, real euros") xtitle("Time relative to placebo event") ///
	xlabel(-16(2)16) ylabel(0(1000)5000) ///
	graphregion(color(white)) bgcolor(white)
graph export des_mfgraph_placebo_pw.pdf, as(pdf) replace 



// Appendix Figure E4-B	
use "temp_coefficients_k5_all.dta", clear

	tw rcap cil ciu time if var=="relearn" & spec=="d7"  & inc==1, color(black) || ///
	connected est time if var=="relearn" & spec=="d7" & inc==1, lcolor(black) mcolor(black) msymbol(O)  || ///
	rcap cil ciu time if var=="relearn" & spec=="overl_placebo1" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="overl_placebo1" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(D)  || ///
	rcap cil ciu time if var=="relearn" & spec=="overl_placebo2" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="overl_placebo2" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(X)   ///
		xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
		ytitle("Annual wage income change (%)") yline(0, lcolor(black) lpattern(dash))  ///
		legend(order(2 4 6)label(2 "Automation events (baseline)")label(4 "Placebo events")label(6 "Placebo events, no automation")) ///
		legend(span) legend(holes(2)) graphregion(color(white)) bgcolor(white) ylabel(-4(1)2)			
	graph export w_relwage_inc_k5_placebo.pdf, as(pdf) replace	


*--------------------------------------------------------------------------
* Apx Fig E5-A (Robustness: Changing spike definition)
*--------------------------------------------------------------------------

use "temp_coefficients_k5_all.dta", clear

// Appendix Figure E5-A
	tw rcap cil ciu time if var=="relearn" & spec=="emp" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="emp" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(D)  || ///
	rcap cil ciu time if var=="relearn" & spec=="empf" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="empf" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(T)  || ///
	rcap cil ciu time if var=="relearn" & spec=="empt0" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="empt0" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(X)  || ///
	rcap cil ciu time if var=="relearn" & spec=="d7" & inc==1, color(black) || ///
	connected est time if var=="relearn" & spec=="d7" & inc==1, lcolor(black) mcolor(black) msymbol(O)  ///
		xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
		ytitle("Annual wage income change (%)") yline(0, lcolor(black) lpattern(dash))  ///
		legend(order(8 6 4 2)label(2 "AC/worker")label(4 "AC/worker, full emp data")label(6 "AC/worker, pre-event emp data")label(8 "Baseline results")) ///
		graphregion(color(white)) bgcolor(white) ylabel(-4(1)2)
	graph export w_relwage_inc_k5_spikedef.pdf, as(pdf) replace	


	
*--------------------------------------------------------------------------
* Apx Fig E5-B (Robustness: Changing spike threshold)
*--------------------------------------------------------------------------

use "temp_coefficients_k5_all.dta", clear

// Relative earnings, spike size		
	tw rcap cil ciu time if var=="relearn" & spec=="spike2" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="spike2" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(D)  || ///
	rcap cil ciu time if var=="relearn" & spec=="spike4" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="spike4" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(X)  || ///
	rcap cil ciu time if var=="relearn" & spec=="spike3" & inc==1, color(black) || ///
	connected est time if var=="relearn" & spec=="spike3" & inc==1, lcolor(black) mcolor(black) msymbol(O)   ///
		xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
		ytitle("Annual wage income change (%)")  yline(0, lcolor(black) lpattern(dash))   ///
		legend(order(6 2 4)label(6 "Spike threshold 3x average automation costs (baseline)")label(4 "Spike threshold 4x average automation costs")label(2 "Spike threshold 2x average automation costs")) ///
		legend(rows(3)) ///
		graphregion(color(white)) bgcolor(white) legend(span) ylabel(-4(1)2)	
	graph export w_relwage_inc_k5_spikesize.pdf, as(pdf) replace	



*--------------------------------------------------------------------------
* Apx Fig E6 (Robustness: Matching type and fixed effects)
*--------------------------------------------------------------------------		

use "temp_coefficients_k5_all.dta", clear

// Appendix Figure E6: Relative earnings
	tw rcap cil ciu time if var=="relearn" & spec=="fe0" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="fe0" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(D)  || ///
	rcap cil ciu time if var=="relearn" & spec=="sizew" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="sizew" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(T)  || ///
	rcap cil ciu time if var=="relearn" & spec=="tenurew" & inc==1, color(gs8) || ///
	connected est time if var=="relearn" & spec=="tenurew" & inc==1, lcolor(gs8) mcolor(gs8) msymbol(X)  || ///
	rcap cil ciu time if var=="relearn" & spec=="d7" & inc==1, color(black) || ///
	connected est time if var=="relearn" & spec=="d7" & inc==1, lcolor(black) mcolor(black) msymbol(O)  ///
		xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
		ytitle("Annual wage income change (%)") yline(0, lcolor(black) lpattern(dash))  ///
		legend(order(8 6 4 2)label(2 "No individual FE")label(4 "Matching firm size")label(6 "Matching worker tenure")label(8 "Baseline results")) ///
		graphregion(color(white)) bgcolor(white) ylabel(-4(1)2)	 	
	graph export w_relwage_inc_k5_modelspec.pdf, as(pdf) replace	


*--------------------------------------------------------------------------
* Apx Fig E7 (Permutation tests) // not yet exported, take old estimates -- 
*--------------------------------------------------------------------------

// Data prep
xmluse "$path_in_temp/permutationtest_pvalues.xml",  doctype(excel) firstrow clear 
	compress
save "temp_perm_pvalues.dta",  replace

clear all
xmluse "$path_in_temp/permutationtest_estimates.xml",  doctype(excel) firstrow clear 
	compress

	merge m:1 ylabel time using "temp_perm_pvalues.dta"
	drop _
	gen marker=string(p_est)
	replace marker="0"+marker
	replace marker="0.00" if marker=="00"
	replace marker="" if marker=="0."
	forvalues x=1(1)9 {
		replace marker="0.`x'0" if marker=="0.`x'"
	}
	replace marker="" if p!=1
save "temp_perm_pvalues.dta",  replace


// Appendix Figure E7
use "temp_perm_pvalues.dta", clear
	keep if ylabel=="relearn"
	gen temp=-4.5
	levelsof p, local(levels)
	foreach l of local levels {
		local gr `gr' line estimate time if p==`l' & p!=0 & ylabel=="relearn", lcolor(gs10) lpattern(solid) || ///
					  line estimate time if p==0 & ylabel=="relearn", lcolor(black) lpattern(solid)  || ///
					  scatter temp time if ylabel=="relearn"&`l'==1, msymbol(none) mlabel(marker) mlabpos(6) || 
					  }
		 
	graph twoway `gr', legend(off) ///
					xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash))  ///
					ylabel(-5(1)5) yline(0, lcolor(black) lpattern(dash)) ///
					yline(0, lcolor(black) lpattern(dash)) ///
					scheme(s2mono) graphregion(color(white)) bgcolor(white) legend(row(1))	///
					xtitle("Year relative to automation event") ///
					ytitle("Estimate for annual wage income change") ///
					graphregion(margin(r=35))  ///
					text(-5 4 "  Empirical p-values", place(r)) ///
					text(-2.5 4 "  Baseline estimates", place(r) color(black)) ///
					text(1 4 "  Permutation estimates", place(r) color(gs10))
	graph export perm_relearn.pdf, as(pdf) replace 
	graph drop _all	

	
*--------------------------------------------------------------------------	
*--------------------------------------------------------------------------
* 2. Descriptives
*--------------------------------------------------------------------------
*--------------------------------------------------------------------------

*--------------------------------------------------------------------------
* Fig 1; Apx Fig A1; Apx Fig F1 (Descriptives)
*--------------------------------------------------------------------------

// Spike descriptives 
xmluse "$path_in/des_mfgraph_autom.xml",  doctype(excel) firstrow clear 
	replace automation_tocosts=automation_tocosts*100

* Figure 1
tw bar automation_tocosts time, scheme(s2mono) ///
	ytitle("Automation cost share, percent") xtitle("Year relative to automation event") ///
	xlabel(-16(2)16) ylabel(0(.2)1.4) ///
	graphregion(color(white)) bgcolor(white)
graph export des_mfgraph_autom.pdf, as(pdf) replace 

	
// Automation cost (share & per worker) distribution over time 
xmluse "$path_in/des_costs_overtime_autom.xml", doctype(excel) firstrow clear 

* Appendix Figure A1-A
tw  connected p25_aemp year, lcolor(black) msymbol(O) mcolor(black) || ///
	connected p50_aemp year, lcolor(black) msymbol(d) mcolor(black) || ///
	line mn_aemp year, lcolor(black) lwidth(thick) msymbol(O) mcolor(black) || ///
	connected p75_aemp year, lcolor(black) msymbol(+) mcolor(black)|| ///
	connected p90_aemp year, lcolor(black) msymbol(Oh) mcolor(black) ///
	xtitle("Year") ///
	ytitle("Automation cost per worker (real euros)") ///
	legend(label(1 "p25")label(2 "p50")label(3 "mean")label(4 "p75")label(5 "p95")) legend(rows(2)) graphregion(color(white)) bgcolor(white)
graph export des_autom_pw_overtime.pdf, as(pdf) replace

* Appendix Figure A1-B
tw  connected p25_costshare year, lcolor(black) msymbol(O) mcolor(black) || ///
	connected p50_costshare year, lcolor(black) msymbol(d) mcolor(black) || ///
	line mn_costshare year, lcolor(black) lwidth(thick) msymbol(O) mcolor(black) || ///
	connected p75_costshare year, lcolor(black) msymbol(+) mcolor(black)|| ///
	connected p90_costshare year, lcolor(black) msymbol(Oh) mcolor(black) ///
	xtitle("Year") ///
	ytitle("Automation cost share (percent)") ///
	legend(label(1 "p25")label(2 "p50")label(3 "mean")label(4 "p75")label(5 "p95")) legend(rows(2)) graphregion(color(white)) bgcolor(white)
graph export des_autom_cs_overtime.pdf, as(pdf) replace


// Computer spikes, and overlapping sample automation spikes
xmluse "$path_in/des_mfgraph_overl_comp.xml", doctype(excel) firstrow clear 

* Appendix Figure F1
tw bar mn_cemp time, scheme(s2mono) ///
	ytitle("Computer investment per worker, real euros") xtitle("Time relative to computerization event") ///
	xlabel(-16(2)16) ylabel(0(500)2500) ///
	graphregion(color(white)) bgcolor(white)
graph export des_mfgraph_weighted_estsample_unbal_comp.pdf, as(pdf) replace 


*--------------------------------------------------------------------------
* Apx Fig A2. Import descriptives
*--------------------------------------------------------------------------	

xmluse "$path_in/des_imports_tot.dta.xml", doctype(excel) firstrow clear

foreach var in imp_AR_aut2 exp_AR_aut2 reexp_AR_aut2 {
	replace `var' = `var' / 1000000
}

* Appendix Figure A2	
tw  connected imp_AR_aut2 year, lcolor(black) msymbol(O) mcolor(black) || ///
	connected exp_AR_aut2 year, lcolor(gs8) msymbol(D) mcolor(gs8) || ///
	connected reexp_AR_aut2 year, lcolor(gs8) msymbol(+) mcolor(gs8)  ///
	xtitle("Year") ylabel(0(200)1000) xlabel(2010(1)2016) ///
	ytitle("Millions of real euros") /// 
	legend(label(1 "Imports")label(2 "Exports")label(3 "Re-exports")) ///
	legend(rows(1)) graphregion(color(white)) bgcolor(white)
	graph export des_imports_overtime2.pdf, as(pdf) replace


*--------------------------------------------------------------------------
* Apx Fig D1 (Comparing automating to non-automating firms)
*--------------------------------------------------------------------------	

xmluse "$path_in/des_automating_nonautomating_balanced.xml",  doctype(excel) firstrow clear
	label var snr_workers_mar "Scaled nr workers in March"
	gen lnnr_workers=ln(nr_workers_mar)


// Appendix Figure D1: Nr of workers, scaled
	tw 	scatter snr_workers_mar year if automating==1, sort connect(l l)  || ///
		scatter snr_workers_mar year if automating==0, sort connect(l l) ///
		legend(label(1 "Firms with automation event")label(2 "Firms without automation event")) ///
		legend(rows(2)) ytitle("Average number of workers, scaled") ///
		scheme(s2mono) graphregion(color(white)) bgcolor(white)
graph export des_firm_emp_scaled.pdf, as(pdf) replace 

	

*--------------------------------------------------------------------------
*--------------------------------------------------------------------------
* 3. Firm-level analyses
*--------------------------------------------------------------------------
*--------------------------------------------------------------------------
	
*--------------------------------------------------------------------------
* Fig 2; Apx Fig D2 (DiD firm-level, automation)
*--------------------------------------------------------------------------	

xmluse "$path_in/firm_stacked_did_weight.dta.xml",  doctype(excel) firstrow clear allstring 
	compress
	cap destring _all, replace
	drop plot
	compress
	rename ll1 cil
	rename ul1 ciu
	rename at time
	rename b est
	
** NOTE! t=-1 values missing, filling these in
preserve
	keep if t==0
	replace est = 0
	replace cil = 0
	replace ciu = 0
	replace t = -1
	save temp, replace
restore
	
	append using temp
	sort var time

* Figure 2A	
tw 	rcap cil ciu time if var=="ln_emp_size11", color(black) || ///
	connected est time if var=="ln_emp_size11", lcolor(black) mcolor(black) msymbol(O)  || ///
	rcap cil ciu time if var=="ln_emp_size12", color(gs10) || ///
	connected est time if var=="ln_emp_size12", lcolor(gs10) mcolor(gs10) msymbol(D) ///
	scheme(s2mono) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("") yline(0, lcolor(black) lpattern(dash)) ylabel(-.3(.1).1) ///
	legend(order(2 4) label(2 "Firms with <500 workers")label(4 "Firms with >500 workers")) ///
	graphregion(color(white)) bgcolor(white) legend(rows(1)) 
graph export firm_stacked_did_weight_emp_500.pdf, as(pdf) replace 
	
* Figure 2B	
tw 	rcap cil ciu time if var=="ln_wage_size11", color(black) || ///
	connected est time if var=="ln_wage_size11", lcolor(black) mcolor(black) msymbol(O)  || ///
	rcap cil ciu time if var=="ln_wage_size12", color(gs10) || ///
	connected est time if var=="ln_wage_size12", lcolor(gs10) mcolor(gs10) msymbol(D) ///
	scheme(s2mono) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("") yline(0, lcolor(black) lpattern(dash)) ylabel(-.05(.05).1) ///
	legend(order(2 4) label(2 "Firms with <500 workers")label(4 "Firms with >500 workers")) ///
	graphregion(color(white)) bgcolor(white) legend(rows(1)) 
graph export firm_stacked_did_weight_wage_500.pdf, as(pdf) replace 
	
* DiD firm level with never-automating firms as control
xmluse "$path_in/firm_stacked_did_weight_never.dta.xml",  doctype(excel) firstrow clear allstring 
	compress
	cap destring _all, replace
	drop plot
	compress
	rename ll1 cil
	rename ul1 ciu
	rename at time
	rename b est
	
** NOTE! t=-1 values missing, filling these in
preserve
	keep if t==0
	replace est = 0
	replace cil = 0
	replace ciu = 0
	replace t = -1
	save temp, replace
restore
	
	append using temp
	sort var time

* Appendix Figure D2-B	
tw 	rcap cil ciu time if var=="ln_emp", color(black) || ///
	connected est time if var=="ln_emp", lcolor(black) mcolor(black) msymbol(O)  ///
	scheme(s2mono) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("") yline(0, lcolor(black) lpattern(dash)) ylabel(-.05(.01).04) ///
	legend(off) ///
	graphregion(color(white)) bgcolor(white) legend(rows(1)) 
graph export firm_stacked_did_weight_emp_nevertreated.pdf, as(pdf) replace 

* Appendix Figure D2-D
tw 	rcap cil ciu time if var=="ln_wage", color(black) || ///
	connected est time if var=="ln_wage", lcolor(black) mcolor(black) msymbol(O)  ///
	scheme(s2mono) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("") yline(0, lcolor(black) lpattern(dash)) ylabel(-.04(.02).04) ///
	legend(off) ///
	graphregion(color(white)) bgcolor(white) legend(rows(1)) 
graph export firm_stacked_did_weight_wage_nevertreated.pdf, as(pdf) replace 


* Compare to the baseline results for all firms
xmluse "$path_in/firm_stacked_did_weight.dta.xml",  doctype(excel) firstrow clear allstring 
	compress
	cap destring _all, replace
	drop plot
	compress
	rename ll1 cil
	rename ul1 ciu
	rename at time
	rename b est
	
** NOTE! t=-1 values missing, filling these in
preserve
	keep if t==0
	replace est = 0
	replace cil = 0
	replace ciu = 0
	replace t = -1
	save temp, replace
restore
	
	append using temp
	sort var time

* Appendix Figure D2-A 	
tw 	rcap cil ciu time if var=="ln_emp_size01", color(black) || ///
	connected est time if var=="ln_emp_size01", lcolor(black) mcolor(black) msymbol(O)  ///
	scheme(s2mono) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("") yline(0, lcolor(black) lpattern(dash)) ylabel(-.15(.05).1) ///
	legend(off) ///
	graphregion(color(white)) bgcolor(white) legend(rows(1)) 
graph export firm_stacked_did_weight_emp_base.pdf, as(pdf) replace 

* Appendix Figure D2-C 
tw 	rcap cil ciu time if var=="ln_wage_size01", color(black) || ///
	connected est time if var=="ln_wage_size01", lcolor(black) mcolor(black) msymbol(O)  ///
	scheme(s2mono) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("") yline(0, lcolor(black) lpattern(dash)) ylabel(-.04(.02).04) ///
	legend(off) ///
	graphregion(color(white)) bgcolor(white) legend(rows(1)) 
graph export firm_stacked_did_weight_wage_base.pdf, as(pdf) replace 


*--------------------------------------------------------------------------
* Apx Figure D3 (DiD, comparison to importers)
*--------------------------------------------------------------------------	

xmluse "$path_in/firmdid_imports_coeff.dta.xml",  doctype(excel) firstrow clear

	drop plot
	compress
	rename ll1 cil
	rename ul1 ciu
	rename at time
	rename b est
	
** NOTE! t=-1 values missing, filling these in
preserve
	keep if t==1
	replace est = 0
	replace cil = 0
	replace ciu = 0
	recode t (1=-1)
	save temp, replace
restore

append using temp
	sort var time		

* Appendix Figure D3	
tw 	rcap cil ciu time if var=="emp" & sample=="all spiking firms", color(gs10) || ///
	connected est time if var=="emp" & sample=="all spiking firms", lcolor(gs10) mcolor(gs10) msymbol(O)  || ///
	rcap cil ciu time if var=="wage" & sample=="all spiking firms", color(gs10) || ///
	connected est time if var=="wage" & sample=="all spiking firms", lcolor(gs10) mcolor(gs10) msymbol(Dh) || ///
	rcap cil ciu time if var=="wb" & sample=="all spiking firms", color(black) || ///
	connected est time if var=="wb" & sample=="all spiking firms", lcolor(black) mcolor(black) msymbol(Oh) ///
	title("All automating firms") scheme(s2mono) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("") yline(0, lcolor(black) lpattern(dash)) ///
	legend(order(2 4 6) label(2 "Employment")label(4 "Daily wage")label(6 "Wage bill")) ///
	graphregion(color(white)) bgcolor(white) legend(rows(1)) ///
	name(aut, replace)	
	
tw 	rcap cil ciu time if var=="emp" & sample=="aut_imp", color(gs10) || ///
	connected est time if var=="emp" & sample=="aut_imp", lcolor(gs10) mcolor(gs10) msymbol(O)  || ///
	rcap cil ciu time if var=="wage" & sample=="aut_imp", color(gs10) || ///
	connected est time if var=="wage" & sample=="aut_imp", lcolor(gs10) mcolor(gs10) msymbol(Dh) || ///
	rcap cil ciu time if var=="wb" & sample=="aut_imp", color(black) || ///
	connected est time if var=="wb" & sample=="aut_imp", lcolor(black) mcolor(black) msymbol(Oh) ///
	title("Automation importers") scheme(s2mono) ///
	xtitle("Year relative to automation event") xlabel(-3(1)4, nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	ytitle("") yline(0, lcolor(black) lpattern(dash)) ///
	legend(order(2 4 6) label(2 "Employment")label(4 "Daily wage")label(6 "Wage bill")) ///
	graphregion(color(white)) bgcolor(white) legend(rows(1)) ///
	name(aut_imp, replace)	
	
	grc1leg  	aut aut_imp,  rows(1) ysize(9) xsize(16) ///
				title("") subtitle("") ///
				graphregion(color(white)) plotregion(color(white)) ///
				legendfrom(aut) l1title("Log change in outcome relative to t=-1") ///
				name(eventimport, replace)
	graph display eventimport, ysize(9) xsize(16)			
	graph export des_firm_DiD_imports.pdf, as(pdf) replace 
	

*--------------------------------------------------------------------------
* Apx Fig C1 (Components of automation cost shares over time relative to event)
*--------------------------------------------------------------------------

* Appendix Figure C1
xmluse "$path_in/des_costs_around_event_balanced.xml",  doctype(excel) firstrow allstring clear
compress
cap destring _all, replace

twoway 	connected automation_real time, sort lcolor(black) mcolor(black) msymbol(O) || ///
		connected costs time, sort yaxis(2) lcolor(gs8) mcolor(gs8) msymbol(D) ///
		xtitle("Year relative to automation event") ytitle("") ytitle("", axis(2)) ///
		ylabel(60000 (4000) 80000,axis(2)) ylabel(0(200)1000) xlabel(-3(1)4) ///
		legend(order (1 "Real automation costs (left axis)" 2 "Real total costs (right axis)")) ///
		legend(rows(2)) graphregion(color(white)) bgcolor(white)
	graph export ACevent.pdf, as(pdf) replace


*--------------------------------------------------------------------------
*--------------------------------------------------------------------------
* Export some xml datasets to xlsx for making tables
*--------------------------------------------------------------------------
*--------------------------------------------------------------------------

* For Appendix Table A3
xmluse $path_in/des_ict_bedrijven.dta.xml, doctype(excel) firstrow clear	
export excel $path_in/des_ict_bedrijven.xlsx, replace firstrow(var)

* For Appendix Table A4	
xmluse "$path_in/des_imports_ind.dta.xml", doctype(excel) firstrow clear
export excel $path_in/des_imports_ind.xlsx, replace firstrow(var)


* For Appendix Table E3
xmluse "$path_in/brier_skill_base.dta.xml", doctype(excel) firstrow clear
	sum
	list
export excel $path_in/brier_skill_base.xlsx, replace firstrow(var)
	
xmluse "$path_in/brier_skill_interact.dta.xml", doctype(excel) firstrow clear
	sum
	list
export excel $path_in/brier_skill_interact.xlsx, replace firstrow(var)
	
xmluse "$path_in/brier_skill_lag.dta.xml", doctype(excel) firstrow clear
	sum
	list
export excel $path_in/brier_skill_lag.xlsx, replace firstrow(var)
		

*--------------------------------------------------------------------------	
* Erase temporary files
cap erase "temp_recent_hires.dta"
cap erase "temp_perm_pvalues.dta"
foreach i in 1 7 9 11 {
	cap erase "temp_coefficients_k5_d`i'.dta"
}
forvalues i=1(1)14 {
	cap erase "temp_coeff`i'.dta"
}
	cap erase "temp_coefficients_k5_all.dta"
cap erase "temp_spike.dta"
cap erase "temp_spike2.dta"
cap erase "temp_spike4.dta"
cap erase "temp.dta"
*--------------------------------------------------------------------------
