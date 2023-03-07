* Create Figure 3 and analyze portfolio choices
* Initialize
** What did the subjects say about their own decisionmaking?
* We asked an open-ended question after the portfolio choice questions in
* the initial experiment. 
use "$data/portfolio_debrief.dta", clear
* br budgetmethod id
* Based on my manual classification, let's look at the people who "got it" in the
* sense that they reported answers indicating they knew to choose high variance projects.
tabstat discount_rate coef_rra finance workrad_ind decisionscience collegemath exhaust yearborn gender elapsedtime, stat(mean sd) by(got_it)
* Heterogeneity we look at in D2
logit got_it discount_rate coef_rra finance workrad_ind decisionscience collegemath exhaust if base_sample, r
* People who "got it" were also more likely to have higher variance preference. Same (though weaker)
* for people who reported looking at individual scores.
reg q13_b_mean got_it if base_sample==1, r
reg q13_b_var got_it if base_sample==1, r
reg q13_b_var var_loving if base_sample==1, r
reg  var_loving if base_sample==1, r
gen revealed_var_loving = (q13_b_var>0)
reg revealed_var_loving var_loving if base_sample==1, r
reg q13_b_var got_it individual_scores if base_sample==1, r
reg q13_b_mean individual_scores if base_sample==1, r
reg q13_b_var individual_scores if base_sample==1, r
* Simple correlation results for appendix
label var got_it "Var. maximizing"
label var q13_b_mean "Project mean pref."
label var q13_b_var "Project var. pref."
label var risk_neutral "Risk neutral"
label var risk_loving "Risk loving"
label var workrad_ind "R&D work experience"
eststo r1: reg got_it q13_b_mean q13_b_var if base_sample==1, r
eststo r2: reg got_it risk_neutral risk_loving workrad_ind if base_sample==1, r
esttab r1 r2 using "debrief_reg.csv", b(2) se(2) pr2(3) star(* 0.10 ** 0.05 *** 0.01) nocons nogaps nonotes replace


* In portfolio choice questions, we can explore how people reacted to costs and we can explicitly vary people's budgets to
* see if those influenced the decision. We see that neither one had much of an effect.
use "$data/portfolio_choice_arm0.dta", clear
* Numbers for discussion in text about probability subjects chose higher
* variance portfolio when presented with two portfolios with the highest mean.
*tab high_var if rank_mean==1 & budget==12 & count_mean==2
* Simple evidence that they always chose less risky projects regardless
* of the budget
*question_group	budget	choice_set_id	value	variance	rank_mean
*1	12	94	53.84	15.14	1
*1	12	79	53.84	8.440001	2
*bysort budget: tab high_var if (rank_mean ==2|rank_mean==1) & choice == 1 & count_mean==2
tab choice attr_variance if choice == 1 & attr_mean > 53.84 & attr_mean < 53.85 & ((attr_variance > 8.44 & attr_variance < 8.45) | (attr_variance > 15.13 & attr_variance < 15.15)), cell

* Figure 3: Effect of Budget on Preference for Portfolio Variance
binscatter choice avg_variance if base_sample == 1, ///
       by(budget2) control(c.avg_mean##c.avg_cost c.avg_variance#c.avg_cost) absorb(question_group) ///
       linetype(lfit) ytitle("Probability subject chose portfolio") xtitle("Average variance of projects in portfolio") ///
       legend(label(1 "Low Budget") label(2 "High Budget")) ///
       xsize(7) ysize(5)  lcolors(black gray) mcolors(black black) msymbol(O Oh) 
graph export "Figure3_portfolio_choice_variance_budget_binscatter.png", replace as(png) width(2100) height(1500)
graph export "Figure3_portfolio_choice_variance_budget_binscatter.pdf", replace as(pdf)
* F-test reported in paper
// reghdfe choice c.avg_variance_n##c.budget2 c.avg_mean_n##c.budget2 avg_cost_n if base_sample==1 & multiple_switching_ever == 0, vce(cluster id) absorb(id b_q)
// test _b[avg_variance_n#budget2] == 0
// * Linear regression
// eststo l5c: reghdfe choice c.avg_variance_n c.avg_mean_n budget_n avg_cost_n if base_sample==1 & multiple_switching_ever == 0, vce(cluster id) absorb(id b_q)
// eststo l5b: reghdfe choice c.avg_variance_n##c.budget_n c.avg_mean_n##c.budget_n avg_cost_n if base_sample==1 & multiple_switching_ever == 0, vce(cluster id) absorb(id b_q)
// * And the conditional logit tables
// eststo l5d: clogit choice c.avg_variance_n c.avg_mean_n c.budget_n avg_cost_n if base_sample==1 & multiple_switching_ever == 0, vce(cluster id) group(id)
// eststo l5a: clogit choice c.avg_variance_n##c.budget_n c.avg_mean_n##c.budget_n avg_cost_n if base_sample==1 & multiple_switching_ever == 0, vce(cluster id) group(id)
// esttab l5d l5c l5a l5b using "`work'/output/tables/portfolio_choice", ///
//        star(* 0.10 ** 0.05 *** 0.01) ///
//        se(a2) b(a2) noconstant nogaps label rtf replace ///
//        interaction(" x ") nobaselevels noomitted ///
//        scalar(N_clust) ///
//        eqlabels(none) ///
//        mlabels("Portfolio choice")
//
// log close
* EOF
