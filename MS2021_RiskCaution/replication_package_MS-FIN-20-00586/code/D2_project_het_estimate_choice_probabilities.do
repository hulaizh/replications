* Generate Table 3, Figure 2 (Heterogeneity analysis)
* Initialize
local work "~/Dropbox/research/projects/active/randd_experiment/output/text/ms accept/to submit/replication files"
cd "`work'/code/"
capture log close
log using ./log/D2_mechanism_analysis.log, replace
* Set number of reps for GMNL. For debugging, set very low (<10) for speed. For
* real estimation, set in the hundreds or thousands. 
local n_reps = 500

** Main Results 1: Choice scenario set 1 in baseline and replication
use "`work'/data/project_choice_all.dta", clear

* Calculate predicted choice probabilities for lots of different covariates
* Compare the results when using three different estimation strategies
* Put things on similar scales: 0 to 1 or binary for all 
gen rra_bin = 0
replace rra_bin = .5 if risk_neutral == 1
replace rra_bin = 1 if risk_loving == 1
su collegemath if experiment == 1
replace collegemath = (collegemath - r(min))/(r(max) - r(min))
su decisionscience if experiment == 1
replace decisionscience = (decisionscience - r(min))/(r(max) - r(min))
su prob_med_prize if experiment == 1
replace prob_med_prize = (prob_med_prize - r(min))/(r(max) - r(min))
su coef_rra unspent_ind workrad_ind discount_rate collegemath decisionscience finance chose_one_ind prob_med_prize
keep if experiment == 1 & question == 1  & base_sample == 1
gen base = 1
eststo clear
* rra_bin coef_rra unspent_ind workrad_ind discount_rate collegemath decisionscience finance prob_med_prize
foreach set in 1 {
   foreach i of varlist base rra_bin coef_rra unspent_ind workrad_ind discount_rate collegemath decisionscience finance prob_med_prize {
      foreach est in  "clogit" "mlogit" "gmnl" {
         if "`est'"=="clogit" {
            local inner_var "attr_mean_n attr_variance_n \`add_var'"
            local rand_var ""
            local group_var "group(group)"
            local gamma ""
            local reps ""
            local lhs "choice"
         }
         else if "`est'"=="mlogit" {
            local inner_var "attr_mean_n attr_variance_n \`add_var' `i'"
            local rand_var "baseoutcome(4)"
            local group_var ""
            local gamma ""
            local reps ""
            local lhs "rank"
         }
         else if "`est'"=="gmnl" {
            local inner_var ""
            local rand_var "rand(attr_mean_n attr_variance_n \`add_var')"
            local group_var "id(id) group(group)"
            local gamma "gamma(1)"
            local reps "nrep(`n_reps') seed(12345)"
            local lhs "choice"
         }
         di "`i'"
         *local add_var "m_int v_int"
         if "`i'" == "base" {
            local add_var ""
         }
         else {
            local add_var "attr_mean_n_int attr_variance_n_int"
         }
         capture drop attr_mean_n_int
         capture drop attr_variance_n_int
         * We name these the same so that they display in a compact way in the table
         gen attr_mean_n_int = attr_mean_n*`i'
         gen attr_variance_n_int = attr_variance_n*`i'
         eststo est`est'_`i': `est' `lhs' `inner_var' if question == `set' & arm == 0, `group_var' vce(cluster id) `rand_var' `gamma' `reps'
         capture gen pred_`est'_`i' = .
         if "`est'" == "gmnl" {
            di "Het dimension: `i'"
            if "`i'" == "base" {
               gmnl_margin if question == `set' & arm == 0, generate(pred)
               local b0_`i' = r(b_variance)
               local se0_`i' = r(se_variance)
            }
            else {
               gmnl_margin if question == `set' & arm == 0, generate(pred) het(int)
               local b0_`i' = r(b_variance)
               local se0_`i' = r(se_variance)
               local b1_`i' = r(b_variance_het)
               local se1_`i' = r(se_variance_het)
            }
            replace pred_`est'_`i' = pred if question == `set' & arm == 0
            drop pred
         }
         else {
            predict pred
            replace pred_`est'_`i' = pred if question == `set' & arm == 0
            drop pred
         }
      }
   }
}
* That code takes a long time to run, so we save the output
save "`work'/data/created/project_predicted_choice_het_justvar_20211020.dta", replace
* Table 3
* Output model results for a table
esttab estgmnl_coef_rra estgmnl_unspent_ind estgmnl_workrad_ind estgmnl_discount_rate ///
       estgmnl_collegemath estgmnl_decisionscience estgmnl_finance estgmnl_prob_med_prize ///
       using "`work'/output/tables/Table3_project_choice_heterogeneity_comp", ///
       star(* 0.10 ** 0.05 *** 0.01) ///
       se(a2) b(a2) nogaps label pr2 rtf replace ///
       interaction(" x ") nobaselevels noomitted scalar(N_clust) ///
       eqlabels(none) ///
       mlabels("Coef. RRA" "Budget unspent" "R\&D Work Exp." "Discount rate" "Math classes" "Decision Science" "Finance of MBA" "Prize Prob.")
