*------------------------------------------------------------------------
* Automation
* descriptives_spike.do
* 11/5/2018
* 4/6/2018: removed spike correlates analyses and created separate do file for them
* 22/6/2018: changed figures to PDF for easier export and latex integration
* 26/11/2018:	Added regression of ever-spike dummy on firm characteristics
* Wiljan van den Berge
* Purpose: create descriptives of spikes and automation costs
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
log using log/descriptives_spikes_automation, text replace
*--------------------------------------------------------------------------

use dta\intermediate\firmsample_autom, clear

/* Table 1: Descriptives on automation cost share */
est clear
cap drop a_emp

// Calculate time-varying automation to costs instead of using the averaged scaling for descriptives
rename automation_tocosts automation_tocosts_avg
gen automation_tocosts = automation_real / (totalcosts_real - automation_real)
replace automation_tocosts=0 if automation_real==0


replace automation_tocosts = automation_tocosts * 100
replace automation_real = automation_real * 1000
gen a_emp=automation_real / nr_workers_mar


eststo: estpost tabstat automation_tocosts automation_real a_emp, statistics(p5 p10 p25 p50 p75 p90 p95 mean)
count if automation_real<=0
gen zero = `r(N)'
sum zero
estadd r(max): est1

eststo: estpost tabstat automation_tocosts automation_real a_emp if automation_real>0, statistics(p5 p10 p25 p50 p75 p90 p95 mean)

esttab est1 est2 using output/des_automationcosts.csv, cells("automation_real(fmt(0)) a_emp(fmt(0)) automation_tocosts(fmt(2))") replace nonumber mtitles("All observations" "Observations with >0 costs") ///
collabels("Cost level" "Cost by worker" "Cost share") stats(N max, fmt(0 0) labels("N firms x years" "N with 0 costs")) title("Automation cost shares and level distribution") plain

est clear

/* Table 2A: mean + sd of automation cost shares and levels by sector */

label define s_edit 1 "Manufacturing" 2 "Construction" 3 "Wholesale and retail trade" 4 "Transportation and storage" ///
5 "Accommodation and food serv" 6 "Information and communication" 7 "Prof scientific techn act" 8 "Admin and support act", replace
label values sbi2008_1dig s_edit

eststo: estpost tabstat automation_tocosts automation_real a_emp, by(sbi2008_1dig) statistics(mean) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp, by(sbi2008_1dig) statistics(sd) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp, by(sbi2008_1dig) statistics(n) nototal
cap drop i
bys beid: gen i = 1 if _n==1
eststo: estpost tabstat automation_tocosts automation_real a_emp if i==1, by(sbi2008_1dig) statistics(n) nototal
drop i

esttab est1 est2 est3 est4 using output/des_automationcosts.csv, cells("automation_real(fmt(0)) a_emp(fmt(0)) automation_tocosts(fmt(2))") append nonumber mtitles("Mean" "SD" "N firms x years" "N firms") ///
collabels("Cost level" "Cost by worker" "Cost share") stats(N, fmt(0) labels("N firms x years")) noobs title("Automation cost shares and levels by 1-digit sector") plain

est clear

/* Table 2B: mean + sd of automation cost shares by AVERAGE size class */
est clear
// Calculate AVERAGE size class
bys beid: egen avg_workers=mean(nr_workers_mar)
replace avg_workers=floor(avg_workers)
recode avg_workers (1/19=1) (20/49=2) (50/99=3) (100/199=4) (200/499=5) (500/999999999999=6), gen(avg_gk)
label define gsize 1 "1-19 employees" 2 "20-49 employees" 3 "50-99 employees" ///
4 "100-199 employees" 5 "200-499 employees" 6 ">=500 employees"

label values avg_gk gsize
eststo: estpost tabstat automation_tocosts automation_real a_emp, by(avg_gk) statistics(mean) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp, by(avg_gk) statistics(sd) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp, by(avg_gk) statistics(n) nototal

bys beid: gen i = 1 if _n==1
eststo: estpost tabstat automation_tocosts automation_real a_emp if i==1, by(avg_gk) statistics(n) nototal
drop i

esttab est1 est2 est3 est4 using output/des_automationcosts.csv, cells("automation_real(fmt(0)) a_emp(fmt(0)) automation_tocosts(fmt(2))") append nonumber mtitles("Mean" "SD" "N firms x years" "N firms") ///
collabels("Cost level" "Cost by worker" "Cost share") stats(N, fmt(0) labels("N firms x years")) noobs title("Automation cost shares and levels by firm size class") plain

/* Table 4: automation spike frequency by firm & sector */
est clear

bys beid: egen t_spikes = total(spike_firm)
label var t_spikes "Spike frequency by firm"
preserve
bys beid: keep if _n==1
eststo: estpost tab t_spikes
esttab est1 using output/des_automationcosts.csv, cells("b pct") append nonumber mtitles("Freq" "Percent") title("Automation spike frequency")

restore

est clear

/* Table C1: share of firms that ever has a spike by sector and size class
Keep 1 observation per firm, use average size class to categorize firms */
est clear

preserve
gen everspike=t_spikes>0
bys beid: keep if _n==1
eststo: estpost tabstat everspike, by(sbi2008_1dig) statistics(mean) nototal
eststo: estpost tabstat everspike, by(avg_gk) statistics(mean) nototal

esttab est1 est2 using output/des_automationcosts.csv, cells("mean(fmt(4))") append nonumber mtitles("Mean") ///
collabels("Share firms with a spike") stats(N, fmt(0) labels("N firms x years")) noobs title("Share of firms that ever has a spike by sector and size") plain
restore

est clear


/* Table 6: Share of automation costs occurring during spikes */
egen total = total(automation_real)
egen total_spike = total(automation_real) if spike_firm == 1
ereplace total_spike = max(total_spike)
gen share_spike = total_spike / total 

label var share_spike "Share of costs during spike"
label var spike_firm "Firm has a spike"

eststo: estpost summarize share_spike spike_firm
drop total total_spike share_spike
// 5.376% of observations concern spikes, and 11.171% of total automation costs occur in these spikes
* And now per firm, restricting to firms that have a spike
bys beid: egen everspike = max(spike_firm)
bys beid: egen total = total(automation_real) if everspike == 1
bys beid: egen total_spike = total(automation_real) if spike_firm == 1 & everspike == 1
bys beid: ereplace total_spike =  max(total_spike) if everspike == 1
local i=1
bys beid: egen n = total(`i') if everspike == 1
gen share_spike_firm = total_spike / total if everspike == 1
gen even_costs = total / n if everspike == 1
gen share_even_firm = even_costs / total if everspike==1

