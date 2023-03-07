clear all

global lpath="D:\replications\MS2021_RiskCaution"
global data="$lpath/data"

cd "$lpath/temp"

capture log close
log using risk_caution.log, smcl replace

* install packages
foreach i in estout coefplot binscatter {
	cap which `i'
	if _rc {
		ssc install `i'
	}
}

* D1 runs the baseline models and summary stats
* Creates Figure 1 and Tables 1, 2, and 4
do "$lpath/src/D1_summary_stats_and_baseline_project_choice.do"

* D2 analyzes heterogeneity from the Phase 1 experiment
* Creates Figure 2 and Table 3
do "$lpath/src/D2_project_het_estimate_choice_probabilities.do"

* D3 analyzes the portfolio choice question from Phase 1
* Creates Figure 3
do "$lpath/src/D3_portfolio_analysis.do"

* D4 analyzes loss and ambiguity aversion treatments from phase 2
* Creates Table 5
do "$lpath/src/D4_phase2_analysis.do"


* delete all dta temp files
local myfilelist: dir "$lpath/temp" files "*.dta"
foreach filename of local myfilelist {
  cap erase "$lpath/temp/`filename'"
}

log close
