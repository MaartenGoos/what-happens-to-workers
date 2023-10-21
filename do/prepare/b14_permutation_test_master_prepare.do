*------------------------------------------------------------------------
* Automation
* permutation_test_master.do
* 5/6/2019
* Wiljan van den Berge
* Purpose: prepare permutation samples with placebo treatments
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
*--------------------------------------------------------------------------


/*
// Permutation test

// Steps:
1. Start with the 36K firms
2. Draw random sample of treated until we have the same nr of treated firms; with restriction that we need to observe the firm in the window
3. Draw random sample of controls (with replacement) with restriction that treated/control don't overlap and that we observe the firm in the relevant window
4. Merge this firm sample to worker_baseline_sample_autom
5. Apply the same restrictions that we apply for the main sample (in worker_panel.do)
6. Matching 
*/

//include both the sampleyear and the sampleyear-1 in the data. We merge on the sampleyear-1, so keep if year==sampleyear-1, but also keep sampleyear so that we know the actual treatment year

/* RUN ONLY ONCE: data preperation */
do prepare/b14_01_permutation_test_prepare_data.do

/* LOOP TO CREATE 100 PERMUTATION SAMPLES */
/* Note: this can also be run from 1 to 100. To enhance running speed, we ran these in parallel (manually) in batches of 25 */

* Samples 1 - 25
global p_min=1
global p_max=25

do do/prepare/b14_02_permutation_test_create_samples.do

* Samples 26 - 50
global p_min=26
global p_max=75

do do/prepare/b14_02_permutation_test_create_samples.do

* Samples 51 - 75
global p_min=51
global p_max=75

do do/prepare/b14_02_permutation_test_create_samples.do

* Samples 76 - 100
global p_min=76
global p_max=100

do do/prepare/b14_02_permutation_test_create_samples.do