label var share_spike_firm "Share of total firm-level costs during spike"
label var share_even_firm "Share of total firm-level costs if evenly distributed"

eststo: estpost summarize share_spike_firm share_even_firm, det
* At firm level (so firms who spike), about 54% of their total automation costs occurs during a spike
* Min is 15%, max is 100%.

esttab est1 using output/des_automationcosts.csv, cells("mean") append nonumber mtitles("Share during spike") title("Share of total automation costs during spikes") stats(N, fmt(0) labels("N firms x years")) noobs  label
esttab est2 using output/des_automationcosts.csv, cells("mean p1 p5 p10 p25 p50 p75 p90 p95 p99") append nonumber mtitles("Share during spike") title("Share of automation costs in automating firms during spikes") stats(N, fmt(0) labels("N firms x years")) noobs label

drop share_even_firm share_spike_firm total_spike n everspike share_spike_firm 


*********** GRAPHS ***************

/* Figure A1: automation cost shares over time */
preserve
	gen n=1
	collapse (mean) mn_aemp=a_emp (p25) p25_aemp=a_emp ///
	(p50) p50_aemp=a_emp (p75) p75_aemp=a_emp ///
	(p90) p90_aemp=a_emp ///
	(mean) mn_costshare=automation_tocosts (p25) p25_costshare=automation_tocosts ///
	(p50) p50_costshare=automation_tocosts (p75) p75_costshare=automation_tocosts ///
	(p90) p90_costshare=automation_tocosts ///
	(sum) n, by(year)
	
	xmlsave output/des_costs_overtime_autom.xml, replace doctype(excel)
	
	tw line mn_costshare year || conn p25_costshare year, msymbol(O) || conn p50_costshare year, msymbol(D) ///
	|| conn p75_costshare year,msymbol(+) || conn p90_costshare year, msymbol(Oh) ///
	graphregion(color(white)) legend(label(1 "Mean")label(2 "25th perc")label(3 "Median")label(4 "75th perc") ///
	label(5 "90th perc")) ytitle("Automation cost shares (percent)") xtitle("Calendar year") ///
	xlabel(2000(4)2020)
	graph export output/des_costshares_over_time_autom.pdf, replace
	
	tw line mn_aemp year || conn p25_aemp year, msymbol(O) || conn p50_aemp year, msymbol(D) ///
	|| conn p75_aemp year,msymbol(+) || conn p90_aemp year, msymbol(Oh) ///
	graphregion(color(white)) legend(label(1 "Mean")label(2 "25th perc")label(3 "Median")label(4 "75th perc") ///
	label(5 "90th perc")) ytitle("Automation costs by worker (euros)") xtitle("Calendar year") ///
	xlabel(2000(4)2020)
	graph export output/des_costsbyworker_overtime_autom.pdf, replace
