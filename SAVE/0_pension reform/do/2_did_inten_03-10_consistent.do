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
************************************************ basic
gen if_savings = (savings > 0)
replace if_savings = . if missing(savings)

gen post = post06
gen interaction = interaction06


*gen post = post07
*gen interaction = interaction07


* drop obs with data quality issue
drop if savings == .

/*
* check
gen if_test = (savings > 0)
tab if_test if_savings, m //checked
exit
*/

tab if_savings, m

* Filter people who always save
gen has_zero = (if_savings == 0)
bysort respid (year): egen any_zero = max(has_zero)
drop if any_zero == 1

* gen log savings
gen log_savings = log(savings)

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

tab year treated,m
exit


* baseline
regress log_savings interaction treated post , vce(cluster respid)
estimate store ols1



* add demo 
regress log_savings interaction treated post  ///
    female age /*partner female_partner east_germany*/ german nchild hh_size /// demo
    , vce(cluster respid)
estimate store ols2

regress log_savings interaction treated post  ///
    female age /*partner female_partner east_germany*/  nchild hh_size /// demo
    , vce(cluster respid)
	
* add edu employ
regress log_savings interaction treated post  ///
    female age /*partner female_partner east_germany*/ german nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    , vce(cluster respid)

estimate store ols3



* add year fe
regress log_savings interaction treated  ///
    female age /*partner female_partner east_germany*/ german nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    i.year , vce(cluster respid)

estimate store ols4



* add panel attrition
regress log_savings interaction treated  ///
    female age /*partner female_partner east_germany*/ german nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
    i.year s0304 s05 s06 s07 s08 s09, vce(cluster respid)

	
estimate store ols5


* add twfe

xtset respid year
xtreg log_savings interaction    ///
     age /// demo
     currently_unemployed i.past_employment /// edu + employment
    s0304 s05 s06 s07 s08 s09, fe vce(cluster respid)
	
estimate store ols6

	

*--------------------- 07 cutoff


*Display Results Side-by-Side
esttab ols1 ols2 ols3 ols4 ols5 ols6 using "${OUT}/DID_ols_03-10.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Results") ///
    label
	






