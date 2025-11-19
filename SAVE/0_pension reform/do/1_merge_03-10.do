*─────────────────────  house-keeping  ───────────────────────────────*
clear all
set more off
capture log close

*── paths (adjust ~ if you run from Windows) ──────────────────────────
global DIR        "~/Desktop/thesis/data/SAVE/0_pension reform"
global IN_DATA    "~/Desktop/thesis/data/SAVE/SAVE_2001-2013"
global OUT_DATA   "$DIR/data"
global OUT_LOG    "$DIR/log"
global OUT_OUTPUT "$DIR/output"

*─────────────────────  1. merge all waves  ──────────────────────────
local variables respid ///
	f62o_imp ///                      expected retirement age
	f45o_imp /// 						  Realised Savings, last yr
    f24s1_imp ///                    treated (employee born after 1963)
    f06s_imp f07o_imp  f10s_imp ///      female, age (calculate from year), f08s_imp german, partner
    f20s1_imp f21s1_imp ///                    education vocational training
    f22s1_imp f26s1_imp ///              employment status
    f73eo1_imp f73eo2_imp f73eo3_imp f73eo5_imp f73eo6_imp f73eo11_imp /// financial wealth
    f73eo10_imp f73eo4_imp ///   f73eo9_imp occupational pension, private old-age provision
    f67s_imp ///                   real estate
    f54o_imp ///                household income
    fg1s1_imp ///                    self-rated health
    f88g1_imp ///                    expected inheritance
    f85g3_imp ///                    expected health worsening
    f86g1_imp ///                    expected income increase
    f87g1_imp ///                    expected unemployment
    f90o1_imp f90o2_imp f91s_imp f91o1_imp f91o2_imp ///              subjective life expectancy
    f65o1_imp ///                    expected pension replacement rate
    f04g2_imp ///                    unsatisfied with current job
    bula ///                    east germany
    year ///                    survey year       
	f08s_imp /// german
	f13o_imp /// nchild
	f18o_imp /// hh_size
	

local files  2003-04/STATA/ZA4436_1.dta ///           
			 2005/STATA/ZA4437_1_v5-0-0.dta ///
             2006/STATA/ZA4521_1.dta ///
             2007/STATA/ZA4740_1.dta ///
             2008/STATA/ZA4970_1.dta ///
             2009/STATA/ZA5230_1.dta ///
			 2010/STATA/ZA5292_1_v1-0-0.dta
			 
			 *2011-12/STATA/ZA5635_2_v1-0-0.dta * missing outcome variable
			 *2013/STATA/ZA5647_1_v1-0-0.dta
             
local first 1

use "${IN_DATA}/2011-12/STATA/ZA5635_2_v1-0-0.dta",clear

foreach f of local files {
	use  "${IN_DATA}/`f'", clear
	
	foreach v in  f73eo11_imp fg1s1_imp f67s_imp f90o1_imp f90o2_imp f91s_imp ///   
	f91o1_imp f91o2_imp f65o1_imp f08s_imp{
        capture confirm variable `v'
        if _rc {
            gen `v' = .
        }
    }
	
	keep `variables'

	
	if `first' == 1 {
        save "${OUT_DATA}/combined.dta", replace
        local first 0
    }
    else {
        append using "${OUT_DATA}/combined.dta"
        save  "${OUT_DATA}/combined.dta", replace
		}
}







*─────────────────────  2. refactor & label  ─────────────────────────
*** DEPENDENT VARIABLE ***
rename f62o_imp era
rename f45o savings

replace savings = savings/12

*** TREATMENT VARIABLE ***
* 1. treated
* Drop categories not used in the analysis
drop if inlist(f24s1_imp, 3, 4, 7, 8, 9)
* Define treatment group: employees born after 1963
gen treated = inlist(f24s1_imp, 1, 2)
drop f24s1_imp

* 2. post
* Define post-reform period
gen post06 = (year >= 2006)
gen post07 = (year >= 2007)

* 3. interaction
gen interaction06 = treated * post06
gen interaction07 = treated * post07


*** CONTROL - demographics ***
* 1. female
gen female = (f06s == 2)
drop f06s


* 2. age
gen birthyear = 1900 + f07o
drop f07o
gen age = year - birthyear



* 3. partner
gen partner = (f10s_imp == 1)
drop f10s_imp

* 4. female_partner
gen female_partner = female * partner


* 5. east_germany
gen east_germany = inlist(bula, 11, 12, 13, 14, 15, 16)
drop bula

* 6. nchild
rename f13o nchild

* 7. hh_size
rename f18o hh_size

* 8. german
rename f08s_imp german
replace german = 0 if german ==2


*** CONTROL - education ***
* 1. education
* Recode into new grouped variable
gen education = f20s1_imp

