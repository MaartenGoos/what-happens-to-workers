*------------------------------------------------------------------------
* Automation
* worker_analysis_heterogeneity.do
* Last updated: 17/10/2022
* Wiljan van den Berge
* Purpose: Heterogeneity analysis for main sample
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
log using log/worker_analysis_heterogeneity, t replace
*--------------------------------------------------------------------------

use dta/analysis/worker_analysis_drop7_autom_heterogeneity.dta, clear

tab age_cat
recode age_cat (20=1) (30=2) (40=3) (50=4)

// Regressions

global x female foreign age age2 i.sector_treatyr i.gk_treatyr i.year // Global with control variables
global outcome "relearn leave2 nonemp lnwage early" // Global with outcome variables

* Age groups	
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y'  1.treat#1.post 1.treat#1.post#b(4).age_cat age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#age_cat)	
		est sto inc_age`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##b(4).age_cat $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_age`y'
	}
}

* Gender

foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#1.female age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#female)
		est sto inc_fem_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##1.female $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_fem_`y'
	}
}

* Flex contracts
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#1.flex age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#flex)
		est sto inc_flex_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##1.flex $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_flex_`y'
	}
}

* Sectors
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#b(1).sector_cat age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#sector_cat)
		est sto inc_sec_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##b(1).sector_cat $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_sec_`y'

	}
}
* Firm size
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#b(1).size_cat age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#size_cat)
		est sto inc_size_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##b(1).size_cat $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_size_`y'

	}
}
* Education [without people with missing education]
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#b(2).educ age age2 [aweight=weight1] if educ!=0, cluster(firmid_inc) absorb(id year time post#educ)
		est sto inc_educ_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##b(2).educ $x [aweight=weight1]  if educ!=0, cluster(firmid_inc)
		est sto inc_educ_`y'
	}
}

* Quartile by age
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#b(1).quart_age age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#quart_age)
		est sto inc_quaa_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##b(1).quart_age $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_quaa_`y'

	}
}

* Quartile by age and firm
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#b(1).quart_age_firm age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#quart_age_firm)
		est sto inc_quaf_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##b(1).quart_age_firm $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_quaf_`y'

	}
}

* Residual wage quartile
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#b(1).quart_res age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#quart_res)
		est sto inc_quar_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##b(1).quart_res $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_quar_`y'
	}
}

// Quartiles for same sample as where we observe quartiles within the firm
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#b(1).quart_age age age2 [aweight=weight1] if !missing(quart_age_firm),  cluster(firmid_inc) absorb(id year time post#quart_age)
		est sto inc_quas_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##b(1).quart_age $x [aweight=weight1] if !missing(quart_age_firm),  cluster(firmid_inc)
		est sto inc_quas_`y'


	}
}

// Quartiles for same sample as where we observe quartiles within the firm
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#b(1).quart_res age age2 [aweight=weight1] if !missing(quart_age_firm),  cluster(firmid_inc) absorb(id year time post#quart_res)
		est sto inc_qurs_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##b(1).quart_res $x [aweight=weight1] if !missing(quart_age_firm),  cluster(firmid_inc)
		est sto inc_qurs_`y'

	}
}
** Only workers below 55
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post age age2 [aweight=weight1] if max_age<55, cluster(firmid_inc) absorb(id year time)
		est sto inc_mage`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post $x [aweight=weight1] if max_age<55, cluster(firmid_inc)
		est sto inc_mage`y'

	}
}
* Nationality
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#1.foreign age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#foreign)
		est sto inc_for_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##1.foreign $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_for_`y'

	}
}

// Recession
foreach y of varlist $outcome{
	if "`y'"!="`leave2'"{
		reghdfe `y' 1.treat#1.post 1.treat#1.post#1.rec age age2 [aweight=weight1], cluster(firmid_inc) absorb(id year time post#rec)
		est sto inc_rec_`y'
	}
	if "`y'"=="`leave2'"{
		reg `y' 1.treat##1.post##1.rec $x [aweight=weight1], cluster(firmid_inc)
		est sto inc_rec_`y'

	}
}

