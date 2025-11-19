/***********************************************************************
                        2_did.do
***********************************************************************/

*──────── housekeeping ───────────────────────────────────────────────*
clear all
set more off
capture log close

*── paths ─────────────────────────────────────────────────────────────
global DIR       "~/Desktop/thesis/data/SAVE/2_expected retirement years"
global DATA      "$DIR/data"
global OUT       "$DIR/output"
global LOG       "$DIR/log"

log using "${LOG}/2_did.log", replace

*──────── 0. load cleaned panel ──────────────────────────────────────*
use "${DATA}/data.dta", clear        // produced by 1_merge_03-10.do

drop if life_expectancy < age //implausible answer, data quality problem

keep if female == 0


*──────── 1. OLS ──────────────────────────────────────*
* basic
reg year_rtm treated post06 interaction06, robust


* add demo edu employ
reg year_rtm treated post06 interaction06 ///
    female age partner female_partner east_germany /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    , robust

	
* add income, wealth
reg year_rtm treated post06 interaction06 ///
    female age partner female_partner east_germany /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
	financial_wealth financial_wealth_sq private_old_age_provision ///
	real_estate household_income household_income_sq ///income & wealth
    , cluster(respid)




* add heath, expectation	
reg year_rtm treated post06 interaction06 ///
    female age partner female_partner east_germany /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
	financial_wealth financial_wealth_sq private_old_age_provision ///
	real_estate household_income household_income_sq ///income & wealth
	health_notgood expected_inheritance expected_health_worsening ///
	expected_income_increase expected_unemployment  ///
	exp_replacement_rate na_expected_replacement unsatisfied_current_job ///health
    , robust



* add panel attrition
	
xtset respid year
xtreg year_rtm treated post06 interaction06 ///
    female age partner female_partner east_germany /// demo
    i.education vocational_training /// edu
	currently_unemployed i.past_employment /// employment
	financial_wealth financial_wealth_sq private_old_age_provision ///
	real_estate household_income household_income_sq ///income & wealth
	health_notgood expected_inheritance expected_health_worsening ///
	expected_income_increase expected_unemployment  ///
	unsatisfied_current_job ///health
	s0304 s05 s06 s07 s08 /// panel attrition
    , cluster(respid)
	

estimates store ols

*──────── 2. Heckman ──────────────────────────────────────*
gen has_era = !missing(era)   // TRUE if not . or .a etc.
	
heckman year_rtm interaction06 treated post06, select (na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy na_era /// exclusion
	female age i.education /// demo
	) cluster(respid)
estimates store heckman0


heckman year_rtm treated post06 interaction06 ///
    female age partner female_partner east_germany /// demo
        , select (na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy na_era /// exclusion
	female age i.education /// demo
	) cluster(respid)
estimates store heckman1


heckman year_rtm treated post06 interaction06 ///
    female age partner female_partner east_germany /// demo
    i.education vocational_training /// edu
	currently_unemployed i.past_employment /// edu + employment
	    , select (na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy na_era /// exclusion
	female age i.education /// demo
	) cluster(respid)
estimates store heckman2


heckman year_rtm treated post06 interaction06 ///
    female age partner female_partner east_germany /// demo
    i.education vocational_training /// edu
	currently_unemployed i.past_employment /// edu + employment
	financial_wealth financial_wealth_sq private_old_age_provision ///
	real_estate household_income household_income_sq ///income & wealth
	   , select (na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy na_era /// exclusion
	female age i.education /// demo
	) cluster(respid)
estimates store heckman3

heckman year_rtm treated post06 interaction06 ///
    female age partner female_partner east_germany /// demo
    i.education vocational_training /// edu
	currently_unemployed i.past_employment /// edu + employment
	financial_wealth financial_wealth_sq private_old_age_provision ///
	real_estate household_income household_income_sq ///income & wealth
	health_notgood expected_inheritance expected_health_worsening ///
	expected_income_increase expected_unemployment ///
	unsatisfied_current_job ///health
    , select (na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy na_era /// exclusion
	female age i.education /// demo
	) cluster(respid)
estimates store heckman4



xtset respid year
heckman year_rtm treated post06 interaction06 ///
    female age partner female_partner east_germany /// demo
    i.education vocational_training /// edu
	currently_unemployed i.past_employment /// edu + employment
	financial_wealth financial_wealth_sq private_old_age_provision ///
	real_estate household_income household_income_sq ///income & wealth
	health_notgood expected_inheritance expected_health_worsening ///
	expected_income_increase expected_unemployment ///
	unsatisfied_current_job ///health
	s0304 s05 s06 s07 s08 /// panel attrition
    , select (na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy na_era /// exclusion
	female age i.education /// demo
	) cluster(respid)
estimates store heckman5
	
xtset respid year
heckman year_rtm treated interaction06 ///
    female age partner female_partner east_germany /// demo
    i.education vocational_training /// edu
	currently_unemployed i.past_employment /// edu + employment
	financial_wealth financial_wealth_sq private_old_age_provision ///
	real_estate household_income household_income_sq ///income & wealth
	health_notgood expected_inheritance expected_health_worsening ///
	expected_income_increase expected_unemployment  ///
	unsatisfied_current_job ///health
	s0304 s05 s06 s07 s08 /// panel attrition
	i. year /// year fe
    , select (na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy na_era /// exclusion
	female age i.education /// demo
	) cluster(respid)
	
estimates store heckman6

*--------------------- 07 cutoff
xtset respid year
heckman year_rtm treated post07 interaction07 ///
    female age partner female_partner east_germany /// demo
    i.education vocational_training /// edu
	currently_unemployed i.past_employment /// edu + employment
	financial_wealth financial_wealth_sq private_old_age_provision ///
	real_estate household_income household_income_sq ///income & wealth
	health_notgood expected_inheritance expected_health_worsening ///
	expected_income_increase expected_unemployment  ///
	unsatisfied_current_job ///health
	s0304 s05 s06 s07 s08 /// panel attrition
    , select (na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy na_era /// exclusion
	female age i.education /// demo
	) cluster(respid)
	
estimates store heckman2007cutoff


*Display Results Side-by-Side
esttab  heckman0 heckman1 heckman2 heckman3 heckman4 heckman5 heckman6 ///
	/*heckman2007cutoff*/ using "${OUT}/DID_male.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Results") ///
    label stats(chi2 p N , fmt(0 3 0 ) ///
          labels("Wald $\chi^2$" "p-value" "Observations"))








log close