* Apply meaningful labels
label define edu_lbl 1 "Hauptschule" 2 "Mittlere Reife" 3 "Polytechnic High School" ///
4 "university of applied sciences Fach" 5 "Abitur"
label values education edu_lbl

drop f20s1_imp

* 2. vocational training
gen vocational_training = (f21s1_imp>1)
drop f21s1_imp

*** CONTROL - Employment & History ***
* 1. currently_unemployed
gen currently_unemployed = (f22s1_imp == 5)
drop f22s1_imp

* 2. past_employment
gen past_employment = .
replace past_employment = 1 if f26s1_imp == 6
replace past_employment = 2 if inlist(f26s1_imp, 1, 2)
replace past_employment = 3 if inlist(f26s1_imp, 3, 4)
replace past_employment = 4 if f26s1_imp == 5

label define past_employ_lbl 1 "no past unemployment spells" 2 "< 6 months" ///
 3 "6 months to 2 years" 4 "more than 2 years"
 label values past_employment past_employ_lbl
 
drop f26s1_imp


*** CONTROL -  income & wealth ***
* 1. financial_wealth
egen financial_wealth = rowtotal(f73eo1_imp f73eo2_imp f73eo3_imp ///
                                 f73eo5_imp f73eo6_imp f73eo11_imp)
								 
replace financial_wealth = financial_wealth/1000

drop f73eo1_imp f73eo2_imp f73eo3_imp f73eo5_imp f73eo6_imp f73eo11_imp

* 2. financial_wealth_sq
gen financial_wealth_sq = financial_wealth^2


* 3. occupational_pension
* Didn't find it

* 4. private_old_age_provision
egen private_old_age_provision = rowtotal(f73eo10 f73eo4)
replace private_old_age_provision = (private_old_age_provision>0)
drop f73eo10 f73eo4

* 5. real_estate
gen real_estate = !missing(f67s_imp)
drop f67s_imp

* 6. household_net_monthly_income
gen household_income = f54o/100/12
drop f54o

* 7. household_income_sq
gen household_income_sq = household_income^2



*** CONTROL - health & expectation ***
* 1. self_rated_health_notgood	fg1s1
gen health_notgood = (inlist(fg1s1_imp, 3,4,5))

* 2. expected_inheritance	f88g1
gen expected_inheritance = (f88g1>5)
 

* 3. expected_health_worsening	f85g3
gen expected_health_worsening = (f85g3<5)

* 4. expected_income_increase	f86g1
gen expected_income_increase = (f86g1>5)

* 5. expected_unemployment	f87g1
gen expected_unemployment = (f87g1>5)
drop fg1s1 f88g1 f85g3 f86g1 f87g1


* 6. life_expectancy	f90o1,f90o2,f91s,f91o1,f91o2
gen life_expectancy = f90o1
replace life_expectancy = f90o2 if female == 1 

replace life_expectancy = life_expectancy - f90o1 if f91s == 1
replace life_expectancy = life_expectancy + f90o2 if f91s == 3

drop f90o1 f90o2 f91s f91o1 f91o2

* 7. expected_state_pension_replacement_rate	f65o1
rename f65o1_imp exp_replacement_rate
replace exp_replacement_rate = exp_replacement_rate/100

* 8. expected_replacement_unkown	f65o1
* in next section


* 9. unsatisfied_current_job	f04g2
gen unsatisfied_current_job = (f04g2<5)
drop f04g2

*** CONTROL - panel attrition dummy ***

save "${OUT_DATA}/combined.dta", replace



*─────────────────────  3. Handling missing imputation  ──────────────────────────
clear
local variables respid year ///
f45o_ind ///savings
f62o /// era
f65o1 /// expected_replacement_unkown
f85g3 /// na_exp_health
f90o1_ind f90o2_ind f91s_ind ///na_exp_life_expectancy
f86g1 /// na_exp_increase_income
f87g1 /// na_exp_unemploy
f85g2 /// na_exp_econ


local files  2003-04/STATA/ZA4436_indicator.dta ///           
		     2005/STATA/ZA4437_indicator_v5-0-0.dta ///
             2006/STATA/ZA4521_indicator.dta ///
             2007/STATA/ZA4740_indicator.dta ///
             2008/STATA/ZA4970_indicator.dta ///
             2009/STATA/ZA5230_indicator.dta ///
			 2010/STATA/ZA5292_indicator_v1-0-0.dta 
			 
			 *2011-12/STATA/ZA5635_indicator_v1-0-0.dta ///
			 *2013/STATA/ZA5647_indicator_v1-0-0.dta
			 

local first 1

