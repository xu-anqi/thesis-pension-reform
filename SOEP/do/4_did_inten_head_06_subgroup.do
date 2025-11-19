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
global MY_OUTPUT_OUT "$AVZ/output/9_subgroup/"



***********************************************
* Intensive Margin: log Savings
***********************************************
use "${MY_DATA_OUT}data_head.dta", clear


* To be consistent with GSOEP, use only year 2003-2010
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

* Filter people who always save
gen has_zero = (if_savings == 0)
bysort hid (syear): egen any_zero = max(has_zero)
drop if any_zero == 1




* Generate log savings
gen log = log(savings_amount)

* Generate Post-Reform Indicator
gen post = syear >= 2006

* Generate Interaction Term for DiD
gen interaction = post * type_employment

*** year 03-10
keep if (syear>=2003) & (syear<=2010)

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

***
* add interaction with sex
gen interaction2 = interaction * female



*** Linear Probability Model (LPM)

reg log interaction2 interaction post type_employment, vce(cluster hid)
estimates store lpm1

reg log interaction2 interaction post type_employment female age age_square i.migback ///
	hh_size nchild, vce(cluster hid)
estimates store lpm2

reg log interaction2 interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, vce(cluster hid)
estimates store lpm3

/*
* identical to the one below
reghdfe log interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, absorb(syear) vce(cluster hid)
estimates store lpm4
*/

reg log interaction2 interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, vce(cluster hid)
estimates store lpm4

xtset hid syear
xtreg log interaction2 interaction post age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree , fe vce(cluster hid)
estimates store lpm5

xtreg log interaction2 interaction age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, fe vce(cluster hid)
estimates store lpm6

*bacon log interaction, id(hid) time(syear) gen(weight estimate g1 g2)

* equivlent to below dyn, but dyn is faster
*did_multiplegt_old log hid syear interaction, cluster(hid)
did_multiplegt (dyn) log hid syear interaction2 , cluster(hid) placebo(1)
graph export "${MY_OUTPUT_OUT}did_multiplegt_subgroup.png", replace

*estimates store lpm7




* Display Results Side-by-Side
esttab lpm1 lpm2 lpm3 lpm4 lpm5 lpm6 using "${MY_OUTPUT_OUT}did_amount_subgroup.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Intensive Margin: Effect of the 2006 Pension Reform on Amount Saved 06") ///
    label stats(r2 N, fmt(3 0) labels("R-squared" "N"))

	



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

reg rate interaction2 interaction post type_employment, vce(cluster hid)
estimates store lpm1

reg rate interaction2 interaction post type_employment female age age_square i.migback ///
	hh_size nchild, vce(cluster hid)
estimates store lpm2

reg rate interaction2 interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, vce(cluster hid)
estimates store lpm3

/* identical to the one below
reghdfe rate interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, absorb(syear) vce(cluster hid)
estimates store lpm4
*/

reg rate interaction2 interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, vce(cluster hid)
estimates store lpm4

xtset hid syear
xtreg rate interaction2 interaction post age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree, fe vce(cluster hid)
estimates store lpm5

xtreg rate interaction2 interaction age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, fe vce(cluster hid)
estimates store lpm6


* Display Results Side-by-Side
esttab lpm1 lpm2 lpm3 lpm4 lpm5 lpm6 using "${MY_OUTPUT_OUT}did_rate_subgroup.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Intensive Margin: Effect of the 2006 Pension Reform on Saving Rate 06") ///
    label stats(r2 N, fmt(3 0) labels("R-squared" "N"))


