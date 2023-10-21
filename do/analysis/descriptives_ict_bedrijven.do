*------------------------------------------------------------------------
* Automation
* descriptives_ict_bedrijven.do
* 2021/04/13, updated 2021/08/13
* Anna Salomons
* Purpose: Descriptives for ICT firm survey data merged with firm-level automation data
*-------------------------------------------------------------------------

*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
capture log close
sysdir set PLUS M:\Stata\Ado\Plus 

cd H:/automation/
log using log/descriptives_ict_bedrijven, text replace
*--------------------------------------------------------------------------

***************************************************************************
* 1. Some further cleaning
***************************************************************************
use dta/intermediate/firm_ict_survey, clear

*Drop firms without ICT data
drop if _merge==1
drop _merge

* Drop flags (have already removed imputed values for all variables)
drop f*

* Generate some variables
gen lnnr_workers_mar = ln(nr_workers_mar)
rename automation_tocosts autcostshare

* Combine some variables which have different names but capture the same thing; and use most recent variable as base
	replace crm_analyse = crm_analyse_klantgeg if crm_analyse==. 
	replace crm_analyse = crmanalyse if crm_analyse==.
	drop crm_analyse_klantgeg crmanalyse
	
	replace crm_opslag = crm_opslag_klantgeg if crm_opslag==.
	replace crm_opslag = crmopslag if crm_opslag==.
	replace crm_opslag = crm_opslag_klantgeg if crm_opslag==.
	drop crm_opslag_klantgeg crmopslag crm_opslag_klantgeg
	 
	replace crm_softw = crmsoftw if crm_softw==.
	drop crmsoftw 
	
	replace erp_softw = erp if erp_softw==.
	replace erp_softw = erpsoftw if erp_softw==.
	drop erp erpsoftw
	
	replace el_inkp = ink_alle if el_inkp==. 
	drop ink_alle
	
	tab keten_via_edi ketint_meth_ade
	replace keten_via_edi = ketint_meth_ade if keten_via_edi==.
	drop ketint_meth_ade
	
	recode downloadsnelheid (0=.)
	gen bigdata = 1 if bigdata_analysezelf==1 | bigdata_analyseander==1
	replace bigdata = 0 if bigdata_analysezelf==0 & bigdata_analyseander==0
	
	
***************************************************************************
* 2. Descriptives 
***************************************************************************
	
	sum autcostshare [w=oph]
	gen stdautcostshare = (autcostshare  - r(mean)) / r(sd)
	global controls lnnr_workers_mar
	
	* Regressions of stdized automation cost shares on tech measures
	areg stdautcostshare proces_innovator product_innovator organisatie_innovator $controls [w=oph], absorb(sbi08) robust
		est store est1
	
	areg stdautcostshare  autdex $controls  [w=oph], absorb(sbi08) robust
		est store est2 
	areg stdautcostshare  crm_opslag crm_analyse $controls  [w=oph], absorb(sbi08) robust
		est store est3
	areg stdautcostshare  erp_softw $controls  [w=oph], absorb(sbi08) robust
		est store est4 
	areg stdautcostshare  keten_via_edi keten $controls  [w=oph], absorb(sbi08) robust
		est store est5 
	areg stdautcostshare  bigdata $controls  [w=oph], absorb(sbi08) robust
		est store est6
	areg stdautcostshare  cloud_crm cloud_boekh $controls  [w=oph], absorb(sbi08) robust
		est store est7 	
	areg stdautcostshare  verk_edi ink_edi $controls  [w=oph], absorb(sbi08) robust
		est store est8
	areg stdautcostshare  koppel_ictsys koppel_inkoop $controls  [w=oph], absorb(sbi08) robust
		est store est9
	areg stdautcostshare  rfid $controls  [w=oph], absorb(sbi08) robust
		est store est10 	
	areg stdautcostshare  draadl_netw $controls  [w=oph], absorb(sbi08) robust
		est store est11
	areg stdautcostshare  ebanking $controls  [w=oph], absorb(sbi08) robust
		est store est12
	areg stdautcostshare  opleiding $controls  [w=oph], absorb(sbi08) robust
		est store est13		

	esttab est1 , se r2	order(lnnr_workers_mar)		
	esttab est2 est3 est4 est5 est6 est7, se r2	order(lnnr_workers_mar)			
	esttab est8 est9 est10 est11 est12 est13, se r2	order(lnnr_workers_mar)			
	
	cap erase output/des_autom_ict_bedrijven.csv
	esttab est1 est2 est3 est4 est5 est6 est7 est8 est9 est10 ///
		est11 est12 est13 ///
		using output/reg_autom_ict_bedrijven.csv, append  nogaps compress nolines ///
		order(lnnr_workers_mar) ///
		stats(N r2) se ///
		title("			" "Dep var = stdautcostshare") ///
		label ///
		addnote("Controls: one-digit industry FE and log nr of workers")
	
	* Sector-specific descriptives of tech measures
preserve 
		* Storing observation numbers
	gcollapse (count) autdex  ///
					crm_opslag ///
					erp_softw ///
					keten_via_edi ///
					cloud_crm cloud_boekh ///
					bigdata_eigen bigdata_geo bigdata_social bigdata_anderebron, ///
					by(sbi08)
	renvars autdex - bigdata_anderebron, prefix(n_)
	order sbi08
	save  dta/temp/temp_ict, replace
	restore

preserve	
		* Storing sample-weighted sectoral means
	gcollapse (mean) autdex  ///
					crm_opslag ///
					erp_softw ///
					keten_via_edi ///
					cloud_crm cloud_boekh ///
					bigdata_eigen bigdata_geo bigdata_social bigdata_anderebron ///
					[w=oph] , by(sbi08)
	order sbi08
	merge 1:1 sbi08 using dta/temp/temp_ict
	assert _merge==3
	drop _merge
	label data "Means from ICT Bedrijven by sector, including nr of individual firm obs per cell"
	save output/des_ict_bedrijven, replace
restore
	

	* Erase temporary data
	cap erase dta/temp/temp_ict.dta
cap log close