foreach f of local files {
	use  "${IN_DATA}/`f'", clear
	
	
	foreach v in f65o1_ind f90o1_ind f90o2_ind f91s_ind f45o_ind f85g3 ///
	f86g1  f87g1 {
        capture confirm variable `v'
        if _rc {
            gen `v' = .
        }
    }
	
	
	keep `variables'
	
	if `first' {
        save "${OUT_DATA}/indicator.dta", replace
        local first 0
    }
    else {
        append using "${OUT_DATA}/indicator.dta"
        save  "${OUT_DATA}/indicator.dta", replace
		}
}



* rename
rename f45o na_savings
rename f62o_ind na_era
rename f65o1_ind na_expected_replacement
rename 	f86g1 na_exp_increase_income
rename 	f85g3 na_exp_health
rename	f90o1 na_exp_life_expectancy_1
rename f90o2 na_exp_life_expectancy_2
rename f91s na_exp_life_expectancy_3
rename	f87g1 na_exp_unemploy
rename	f85g2 na_exp_econ


save  "${OUT_DATA}/indicator.dta", replace


*** merge
use "${OUT_DATA}/combined.dta", clear


merge 1:1 respid year using "${OUT_DATA}/indicator.dta"

keep if _merge == 3
drop _merge




*─────────────────────  4. further cleaning ──────────────────────────
* 1. birth cohort
drop if birthyear<=1963

* 2. replace era with true observed value
replace era = . if na_era == 1
replace savings = . if na_savings == 1 

save  "${OUT_DATA}/data.dta", replace

* 3. deflate the monetary variables
import excel using "${OUT_DATA}/CPI_table.xlsx", sheet("Sheet1") cellrange(A6:B38) firstrow clear
rename A year
rename B CPI
destring year, replace
tempfile cpi
save "${OUT_DATA}/CPI.dta",replace

/* back to sample */
use "${OUT_DATA}/data.dta", clear
merge m:1 year using "${OUT_DATA}/CPI.dta"
drop if _merge==2
drop _merge

* base year 2003: 78.9
replace financial_wealth      = financial_wealth / 81.5 * 78.9
replace financial_wealth_sq = financial_wealth^2
replace household_income = household_income / 81.5 * 78.9
replace household_income_sq = household_income^2
replace savings = savings / 81.5 * 78.9

* 4. panel attrition control
xtset respid year

gen s0304 = 0
gen s05 = 0
gen s06 = 0
gen s07 = 0
gen s08 = 0
gen s09 = 0

bysort respid (year): gen next_year = year[_n+1]

replace s0304 = 1 if year == 2003 & next_year == 2005
replace s0304 = 1 if year == 2004 & next_year == 2005
replace s05 = 1 if year == 2005 & next_year == 2006
replace s06 = 1 if year == 2006 & next_year == 2007
replace s07 = 1 if year == 2007 & next_year == 2008
replace s08 = 1 if year == 2008 & next_year == 2009
replace s09 = 1 if year == 2009 & next_year == 2010


drop next_year

*** 5. drop changing type of employment to ensure they don't swich between treated and control group
* flag to indicate any change
//use "${OUT_DATA}temp.dta", clear
bysort respid (year): gen change_flag = treated != treated[_n-1] if _n > 1

* check flag and changed person
//tab change_flag,m
//bysort pid (syear): gen change = type_employment != type_employment[_n-1] if _n > 1
//list pid syear type_employment if change == 1, sepby(pid)

/*
*** see the trend ***
gen change_01 = .
gen change_10 = .

bysort pid (syear): replace change_01 = (type_employment[_n-1] == 0 & type_employment == 1) if _n > 1
bysort pid (syear): replace change_10 = (type_employment[_n-1] == 1 & type_employment == 0) if _n > 1

collapse (sum) change_01 change_10 (count) pid, by(syear)

gen change_01_pct = (change_01 / pid) * 100
gen change_10_pct = (change_10 / pid) * 100

twoway (line change_01_pct syear, lcolor(blue) lpattern(solid)) ///
       (line change_10_pct syear, lcolor(red) lpattern(dash)), ///
       title("Transitions in Type Employment Over Time") ///
       legend(label(1 "0 → 1") label(2 "1 → 0")) ///
       xtitle("Year") ytitle("Percentage of Changes") ///
       xlabel(, angle(45))
graph export "${OUT_OUTPUT}type_change.png", replace
*/


* drop person with changed type
replace change_flag = 0 if missing(change_flag)
egen change = max(change_flag), by(respid)

/* Count unique `pid`s where `change == 1`
bysort pid (syear): gen count_pid = _n == 1  // Creates a unique `pid` counter
count if count_pid == 1
count if change == 1 & count_pid == 1
drop change_pid
*/

drop if change == 1
drop change change_flag

/* check
bysort pid (syear): gen change_flag = type_employment != type_employment[_n-1] if _n > 1
tab change_flag  // Should now show 0
*/



*─────────────────────  5. Save  ──────────────────────────
save  "${OUT_DATA}/data.dta", replace


