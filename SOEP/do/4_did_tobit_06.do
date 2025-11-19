clear all
set more off
cap log close

***********************************************
* Set relative paths to the working directory
***********************************************
global AVZ 	"/Users/angelxu/Desktop/thesis/data/SOEP/reform analysis"
global MY_DATA_IN "/Users/angelxu/Desktop/thesis/data/SOEP/exercise/soepdata/"
global MY_DO_FILES "$AVZ/do/"
global MY_LOG_OUT "$AVZ/log/4_tobit/"
global MY_DATA_OUT "$AVZ/data/"
global MY_OUTPUT_OUT "$AVZ/output/4_tobit/"

log using "${MY_LOG_OUT}4_did_tobit_06.log", replace

***********************************************
* Intensive Margin: log Savings
***********************************************
use "${MY_DATA_OUT}data_head.dta", clear
label variable savings_amount "amount"
* drop obs with data quality issue
drop if if_savings == .
drop if savings_amount == .

* To be consistent with GSOEP, use only year 2003-2010
* keep if (syear >= 2005) & (syear <=2009)
 keep if (syear >= 2003) & (syear <=2010)
*



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
* gen post = syear >= 2007
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


*** Linear Probability Model (LPM)

tobit savings_amount interaction post type_employment, ll(0) vce(robust)
estimates store lpm1

tobit savings_amount interaction post type_employment female age age_square i.migback ///
	hh_size nchild, ll(0) vce(robust)
estimates store lpm2

tobit savings_amount interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, ll(0) vce(robust)
estimates store lpm3

tobit savings_amount interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, ll(0) vce(cluster hid)
estimates store lpm4

margins, dydx(interaction)
margins, dydx(interaction) predict(ystar(0,.))


/* 
* No standard Tobit with FE
xtset hid syear
xtreg log interaction age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree, fe
estimates store lpm5
*/




* Display Results Side-by-Side
esttab lpm1 lpm2 lpm3 lpm4 using "${MY_OUTPUT_OUT}tobit_amount_06.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Tobit: Effect of the 2006 Pension Reform on Amount Saved") ///
    label stats(ll r2_p N, fmt(2 3 0) labels("Log-Likelihood" "Pseudo R-squared" "N"))

esttab lpm1 lpm2 lpm3 lpm4 using "${MY_OUTPUT_OUT}tobit_amount_06.tex", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Tobit: Effect of the 2006 Pension Reform on Amount Saved") ///
    label booktabs drop(*.syear)

	
	



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



*** Linear Probability Model (LPM)
/*
tobit savings_amount interaction post type_employment, ll(0) vce(robust)
estimates store lpm1


tobit savings_amount interaction post type_employment female age age_square i.migback ///
	hh_size nchild, ll(0) vce(robust)
estimates store lpm2

tobit savings_amount interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, ll(0) vce(robust)
estimates store lpm3
*/


tobit rate interaction post type_employment, ll(0) vce(robust)
estimates store lpm1

tobit rate interaction post type_employment female age age_square i.migback ///
	hh_size nchild, ll(0) vce(robust)
estimates store lpm2

tobit rate interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, ll(0) vce(robust)
estimates store lpm3


tobit rate interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, ll(0) vce(cluster hid)
estimates store lpm4

margins, dydx(interaction)
margins, dydx(interaction) predict(ystar(0,.))

/*
xtset hid syear
xtreg rate interaction age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree
estimates store lpm5
*/



* Display Results Side-by-Side
esttab lpm1 lpm2 lpm3 lpm4 using "${MY_OUTPUT_OUT}tobit_rate_06.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Tobit: Effect of the 2007 Pension Reform on Saving Rate") ///
    label stats(ll r2_p N, fmt(2 3 0) labels("Log-Likelihood" "Pseudo R-squared" "N"))

esttab lpm1 lpm2 lpm3 lpm4 using "${MY_OUTPUT_OUT}tobit_rate_06.tex", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Tobit: Effect of the 2007 Pension Reform on Saving Rate") ///
    label booktabs drop(*.syear) 

log close
