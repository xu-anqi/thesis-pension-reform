cap log close
clear all
set more off

***********************************************
* Set relative paths to the working directory
***********************************************
global AVZ 	"/Users/angelxu/Desktop/thesis/data/SOEP/reform analysis"
global DO "$AVZ/do/"
global LOG "$AVZ/log/"
global DATA "$AVZ/data/"
global OUT "$AVZ/output/3_did_assumption_test/"

log using "${LOG}3_did_assumption_test.log", replace

***********************************************
* Pre-trend Interaction Test
***********************************************
use "${DATA}data_head.dta", clear

* Generate Post-Reform Indicator
gen post = syear > 2006

* Generate Interaction Term for DiD
gen interaction = post * type_employment


*** if_savings ***
logit if_savings post##type_employment, robust

logit if_savings type_employment##i.syear, robust


keep if syear < 2007
logit if_savings type_employment##i.syear, robust
testparm type_employment#i.syear


*** savings_amount ***
drop if savings_amount <=0
drop if missing(savings_amount)

* Generate log savings
gen log = log(savings_amount)

xtset hid syear
reg log type_employment##i.syear, robust
testparm type_employment#i.syear


*** saving rate ***
drop if household_income == 0
drop if household_income == .

gen rate = savings_amount/household_income
xtset hid syear
reg rate type_employment##i.syear, robust
testparm type_employment#i.syear



***********************************************
* Event Study
***********************************************
use "${DATA}data_head.dta", clear

* Generate Post and Interaction
gen post = syear > 2006
gen interaction = post * type_employment
gen treated = (type_employment == 1)

* Event Study Setup
gen rel_year = syear - 2007
keep if rel_year >= -6 & rel_year <= 6 // restrict years to avoid sparse tails
tab rel_year, gen(Dyear)
foreach i in  1 2 3 4 5 6 {
    local dy = -`i' + 7
    gen did_`i' = Dyear`dy' * treated
}

foreach i in  1 2 3 4 5 6 {
    local dy = `i' + 7
    gen did`i' = Dyear`dy' * treated
}
*** if savings
xtset hid syear
xtlogit if_savings ///
	did_6 did_5 did_4 did_3 did_2 did_1 did1 did2 did3 did4 did5 ///
	hh_size nchild full_time years_employ education_years vocational_degree, fe





* Plot coefficients (omit 0 as baseline)
coefplot, keep(did*) vertical xline(6) ///
    title("Event Study: if savings") ///
    ytitle("Effect relative to 2007") xtitle("Year relative to reform")


	
*** savings_amount
* drop obs with data quality issue
drop if if_savings == .
drop if savings_amount == .

* Filter people who always save
gen has_zero = (if_savings == 0)
bysort hid (syear): egen any_zero = max(has_zero)
drop if any_zero == 1

* Generate log savings
gen log = log(savings_amount)

xtset hid syear
* Regress with fixed effects and covariates if needed
xtreg log ///
     did_6 did_5 did_4 did_3 did_2 did_1 did1 did2 did3 did4 did5 ///
	 did6 female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, ///
	 vce(cluster hid)

* Plot coefficients (omit 0 as baseline)
coefplot, keep(did*) vertical xline(6.5) ///
    title("Event Study: savings amount") ///
    ytitle("Effect relative to 2007") xtitle("Year relative to reform")


***********************************************
* Placebo Test
***********************************************
***********************************************
* Extensive Margin: If Savings
***********************************************
use "${OUT_DATA}data_head.dta", clear

* Generate Post-Reform Indicator
gen post = syear > 2000

* Generate Interaction Term for DiD
gen interaction = post * type_employment

	
	
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
estimates store logit6 drop(*.syear)


* Display Results Side-by-Side
esttab logit1 logit2 logit3 logit4 logit5 logit6 using "${OUT}did_if_savings_logit.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Extensive Margin: Effect of the 2006 Pension Reform on Savings (Logit)") ///
    label

esttab logit1 logit2 logit3 logit4 logit5 logit6 using "${OUT}did_if_savings_logit.tex", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Extensive Margin: Effect of the 2006 Pension Reform on Savings (Logit)") ///
    label booktabs

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
esttab probit1 probit2 probit3 probit4 using "${OUT}did_if_savings_probit.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Extensive Margin: Effect of the 2006 Pension Reform on Savings (Probit)") ///
    label

esttab probit1 probit2 probit3 probit4 using "${OUT}did_if_savings_probit.tex", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Extensive Margin: Effect of the 2006 Pension Reform on Savings (Probit)") ///
    label booktabs drop(*.syear)






***********************************************
* Intensive Margin: log Savings
***********************************************
use "${DATA}data_head.dta", clear

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
gen post = syear > 2000

* Generate Interaction Term for DiD
gen interaction = post * type_employment



*** Linear Probability Model (LPM)

reg log interaction post type_employment, robust
estimates store lpm1

reg log interaction post type_employment female age age_square i.migback ///
	hh_size nchild, robust
estimates store lpm2

reg log interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, robust
estimates store lpm3

reg log interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, robust
estimates store lpm4

xtset hid syear
xtreg log interaction post age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree , fe
estimates store lpm5

xtreg log interaction age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, fe
estimates store lpm6




* Display Results Side-by-Side
esttab lpm1 lpm2 lpm3 lpm4 lpm5 lpm6 using "${OUT}did_amount.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Intensive Margin: Effect of the 2006 Pension Reform on Amount Saved") ///
    label 

esttab lpm1 lpm2 lpm3 lpm4 lpm5 lpm6 using "${OUT}did_amount.tex", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Intensive Margin: Effect of the 2006 Pension Reform on Amount Saved") ///
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

reg rate interaction post type_employment, robust
estimates store lpm1

reg rate interaction post type_employment female age age_square i.migback ///
	hh_size nchild, robust
estimates store lpm2

reg rate interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, robust
estimates store lpm3

/* identical to the one below
reghdfe rate interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, absorb(syear) vce(cluster hid)
estimates store lpm4
*/

reg rate interaction type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, robust
estimates store lpm4

xtset hid syear
xtreg rate interaction post age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree, fe
estimates store lpm5

xtreg rate interaction age age_square ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, fe
estimates store lpm6


* Display Results Side-by-Side
esttab lpm1 lpm2 lpm3 lpm4 lpm5 lpm6 using "${OUT}did_rate.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Intensive Margin: Effect of the 2006 Pension Reform on Saving Rate") ///
    label

esttab lpm1 lpm2 lpm3 lpm4 lpm5 lpm6 using "${OUT}did_rate.tex", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Intensive Margin: Effect of the 2006 Pension Reform on Saving Rate") ///
    label booktabs drop(*.syear)





log close

