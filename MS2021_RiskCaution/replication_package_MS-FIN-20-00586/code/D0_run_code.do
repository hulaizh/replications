* Run all of the code for "The Risk of Caution: Evidence from an Experiment"
* You need to navigate to the directory where you have "gmnl_margin.ado" for the
* code to complete.
*
* Set the path to for the local "work" in each of the files.
*
* Author: Jeff Shrader
* First version: 2021-05-30
* Time-stamp: "2021-10-20 21:57:40 jgs"

* Initialize
local work "~/Dropbox/research/projects/active/randd_experiment/output/text/ms accept/to submit/replication files"
cd "`work'/code/"
* D1 runs the baseline models and summary stats
* Creates Figure 1 and Tables 1, 2, and 4
do "`work'/code/D1_summary_stats_and_baseline_project_choice.do"
* D2 analyzes heterogeneity from the Phase 1 experiment
* Creates Figure 2 and Table 3
do "`work'/code/D2_project_het_estimate_choice_probabilities.do"
* D3 analyzes the portfolio choice question from Phase 1
* Creates Figure 3
do "`work'/code/D3_portfolio_analysis.do"
* D4 analyzes loss and ambiguity aversion treatments from phase 2
* Creates Table 5
do "`work'/code/D4_phase2_analysis.do"

* EOF
