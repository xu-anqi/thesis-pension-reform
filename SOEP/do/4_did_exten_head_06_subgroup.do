cap log close
clear all
set more off

***********************************************
* Set relative paths to the working directory
***********************************************
global DIR "D:\thesis\data\SOEP"
global AVZ "$DIR/reform analysis"
global IN_DATA "$DIR/exercise/soepdata/"

*global AVZ 	"/Users/angelxu/Desktop/thesis/data/SOEP/reform analysis"
*global IN_DATA "/Users/angelxu/Desktop/thesis/data/SOEP/exercise/soepdata/"
global DO_FILES "$AVZ/do/"
global OUT_LOG "$AVZ/log/"
global OUT_DATA "$AVZ/data/"
global OUT_OUTPUT "$AVZ/output/9_subgroup/"

*log using "${OUT_LOG}4_did_exten_head_06.log", replace


***********************************************
* Extensive Margin: If Savings
***********************************************
use "${OUT_DATA}data_head.dta", clear


* To be consistent with GSOEP, use only year 2003-2009
* keep if (syear >= 2005) & (syear <=2009)
 keep if (syear >= 2003) & (syear <=2010)
*


* Generate Post-Reform Indicator
gen post = (syear >= 2006)

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




gen interaction2 = interaction*female

*** Probit Model
//probit if_savings interaction post type_employment, robust
//estimates store probit
probit if_savings interaction2 interaction post type_employment, cluster(hid)
estimates store probit1
estpost margins, dydx(interaction)
estimates store ame1


probit if_savings interaction2 interaction post type_employment female age age_square i.migback ///
	hh_size nchild, cluster(hid)
estimates store probit2
estpost margins, dydx(interaction)
estimates store ame2


probit if_savings interaction2 interaction post type_employment female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree, cluster(hid)
estimates store probit3
estpost margins, dydx(interaction)
estimates store ame3



probit if_savings interaction2 interaction type_employment i.female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, cluster(hid)
estimates store probit4
estpost margins i.female, dydx(interaction)
estimates store ame4





probit if_savings i.post##i.type_employment##i.female age age_square i.migback ///
	hh_size nchild full_time years_employ education_years vocational_degree i.syear, cluster(hid)
estimates store probit4

test 1.post#1.type_employment#1.female    
margins i.female, dydx(female)


estimates store ame4



* 2) 给出男女各自的 DiD 概率效应（更好解释）
margins i.female, dydx(post#treated)



/* fixed effect fails for probit model
xtprobit if_savings interaction nchild full_time years_employ education_years ///
	vocational_degree, fe
estimates store probit5
*/

* Display Results Side-by-Side
esttab probit1 probit2 probit3 probit4 using "${OUT_OUTPUT}did_if_savings_probit_subgroup.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Extensive Margin: Effect of the 2006 Pension Reform on Savings (Probit) 06 cut-off") ///
    label stats(ll r2_p N, fmt(2 3 0) labels("Log-Likelihood" "Pseudo R-squared" "N"))

	
esttab ame1 ame2 ame3 ame4 using "${OUT_OUTPUT}ame_probit_subgroup.txt", ///
    replace b(3) se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Average Marginal Effects (Probit Models)") ///
    label nodepvars nonumber





