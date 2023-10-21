cd H:/automation
* All tables & figures are produced in the analysis do-files below

*----------------*
** Descriptives **
*----------------*

do do/analysis/descriptives_automation.do 
* This creates the output for Appendix Figures 1, A.1, D.1 and Appendix Tables 1, 2, C.1, C.2

do do/analysis/descriptives_ict_bedrijven.do 
* This creates the output for Appendix Tables A.1, A.2 and A.3

do do/analysis/descriptives_imports.do 
* This creates output for Appendix Tables A.4, A.5, D.4, and D.5, and Appendix Figure A.2

do do/analysis/des_events_by_year.do // Note that this doesn't produce a table, but only the numbers
* This creates the output for Appendix Table E.1

do do/analysis/predict_timing.do
* This creates the output for Appendix Tables D.1 and E.3

do do/analysis/descriptives_workers_automation.do 
* This creates the output for Appendix Table E.2

do do/analysis/descriptives_computers.do 
* This creates the output for Appendix Tables F.1, F.2, F.3, F.4 and Appendix Figure F.1

do do/analysis/descriptives_placebo.do 
* This creates the output for Appendix Tables E.6, E.7 and Appendix Figure E.3

do do/analysis/descriptives_firms_around_events.do
* This creates the output for Figure C.1

*-------------------------------------*
** Firm-level analyses of automation **
*-------------------------------------*

* Main firm analysis
do do/analysis/firm_stacked_did.do 
* This creates the output for Figure 2 (firm size <500 >500 split), and part of Appendix Figure D.2 (baseline only)

* Firm robustness using firms that do not have a spike as controls
do do/analysis/firm_stacked_did_nevertreated.do 
* This creates the remaining output for Appendix Figure D.2 (using never-treated as control group)

* Firm analysis comparing automation and non-automating firms
do do/analysis/firm_automation_vs_nonautomating.do 
* This creates the output for Table 3

* Firm analysis comparing importing and non-importing firms
do do/analysis/firm_stacked_did_imports.do 
* This creates the output for Appendix Tables D.2, D.3, and Appendix Figure D.3


*-------------------------*
** Worker-level analyses **
*-------------------------*

* Main worker analyses
do do/analysis/worker_analysis.do 
* If run for all samples and sets of sample restrictions, this creates the output for Figures 3, 4, 5 from the main paper and Figures E.1, E.2, E.4, E.5 and E.6 from the Appendix.

* Heterogeneity analyses
do do/analysis/worker_analysis_heterogeneity.do 
* This creates the output for Table 4 and Appendix Table E.4

* Worker analysis for importers vs non-importers
do do/analysis/worker_analysis_imports.do
* This creates the output for Appendix Table E.5

* Permutation test
do do/analysis/permutation_test_analysis.do  
* This creates the output for Appendix Figure E.7


*-----------------*
** Making graphs **
*-----------------*

do do/analysis/make_graphs.do // placeholder, Anna adds code


** Create graphs from output ** // probably obsolete, Anna will check
do do/analysis/graphs_firm_stacked_did.do // These don't use the correct input files! Best to have the graphs and tables using the exported data?