esttab estclogit_coef_rra estclogit_unspent_ind estclogit_workrad_ind estclogit_discount_rate ///
       estclogit_collegemath estclogit_decisionscience estclogit_finance estclogit_prob_med_prize ///
       using "`work'/output/tables/project_choice_heterogeneity_clogit", ///
       star(* 0.10 ** 0.05 *** 0.01) ///
       se(a2) b(a2) noconstant nogaps label pr2 rtf replace ///
       interaction(" x ") nobaselevels noomitted scalar(N_clust) ///
       eqlabels(none) ///
       mlabels("Coef. RRA" "Budget unspent" "R\&D Work Exp." "Discount rate" "Math classes" "Decision Science" "Finance of MBA" "Prize Prob.")
* Plot
capture program drop repost_b
program repost_b, eclass
   ereturn repost b = `1'
end
capture estimates drop *
use "`work'/data/created/project_predicted_choice_het_justvar_20211020.dta", clear
merge 1:1 id question set question_group choice_set choice_option using "`work'/data/project_predicted_choice_main.dta"
keep if _merge == 3
drop _merge
* Analyze the choices by calculating effects on predicted probabilities
* baseline
capture drop vv_*
gen vv_base = attr_variance
label var vv_base "Baseline"
reg pred_set1arm0 attr_mean vv_base
local base_line = _b[vv_base]
estimates store mar_base
* risk
drop vv_*
gen vv_averse = attr_variance*(coef_rra > 1.25)
gen vv_neutral = attr_variance*(coef_rra > 1.1 & coef_rra < 1.25)
gen vv_loving = attr_variance*(coef_rra < 1.1)
label var vv_averse "Risk averse"
label var vv_neutral "Risk neutral"
label var vv_loving "Risk loving"
reg pred_gmnl_coef_rra attr_mean attr_variance
local force = _b[attr_variance] - `base_line'
di `force'
reg pred_gmnl_coef_rra attr_mean c.attr_mean#c.coef_rra##c.coef_rra vv_*
nlcom _b[vv_averse] - _b[vv_loving]
mat b = e(b)
mat b[1,5] = b[1,5]-`force'
mat b[1,6] = b[1,6]-`force'
mat b[1,7] = b[1,7]-`force'
repost_b b
estimates store mar_risk
* discount_rate
drop vv_*
gen vv_lowd = attr_variance*(discount_rate <= .15)
gen vv_highd = attr_variance*(discount_rate > .15)
label var vv_lowd "Low discount rate"
label var vv_highd "High discount rate"
reg pred_gmnl_discount_rate attr_mean attr_variance
local force = _b[attr_variance] - `base_line'
di `force'
reg pred_gmnl_discount_rate attr_mean c.attr_mean#c.discount_rate vv_*
nlcom _b[vv_lowd] - _b[vv_highd]
mat b = e(b)
mat b[1,3] = b[1,3]-`force'
mat b[1,4] = b[1,4]-`force'
repost_b b
estimates store mar_discount_rate
* Budget
drop vv_*
gen vv_unspent = attr_variance*(unspent_ind==1)
gen vv_spent = attr_variance*(unspent_ind==0)
label var vv_unspent "Left some budget"
label var vv_spent "Spent all budget"
*reghdfe pred_gmnl_unspent_ind attr_mean c.attr_mean#c.unspent_ind vv_*, absorb(group)
reg pred_gmnl_unspent_ind attr_mean attr_variance
local force = _b[attr_variance] - `base_line'
di `force'
reg pred_gmnl_unspent_ind attr_mean c.attr_mean#c.unspent_ind vv_*
nlcom _b[vv_unspent] - _b[vv_spent]
mat b = e(b)
mat b[1,3] = b[1,3]-`force'
mat b[1,4] = b[1,4]-`force'
repost_b b
estimates store mar_spend
* R&D
drop vv_*
gen vv_norad = attr_variance*(workrad_ind==0)
gen vv_rad = attr_variance*(workrad_ind==1)
label var vv_rad "R&D work experience"
label var vv_norad "No R&D experience"
*reghdfe pred_gmnl_workrad_ind attr_mean c.attr_mean#c.workrad_ind vv_*, absorb(group)
reg pred_gmnl_workrad_ind attr_mean attr_variance
local force = _b[attr_variance] - `base_line'
di `force'
reg pred_gmnl_workrad_ind attr_mean c.attr_mean#c.workrad_ind vv_*
nlcom _b[vv_rad] - _b[vv_norad]
mat b = e(b)
mat b[1,3] = b[1,3]-`force'
mat b[1,4] = b[1,4]-`force'
repost_b b
estimates store mar_workrad_ind
* collegemath
drop vv_*
gen vv_lowcollegemath = attr_variance*(collegemath<.7)
gen vv_highcollegemath = attr_variance*(collegemath>.7)
label var vv_highcollegemath "Many college math classes"
label var vv_lowcollegemath "Few college math classes"
*reghdfe pred_gmnl_collegemath attr_mean c.attr_mean#c.collegemath vv_*, absorb(group)
reg pred_gmnl_collegemath attr_mean attr_variance
local force = _b[attr_variance] - `base_line'
di `force'
reg pred_gmnl_collegemath attr_mean c.attr_mean#c.collegemath vv_*
nlcom _b[vv_highcollegemath] - _b[vv_lowcollegemath]
mat b = e(b)
mat b[1,3] = b[1,3]-`force'
mat b[1,4] = b[1,4]-`force'
repost_b b
mat list e(b)
estimates store mar_collegemath
* decisionscience
drop vv_*
gen vv_lowdecisionscience = attr_variance*(decisionscience<0.6)
gen vv_highdecisionscience = attr_variance*(decisionscience>=.6)
label var vv_highdecisionscience "Many decision science classes"
label var vv_lowdecisionscience "Few decision science classes"
*reghdfe pred_gmnl_decisionscience attr_mean c.attr_mean#c.decisionscience vv_*, absorb(group)
reg pred_gmnl_decisionscience attr_mean attr_variance
local force = _b[attr_variance] - `base_line'
di `force'
reg pred_gmnl_decisionscience attr_mean c.attr_mean#c.decisionscience vv_*
nlcom _b[vv_lowdecisionscience] - _b[vv_highdecisionscience]
mat b = e(b)
mat b[1,3] = b[1,3]-`force'
mat b[1,4] = b[1,4]-`force'
repost_b b
mat list e(b)
estimates store mar_decisionscience
* finance
drop vv_*
gen vv_finance = attr_variance*(finance==1)
gen vv_notfinance = attr_variance*(finance==0)
label var vv_finance "Finance degree"
label var vv_notfinance "Business degree"
*reghdfe pred_gmnl_finance attr_mean c.attr_mean#c.finance vv_*, absorb(group)
reg pred_gmnl_finance attr_mean attr_variance
local force = _b[attr_variance] - `base_line'
di `force'
reg pred_gmnl_finance attr_mean c.attr_mean#c.finance vv_*
nlcom _b[vv_finance] - _b[vv_notfinance]
mat b = e(b)
mat b[1,3] = b[1,3]-`force'
mat b[1,4] = b[1,4]-`force'
repost_b b
mat list e(b)
estimates store mar_finance
* prob_med_prize
drop vv_*
gen vv_high_prob_med_prize = attr_variance*(prob_med_prize>0)
gen vv_low_prob_med_prize = attr_variance*(prob_med_prize==0)
label var vv_high_prob_med_prize "High prob. of prize"
label var vv_low_prob_med_prize "Low prob. of prize"
*reghdfe pred_gmnl_prob_med_prize attr_mean c.attr_mean#c.prob_med_prize vv_*, absorb(group)
reg pred_gmnl_prob_med_prize attr_mean attr_variance
local force = _b[attr_variance] - `base_line'
di `force'
reg pred_gmnl_prob_med_prize attr_mean c.attr_mean#c.prob_med_prize vv_*
nlcom _b[vv_low_prob_med_prize] - _b[vv_high_prob_med_prize]
mat b = e(b)
mat b[1,3] = b[1,3]-`force'
mat b[1,4] = b[1,4]-`force'
repost_b b
mat list e(b)
estimates store mar_prob_med_prize

* Figure 2
* ordered by gap in effect size (so the things that explain most are at the bottom)
coefplot (mar_base mar_collegemath mar_decisionscience mar_discount_rate mar_spend mar_risk mar_prob_med_prize mar_workrad_ind mar_finance , ciopts(lcolor(black)) color(black)), ///
       keep(vv_*)  byopts(row(1)) ///
       graphregion(margin(l=50)) coeflabels(, notick labgap(-125)) ///
       xline(`base_line', lcolor(blue) lpattern(dash)) xline(0, lcolor(black)) ///
       headings(vv_base = "{bf:Baseline}" vv_averse = "{bf:Risk Aversion}" ///
       vv_unspent = "{bf:Budget Spending}" vv_norad = "{bf:R&D Experience}" ///
       vv_lowd = "{bf:Discount Rate}" vv_lowcollegemath = "{bf:College Math}" ///
       vv_lowdecisionscience = "{bf:Decision Science Classes}" vv_finance = "{bf:Finance or MBA}" ///
       vv_high_prob_med_prize = "{bf:Incentive Strength}" ///
       , labgap(-130)) ///
       yscale(noline alt) legend(off) scale(1.1) levels(95)
