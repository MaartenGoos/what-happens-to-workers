
*------------------------------------------------------------------------
* Automation
* permutation_test_analysis.do
* 7/6/2019
* Wiljan van den Berge
* Purpose: run permutation test analyses
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
log using log/permutation_test_analysis, text replace
*--------------------------------------------------------------------------

* This creates the permutation test analyses presented in Figure E.7 for relative earnings. This also creates the same analyses for probability to leave, nonemployment duration and log daily wage
* Each analyses requires 101 regressions (the main regression and 100 random permutations). This takes about 10 hours to run.

* Main regression
use dta/analysis/worker_analysis_drop7_autom.dta if inc==1 & !missing(weight1), clear

gen weight=weight1

qui tab time, gen(t)
compress

global x female foreign age age2 i.sector_treatyr i.gk_treatyr i.year // Global with control variables

label var relearn "relearn"
label var leave2 "leave2"
label var nonemp "nonemp"
label var lnwage "lnwage"

foreach var of varlist relearn leave2 nonemp lnwage{ 
	if "`var'"!="leave2"{
		reghdfe `var' 1.(t1-t2)#1.treat 1.(t4-t8)#1.treat 1.(t1-t2) 1.(t4-t8) age age2 i.year [aweight=weight], cluster(firmid_inc) absorb(id)	
	}
	else{
		reg `var' 1.(t1-t2)#1.treat 1.(t4-t8)#1.treat 1.(t1-t2) 1.(t4-t8) $x [aweight=weight], cluster(firmid_inc)
	}
	parmest, saving(output/perm/`var'_main.dta, replace) ylabel
}

clear all
foreach var in relearn leave2 nonemp lnwage{ 
	append using output/perm/`var'_main.dta
}

keep if parm=="1.t1#1.treat" | parm=="1.t2#1.treat" | parm=="1.t4#1.treat" | parm=="1.t5#1.treat" ///
	| parm=="1.t6#1.treat" | parm=="1.t7#1.treat" | parm=="1.t8#1.treat"



* Then add 4 observations for each variable
set obs `=_N+4'
replace ylabel = "relearn" if _n==_N-3
replace ylabel = "leave2" if _n==_N-2
replace ylabel = "nonemp" if _n==_N-1
replace ylabel = "lnwage" if _n==_N
replace parm = "1.t3#1.treat" if missing(parm)

sort ylabel parm
by ylabel: gen byte time=_n
replace time = time - 4

keep estimate stderr min95 max95 time ylabel t
foreach var in estimate stderr min95 max95 t{
	replace `var' = 0 if missing(`var')
}
compress
save output/perm/perm_main.dta, replace


* The 100 permutations
forval p=1/100{
	use dta/analysis/worker_analysis_perm`p'.dta, clear

	qui tab time, gen(t)
	global x female foreign age age2 i.sector_treatyr i.gk_treatyr i.year // Global with control variables

	label var relearn "relearn"
	label var leave2 "leave2"
	label var nonemp "nonemp"
	label var lnwage "lnwage"

	foreach var of varlist relearn leave2 nonemp lnwage{ 
		if "`var'"!="leave2"{
			reghdfe `var' 1.(t1-t2)#1.treat 1.(t4-t8)#1.treat 1.(t1-t2) 1.(t4-t8) age age2 i.year [aweight=weight1], cluster(firmid2) absorb(id)	
		}
		else{
			reg `var' 1.(t1-t2)#1.treat 1.(t4-t8)#1.treat 1.(t1-t2) 1.(t4-t8) $x [aweight=weight1], cluster(firmid2)
		}
		parmest, saving(output/perm/`var'_p`p'.dta, replace) ylabel
	}


	use output/perm/relearn_p`p'.dta, clear
	foreach var in leave2 nonemp lnwage{ 
		append using output/perm/`var'_p`p'.dta
	}
	keep if parm=="1.t1#1.treat" | parm=="1.t2#1.treat" | parm=="1.t4#1.treat" | parm=="1.t5#1.treat" ///
		| parm=="1.t6#1.treat" | parm=="1.t7#1.treat" | parm=="1.t8#1.treat"



	* Then add 4 observations for each variable
	set obs `=_N+4'
	replace ylabel = "relearn" if _n==_N-3
	replace ylabel = "leave2" if _n==_N-2
	replace ylabel = "nonemp" if _n==_N-1
	replace ylabel = "lnwage" if _n==_N
	replace parm = "1.t3#1.treat" if missing(parm)

	sort ylabel parm
	by ylabel: gen byte time=_n
	replace time= time - 4 

	keep estimate stderr min95 max95 time ylabel t
	foreach var in estimate stderr min95 max95 t{
		replace `var' = 0 if missing(`var')
	}
	compress
	save output/perm/perm_p`p'.dta, replace
}



* Save output
use output/perm/perm_main.dta, clear
gen p=0
forvalues p=1/100{
	append using output/perm/perm_p`p'.dta
	replace p = `p' if missing(p)
}

save output/perm/perm_output.dta, replace

* Calculate p-values for estimates and t-stats
use output/perm/perm_output.dta, clear

gen main_est = estimate if p==0
gen main_t = t if p==0

foreach var of varlist main_est main_t{
	gsort ylabel time -`var'
	by ylabel time: replace `var'=`var'[_n-1] if missing(`var')
}

