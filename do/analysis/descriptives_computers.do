*------------------------------------------------------------------------
* Automation
* descriptives_computers.do
* 26/11/2021
* Wiljan van den Berge
* Purpose: create descriptives of computer spikes and computer investments
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
log using log/descriptives_computers.do, text replace
*--------------------------------------------------------------------------

* Load data
use dta\intermediate\firmsample_overl.dta, clear

/* Table F.1: Descriptives on automation cost share and computer investment share */
est clear
cap drop a_emp

// Calculate time-varying automation to costs instead of using the averaged scaling for descriptives
rename automation_tocosts automation_tocosts_avg
gen automation_tocosts = automation_real / (totalcosts_real - automation_real)
replace automation_tocosts=0 if automation_real==0
replace automation_tocosts = automation_tocosts * 100
replace automation_real = automation_real * 1000
gen a_emp=automation_real / nr_workers_mar

gen computer_toinv = computers_real / totalinvestments_real
replace computer_toinv=0 if computers_real==0
replace computer_toinv = computer_toinv * 100
replace computers_real = computers_real * 1000
gen c_emp=computers_real / nr_workers_mar


eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, statistics(p5 p10 p25 p50 p75 p90 p95 mean)
count if automation_real<=0
gen zero_a = `r(N)'
sum zero_a
estadd r(max): est1
count if computers_real<=0
gen zero_c = `r(N)'
sum zero_c
estadd r(min): est1

eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp if automation_real>0, statistics(p5 p10 p25 p50 p75 p90 p95 mean)
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp if computers_real>0, statistics(p5 p10 p25 p50 p75 p90 p95 mean)

esttab est1 est2 est3 using output/des_overlapping.csv, cells("automation_real(fmt(0)) a_emp(fmt(0)) automation_tocosts(fmt(2)) computers_real(fmt(0)) c_emp(fmt(0)) computer_toinv(fmt(2))") ///
replace nonumber mtitles("All observations" "Observations with >0 automation costs" "Observations with >0 computer inv") ///
collabels("Autom level" "Autom by worker" "Autom share" "Comp level" "Comp by worker" "Comp share") stats(N max, fmt(0 0) labels("N firms x years" "N with 0 costs")) title("Automation and computer cost shares and level distribution") plain

est clear

/* Table F.3: mean + sd of automation cost shares and levels by sector */

label define s_edit 1 "Manufacturing" 2 "Construction" 3 "Wholesale and retail trade" 4 "Transportation and storage" ///
5 "Accommondation and food serv" 6 "Information and communication" 7 "Prof scientific techn act" 8 "Admin and support act", replace
label values sbi2008_1dig s_edit

eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(sbi2008_1dig) statistics(mean) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(sbi2008_1dig) statistics(sd) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(sbi2008_1dig) statistics(n) nototal


cap drop i
bys beid: gen i = 1 if _n==1
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp if i==1, by(sbi2008_1dig) statistics(n) nototal

esttab est1 est2 est3 est4 using output/des_overlapping.csv, cells("automation_real(fmt(0)) a_emp(fmt(0)) automation_tocosts(fmt(2)) computers_real(fmt(0)) c_emp(fmt(0)) computer_toinv(fmt(2))") ///
append nonumber mtitles("Mean" "SD" "N firms x years" "N firms") collabels("Autom level" "Autom by worker" "Autom share" "Comp level" "Comp by worker" "Comp share") ///
stats(N, fmt(0) labels("N firms x years")) noobs title("Automation and computer cost shares and levels by 1-digit sector") plain

/* Table F.4: mean + sd of automation cost shares by size class */
est clear
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(gk_manual) statistics(mean) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(gk_manual) statistics(sd) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(gk_manual) statistics(n) nototal
cap drop i
bys beid: gen i = 1 if _n==1
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp if i==1, by(gk_manual) statistics(n) nototal

esttab est1 est2 est3 est4 using output/des_overlapping.csv, cells("automation_real(fmt(0)) a_emp(fmt(0)) automation_tocosts(fmt(2)) computers_real(fmt(0)) c_emp(fmt(0)) computer_toinv(fmt(2))") ///
 append nonumber mtitles("Mean" "SD" "N firms x years" "N firms") collabels("Autom level" "Autom by worker" "Autom share" "Comp level" "Comp by worker" "Comp share") ///
 stats(N, fmt(0) labels("N firms x years")) noobs title("Automation and computer cost shares and levels by firm size class") plain

/* Table F.2: automation spike frequency by firm */
est clear

label define sa 0 "No autom spike" 1 "Autom spike"
label define sc 0 "No comp spike" 1 "Comp spike"
label values spike_autom spike_autom_first sa
label values spike_comp spike_comp_first sc


bys beid: egen t_spikes_a = total(spike_autom)
bys beid: egen t_spikes_c = total(spike_comp)
label var t_spikes_a "Automation spike frequency by firm"
label var t_spikes_c "Computer spike frequency by firm"

eststo: estpost tab spike_autom spike_comp
eststo: estpost tab spike_autom_first spike_comp_first

esttab est1 est2 using output/des_overlapping.csv, cells("colpct(fmt(2))") label eqlabels(, lhs("Automation spike")) append nonumber mtitles("All spikes" "First spikes") title("Co-occurring automation and computer spikes (all and first)")

preserve
bys beid: keep if _n==1
eststo: estpost tab t_spikes_a
eststo: estpost tab t_spikes_c

gen everspike_a=t_spikes_a>0
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(everspike_a) statistics(mean) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(everspike_a) statistics(sd) nototal

gen everspike_c=t_spikes_c>0
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(everspike_c) statistics(mean) nototal
eststo: estpost tabstat automation_tocosts automation_real a_emp computer_toinv computers_real c_emp, by(everspike_c) statistics(sd) nototal

esttab est3 est4 using output/des_overlapping.csv, cells("b pct") append nonumber mtitles("Automation spikes" "Computer spikes") title("Automation spike frequency")

esttab est5 est6 est7 est8 using output/des_overlapping.csv, cells("automation_real(fmt(0)) a_emp(fmt(0)) automation_tocosts(fmt(2)) computers_real(fmt(0)) c_emp(fmt(0)) computer_toinv(fmt(2))") append nonumber ///
mtitles("Ever has autom spike (Mean)" "Ever has autom spike (SD)" "Ever has comp spike (Mean)" "Ever has comp spike (SD)") ///
collabels("Autom level" "Autom by worker" "Autom share" "Comp level" "Comp by worker" "Comp share") stats(N, fmt(0) labels("N firms x years")) noobs title("Cost shares and levels by whether firm spikes at some point") plain

restore

/* Figure F.1: Middlefinger graph for computerization events */
* define year relative to first spike
gen year_first_spike = year if spike_comp_first==1
bys beid: ereplace year_first_spike = max(year_first_spike)
gen time_c = year - year_first_spike
preserve
	gen n=1
	collapse (mean) mn_cemp=c_emp (sum) n, by(time_c)
	xmlsave output/des_mfgraph_overl_comp.xml, replace doctype(excel)
restore
