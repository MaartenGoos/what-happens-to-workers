*------------------------------------------------------------------------
* Automation
* prepare_worker_data.do
* 2/5/2018
* Wiljan van den Berge
* Purpose: merge demographics for each worker in our sample
*-------------------------------------------------------------------------


*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16
set more off
clear all
* No separate log, this is part of prepare_worker_data.do

cd H:/automation/
*--------------------------------------------------------------------------


use dta\intermediate\rinpersoon.dta, clear

merge 1:1 rinpersoons rinpersoon using "G:\Bevolking\GBAPERSOONTAB\2019\geconverteerde data\GBAPERSOON2019TABV1.dta" , keep(match master) ///
keepusing(gbageslacht gbageboorteland gbageneratie gbageboortejaar gbageboortemaand gbaherkomstgroepering) nogen

destring gbageboortejaar gbageboortemaand gbageslacht gbageneratie gbageboorteland gbaherkomstgroepering, replace force

gen dateofbirth=mdy(gbageboortemaand,1,gbageboortejaar)
format dateofbirth %td
drop gbageboortemaand gbageboortejaar

gen female=gbageslacht==2
drop gbageslacht
label define gen 0 "Native" 1 "First generation foreign" 2 "Second generation foreign"
label values gbageneratie gen
rename gbageneratie generation
rename gbageboorteland countryofbirth

compress
save dta\intermediate\rinpersoon_gba.dta, replace
