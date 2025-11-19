clear all
set more off
cap log close

***********************************************
* Set relative paths to the working directory
***********************************************
global AVZ 	"/Users/angelxu/Desktop/thesis/data/SOEP/reform analysis"
global MY_DATA_IN "/Users/angelxu/Desktop/thesis/data/SOEP/exercise/soepdata/"
global MY_DO_FILES "$AVZ/do/"
global MY_LOG_OUT "$AVZ/log/"
global MY_DATA_OUT "$AVZ/data/"
global MY_OUTPUT_OUT "$AVZ/output/4_ppml/"

log using "${OUT_LOG}4_did_PPML.log", replace

***********************************************
* Intensive Margin: log Savings
***********************************************
use "${MY_DATA_OUT}data_head.dta", clear
label variable savings_amount "amount"

* To be consistent with SAVE, use only year 2003-2010
* keep if (syear >= 2005) & (syear <=2009)
 keep if (syear >= 2003) & (syear <=2010)
*


* drop obs with data quality issue
drop if if_savings == .
drop if savings_amount == .

/* 
* check
gen if_test = (savings_amount > 0)
tab if_test if_savings //checked
*/

tab if_savings, m
sum savings_amount,d


* Generate log savings - For TOBIT, log is not needed
* gen log = log(savings_amount)

* Generate Post-Reform Indicator
gen post = syear >= 2006

* Generate Interaction Term for DiD
gen interaction = post * type_employment

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



*** PPML
* Model 1: No controls
ppmlhdfe savings_amount interaction post type_employment, ///
    absorb() vce(robust)
estimates store ppml1

* Model 2: Add demographics
ppmlhdfe savings_amount interaction post type_employment female age age_square i.migback ///
    hh_size nchild, absorb() vce(robust)
estimates store ppml2

* Model 3: Add labor & education
ppmlhdfe savings_amount interaction post type_employment female age age_square i.migback ///
    hh_size nchild full_time years_employ education_years vocational_degree, ///
    absorb() vce(robust)
estimates store ppml3

* Model 4: + Year fixed effects
ppmlhdfe savings_amount interaction type_employment female age age_square i.migback ///
    hh_size nchild full_time years_employ education_years vocational_degree, ///
    absorb(syear) vce(robust)
estimates store ppml4

* Model 5: + Household fixed effects
ppmlhdfe savings_amount interaction post age age_square ///
    hh_size nchild full_time years_employ education_years, ///
    absorb(hid) vce(cluster hid)
estimates store ppml5

* Model 6: Two-way fixed effects (your TWFE model)
ppmlhdfe savings_amount interaction ///
    hh_size nchild full_time years_employ education_years, ///
    absorb(hid syear) vce(cluster hid)
estimates store ppml6




* Display Results Side-by-Side
esttab ppml1 ppml2 ppml3 ppml4 ppml5 ppml6 using "${MY_OUTPUT_OUT}ppml_amount_06.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("PPML: Effect of the 2007 Pension Reform on Amount Saved") ///
    label stats(r2_p N, fmt( 3 0) labels("Pseudo R-squared" "N"))


esttab ppml1 ppml2 ppml3 ppml4 ppml5 ppml6 using "${MY_OUTPUT_OUT}ppml_amount_06.tex", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("PPML: Effect of the 2007 Pension Reform on Amount Saved") ///
    label booktabs

	



***********************************************
* Intensive Margin: saving rate
***********************************************

/* check
tab household_income if household_income < 10, m
tab savings_amount if savings_amount < 10, m
tab household_income if household_income ==.
*/

drop if household_income == 0
drop if household_income == .

gen rate = savings_amount/household_income

tab rate if rate>1
drop if rate > 1
sum rate, d



*** PPML

* Column (1): No controls
ppmlhdfe rate interaction post type_employment, ///
    absorb() vce(robust)
estimates store ppmlr1

* Column (2): Add demographics
ppmlhdfe rate interaction post type_employment female age age_square i.migback ///
    hh_size nchild, ///
    absorb() vce(robust)
estimates store ppmlr2

* Column (3): Add labor + education
ppmlhdfe rate interaction post type_employment female age age_square i.migback ///
    hh_size nchild full_time years_employ education_years vocational_degree, ///
    absorb() vce(robust)
estimates store ppmlr3

* Column (4): Add year fixed effects
ppmlhdfe rate interaction type_employment female age age_square i.migback ///
    hh_size nchild full_time years_employ education_years vocational_degree, ///
    absorb(syear) vce(robust)
estimates store ppmlr4

* Column (5): Add household fixed effects
ppmlhdfe rate interaction post age age_square ///
    hh_size nchild full_time years_employ education_years, ///
    absorb(hid) vce(cluster hid)
estimates store ppmlr5

* Column (6): Two-way fixed effects
ppmlhdfe rate interaction ///
    hh_size nchild full_time years_employ education_years, ///
    absorb(hid syear) vce(cluster hid)
estimates store ppmlr6





* Text output
esttab ppmlr1 ppmlr2 ppmlr3 ppmlr4 ppmlr5 ppmlr6 using ///
    "${MY_OUTPUT_OUT}ppml_rate_06.txt", replace se b(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("PPML: Effect of the 2006 Pension Reform on Saving Rate") ///
	label stats(r2_p N, fmt( 3 0) labels("Pseudo R-squared" "N"))

* LaTeX output
esttab ppmlr1 ppmlr2 ppmlr3 ppmlr4 ppmlr5 ppmlr6 using ///
    "${MY_OUTPUT_OUT}ppml_rate_06.tex", replace se b(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("PPML: Effect of the 2006 Pension Reform on Saving Rate") ///
    label booktabs
log close
