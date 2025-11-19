/***********************************************************************
                        BUILD ANALYTIC SAMPLE
                  (mirror of 2_sampling.R, 25 Apr 2025)
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

log using "${LOG}/2_filter.log", replace

*──────── 1. load cleaned panel ──────────────────────────────────────*
use "${DATA}/combined.dta", clear        // produced by 1_append.do

*──────── 2. FILTERS (exactly as in R) ───────────────────────────────*
* 2.1 keep only employed (exclude marginal / occasional / not employed)
keep if !inlist(employ_pct, 3, 4, 5)

* 2.2 drop birth cohort ≤ 1964 (fully treated by reform) and older than 16*
gen birth_cohort = birthyr<=1964
keep if birthyr>1964
keep if age >= 16

* 2.3 keep employment types: 1 & 2 (employee) or 6 (self-employed)    *
keep if inlist(employ_type, 1, 2, 6)

* 2.4 recode to treatment dummy (1 = employee, 0 = self-employed)      *
gen byte type_employment = .
replace type_employment = 1 if inlist(employ_type,1,2)
replace type_employment = 0 if employ_type==6
label define Ltype 0 "Self-Employed" 1 "Employee"
label values  type_employment Ltype

* 2.5 drop respondents who ever switch treatment status              *
* mark exactly one observation for every (respid  type_employment) pair
egen byte tag = tag(respid type_employment)

* count how many different employment types each respondent ever shows
egen n_types = total(tag), by(respid)

* drop those who appear with more than one type
drop if n_types > 1

* tidy up
drop tag n_types

save, replace

*──────── 3. CPI MERGE & REAL VARIABLES ─────────────────────────────*
import excel using "${DATA}/CPI_table.xlsx", sheet("Sheet1") cellrange(A6:B38) firstrow clear
rename A year
rename B CPI
destring year, replace
tempfile cpi
save "${DATA}/CPI.dta",replace

/* back to sample */
use "${DATA}/combined.dta", clear
keep if !inlist(employ_pct, 3, 4, 5) & birthyr>1964 & inlist(employ_type,1,2,6)
merge m:1 year using "${DATA}/CPI.dta"
drop if _merge==2
drop _merge

gen real_saving      = realised_sav / CPI * 77
gen real_net_income  = tot_net_income / CPI * 77
gen net_wealth_1000  = net_wealth/1000
gen real_net_wealth  = net_wealth_1000 / CPI * 77
gen real_net_wealth2 = real_net_wealth^2

*──────── 4. NEW VARIABLES / RECODING ────────────────────────────────*
* 4.1 dependent variable variations
gen log_real_saving   = ln(real_saving + 1)
gen asinh_real_saving = asinh(real_saving)

* 4.2 policy variables
gen byte post = year>2007
gen     interaction = post*type_employment

* 4.3 education recode (combine codes 3&4)           *
recode education (3=4)
label define Ledu 1 "Hauptschule" 2 "Mittlere Reife" 4 "(Fach-)Abitur" 5 "University Degree"
label values education Ledu

* 4.4 vocational training dummy (0 =no, 1 =yes)      *
recode vocational_training (1=0) (2/5=1), gen(voc_train)

* 4.5 female × partner dummy
gen female_partner = gender==2 & living_with_partner==1

* 4.6 saving rate  (real_saving ÷ 12×real_income)
gen saving_rate = real_saving / (real_net_income*12)
replace saving_rate = . if real_net_income ==0



*──────── 6. SAVE THE ANALYTIC SAMPLE ────────────────────────────────*
save "${DATA}/data.dta", replace

log close