// Extensive version with SE, stars etc.
esttab inc_age*  using output/heterogeneity.csv, replace not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2) ///
	keep(1.treat#1.post#2.age_cat 1.treat#1.post#3.age_cat 1.treat#1.post#1.age_cat 1.treat#1.post) label nogaps nolines nonotes noobs title("Panel A. Incumbents") ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#2.age_cat 100*@ 100 1.treat#1.post#3.age_cat 100*@ 100 1.treat#1.post#1.age_cat 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	mtitles("Relative earnings" "Leave" ///
	"Nonemployment duration" "ln(daily wage)" "Early retirement" "Total benefits" "Self emp") ///
	coeflabels(1.treat#1.post "Age 50-60 (ref)" 1.treat#1.post#2.age_cat "Age 30-39" 1.treat#1.post#3.age_cat "Age 40-49" 1.treat#1.post#1.age_cat "Age 20-29")

esttab inc_fem* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2) ///
	keep(1.treat#1.post#1.female 1.treat#1.post) label nogaps nolines nonotes nomtitle nonumber ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#1.female 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	coeflabels(1.treat#1.post "Male (ref)" 1.treat#1.post#1.female "Female")

esttab inc_flex* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2) ///
	keep(1.treat#1.post#1.flex 1.treat#1.post) label nogaps nolines nonotes nomtitle nonumber ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#1.flex 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	coeflabels(1.treat#1.post "Open-ended contract (ref)" 1.treat#1.post#1.flex "Flexible contract")

esttab inc_sec* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2) ///
	keep(1.treat#1.post#2.sector_cat 1.treat#1.post#3.sector_cat 1.treat#1.post#4.sector_cat 1.treat#1.post#5.sector_cat 1.treat#1.post#6.sector_cat ///
	1.treat#1.post#7.sector_cat 1.treat#1.post#8.sector_cat 1.treat#1.post) label nogaps nolines nonotes noobs nomtitle nonumber ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#2.sector_cat 100*@ 100 1.treat#1.post#3.sector_cat 100*@ 100 1.treat#1.post#4.sector_cat 100*@ 100 ///
	1.treat#1.post#5.sector_cat 100*@ 100 1.treat#1.post#6.sector_cat 100*@ 100 1.treat#1.post#7.sector_cat 100*@ 100 1.treat#1.post#8.sector_cat 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	coeflabels(1.treat#1.post "Manufacturing (ref)" 1.treat#1.post#2.sector_cat "Construction" 1.treat#1.post#3.sector_cat "Wholesale and retail trade" ///
	1.treat#1.post#4.sector_cat "Transportation and storage" 1.treat#1.post#5.sector_cat "Accommodation and food serving" 1.treat#1.post#6.sector_cat "Information and comm" ///
	1.treat#1.post#7.sector_cat "Prof scientific techn act" 1.treat#1.post#8.sector_cat "Admin and suport act")

esttab inc_size* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2) ///
	keep(1.treat#1.post#2.size_cat 1.treat#1.post#3.size_cat 1.treat#1.post#4.size_cat 1.treat#1.post#5.size_cat 1.treat#1.post#6.size_cat 1.treat#1.post) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#2.size_cat 100*@ 100 1.treat#1.post#3.size_cat 100*@ 100 ///
	1.treat#1.post#4.size_cat 100*@ 100 1.treat#1.post#5.size_cat 100*@ 100 1.treat#1.post#6.size_cat 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	label nogaps nolines nomtitle nonumber nonotes ///
	coeflabels(1.treat#1.post "1-19 employees (ref)" 1.treat#1.post#2.size_cat "20-49 employees" 1.treat#1.post#3.size_cat "50-99 employees" ///
	1.treat#1.post#4.size_cat "100-199 employees" 1.treat#1.post#5.size_cat "200-499 employees" 1.treat#1.post#6.size_cat "500+ employees")

esttab inc_educ* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2) ///
	keep(1.treat#1.post 1.treat#1.post#1.educ 1.treat#1.post#3.educ) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#1.educ 100*@ 100 1.treat#1.post#3.educ 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	label nogaps nolines nomtitle nonumber nonotes ///
	coeflabels(1.treat#1.post "Middle education (ref)" 1.treat#1.post#1.educ "Low education" 1.treat#1.post#3.educ "High education")

esttab inc_quaa* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2)  ///
	keep(1.treat#1.post 1.treat#1.post#2.quart_age 1.treat#1.post#3.quart_age 1.treat#1.post#4.quart_age) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#2.quart_age 100*@ 100 1.treat#1.post#3.quart_age 100*@ 100 1.treat#1.post#4.quart_age 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	label nogaps nolines nomtitle nonumber nonotes ///
	coeflabels(1.treat#1.post "Wage quartile by age bottom (1 ref)" 1.treat#1.post#2.quart_age "Wage quartile by age 2" 1.treat#1.post#3.quart_age "Wage quartile by age 3" ///
	1.treat#1.post#4.quart_age "Wage quartile by age top (4 ref)")

esttab inc_quas* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2)  ///
	keep(1.treat#1.post 1.treat#1.post#2.quart_age 1.treat#1.post#3.quart_age 1.treat#1.post#4.quart_age) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#2.quart_age 100*@ 100 1.treat#1.post#3.quart_age 100*@ 100 1.treat#1.post#4.quart_age 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	label nogaps nolines nomtitle nonumber nonotes ///
	coeflabels(1.treat#1.post "Wage quart by age bottom (1 small sample)" 1.treat#1.post#3.quart_age "Wage quart by age 3"  1.treat#1.post#2.quart_age "Wage quart by age 2" ///
	1.treat#1.post#4.quart_age "Wage quart by age top (4)")

esttab inc_quaf* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2)  ///
	keep(1.treat#1.post 1.treat#1.post#2.quart_age_firm 1.treat#1.post#3.quart_age_firm 1.treat#1.post#4.quart_age_firm) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#2.quart_age_firm 100*@ 100 1.treat#1.post#3.quart_age_firm 100*@ 100 1.treat#1.post#4.quart_age_firm 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	label nogaps nolines nomtitle nonumber nonotes ///
	coeflabels(1.treat#1.post "Wage quartile by age and firm bottom (1 ref)"  1.treat#1.post#3.quart_age_firm "Wage quartile by age and firm 3" 1.treat#1.post#2.quart_age_firm "Wage quartile by age and firm 2" ///
	1.treat#1.post#4.quart_age_firm "Wage quartile by age and firm top (4)")

esttab inc_quar* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2)  ///
	keep(1.treat#1.post 1.treat#1.post#2.quart_res 1.treat#1.post#3.quart_res 1.treat#1.post#4.quart_res) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#2.quart_res 100*@ 100 1.treat#1.post#3.quart_res 100*@ 100 1.treat#1.post#4.quart_res 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	label nogaps nolines nomtitle nonumber nonotes ///
	coeflabels(1.treat#1.post "Residual wage quartile bottom (1 ref)"  1.treat#1.post#3.quart_res "Residual wage quartile 3" 1.treat#1.post#2.quart_res "Residual wage quartile 2" ///
	1.treat#1.post#4.quart_res "Residual wage quartile top (4)")

esttab inc_qurs* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2)  ///
	keep(1.treat#1.post 1.treat#1.post#2.quart_res 1.treat#1.post#3.quart_res 1.treat#1.post#4.quart_res) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#2.quart_res 100*@ 100 1.treat#1.post#3.quart_res 100*@ 100 1.treat#1.post#4.quart_res 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	label nogaps nolines nomtitle nonumber nonotes ///
	coeflabels(1.treat#1.post "Res wage quart bottom (1 ref small sample)" 1.treat#1.post#3.quart_res "Res wage quart 3" 1.treat#1.post#2.quart_res "Res wage quart 2" ///
	1.treat#1.post#4.quart_res "Res wage quart top (4)")


esttab inc_mage* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2)   ///
	keep(1.treat#1.post) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#1.rec 100*@ 100, pattern(1 1 0 1 1 0 1)) ///	
	label nogaps nolines nomtitle nonumber nonotes ///
	coeflabels(1.treat#1.post "Max age <55")

esttab inc_for* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2)   ///
	keep(1.treat#1.post 1.treat#1.post#1.foreign) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#1.foreign 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	label nogaps nolines nomtitle nonumber nonotes ///
	coeflabels(1.treat#1.post "Native" 1.treat#1.post#1.foreign "Foreign born or foreign born parents")

esttab inc_rec* using output/heterogeneity.csv, append not star(* 0.1 ** 0.05 *** 0.01) b(2) se(2)   ///
	keep(1.treat#1.post 1.treat#1.post#1.rec) ///
	transform(1.treat#1.post 100*@ 100 1.treat#1.post#1.rec 100*@ 100, pattern(1 1 0 1 1 0 1)) ///
	label nogaps nolines nomtitle nonumber ///
	coeflabels(1.treat#1.post "Boom" 1.treat#1.post#1.rec "Recession")
