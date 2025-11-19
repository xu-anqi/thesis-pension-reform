/***********************************************************************
                        2_did.do
***********************************************************************/

*──────── housekeeping ───────────────────────────────────────────────*
clear all
set more off
capture log close

*── paths ─────────────────────────────────────────────────────────────
global DIR       "~/Desktop/thesis/data/SAVE/0_pension reform"
global DATA      "$DIR/data"
global OUT       "$DIR/output"
global LOG       "$DIR/log"


*──────── 0. load cleaned panel ──────────────────────────────────────*
use "${DATA}/data.dta", clear        // produced by 1_append.do


***********************************************
* Extensive Margin: If Savings
***********************************************
* basic
gen log_savings = log(savings)
gen if_savings = (savings > 0)
replace if_savings = . if missing(savings)

gen post = post06
gen interaction = interaction06

**********
* avoid compositional change

*** compositional change check
* 1. define cutoff year
local cutoff = 2006

* 2. Compute for each pid their first and last survey year
egen min_year = min(year), by(respid)
egen max_year = max(year), by(respid)

* 3. Create a compositional‐change indicator
gen byte comp_status = .
replace comp_status = 1 if max_year <= `cutoff'-1   // only pre‐reform
replace comp_status = 2 if min_year >= `cutoff'    // only post‐reform
replace comp_status = 3 if max_year >= `cutoff' & min_year <= `cutoff'-1  /// both periods

* 4. Tabulate counts
tab comp_status,m

* 5. keep only balanced heads
 keep if comp_status == 3

/*
**********
* baseline
logit if_savings interaction treated post , robust
estimate store logit1


* add demo 
logit if_savings interaction treated post  ///
    female age partner female_partner east_germany german nchild hh_size /// demo
    , robust
estimate store logit2


	
* add edu employ
logit if_savings interaction treated post  ///
    female age partner female_partner east_germany german nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    , robust

estimate store logit3



* add year fe
logit if_savings interaction treated post  ///
    female age partner female_partner east_germany german nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    i.year , robust

estimate store logit4



* add panel attrition
logit if_savings interaction treated post  ///
    female age partner female_partner east_germany german nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    i.year s05 s06 s07 s08, robust

	
estimate store logit5


/* add twfe

xtset respid year
xtlogit if_savings interaction treated post  ///
    female age partner female_partner east_germany german nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    s05 s06 s07 s08, fe
	
estimate store logit6

*/

*/

*──────── 2. Heckman ──────────────────────────────────────*
* gen has_era = !missing(era)   // TRUE if not . or .a etc.

* baseline
* doesn't converge
/*
heckprobit if_savings interaction treated post , ///
	select (na_era na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy na_exp_life_expectancy_1 na_exp_life_expectancy_2 ///
	na_exp_life_expectancy_3 /// exclusion
	female age i.education /// demo
	) 
estimates store heckprobit1



* add demo
heckprobit if_savings interaction treated post  ///
    female age partner east_germany /*german*/ nchild hh_size /// demo
  , select (na_era na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy  /// exclusion
	female age i.education /// demo
	) 
	
estimates store heckprobit2
estpost margins, dydx(interaction)
estimates store ame1
*/


* add edu employ
heckprobit if_savings interaction treated post  ///
    female age partner female_partner east_germany /*german*/ nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    , select (na_era na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy  /// exclusion
	female age i.education /// demo
	) 
estimates store heckprobit3
estpost margins, dydx(interaction)
estimates store ame2


* add year fe
heckprobit if_savings interaction treated post  ///
    female age partner female_partner east_germany /*german*/ nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    i.year , select (na_era na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy  /// exclusion
	female age i.education /// demo
	) 
	
estimates store heckprobit4
estpost margins, dydx(interaction)
estimates store ame3


* add panel attrition
heckprobit if_savings interaction treated post  ///
    female age partner female_partner east_germany /*german*/ nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    i.year s05 s06 s07 s08, select (na_era na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy  /// exclusion
	female age i.education /// demo
	) 
	
estimates store heckprobit5
estpost margins, dydx(interaction)
estimates store ame4

	

*--------------------- 07 cutoff


*Display Results Side-by-Side
/*
esttab logit1 logit2 logit3 logit4 logit5 using "${OUT}/DID_logit_wo_comp.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Results") ///
    label stats(ll r2_p N, fmt(2 3 0) labels("Log-Likelihood" "Pseudo R-squared" "N"))
*/
	
esttab  heckprobit3 heckprobit4 heckprobit5 using "${OUT}/DID_heckprobit_wo_comp.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Results") ///
    label stats(ll chi2 rho N, ///
    fmt(2 2 3 0) ///
    labels("Log-Likelihood" "Wald chi2" "Rho" "N"))

esttab  ame2 ame3 ame4 using "${OUT}/ame_probit.txt", ///
    replace b(3) se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Average Marginal Effects (Heckman Probit Models)") ///
    label nodepvars nonumber





