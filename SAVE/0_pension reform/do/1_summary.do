clear
clear all
set more off
cap log close

***********************************************
* Set relative paths to the working directory
***********************************************

global DIR       "~/Desktop/thesis/data/SAVE/0_pension reform"
global DATA      "$DIR/data/"
global OUT       "$DIR/output"
global LOG       "$DIR/log"
cd "$DIR"

log using "${LOG}2_summary.log", replace

***********************************************
* summary statistics *
***********************************************
use "${DATA}/data.dta", clear        // produced by 1_append.do

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
gen migback_1 = (migback == 1)
gen migback_2 = (migback == 2)
gen migback_3 = (migback == 3)

by type_employment, sort : sum if_savings savings_amount female age age_square ///
migback_1 migback_2 migback_3 married hh_size nchild full_time years_employ education_years vocational_degree ///
labor_income household_income hh_head

* the summary table is then copy pasted to the report with small adjustment.
*/

* Tag employees
gen employee = (treated==1)
gen selfemployed = (treated==0)


* gen education categories
gen edu_1 = (education == 1)
gen edu_2 = (education == 2)
gen edu_3 = (education == 3)
gen edu_4 = (education == 4)
gen edu_5 = (education == 5)

* gen past employment categories
gen past_1 = (past_employment == 1)
gen past_2 = (past_employment == 2)
gen past_3 = (past_employment == 3)
gen past_4 = (past_employment == 4)

* Collapse means and standard deviations




collapse ///
(mean) if_savings log_savings  savings ///
    female age partner female_partner east_germany german nchild hh_size /// demo
    edu_1 edu_2 edu_3 edu_4 edu_5 ///
	currently_unemployed past_1 past_2 past_3 past_4 /// edu + employment
(sd) sd_if_savings = if_savings ///
	sd_log_savings = log_savings    ///
	sd_savings = savings ///
    sd_female = female ///
	sd_age = age ///
	sd_partner = partner ///
	sd_female_partner = female_partner ///
	sd_east_germany = east_germany ///
	sd_german = german ///
	sd_nchild = nchild ///
	sd_hh_size = hh_size /// demo /*i.education*/ 
	sd_currently_unemployed = currently_unemployed /// /*i.past_employment*/ /// edu + employment
, by(treated)


* Then export

xpose, clear varname


export excel using "${OUT}/descriptive_statistics.xlsx", ///
sheet("original") firstrow(variables) replace







/***********************************************
* variables in interest
***********************************************
use "${OUT_DATA}data_head.dta", clear

*** has savings
fre if_savings

* To be consistent with SAVE, use only year 2003-2010
* keep if (syear >= 2005) & (syear <=2009)
 keep if (syear >= 2003) & (syear <=2010)
*

***
summarize savings_amount if type_employment == 0,d
summarize savings_amount if type_employment == 1,d


*** amount saved
drop if savings_amount > 5000

* Generate ECDF separately for each group
gen rank_self = .
gen rank_emp = .

sort type_employment savings_amount
by type_employment (savings_amount), sort: gen n = _n
by type_employment: gen N = _N
by type_employment: replace rank_self = n/N if type_employment==0
by type_employment: replace rank_emp = n/N if type_employment==1

* Plot ECDFs together
twoway (line rank_self savings_amount if type_employment==0, sort lcolor(blue)) ///
       (line rank_emp savings_amount if type_employment==1, sort lcolor(red)), ///
       legend(label(1 "Self-Employed") label(2 "Employees")) ///
       title("Empirical CDF of Monthly Amount of Savings (≤ €5000)") ///
       xlabel(0(500)5000) ///
       ylabel(0(.1)1, angle(0)) ///
       ytitle("Cumulative Proportion") ///
       xtitle("Monthly Savings Amount (€)")

graph export "${OUT}/amount saved.png", replace

*** type_employment
fre type_employment

*/
log close
