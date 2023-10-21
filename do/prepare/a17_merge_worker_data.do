* merge worker data
cd H:/automation/
* Load job data
use dta/intermediate/jobdata9916_polis.dta, clear

* Merge worker benefits and SECM status
merge 1:1 rinpersoons rinpersoon year using dta/intermediate/rin_secm9916.dta, keep(match master) nogen keepusing(secm)
merge 1:1 rinpersoons rinpersoon year using dta/intermediate/worker_benefits.dta, keep(match master) nogen

* Set wages and days to zero if missing or <0. And round them to nearest integer to save space.
foreach var in earnings wage days totaldays unemploymentbenefits welfare sickness totalbenefits{
	replace `var'=0 if missing(`var') | `var'<0
	replace `var'=round(`var')
}
replace hours = . if year<2006
replace totalhours = . if year<2006

gen byte selfemp = (secm==12 | secm==13 | secm==14)

compress
save dta/intermediate/workerdata9916.dta, replace

* Delete temporary files
rm dta/intermediate/rin_secm9916.dta
rm dta/intermediate/worker_benefits.dta