graph export "`work'/output/graphs/Figure2_project_choice_1_het.pdf", replace as(pdf)
graph export "`work'/output/graphs/Figure2_project_choice_1_het.png", replace as(png)

* All together
* Do this as well with the Phase 2 data that allows us to include loss aversion
* The code takes a long time to run (hours at least). In the replication package
* it is run with a low number of replications to ensure completion. Set to a number
* in the hundreds to reproduce the values in the paper.
local n_reps = 5
use "`work'/data/project_choice_all.dta", clear
* Put things on similar scales: 0 to 1 or binary for all 
gen rra_bin = 0
replace rra_bin = .5 if risk_neutral == 1
replace rra_bin = 1 if risk_loving == 1
su collegemath if experiment == 1
replace collegemath = (collegemath - r(min))/(r(max) - r(min))
su decisionscience if experiment == 1
replace decisionscience = (decisionscience - r(min))/(r(max) - r(min))
su prob_med_prize if experiment == 1
replace prob_med_prize = (prob_med_prize - r(min))/(r(max) - r(min))
su coef_rra if experiment == 1
gen coef_rra_n = (coef_rra - r(min))/(r(max) - r(min))
su discount_rate if experiment == 1
gen discount_rate_n = (discount_rate - r(min))/(r(max) - r(min))
capture drop m_*
capture drop v_*
foreach i of varlist coef_rra_n unspent_ind workrad_ind discount_rate_n collegemath decisionscience finance prob_med_prize { 
 gen m_`i' = attr_mean_n*`i'
 gen v_`i' = attr_variance_n*`i'
}
eststo clear
* The following command takes hours to run 
eststo gmnl_all_het: gmnl choice if question==1 & base_sample==1 & arm==0, ///
       id(id) group(group) rand(attr_mean_n attr_variance_n m_* v_*) ///
       vce(cluster id) gamma(1) nrep(`n_reps') seed(12345)
gmnl_margin if question==1 & base_sample==1 & arm==0, generate(pred_het_all)
esttab gmnl_all_het  ///
       using "`work'/output/tables/project_choice_heterogeneity_all", ///
       star(* 0.10 ** 0.05 *** 0.01) ///
       se(a2) b(a2) nogaps label pr2 rtf replace ///
       interaction(" x ") nobaselevels noomitted

reg pred_het_all attr_mean_n attr_variance_n m_* v_*, r
estimates store mar_het_all

* Appendix figure 2
coefplot (mar_het_all, ciopts(lcolor(black)) color(black)), ///
       keep(v_*)  byopts(row(1)) xline(0, lcolor(black)) sort
graph export "`work'/output/graphs/project_choice_1_het_all.pdf", replace as(pdf)
graph export "`work'/output/graphs/project_choice_1_het_all.png", replace as(png)

log close
* EOF