gen p_t = 1 if abs(t) >= abs(main_t)
gen p_est = 1 if abs(estimate) >= abs(main_est)
replace p_t = 0 if missing(p_t) | missing(t)
replace p_est = 0 if missing(p_est) | missing(estimate)

keep if p>0
collapse (mean) p_t p_est, by(time ylabel)
sort ylabel time
replace p_t = . if time==-1
replace p_est = . if time==-1

* Create graphs
tw conn p_t time if ylabel=="relearn", msymbol(O) lcolor(gs0) mcolor(gs0) || conn p_t time if ylabel=="leave2", msymbol(D) lcolor(gs4) mcolor(gs4) || ///
	conn p_t time if ylabel=="nonemp", msymbol(+) lcolor(gs8) mcolor(gs8) || conn p_t time if ylabel=="lnwage", msymbol(S) lcolor(gs12) mcolor(gs12) ///
	, graphregion(color(white)) ytitle("P-value of t-statistic") xtitle("Year relative to first automation spike") ///
	legend(label(1 "Relative earnings")label(2 "Probability to leave")label(3 "Nonemployment duration") ///
	label(4 "Ln(daily wage)")) xlabel(-3(1)4) ylabel(0(0.2)1) xline(0, lcolor(black) lpattern(dash))

tw conn p_est time if ylabel=="relearn", msymbol(O) lcolor(gs0) mcolor(gs0) || conn p_est time if ylabel=="leave2", msymbol(D) lcolor(gs4) mcolor(gs4) || ///
	conn p_est time if ylabel=="nonemp", msymbol(+) lcolor(gs8) mcolor(gs8) || conn p_est time if ylabel=="lnwage", msymbol(S) lcolor(gs12) mcolor(gs12) ///
	, graphregion(color(white)) ytitle("P-value of estimate") xtitle("Year relative to first automation spike") ///
	legend(label(1 "Relative earnings")label(2 "Probability to leave")label(3 "Nonemployment duration") ///
	label(4 "Ln(daily wage)")) xlabel(-3(1)4) ylabel(0(0.2)1) xline(0, lcolor(black) lpattern(dash))

xmlsave output/permutationtest_pvalues.xml, replace doctype(excel)


* This creates the final graphs as they appear in the main paper
use output/perm/perm_output.dta, clear
replace estimate = estimate*100 if ylabel=="relearn" | ylabel=="leave2" | ylabel=="lnwage"

xmlsave output/permutationtest_estimates.xml, replace doctype(excel)

