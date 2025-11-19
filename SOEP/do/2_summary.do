clear
clear all
set more off
cap log close

***********************************************
* Set relative paths to the working directory
***********************************************
global AVZ 	"/Users/angelxu/Desktop/thesis/data/SOEP/reform analysis"
global IN_DATA "/Users/angelxu/Desktop/thesis/data/SOEP/exercise/soepdata/"
global DO_FILES "$AVZ/do/"
global OUT_LOG "$AVZ/log/"
global OUT_DATA "$AVZ/data/"
global OUT "$AVZ/output/2_summary"
cd "$AVZ"

log using "${OUT_LOG}2_summary.log", replace

***********************************************
* summary statistics
***********************************************


/*
gen migback_1 = (migback == 1)
gen migback_2 = (migback == 2)
gen migback_3 = (migback == 3)

by type_employment, sort : sum if_savings savings_amount female age age_square ///
migback_1 migback_2 migback_3 married hh_size nchild full_time years_employ education_years vocational_degree ///
labor_income household_income hh_head

* the summary table is then copy pasted to the report with small adjustment.
*/
local files data data_head

foreach file of local files {

use "${OUT_DATA}`file'.dta", clear

*** compositional change check
* 1. define cutoff year
local cutoff = 2006

* 2. Compute for each pid their first and last survey year
egen min_year = min(syear), by(pid)
egen max_year = max(syear), by(pid)

* 3. Create a compositional‐change indicator
gen byte comp_status = .
replace comp_status = 1 if max_year <= `cutoff'-1   // only pre‐reform
replace comp_status = 2 if min_year >= `cutoff'    // only post‐reform
replace comp_status = 3 if max_year >= `cutoff' & min_year <= `cutoff'-1  /// both periods

* 4. Tabulate counts
tab comp_status,m

* 5. keep only balanced heads
keep if comp_status == 3
drop comp_status

* Tag employees
gen employee = (type_employment==0)
gen selfemployed = (type_employment==1)

* To be consistent with SAVE, use only year 2003-2010
* keep if (syear >= 2005) & (syear <=2009)
 keep if (syear >= 2003) & (syear <=2010)
*




* gen migration background categories
gen migback_1 = (migback == 1)
gen migback_2 = (migback == 2)
gen migback_3 = (migback == 3)
* Collapse means and standard deviations
collapse ///
(mean) if_savings savings_amount female age migback_1 migback_2 migback_3 ///
		married hh_size nchild full_time years_employ education_years ///
		vocational_degree labor_income household_income hh_head ///
(sd) sd_if_savings = if_savings ///
    sd_savings_amount = savings_amount ///
    sd_female = female ///
    sd_age = age ///
    sd_migback_1 = migback_1 ///
    sd_migback_2 = migback_2 ///
    sd_migback_3 = migback_3 ///
    sd_married = married ///
    sd_hh_size = hh_size ///
    sd_nchild = nchild ///
    sd_full_time = full_time ///
    sd_years_employ = years_employ ///
    sd_education_years = education_years ///
    sd_vocational_degree = vocational_degree ///
    sd_labor_income = labor_income ///
    sd_household_income = household_income ///
    sd_hh_head = hh_head, ///
by(type_employment)


* Then export

xpose, clear varname


export excel using "${OUT}/descriptive_statistics_`file'.xlsx", ///
sheet("original_`file'") firstrow(variables) replace


}




***********************************************
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


log close
