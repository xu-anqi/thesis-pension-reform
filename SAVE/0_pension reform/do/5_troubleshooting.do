*** troubleshooting ***
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



****---------

graph box savings, over(treated) over(year) ///
    asyvars ///
    ytitle("Savings") ///
    title("Boxplot of Savings by Year and Treatment Group") ///
    legend(label(1 "Control (treated = 0)") label(2 "Treated (treated = 1)"))

	
	
	
preserve
collapse (mean) savings, by(year treated)
twoway (line savings year if treated == 0, lpattern(solid) lcolor(blue)) ///
       (line savings year if treated == 1, lpattern(dash) lcolor(red)), ///
       legend(label(1 "Control (treated = 0)") label(2 "Treated (treated = 1)")) ///
       ytitle("Average Savings") ///
       xtitle("Year") ///
       title("Savings Over Time by Treatment Status")