// thick black line for main estimate, and thin gray lines for permutation tests
tw 	line estimate time if p==0 & ylabel=="relearn", lcolor(gs0) lwidth(medthick)  	lpattern(solid) || ///
	line estimate time if p==1 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==2 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==3 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==4 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==5 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==6 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==7 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==8 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==9 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==10 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==11 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==12 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==13 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==14 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==15 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==16 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==18 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==19 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==20 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==21 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==22 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==23 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==24 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==25 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==26 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==27 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==28 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==29 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==30 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==31 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==32 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==33 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==34 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==35 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==36 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==37 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==38 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==39 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==40 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==41 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==42 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==43 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==44 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==45 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==46 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==47 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==48 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==49 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==50 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==51 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==52 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==53 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==54 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==55 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==56 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==57 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==58 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==59 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==60 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==61 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==62 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==63 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==64 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==65 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==66 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==67 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==68 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==69 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==70 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==71 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==72 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==73 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==74 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==75 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==76 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==77 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==78 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==79 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==80 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==81 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==82 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==83 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==84 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==85 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==86 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==87 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==88 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==89 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==90 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==91 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==92 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==93 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==94 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==95 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==96 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==97 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==98 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==99 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==100 & ylabel=="relearn", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	,graphregion(color(white)) scheme(s2mono) xlabel(-3(1)4,nogrid) ylabel(-4(2)4,nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	yline(0, lcolor(black) lpattern(dash)) legend(label(1 "Main estimates")label(2 "Permutation estimates")order(1 2)) xtitle("Year relative to first automation spike") ytitle("Relative earnings (%)")
graph export output/permutation_relearn.pdf, replace

tw 	line estimate time if p==0 & ylabel=="leave2", lcolor(gs0) lwidth(medthick)  	lpattern(solid) || ///
	line estimate time if p==1 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==2 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==3 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==4 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==5 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==6 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==7 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==8 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==9 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==10 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==11 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==12 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==13 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==14 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==15 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==16 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==18 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==19 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==20 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==21 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==22 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==23 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==24 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==25 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==26 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==27 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==28 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==29 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==30 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==31 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==32 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==33 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==34 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==35 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==36 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==37 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==38 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==39 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==40 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==41 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==42 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==43 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==44 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==45 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==46 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==47 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==48 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==49 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==50 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==51 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==52 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==53 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==54 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==55 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==56 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==57 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==58 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==59 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==60 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==61 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==62 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==63 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==64 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==65 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==66 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==67 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==68 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==69 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==70 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==71 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==72 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==73 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==74 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==75 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==76 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==77 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==78 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==79 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==80 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==81 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==82 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==83 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==84 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==85 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==86 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==87 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==88 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==89 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==90 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==91 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==92 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==93 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==94 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==95 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==96 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==97 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==98 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==99 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==100 & ylabel=="leave2", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	,graphregion(color(white)) scheme(s2mono) xlabel(-3(1)4,nogrid) ylabel(-4(2)4,nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	yline(0, lcolor(black) lpattern(dash)) legend(label(1 "Main estimates")label(2 "Permutation estimates")order(1 2)) xtitle("Year relative to first automation spike") ytitle("Hazard of leaving the firm")
graph export output/permutation_leave2.pdf, replace

tw 	line estimate time if p==0 & ylabel=="nonemp", lcolor(gs0) lwidth(medthick)  	lpattern(solid) || ///
	line estimate time if p==1 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==2 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==3 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==4 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==5 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==6 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==7 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==8 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==9 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==10 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==11 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==12 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==13 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==14 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==15 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==16 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==18 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==19 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==20 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==21 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==22 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==23 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==24 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==25 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==26 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==27 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==28 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==29 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==30 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==31 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==32 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==33 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==34 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==35 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==36 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==37 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==38 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==39 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==40 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==41 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==42 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==43 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==44 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==45 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==46 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==47 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==48 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==49 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==50 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==51 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==52 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==53 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==54 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==55 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==56 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==57 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==58 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==59 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==60 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==61 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==62 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==63 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==64 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==65 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==66 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==67 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==68 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==69 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==70 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==71 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==72 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==73 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==74 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==75 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==76 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==77 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==78 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==79 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==80 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==81 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==82 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==83 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==84 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==85 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==86 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==87 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==88 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==89 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==90 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==91 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==92 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==93 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==94 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==95 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==96 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==97 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==98 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==99 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==100 & ylabel=="nonemp", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	,graphregion(color(white)) scheme(s2mono) xlabel(-3(1)4,nogrid) ylabel(-4(2)8,nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	yline(0, lcolor(black) lpattern(dash)) legend(label(1 "Main estimates")label(2 "Permutation estimates")order(1 2)) xtitle("Year relative to first automation spike") ytitle("Nonemployment duration (days)")
graph export output/permutation_nonemp.pdf, replace

tw 	line estimate time if p==0 & ylabel=="lnwage", lcolor(gs0) lwidth(medthick)  	lpattern(solid) || ///
	line estimate time if p==1 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==2 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==3 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==4 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==5 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==6 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==7 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==8 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==9 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==10 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==11 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==12 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==13 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==14 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==15 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==16 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==18 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==19 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==20 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==21 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==22 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==23 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==24 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==25 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==26 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==27 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==28 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==29 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==30 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==31 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==32 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==33 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==34 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==35 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==36 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==37 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==38 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==39 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==40 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==41 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==42 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==43 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==44 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==45 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==46 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==47 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==48 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==49 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==50 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==51 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///
	line estimate time if p==52 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==53 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==54 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==55 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==56 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==57 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==58 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==59 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==60 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==61 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==62 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==63 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==64 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==65 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==66 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==67 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==68 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==69 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==70 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==71 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==72 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==73 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==74 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==75 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==76 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==77 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==78 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==79 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==80 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==81 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==82 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==83 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==84 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==85 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==86 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==87 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==88 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==89 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==90 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==91 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==92 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==93 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==94 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==95 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==96 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==97 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==98 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==99 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	line estimate time if p==100 & ylabel=="lnwage", lcolor(gs8) lwidth(thin) 		lpattern(solid) || ///	
	,graphregion(color(white)) scheme(s2mono) xlabel(-3(1)4,nogrid) ylabel(-3(1)3,nogrid) xline(0, lcolor(black) lpattern(dash)) ///
	yline(0, lcolor(black) lpattern(dash)) legend(label(1 "Main estimates")label(2 "Permutation estimates")order(1 2)) xtitle("Year relative to first automation spike") ytitle("ln(daily wage)")
graph export output/permutation_lnwage.pdf, replace






