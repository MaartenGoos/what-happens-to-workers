/* Import sector prices */
cd H:/automation/

import excel import\Prices_output_addedvalue_sector.xlsx, sheet("data_edit") firstrow clear

*Prices are relative to 2010.
sort year sbi2008_letter
rename output p_output
rename addedvalue p_addedvalue
label var p_output "Output price (2010=100)"
label var p_addedvalue "Added value price (2010=100)"

save dta/intermediate/sector_prices.dta, replace
