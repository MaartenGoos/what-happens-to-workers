*------------------------------------------------------------------------
* Automation
* crosswalk_2009beid.do
* 1/5/2018
* Wiljan van den Berge
* Purpose: create crosswalk for firm ID's in 2009
*-------------------------------------------------------------------------


*-------------------------------------------------------------------------
* Program Setup
*-------------------------------------------------------------------------
version 16
set more off
clear all
capture log close

cd H:/automation/
log using log/crosswalk_2009beid, text replace
*--------------------------------------------------------------------------
import spss "K:\Utilities\Code_Listings\Productiestatistieken\PS 2009basistabelovergang.sav", clear

// Drop duplicates and missings
drop if missing(beidplus)
drop if missing(beid)
duplicates drop

// Data structure is such that we have many observations where beid==beidplus
// Because there are observations for each separate unit of the firm, where the BEID doesn't differ
// We are only interested in BEID level changes, so only keep those two variables
keep beid beidplus
duplicates drop // Duplicates are useless

// Now drop all beid's where beidplus is the same AND there are no other observations with the same beidplus
gen same = beid==beidplus
duplicates tag beidplus, gen(dup)
sort beidplus beid
drop if same==1 & dup==0
drop same dup
keep beid
duplicates drop
save dta/intermediate/crosswalk_beidold_2009.dta, replace


import spss "K:\Utilities\Code_Listings\Productiestatistieken\PS 2009basistabelovergang.sav", clear

/* beidplus = BEID in PS2009 and beyond; and BEID in 2010 for other files.
beid = BEID in PS2008 and earlier and 2009 for other files
*/

keep beid beidplus

// Drop duplicates and missings
drop if missing(beidplus)
drop if missing(beid)
duplicates drop


// Per beidplus, check to which BEID's it corresponds
sort beidplus beid
by beidplus: gen n = _n
sum n, det // Some have a lot of BEID's, difficult for reshape. 99th percentile is 4, max=176
duplicates tag beidplus, gen(dup)
sum dup, det
drop if dup>6 // 99th percentile. Drop those with very many duplicates, difficult for reshape
drop dup

// Reshape to a file with BEIDPLUS (PS2009) -> BEID (PS2008)
rename beid beid_old
reshape wide beid_old, i(beidplus) j(n)

// If BEID == BEIDPLUS and there are no others, they are fine and not necesary here
drop if beid_old1 == beidplus & beid_old2==""
gen year=2009
rename beidplus beid
compress
save dta/intermediate/crosswalk_beidplus_beidold.dta, replace

