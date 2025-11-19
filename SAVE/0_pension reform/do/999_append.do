/***********************************************************************

            CLEAN & APPEND SAVE 2001–2013  (Stata version)
            ----------------------------------------------------------------
            mirrors: 1_clean data.R 
            author :  anqi
            date   :  25 Apr 2025
***********************************************************************/

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

log using "${OUT_LOG}/1_append.log", replace

*─────────────────────  1. merge all waves  ──────────────────────────
local wanted respid year wave                                    ///
             f06s f07o f08s f09s f10s f12s f13o f14o f18o        ///
             f20s1 f21s1 f22s1 f24s1 fg1s1                       ///
             f43o f44j f44m f45o f46g4 f53m1_a f54o              ///
             f60_61 f60_61_2 f62o f66_70 f68o f70o

local files  2001/STATA/ZA4051_1.dta ///
             2003-04/STATA/ZA4436_1.dta ///
             2005/STATA/ZA4437_1_v5-0-0.dta ///
             2006/STATA/ZA4521_1.dta ///
             2007/STATA/ZA4740_1.dta ///
             2008/STATA/ZA4970_1.dta ///
             2009/STATA/ZA5230_1.dta ///
             2010/STATA/ZA5292_1_v1-0-0.dta ///
             2011-12/STATA/ZA5635_1_v1-0-0.dta ///
             2013/STATA/ZA5647_1_v1-0-0.dta

tempfile master
local first 1

foreach f of local files {
    use "${IN_DATA}/`f'", clear

    /** 1. Strip _imp suffix everywhere ------------------------------ **/
    ds *_imp
    foreach v of varlist `r(varlist)' {
        local new = subinstr("`v'","_imp","",.)
        rename `v' `new'
    }

    /** 2. Make sure every wanted variable exists -------------------- **/
    foreach v of local wanted {
        capture confirm variable `v'
        if _rc generate `v' = .   // numeric placeholder (use "" if string)
    }

    /** 3. Keep just the variables we care about -------------------- **/
    keep `wanted'

    /** 4. Stack onto the growing master file ----------------------- **/
    if `first' {
        save "`master'", replace
        local first 0
    }
    else {
        append using "`master'"
        save  "`master'", replace
    }
}

save "${OUT_DATA}/combined.dta", replace


*─────────────────────  2. refactor & label  ─────────────────────────
use "${OUT_DATA}/combined.dta", clear

*—— variable labels
label var respid  "Respondent ID"
label var year    "Year"
label var wave    "Wave"
label var f06s    "Gender"
label var f07o    "Year of Birth"
label var f08s    "German Citizen"
label var f09s    "Marital Status"
label var f10s    "Living with Partner"
label var f12s    "Has Children"
label var f13o    "Number of Children"
label var f14o    "Children in Household"
label var f18o    "Household Size"
label var f20s1   "Education"
label var f21s1   "Vocational Training"
label var f22s1   "Employment %"
label var f24s1   "Type of Employment"
label var fg1s1   "Self-assessed Health"
label var f43o    "Aspired Savings"
label var f44j    "Target Year (rel)"
label var f44m    "Target Month"
label var f45o    "Realised Savings, last yr"
label var f46g4   "Reason: Old-age provision"
label var f53m1_a "Receives wages/salary"
label var f54o    "Total Net Income"
label var f60_61  "Retired"
label var f60_61_2 "Partner retired"
label var f62o    "Expected Retirement Age"
label var f66_70  "Net Wealth"
label var f68o    "Real-estate assets"
label var f70o    "Non-real-estate assets"

*—— rename variables (preserves labels) ———————————————
rename f06s  gender
rename f07o  birthyr
replace birthyr = 1900 + birthyr

rename f08s  german
rename f09s  marital_status
gen married = inlist(marital_status, 1, 2)

rename f10s  living_with_partner
rename f12s  has_children
rename f13o  n_child
rename f14o  n_child_hh
rename f18o  hh_size
rename f20s1 education
rename f21s1 vocational_training
rename f22s1 employ_pct
rename f24s1 employ_type
rename fg1s1 health_self
rename f43o  asp_sav_amt

rename f44j  asp_year
replace asp_year = asp_year + 2000

rename f44m  asp_month
rename f45o  realised_sav
rename f46g4 reason_old_age
rename f53m1_a wageincome_yesno
rename f54o  tot_net_income
rename f60_61  retired
rename f60_61_2 partner_retired
rename f62o  exp_retire_age
rename f66_70 net_wealth
rename f68o  real_estate_asset
rename f70o  non_real_asset


*—— recode categorical variables with value labels
label define Lgender   1 "Male" 2 "Female"
label values gender Lgender

label define Lyesno 1 "Yes" 2 "No"
label values german Lyesno
label values living_with_partner Lyesno
label values has_children Lyesno
label values retired Lyesno
label values partner_retired Lyesno

label define Lmarital 1 "Married" 2 "Separated" 3 "Single" 4 "Divorced" 5 "Widowed" 9 "Missing"
label values marital_status Lmarital

label define Lhealth 1 "Very good" 2 "Good" 3 "Mediocre" 4 "Bad" 5 "Very bad"
label values health_self Lhealth

label define Lemploypct 1 "Full-time" 2 "Part-time" 3 "Marginal" 4 "Occasional" 5 "Not employed"
label values employ_pct Lemploypct

label define Lreason 1 "Completely unimportant" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" ///
                     7 "7" 8 "8" 9 "9" 10 "Very important"
label values reason_old_age Lreason

*—— calculate age
gen age = year - birthyr

*—— net wealth fallback if missing
replace net_wealth = real_estate_asset + non_real_asset if missing(net_wealth)



save, replace






log close

