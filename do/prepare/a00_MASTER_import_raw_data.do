*------------------------------------------------------------------------
* Automation
* MASTER_import_raw_data.do
* Wiljan van den Berge
* Purpose: run all the do-files necessary to import raw CBS data
*-------------------------------------------------------------------------


*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16.1
set more off
clear all
macro drop _all
capture log close

cd H:/automation/
*--------------------------------------------------------------------------

* Be sure to place all do-files in a folder called "H:/automation/do", keeping the folder structure with "prepare" and "analysis" intact.
* Place all additional datasets from the "import" folder in "H:/automation/import".

** Create folders if they do not exist yet **
cap mkdir "H:/automation/dta"
cap mkdir "H:/automation/dta/intermediate"
cap mkdir "H:/automation/dta/analysis"
cap mkdir "H:/automation/dta/temp"
cap mkdir "H:/automation/output"
cap mkdir "H:/automation/log"

* This do-file calls all the programs to import the raw CBS data from the servers and create our datasets for analysis.
* It starts with importing files we need for cleaning other files (e.g. prices, x-walks).
* It then loads the firm-level data with automation costs and the worker-level data.
* After cleaning these datasets, they are merged and we create cohort-specific datasets. Then we perform matching and get our analysis files.
* All links point to the server and are confirmed to work at the last check (31 October 2022)



** 1. Load necessary adjacent files **

** - Do we still use this? WE CAN REMOVE THIS ONCE CBS EXPORTS THE DTA FILE!
* import_sector_prices.do
* 	Reads a hand-prepared Excel file with prices for output and added value
* 	At the 1-digit sector level. Downloaded from CBS Statline.
*	File included in "import" folder.
* 		Output: dta/intermediate/sector_prices.dta
do do/prepare/a01_import_sector_prices.do

* import_crosswalk_sbi9308_maxsector.do
* For 2006-2009 we observe both sbi1993 and sbi2008 for each sector.
* Create a file where we take the most commonly observed code per sector to 
* create a (potential) crosswalk
do do/prepare/a02_import_crosswalk_sbi9308_maxsector.do


* import_crosswalk_sbi9308.do
*	Reads a hand-prepared data file with many to many crosswalk for sector
*	codes SBI1993 and SBI2008. It generates 5-digit, 2-digit and 1-digit 
*	SBI2008 codes for each SBI1993 code.
*	File included in "import" folder
* 		Output: dta/intermediate/sbi9308_crosswalk.dta
do do/prepare/a03_import_crosswalk_sbi9308.do

* import_crosswalk_beid2009.do
*	Reads the CBS file 'basistabelovergang2009' to create a crosswalk for
*	firmids (beid) that change in 2009. [In 2009 CBS switched to different definition of firm IDs, which primarily affects medium to large firms, but not the 2000 largest firms in the Netherlands] 
*   Create a crosswalk both from 2008 -> 2009 and from 2009 -> 2008.
*		Output: dta/intermediate/crosswalk_beidplus_beidold.dta
*				dta/intermediate/crosswalk_beidold_beidplus.dta
do do/prepare/a04_import_crosswalk_beid2009.do


** 2. Import raw firm CBS data and clean **

* Production Statistics (PS) *

* import_ps9308.do
*	Reads the Production Statistics files for 1993-2008, keeps only the variables that are also
*	in the PS files from 2009 onwards and generates a measure for turnover. The PS files are separate by sector, for 6 sectors.
*		Output: dta/intermediate/ps_bouw_1993-2008.dta /* Construction */
*				dta/intermediate/ps_industrie_1993-2008.dta /* Manufacturing */
*				dta/intermediate/ps_detailhandel_1993-2008.dta /* Retail */
*				dta/intermediate/ps_groothandel_1993-2008.dta /* Wholesale */
*				dta/intermediate/ps_commercieel_1995-2008.dta /* Commercial services */
*				dta/intermediate/ps_transport_2000-2008.dta /* Transport */
do do/prepare/a05_import_ps9308.do


* import_ps0917.do
*	Reads the PS source files for 2009 - 2016 and makes them consistent with the
*	files from 1993-2008. It drops imputed observations. It then uses the 2009 crosswalk
*	to identify firms whose firmid changes in 2009 and those for whom we don't observe
*	all firms who are combined into a new firmid. These are dropped.
*		Output: dta/intermediate/ps_9316_merged_final.dta 
do do/prepare/a06_import_ps0916.do

* Investments * 

* merge_investeringen.do
*	Reads the Investments source files for 2000 - 2016. For files after 2012 it uses a
*	correspondence table provided by CBS (in investeringen_2012_correspondence_table.do)
*	which combines some variables so that they are longitudinally consistent.
*		Output: dta/intermediate/inv_0016_merged.dta
do do/prepare/a07_import_investeringen.do 

* Merge Investments and PS *

* merge_ps_inv.do
*	Merges inv_0016_merged.dta and ps_9316_merged_final.dta. Also adds sector codes using
*	the SBI1993-SBI2008 crosswalk and adds the sector-specific prices.
*		Output: dta/intermediate/inv_ps_9316_merged.dta
*				dta/intermediate/beid.dta // only the firm identifiers of all firms observed at some point
do do/prepare/a08_merge_ps_inv.do

* Firm events: import firm events like M&A
do do/prepare/a09_import_firm_events.do

* Robot imports
do do/prepare/a10_robot_imports.do


* Use worker-level admin data to calculate firm size, wagebill and firm age *

* Firm size
do do/prepare/a11_import_firm_size.do
* Firm wage bill
do do/prepare/a12_import_firm_wagebill.do
* Firm age 
do do/prepare/a13_import_firm_age.do




** 3. Import raw CBS worker data and clean **

* worker_job_polis.do
*	Takes the dta/intermediate/beid.dta with all firm identifiers observed at some point in PS or Investments and merges to raw worker data
*	Only workers between 18 & 65
*	Calls 	worker_education.do to get education level for workers if observed
*			worker_demographics.do to get demographics (age, gender, ethnicity) for workers
*	Output:	dta/intermediate/jobdata9919.dta

do do/prepare/a14_worker_job_polis.do

* Merge socio-economic classification (secm) and benefit values to workers in jobdata9919
do do/prepare/a15_worker_secm.do
do do/prepare/a16_worker_benefits.do

* Merge worker data files
do do/prepare/a17_merge_worker_data.do

** END OF IMPORTING AND CLEANING OF RAW DATA **
