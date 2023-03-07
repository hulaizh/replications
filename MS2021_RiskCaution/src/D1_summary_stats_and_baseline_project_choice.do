* Primary result estimates 
* Set number of reps for GMNL. For debugging, set very low (<10) for speed. For
* real estimation, set in the hundreds.
global n_reps = 500

** Main Results 1: Choice scenario set 1 in baseline and replication
use "$data/project_choice_all.dta", clear
eststo clear
capture drop pred*
* Prep interactions for estimation
gen rep = arm if arm < 2
foreach i of varlist rep {
   foreach j of varlist attr_mean_n attr_variance_n {
      gen `j'_`i' = `j'*`i'
   }
}
* Estimates for choices in first set of choice scenarios for GMNL, clogit and mlogit (body and appendix tables)
eststo set1arm0: gmnl choice if question==1 & base_sample==1 & arm==0, id(id) group(group) rand(attr_mean_n attr_variance_n) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
gmnlbeta attr_mean_n attr_variance_n if question==1 & base_sample==1 & arm==0, saving("gmnl_betas_set1_arm0.dta") replace nrep($n_reps)
gmnl_margin if question==1 & base_sample==1 & arm==0, generate(pred_set1arm0)
gen set1arm0_b_mean = r(b_mean)
gen set1arm0_se_mean = r(se_mean)
gen set1arm0_b_variance = r(b_variance)
gen set1arm0_se_variance = r(se_variance)
eststo set1arm1: gmnl choice if question==1 & base_sample==1 & arm==1, id(id) group(group) rand(attr_mean_n attr_variance_n) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
// gmnl_margin if question==1 & base_sample==1 & arm==1, generate(pred_set1arm1)
eststo set1arm01: gmnl choice if question==1 & base_sample==1 & (arm==0 | arm==1), id(id) group(group) rand(attr_mean_n attr_variance_n attr_mean_n_rep attr_variance_n_rep) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
gmnl_margin if question==1 & base_sample==1 & (arm==0 | arm==1), generate(pred_set1arm01) het(rep)
eststo set1arm0_all: gmnl choice if question==1 & arm==0, id(id) group(group) rand(attr_mean_n attr_variance_n) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
gmnl_margin if question==1 & arm==0, generate(pred_set1arm0_all)
* clogit version
eststo set1arm0_cl: clogit choice attr_mean_n attr_variance_n if question==1 & base_sample==1 & arm==0, group(group) vce(cluster id)
margins , dydx(attr_mean_n attr_variance_n) at(attr_mean_n = 0 attr_variance_n = 0)
eststo set1arm1_cl: clogit choice attr_mean_n attr_variance_n if question==1 & base_sample==1 & arm==1, group(group) vce(cluster id)
margins , dydx(attr_mean_n attr_variance_n) at(attr_mean_n = 0 attr_variance_n = 0)
eststo set1arm01_cl: clogit choice attr_mean_n attr_variance_n attr_mean_n_rep attr_variance_n_rep if question==1 & base_sample==1 & (arm==0 | arm==1), group(group) vce(cluster id)
margins , dydx(attr_mean_n attr_variance_n) at(attr_mean_n = 0 attr_variance_n = 0)
eststo set1arm0_cl_all: clogit choice attr_mean_n attr_variance_n if question==1 & arm==0, group(group) vce(cluster id)
margins , dydx(attr_mean_n attr_variance_n) at(attr_mean_n = 0 attr_variance_n = 0)
* mlogit version
eststo set1arm0_ml: mlogit rank attr_mean_n attr_variance_n if question==1 & base_sample==1 & arm==0, vce(cluster id) baseoutcome(4)
eststo set1arm1_ml: mlogit rank attr_mean_n attr_variance_n if question==1 & base_sample==1 & arm==1, vce(cluster id) baseoutcome(4)
eststo set1arm01_ml: mlogit rank attr_mean_n attr_variance_n attr_mean_n_rep attr_variance_n_rep if question==1 & base_sample==1 & (arm==0 | arm==1), vce(cluster id) baseoutcome(4)
* Output
* Table 3
* Baseline results table: Phase 1, Choice Scenario set 1
esttab set1arm0 set1arm0_cl using "Table2_baseline_gmnl_cl.csv", b(2) se(2) pr2(3) star(* 0.10 ** 0.05 *** 0.01) nocons nogaps nonotes replace

* Compare Phase 1 and Phase 2 replication (appendix)
// esttab set1arm0 set1arm0_cl set1arm1 set1arm1_cl using "baseline_arm1_gmnl_cl", ///
//        star(* 0.10 ** 0.05 *** 0.01) ///
//        se(a2) b(a2) nogaps label pr2 rtf replace ///
//        interaction(" x ") nobaselevels noomitted scalar(N_clust) ///
//        eqlabels(none) ///
//        mlabels("Project choice\line Phase 1\line GMNL" "Project choice\line Phase 1\line Cond. logit" "Project choice\line Phase 2 (replication)\line GMNL" "Project choice\line Phase 2 (replication)\line Cond. logit")
// * Phase 1 regular multinomial logit results (appendix)
// esttab set1arm0_ml set1arm1_ml using "baseline_arm1_ml", ///
//        star(* 0.10 ** 0.05 *** 0.01) ///
//        se(a2) b(a2) nogaps label pr2 rtf replace ///
//        interaction(" x ") nobaselevels noomitted scalar(N_clust) ///
//        eqlabels(none) ///
//        mlabels("Project choice\line Phase 1\line Mult. logit" "Project choice\line Phase 2 (replication)\line Mult. logit")
// * Phase 1 results using all subjects (appendix)
// esttab set1arm0_all set1arm0_cl_all using "baseline_gmnl_cl_all_subjects", ///
//        star(* 0.10 ** 0.05 *** 0.01) ///
//        se(a2) b(a2) nogaps label pr2 rtf replace ///
//        interaction(" x ") nobaselevels noomitted scalar(N_clust) ///
//        eqlabels(none) ///
//        mlabels("Project choice\line GMNL" "Project choice\line Cond. logit" )


** Choice scenario set 2 (showing the variance)
* Estimates for choices in first set of choice scenarios for GMNL, clogit and mlogit (body and appendix tables)
gen attr_mean_n_set2 = attr_mean_n*(question==2)
gen attr_variance_n_set2 = attr_variance_n*(question==2)

eststo set2arm0: gmnl choice if question==2 & base_sample==1 & arm==0, id(id) group(group) rand(attr_mean_n attr_variance_n) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
gmnl_margin if question==2 & base_sample==1 & arm==0, generate(pred_set2arm0)
eststo set12arm0: gmnl choice if base_sample==1 & arm==0, id(id) group(group) rand(attr_mean_n attr_variance_n attr_mean_n_set2 attr_variance_n_set2) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
gmnl_margin if base_sample==1 & arm==0, generate(pred_set12arm0)
eststo set2arm1: gmnl choice if question==2 & base_sample==1 & arm==1, id(id) group(group) rand(attr_mean_n attr_variance_n) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
gmnl_margin if question==2 & base_sample==1 & arm==1, generate(pred_set2arm1)
eststo set2arm01: gmnl choice if question==2 & base_sample==1 & (arm==0 | arm==1), id(id) group(group) rand(attr_mean_n attr_variance_n attr_mean_n_rep attr_variance_n_rep) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
gmnl_margin if question==2 & base_sample==1 & (arm==0 | arm==1), generate(pred_set2arm01) het(rep)
* clogit version
eststo set2arm0_cl: clogit choice attr_mean_n attr_variance_n if question==2 & base_sample==1 & arm==0, group(group) vce(cluster id)
margins , dydx(attr_mean_n attr_variance_n)
eststo set12arm0_cl: clogit choice attr_mean_n attr_variance_n attr_mean_n_set2 attr_variance_n_set2 if base_sample==1 & arm==0, group(group) vce(cluster id)
margins , dydx(attr_mean_n attr_variance_n)
eststo set2arm1_cl: clogit choice attr_mean_n attr_variance_n if question==2 & base_sample==1 & arm==1, group(group) vce(cluster id)
margins , dydx(attr_mean_n attr_variance_n)
eststo set2arm01_cl: clogit choice attr_mean_n attr_variance_n attr_mean_n_rep attr_variance_n_rep if question==2 & base_sample==1 & (arm==0 | arm==1), group(group) vce(cluster id)
margins , dydx(attr_mean_n attr_variance_n)
* Output
* Table 4
* For the paper: Set 2 and then Set 1 and 2 nested
esttab set2arm0 set12arm0 set2arm0_cl set12arm0_cl using "table4_set1_2_nest_gmnl_cl.csv", b(2) se(2) pr2(3) star(* 0.10 ** 0.05 *** 0.01) nocons nogaps nonotes replace
// * Baseline results table: Phase 1, Choice Scenario set 1
// esttab set1arm0 set2arm0 set1arm0_cl set2arm0_cl using "set1_2_gmnl_cl.csv", b(2) se(2) pr2(3) star(* 0.10 ** 0.05 *** 0.01) nocons nogaps nonotes replace
// * Compare Phase 1 and Phase 2 replication
// esttab set2arm0 set2arm0_cl set2arm1 set2arm1_cl using "baseline_set2_arm1_gmnl_cl.csv", b(2) se(2) pr2(3) star(* 0.10 ** 0.05 *** 0.01) nocons nogaps nonotes replace

* Figure 1
* Graphical display 
use "$data/project_choice_all.dta", clear
capture drop pred*
gmnl choice if question==1 & base_sample==1 & arm==0, id(id) group(group) ///
       rand(attr_mean_n attr_variance_n) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
rename attr_mean_n am
rename attr_variance_n av
* Generate some nicely spaced values for producing figures showing relationship
* between variance, mean, and choice.
su attr_variance if choice_set == 1
local av_mean = r(mean)
gen attr_variance_n = -1 if av < -.75
replace attr_variance_n = 0 if av > -.75 & av < 0
replace attr_variance_n = 1 if av > 0 & av < .5
replace attr_variance_n = 2 if av > .5 & av < .
numlist "-1 0 0.5 1"
tokenize `r(numlist)'
gen attr_mean_n = `1' if am < -1
replace attr_mean_n = `2' if am > -1 & am < 0
replace attr_mean_n = `3' if am > 0 & am < 1
replace attr_mean_n = `4' if am > 1 & am < .
tab attr_mean_n am
gmnlpred pred1 if question==1 & base_sample==1 & arm==0, nrep($n_reps)
* Testing the slopes to provide estimates highlighting the more
* extreme variance aversion for high-mean projects.
* Slope for high mean
ttest pred1 if attr_mean_n==`4' & (attr_variance_n==0 | attr_variance_n==1), by(attr_variance_n)
* Slope for low mean
ttest pred1 if attr_mean_n==`2' & (attr_variance_n==0 | attr_variance_n==1), by(attr_variance_n)
* Slope example in intro
ttest pred1 if attr_mean_n==`4' & (attr_variance_n==-1 | attr_variance_n==0), by(attr_variance_n)
* What about across all means? This is very close to the estimated marginal effect.
* It differs only in the exact levels of mean and variance used to generate the
* estimate.
ttest pred1 if (attr_variance_n==0 | attr_variance_n==1), by(attr_variance_n)
* Put back into natural units and draw graph
replace attr_variance_n = attr_variance_n + `av_mean'
collapse (mean) pred1 (sd) sd1=pred1 (sum) n1=pred1, by(attr_mean_n attr_variance_n )
gen uci1 = pred1 + 1.96*sd1/sqrt(n1)
gen lci1 = pred1 - 1.96*sd1/sqrt(n1)
forvalues i = 2/4 {
   su pred1 if attr_mean_n == ``i'' & attr_variance_n > 1
   local j = `i' - 1
   local c`j'=r(min)+.06
}
twoway ///
       (rarea lci1 uci1 attr_variance_n if attr_mean_n == `2', color(ltblue)) ///
       (rarea lci1 uci1 attr_variance_n if attr_mean_n == `3', color(ltblue)) ///
       (rarea lci1 uci1 attr_variance_n if attr_mean_n == `4', color(ltblue)) ///
       (line pred1 attr_variance_n if attr_mean_n == `2', color(black)) ///
       (line pred1 attr_variance_n if attr_mean_n == `3', color(black)) ///
       (line pred1 attr_variance_n if attr_mean_n == `4', color(black)), ///
       text(`c1' 2.86 "Low mean") ///
       text(`c2' 2.85 "Med. mean") ///
       text(`c3' 2.85 "High mean") ///
       xsize(6) ysize(5) yscale(range(.2 .8) titlegap(*4)) xscale(titlegap(*2)) ///
       legend(off) ytitle("Probability subject chose project") xtitle("Research project variance") ///
       graphregion(margin(l=4 r=1 b=1 t=12)) ///
       scale(1.1)   
graph export "choice_by_variance_pred1.pdf", replace as(pdf)
graph export "choice_by_variance_pred1.png", replace as(png) width(1800) height(1$n_reps)

* Distribution of preference parameters
* Appendix Figure 1
// use "$data/created/gmnl_betas_set1_arm0.dta", clear
// hist attr_mean_n, xtitle("Average project score")
// graph export "`work'/output/graphs/hist_attr_mean_n_pref_set1_arm0.png", replace as(png) width(1800) height(1$n_reps)
// hist attr_variance_n, xtitle("Project score variance")
// graph export "`work'/output/graphs/hist_attr_variance_n_pref_set1_arm0.png", replace as(png) width(1800) height(1$n_reps)
// * How many were variance lovers?
// gen var_lover = (attr_variance_n>0)
// tab var_lover

** Summary statistics
* Table 1
* Estimate GMNL-based, subject-specific preference parameters
use "$data/project_choice_all.dta", clear
gmnl choice if question==1, id(id) group(group) rand(attr_mean_n attr_variance_n) vce(cluster id) gamma(1) nrep($n_reps) seed(12345)
gmnlbeta attr_mean_n attr_variance_n , saving("gmnl_betas.dta") replace nrep($n_reps)
* Look at our various demographic variables, focusing on the ones that we use for heterogeneity
* to help interpret those results
use "$data/demographics_all.dta", clear
merge 1:1 id using "gmnl_betas.dta", nogen keep(1 3)
su elapsedtime
* Phase 1
tabstat age numyearswork workrad_ind coef_rra discount_rate collegemath decisionscience if arm == 0 & base_sample == 1, stat(count mean sd) c(s)
* Phase 2
tabstat age numyearswork workrad_ind coef_rra discount_rate loss_averse collegemath decisionscience if base_sample == 1 & arm == 1, stat(count mean sd) c(s)
tabstat age numyearswork workrad_ind coef_rra discount_rate loss_averse collegemath decisionscience if base_sample == 1 & arm == 2, stat(count mean sd) c(s)
tabstat age numyearswork workrad_ind coef_rra discount_rate loss_averse collegemath decisionscience if base_sample == 1 & arm == 3, stat(count mean sd) c(s)

** Balance Tables (Appendix)
* Running omnibus tests
* https://blogs.worldbank.org/impactevaluations/tools-trade-joint-test-orthogonality-when-testing-balance
// *
// * Check balance on project choice questions
// use "$data/demographics_all.dta", clear
// gen set1 = (set == "I")
// gen set2 = (set == "II")
// gen set3 = (set == "III")
// gen set4 = (set == "IV")
// eststo clear
// forvalues i = 1/4 {
//    eststo: reg set`i' discount_rate coef_rra collegemath decisionscience finance workrad_ind age numyearswork if base_sample == 1 & arm == 0, r
//    test discount_rate coef_rra collegemath decisionscience finance workrad_ind age numyearswork
//    estadd scalar pval = r(p)
// }
// esttab * using "balance_project_choice_set", ///
//        star(* 0.10 ** 0.05 *** 0.01) ///
//        se(a2) b(a2) noconstant nogaps label  replace ///
//        scalar(F pval) ///
//        eqlabels(none) rtf 
//
// * Check balance on budget randomization
// use "$data/demographics_all.dta", clear
// merge 1:1 id using "$data/portfolio_budget.dta", nogen keep(3)
// drop if base_sample == 0
// eststo clear
// forvalues i = 1/8 {
//    eststo: reg budget`i' discount_rate coef_rra collegemath decisionscience finance workrad_ind, r
//    test discount_rate coef_rra collegemath decisionscience finance workrad_ind
//    estadd scalar pval = r(p)
// }
// esttab * using "balance_portfolio_budget", ///
//        star(* 0.10 ** 0.05 *** 0.01) ///
//        se(a2) b(a2) noconstant nogaps label  replace ///
//        scalar(F pval) ///
//        eqlabels(none) rtf 
//
// * Check balance on Phase 2 arms
// use "$data/demographics_all.dta", clear
// keep if arm > 0
// gen arm1 = (set == "I")
// gen arm2 = (set == "II")
// gen arm3 = (set == "III")
// eststo clear
// forvalues i = 1/3 {
//    eststo: reg arm`i' discount_rate coef_rra collegemath decisionscience workrad_ind age numyearswork loss_lambda if base_sample == 1 & arm != 0, r
//    test discount_rate coef_rra collegemath decisionscience workrad_ind age numyearswork loss_lambda
//    estadd scalar pval = r(p)
// }
// esttab * using "balance_phase_2_arm", ///
//        star(* 0.10 ** 0.05 *** 0.01) ///
//        se(a2) b(a2) noconstant nogaps label  replace ///
//        scalar(F pval) ///
//        eqlabels(none) rtf 
//
// log close
* EOF

