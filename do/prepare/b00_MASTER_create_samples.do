
cd H:/automation/

** START OF CREATION OF SAMPLES **

** This do-file calls all programs to create our samples
* Each sample follows the following steps
/*
1. Each sample starts with the definition of a spike. The first do-files create spikes for the different technologies we consider: automation, computers, the overlapping sample of automation and computers, and the placebo including investments in other materials.
2. Create both a firm- and a worker-level dataset including all the firms that have a spike at some point. This is also necessary to shrink the data to keep it manageable within CBS memory restrictions.
3. create a firm-level panel. Here we create stacked panels of firms that have a spike in year C ("treated") and firms that have a spike in year C+K (baseline k=5) or later ("control")
4. Create a worker-level panel based on the firm-level panel. We basically merge the workers to the firms selected in step 3.
5. We perform matching to ensure our controls and treated are similar in observables.
*/
* A sample is defined by a set of variables:

* The `sample' name: this refers to the spike we consider for this sample (e.g. autom for automation or comp for computer) and possible adjustments to the baseline sample (which is just autom), such as scaling the automation costs by employment instead of total costs (emp_autom), or using a stricter (spike4) or less strict (spike2) definition of a spike.


global samplelist "autom overl_autom1 overl_autom2 overl_comp1 overl_comp2 empf_autom emp_autom spike2_autom spike4_autom empt0_autom overl_other1 overl_other2 never_autom" // 

// Define spikes on different samples: automation, overlapping automation/computer sample and overlapping automation/other material investments (placebo) sample
do do/prepare/b01_define_spikes_automation.do // This defines automation spikes
do do/prepare/b02_define_spikes_overlapping.do // This defines automation & computer spikes on the overlapping sample where we observe both
do do/prepare/b03_define_spikes_placebo_overlapping.do // This defines automation & other material investments (placebo) spikes on the overlapping sample where we observe both

// Creates firm and worker samples  

* NOTE: create_samples runs separately for each overl sample, but the final samples are the same, they include both computer and automation spikes

do do/prepare/b04_create_samples.do

global samplelist "overl_autom1 overl_autom2 overl_comp1 overl_comp2 empf_autom emp_autom spike2_autom spike4_autom empt0_autom overl_other1 overl_other2 never_autom" // 

// Creates dataset with firm panels, also includes overlapping panels
do do/prepare/b05_firm_panel.do 
// Defines different sample selections and restricts sample to the t=[-3,k-1] observation window
do do/prepare/b06_firm_events_drop.do 
// Creates worker-level panels
do do/prepare/b07_worker_panel.do

// Prepare data for "new manager" robustness check
do do/prepare/b08_managerswitch.do 
 
* Coarsened exact matching
do do/prepare/b09_matching.do 


* Data prep for additional analyses and robustness checks *

* Heterogeneity analyses *
do do/prepare/b10_worker_quantiles.do // Calculate position of workers in wage distribution
do do/prepare/b11_prepare_heterogeneity.do // Create other heterogeneity dimensions (e.g. age, gender, sector, etc.)

* Create dataset with dummy indicator for importers of robots or other automation technology *
do do/prepare/b12_create_beid_importer_indicator.do

* ICT Bedrijven data to check correlates with automation costs
do do/prepare/b13_clean-ict-bedrijven.do


* Permutation test * [Note: this takes about a week to run!]
do do/prepare/b14_permutation_test_master_prepare.do


