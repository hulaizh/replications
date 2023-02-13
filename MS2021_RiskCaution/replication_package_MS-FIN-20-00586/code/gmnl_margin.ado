program define gmnl_margin, rclass
   version 16.1
   syntax [if], Generate(name) [HET(name)]
   confirm new variable `generate'
   gmnlpred `generate' `if'
   * Save GMNL estimates
   estimates store mm11
   * Show marginal effects around the center
   quietly: lincom _b[attr_mean_n]/4
   local b_mean = r(estimate)
   local se_mean = r(se)
   quietly: lincom _b[attr_variance_n]/4
   local b_var = r(estimate)
   local se_var = r(se)
   di "Marginal effects (around 0, assuming 0 latent pref heterogeneity)."
   di "Mean: " round(`b_mean', .001) " (" round(`se_mean', 0.001) "), Variance: " round(`b_var', .001) " (" round(`se_var', 0.001) ")"
   if "`het'" != "" {
      quietly: lincom (_b[attr_mean_n] + _b[attr_mean_n_`het'])/4
      local b_mean_het = r(estimate)
      local se_mean_het = r(se)
      quietly: lincom (_b[attr_variance_n] + _b[attr_variance_n_`het'])/4
      local b_var_het = r(estimate)
      local se_var_het = r(se)
      di "`het'=1 Mean: " round(`b_mean_het', .0001) " (" round(`se_mean_het', 0.0001) "), Variance: " round(`b_var_het', .0001) " (" round(`se_var_het', 0.0001) ")"
   }
   quietly: estimates restore mm11
   estimates drop mm11
   return scalar b_mean = `b_mean'
   return scalar se_mean = `se_mean'
   return scalar b_variance = `b_var'
   return scalar se_variance = `se_var'
   if "`het'" != "" {
      return scalar b_mean_het = `b_mean_het'
      return scalar se_mean_het = `se_mean_het'
      return scalar b_variance_het = `b_var_het'
      return scalar se_variance_het = `se_var_het'
   }
end
