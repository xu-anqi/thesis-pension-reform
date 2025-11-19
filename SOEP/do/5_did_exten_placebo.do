cap log close
clear all
set more off

***********************************************
* Set relative paths to the working directory
***********************************************
global AVZ 	"/Users/angelxu/Desktop/thesis/data/SOEP/reform analysis"
global IN_DATA "/Users/angelxu/Desktop/thesis/data/SOEP/exercise/soepdata/"
global DO_FILES "$AVZ/do/"
global OUT_LOG "$AVZ/log/"
global OUT_DATA "$AVZ/data/"
global OUT_OUTPUT "$AVZ/output/5_placebo/"

log using "${OUT_LOG}5_did_exten_placebo.log", replace


***********************************************
* Extensive Margin: If Savings
***********************************************
use "${OUT_DATA}data_head.dta", clear

* Generate Post-Reform Indicator
gen post = syear >= 2000

* Generate Interaction Term for DiD
gen interaction = post * type_employment



*** compositional change check
* 1. define cutoff year
local cutoff = 2000

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




	
	
	
*** Logit Model
logit if_savings interaction post type_employment, robust
estimates store logit1
margins, dydx(interaction)

logit if_savings interaction post type_employment female age age_square i.migback ///
	hh_size nchild, robust
estimates store logit2

logit if_savings interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, robust
estimates store logit3

logit if_savings interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, robust
estimates store logit4

*** add household fe
xtset hid syear
xtlogit if_savings interaction post age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree, fe
estimates store logit5

*** add household and year fe
xtset hid syear
xtlogit if_savings interaction age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, fe
estimates store logit6


* Display Results Side-by-Side
esttab logit1 logit2 logit3 logit4 logit5 logit6 using "${OUT_OUTPUT}did_if_savings_logit.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Extensive Margin: Placebo Test") ///
    label

esttab logit1 logit2 logit3 logit4 logit5 logit6 using "${OUT_OUTPUT}did_if_savings_logit.tex", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Extensive Margin: Placebo Test") ///
    label booktabs drop(*.syear)
/*
*** Probit Model
//probit if_savings interaction post type_employment, robust
//estimates store probit
probit if_savings interaction post type_employment, robust
estimates store probit1
margins, dydx(interaction)


probit if_savings interaction post type_employment female age age_square i.migback ///
	hh_size nchild, robust
estimates store probit2

probit if_savings interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, robust
estimates store probit3

probit if_savings interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, robust
estimates store probit4

/* fixed effect fails for probit model
xtprobit if_savings interaction nchild full_time years_employ education_years ///
	vocational_degree, fe
estimates store probit5
*/

* Display Results Side-by-Side
esttab probit1 probit2 probit3 probit4 using "${OUT_OUTPUT}did_if_savings_probit.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Extensive Margin: Effect of the 2006 Pension Reform on Savings (Probit)") ///
    label

esttab probit1 probit2 probit3 probit4 using "${OUT_OUTPUT}did_if_savings_probit.tex", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Extensive Margin: Effect of the 2006 Pension Reform on Savings (Probit)") ///
    label booktabs drop(*.syear)
*/
log close

