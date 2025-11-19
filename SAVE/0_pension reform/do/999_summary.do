/***********************************************************************

         mirrors: part of 1_clean data.R 2_ sample.R => summary

***********************************************************************/

*─────────────────────  house-keeping  ───────────────────────────────*
clear all
set more off
capture log close

*── paths (adjust ~ if you run from Windows) ──────────────────────────
global DIR       "~/Desktop/thesis/data/SAVE/0_pension reform"
global DATA      "$DIR/data"
global OUT       "$DIR/output"
global LOG       "$DIR/log"

log using "${OUT_LOG}/3_summary.log", replace


*─────────────────────  3. quick data audit  ─────────────────────────
use "${DATA}/data.dta", clear

file open audit using "${OUT}/combined_data_summary.txt", write replace
file write audit "***** Missing-value count *****" _n
quietly ds
foreach v of varlist `r(varlist)' {
    qui count if missing(`v')
    file write audit "`v' : " r(N) _n
}

file write audit _n "***** Frequency / summary *****" _n _n
foreach v of varlist `r(varlist)' {
    file write audit "--- `v' ---" _n
    capture confirm numeric variable `v'
    if !_rc {
        summarize `v', detail
        file write audit "N=" r(N) "  mean=" r(mean) "  p50=" r(p50) "  SD=" r(sd) _n _n
    }
    else {
        tabulate `v', missing
        file write audit _n
    }
}
file close audit
display "Summary saved to ${OUT}/combined_data_summary.txt"


*─────────────────────  4. descriptive stats by year  ─────────────────
preserve
contract year, freq(total_count)
tempfile counts
save "`counts'"

* female share
bysort year: gen female = gender==2
collapse (count) female= female ///
         (mean)  mean_age=age, by(year)
merge 1:1 year using "`counts'", nogen

gen female_pct  = female / total_count
gen married_pct = .
bysort year: egen married_total = total(married)
replace married_pct = married_total / total_count
keep year total_count mean_age female_pct married_pct
order year total_count mean_age female_pct married_pct
format female_pct married_pct %9.2fc

export excel using "${OUT_OUTPUT}/descriptive_statistics_by_year.xlsx", ///
       sheet("stats") firstrow(variables) replace
restore

*─────────────────────  5. plot expected retirement age  ─────────────
twoway (line exp_retire_age year if gender==1, lwidth(medthick)) ///
       (line exp_retire_age year if gender==2, lpattern(dash) lwidth(medthick)), ///
       legend(order(1 "Male" 2 "Female")) ///
       ytitle("Expected retirement age") xtitle("Year") ///
       xline(2007, lpattern(dot) lcolor(red)) ///
       title("Expected Retirement Age, by Gender")

graph export "${OUT}/expected_retirement_age_by_gender.png", width(2400) replace



*──────── 5. QUICK SUMMARIES (analogous to tables/plots) ─────────────*
tab employ_pct, m
tab type_employment, m
tab bi birthyr, m         // etc. – add any tabs you need

* mean real income & saving by year (for later graph) *
collapse (mean) mean_income=real_net_income mean_sav=real_saving, by(year)
twoway (bar mean_income year, barw(.8)) ///
      (bar mean_sav year, barw(.4) blcolor(gs14) fcolor(gs14%60) ///
       legend(order(1 "Income" 2 "Saving")) ///
       xtitle("Year") ytitle("Euro (real, 2000=100)")), ///
      title("Mean real income & saving")
graph export "${OUT}/income_saving_bar.png", width(2400) replace
restore   // return to full data if you collapse