restore

/* Figure 1: Middlefinger graph in automation cost shares, relative to first spike */

* Define time relative to first spike
gen time = 0 if spike_firm_first==1
sort beid year
by beid: replace time = time[_n-1]+1 if missing(time)
gsort beid -year
by beid: replace time = time[_n-1]-1 if missing(time)

preserve
	gen n=1
	collapse (mean) a_emp automation_tocosts_avg automation_real (sum) n, by(time)
	xmlsave output/des_mfgraph_autom.xml, replace doctype(excel)
	
	egen total_n = total(n)

	keep if time>=-8 & time <=8

	replace automation_tocosts_avg = automation_tocosts_avg*100
	sum total_n
	tw bar automation_tocosts_avg time ///
	, graphregion(color(white)) xtitle("Year relative to the first spike") ytitle("Automation cost shares (percent, with costs averaged)") ///
	legend(off) xlabel(-8(1)8)  note("N = `r(mean)'") ylabel(0(0.5)1.5)
	graph export output/des_mfgraph_costshare_autom.pdf, replace 
	
	sum total_n
	tw bar a_emp time ///
	, graphregion(color(white)) xtitle("Year relative to the first spike") ytitle("Automation costs by worker (euros)") ///
	legend(off) xlabel(-8(1)8)  note("N = `r(mean)'") ylabel(0(500)3000)
	graph export output/des_mfgraph_costbyworker_autom.pdf, replace 

	sum total_n
	replace automation_real = automation_real/1000
	tw bar automation_real time ///
	, graphregion(color(white)) xtitle("Year relative to first spike") ytitle("Automation costs (1,000s euros)") ///
	legend(off) xlabel(-8(1)8) ylabel(0(100)500) note("N = `r(mean)'")
	graph export output/des_mfgraph_levels_autom.pdf, replace 
restore


/* Figure D2: Fully balanced sample, employment growth relative to 2000 */
use dta/intermediate/firmsample_autom.dta, clear 

* Define ever-treated status [Firms with at least one spike]
sort beid year
by beid: egen t_spike = total(spike_firm)
gen automating= t_spike>0

* Keep firms that we observe for the full period
local i=1
by beid: egen t_i = total(`i')
sum t_i
keep if t_i==`r(max)'

* 3 outcomes: employment, daily wage, revenue
gen ln_emp=ln(nr_workers_mar)
gen ln_rev=ln(revenue_real)
gen ln_wage=ln(mn_dwage)

gen n=1
collapse (mean) nr_workers_mar (sum) n, by(automating year)
// Scale the levels
foreach var in nr_workers_mar{
	gen `var'1=`var' if year==2000
	gsort automating -`var'1
	by automating: replace `var'1=`var'1[_n-1] if missing(`var'1)
	gen s`var'=(`var'/`var'1)*100
	drop `var'1
}
sort automating year

xmlsave output/des_automating_nonautomating_balanced.xml, replace doctype(excel)


