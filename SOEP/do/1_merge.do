clear
clear all
set more off
cap log close

***********************************************
* Set relative paths to the working directory
***********************************************
global DIR 	"/Users/angelxu/Desktop/thesis/data/SOEP/reform analysis"
global IN_DATA "/Users/angelxu/Desktop/thesis/data/SOEP/exercise/soepdata/"
global DO_FILES "$DIR/do/"
global OUT_LOG "$DIR/log/"
global OUT_DATA "$DIR/data/"
global OUT_OUTPUT "$DIR/output/"

log using "${OUT_LOG}1_merge.log", replace


***********************************************
* get variable in interest from different dataset
***********************************************

*** use ppathl file as master file ***
* use "${IN_DATA}ppathl.dta", clear
use pid syear hid sex gebjahr migback using "${IN_DATA}ppathl.dta", clear
label language EN
* keep data after 1992
keep if syear >= 1992
* replace negative value with missing
replace sex = . if sex < 0
replace gebjahr = . if gebjahr < 0
replace migback = . if migback < 0
* generate age, only keep age greater than or equal to 16
gen age = syear - gebjahr
gen age_square = age^2
keep if age >= 16
* save data ppathl
save "${OUT_DATA}ppathl.dta", replace


*** get variables from pgen ***
use pid hid syear pgfamstd pgemplst pgbilzeit pgpbbil01 pglabnet pgexpft pgexppt using "${IN_DATA}pgen.dta", clear
label language EN
keep if syear >= 1992
* maritial status pgfamstd
gen married = .
replace married = 0 if pgfamstd > 0
replace married = 1 if pgfamstd ==1
drop pgfamstd
* employment percentage pgemplst
gen employment_percentage = ""
replace employment_percentage = "less than part-time" if pgemplst >0
replace employment_percentage = "full-time" if pgemplst == 1
replace employment_percentage = "part-time" if pgemplst == 2
drop pgemplst
* education in years pgbilzeit
gen education_years = .
replace education_years = pgbilzeit if pgbilzeit > 0
drop pgbilzeit
* vocational training degree pgpbbil01 
* change to boolean?
gen vocational_degree = .
replace vocational_degree = 1 if pgpbbil01>0
replace vocational_degree = 0 if pgpbbil01 == -2
drop pgpbbil01
* current net labor income pglabnet
gen labor_income = .
replace labor_income = 0 if pglabnet==-2
replace labor_income = pglabnet if pglabnet >= 0
drop pglabnet

* years of employment
gen years_employ = pgexpft + pgexppt
replace years_employ = . if years_employ == -2
drop pgexpft pgexppt

* save data pgen
save "${OUT_DATA}pgen.dta", replace


*** get variables from pl ***
* use "${IN_DATA}pl.dta", clear
use pid hid syear plb0057_h1 using "${IN_DATA}pl.dta", clear
label language EN
keep if syear >= 1992
* generate type_employment based on plb0057_h1
gen type_employment = .
replace type_employment = 0 if plb0057_h1 > 0
replace type_employment = 1 if plb0057_h1 == -2
drop plb0057_h1
save "${OUT_DATA}pl.dta", replace

*** get variables from pbrutto ***
use pid syear stell_h using "${IN_DATA}pbrutto.dta", clear
label language EN
* drop individuals without relationship to the household head
drop if stell_h < 0
* household head
gen hh_head = (stell_h == 0)
drop stell_h
save "${OUT_DATA}pbrutto.dta", replace



*** get variables from hl ***
* not from kidlong (k_nrkid)
* number of children , savings amount, if savings
//use "${IN_DATA}hl.dta", clear
use hid syear hlc0043 hlk0044_v1 hlc0119_v1 hlc0119_v2 hlc0119_v5 hlc0120_h using "${IN_DATA}hl.dta", clear
label language EN
* number of children hlc0043 hlk0044_v1
gen nchild = .
replace nchild = 0 if hlc0043 == -2
replace nchild = hlc0043 if hlc0043 >= 0
replace nchild = 0 if hlk0044_v1 == 2
drop hlc0043 hlk0044_v1
* if_savings 
gen if_savings_temp = .
replace if_savings_temp = hlc0119_v1 if syear >=1992 & syear <=2014
replace if_savings_temp = hlc0119_v2 if syear >=2015 & syear <=2020
replace if_savings_temp = hlc0119_v5 if syear >=2021 & syear <=2022
replace if_savings_temp = -10 if if_savings_temp ==.
gen if_savings = .
replace if_savings = 0 if if_savings_temp >= 2
replace if_savings = 1 if if_savings_temp == 1
drop if_savings_temp hlc0119_v1 hlc0119_v2 hlc0119_v5
* savings amount hlc0120_h
rename hlc0120_h savings_amount
replace savings_amount = . if savings_amount < 0
* harmonize if_savings and savings_amount
replace if_savings = 1 if missing(if_savings) & (savings_amount > 0 & !missing(savings_amount))
replace if_savings = 0 if missing(if_savings) & (savings_amount== 0 & !missing(savings_amount))
replace savings_amount = 0 if if_savings == 0 & missing(savings_amount)
//gen test_savings = .
//replace test_savings = 1 if savings_amount > 0 & savings_amount != .
//replace test_savings = 0 if savings_amount == 0 & savings_amount != .
* save data hl
save "${OUT_DATA}hl.dta", replace


*** get variables from hgen ***
*   monthly household net income
use "${IN_DATA}hgen.dta", clear
use hid syear hghinc using "${IN_DATA}hgen.dta", clear
label language EN
keep if syear >= 1992
gen household_income = .
replace household_income = hghinc if hghinc < -10
replace household_income = hghinc if hghinc >= 0
drop hghinc
save "${OUT_DATA}hgen.dta", replace

*** get variables from hbrutto ***
use hid syear hhgr using "${IN_DATA}hbrutto.dta", clear
label language EN
* drop household without household size (<0) or dissolved (=0)
drop if hhgr <= 0
* household size
rename hhgr hh_size
save "${OUT_DATA}hbrutto.dta", replace

*** hpathl
use hid syear using "${IN_DATA}hpathl.dta", clear
label language EN
save "${OUT_DATA}hpathl.dta", replace


*** get variables from equiv ***
use pid syear y11101 using "${IN_DATA}pequiv.dta", clear
rename y11101 CPI
drop if CPI < 0 //drop missing values
save "${OUT_DATA}pequiv.dta", replace




***********************************************
* merge
***********************************************
* individual level data
use "${OUT_DATA}ppathl.dta", clear
merge 1:1 pid syear using "${OUT_DATA}pl.dta"
keep if _merge==3
drop _merge

merge 1:1 pid syear using "${OUT_DATA}pgen.dta"
keep if _merge==3
drop _merge

merge 1:1 pid syear using "${OUT_DATA}pbrutto.dta"
keep if _merge == 3
drop _merge



* save temporary individual level data
save "${OUT_DATA}temp.dta", replace


* merge household level data
use "${OUT_DATA}hpathl.dta", clear
merge 1:1 hid syear using "${OUT_DATA}hl.dta"
keep if _merge==3
drop _merge
merge 1:1 hid syear using "${OUT_DATA}hgen.dta"
drop _merge
merge 1:1 hid syear using "${OUT_DATA}hbrutto.dta"
keep if _merge==3
drop _merge

* merge household and individual level data
merge 1:m hid syear using "${OUT_DATA}temp.dta"
keep if _merge==3
drop _merge

merge 1:m pid syear using "${OUT_DATA}pequiv.dta"
keep if _merge==3
drop _merge


***********************************************
* Data Filtering
***********************************************
*** 1. syear
drop if syear < 1992

*** 2. keep only full-time and part-time employed individuals.
keep if employment_percentage == "full-time" | employment_percentage == "part-time"
gen full_time = (employment_percentage == "full-time")
drop employment_percentage

*** 3. keep only birth year > 1964
keep if gebjahr > 1964 & !missing(gebjahr)

*** 4. drop irregular and missing age, sex, type of employment, 
***    migration background, married
keep if age>=17 & !missing(gebjahr)
keep if !missing(sex) & !missing(type_employment) & !missing(age) & !missing(migback) & !missing(married)

//save "${OUT_DATA}temp.dta", replace

*** 5. drop missing if_savings (first step)
*drop if missing(if_savings)


*** 6. drop changing type of employment to ensure they don't swich between treated and control group
* flag to indicate any change
//use "${OUT_DATA}temp.dta", clear
bysort pid (syear): gen change_flag = type_employment != type_employment[_n-1] if _n > 1
* check flag and changed person
//tab change_flag
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
egen change = max(change_flag), by(pid)

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

***********************************************
* transform sex into binary variable
gen female = (sex == 2)
drop sex
order pid hid syear if_savings savings_amount type_employment female age ///
	age_square gebjahr migback married hh_size nchild full_time years_employ education_years ///
	vocational_degree labor_income household_income CPI


* transform nominal variables into real variables
* savings_amount labor_income household_income
* base year 2003: 78.1
replace savings_amount = savings_amount * 78.1 / CPI
replace labor_income = labor_income * 78.1 / CPI
replace household_income = household_income * 78.1 / CPI

***********************************************
* Save Data
***********************************************
* save data
save "${OUT_DATA}data.dta", replace

* data with only household head
keep if hh_head == 1
save "${OUT_DATA}data_head.dta",replace

log close



