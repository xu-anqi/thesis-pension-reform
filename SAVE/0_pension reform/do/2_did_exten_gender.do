/***********************************************************************
                        2_did.do
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


*──────── 0. load cleaned panel ──────────────────────────────────────*
use "${DATA}/data.dta", clear        // produced by 1_append.do


***********************************************
* Extensive Margin: If Savings
***********************************************
* basic
gen log_savings = log(savings)
gen if_savings = (savings > 0)
replace if_savings = . if missing(savings)

gen post = post06
gen interaction = interaction06
drop post06 post07

**********
* avoid compositional change

*** compositional change check
* 1. define cutoff year
local cutoff = 2006

* 2. Compute for each pid their first and last survey year
egen min_year = min(year), by(respid)
egen max_year = max(year), by(respid)

* 3. Create a compositional‐change indicator
gen byte comp_status = .
replace comp_status = 1 if max_year <= `cutoff'-1   // only pre‐reform
replace comp_status = 2 if min_year >= `cutoff'    // only post‐reform
replace comp_status = 3 if max_year >= `cutoff' & min_year <= `cutoff'-1  /// both periods

* 4. Tabulate counts
tab comp_status,m

* 5. keep only balanced heads
 keep if comp_status == 3


* add panel attrition
heckprobit if_savings i.female##i.treated##i.post  ///
    age partner female_partner east_germany /*german*/ nchild hh_size /// demo
    i.education currently_unemployed i.past_employment /// edu + employment
     s05 s06 s07 s08, select (na_era na_exp_econ na_exp_health na_exp_increase_income /// 
	na_exp_unemploy  /// exclusion
	female age i.education /// demo
	) 

	
estimates store heckprobit5

* Is women’s DiD different from men’s DiD?
test 1.post#1.treated#1.female = 0


* --- Coefficient-level (index scale) checks ---
lincom 1.post#1.treated                                  // men’s DiD (index)
lincom 1.post#1.treated + 1.post#1.treated#1.female      // women’s DiD (index)
lincom 1.post#1.treated#1.female                         // diff (women − men)

* --- Probability-level DiDs (what you’ll report) ---
margins female#treated, at(post=(0 1)) predict(pcond)       // pre & post probs
margins, at(post=(0 1)) over(female treated) predict(pcond) post    // “post jump” (pp) by cell
margins, coeflegend

* Women’s post jump (treated) minus women’s post jump (control):
lincom ( _b[2._at#1.female#1.treated] - _b[1._at#1.female#1.treated] ) ///
    - ( _b[2._at#1.female#0.treated] - _b[1._at#1.female#0.treated] )

* Men’s post jump (treated) minus men’s post jump (control):
lincom ( _b[2._at#0.female#1.treated] - _b[1._at#0.female#1.treated] ) ///
    - ( _b[2._at#0.female#0.treated] - _b[1._at#0.female#0.treated] )

* Difference-in-DID (women − men):
lincom ( (_b[2._at#1.female#1.treated] - _b[1._at#1.female#1.treated]) ///
       - (_b[2._at#1.female#0.treated] - _b[1._at#1.female#0.treated]) ) ///
    - ( (_b[2._at#0.female#1.treated] - _b[1._at#0.female#1.treated]) ///
       - (_b[2._at#0.female#0.treated] - _b[1._at#0.female#0.treated]) )



*--------------------- 07 cutoff


*Display Results Side-by-Side

	
esttab  /*heckprobit3 heckprobit4*/ heckprobit5 using "${OUT}/DID_heckprobit_wo_comp.txt", ///
    replace se b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Results") ///
    label stats(ll chi2 rho N, ///
    fmt(2 2 3 0) ///
    labels("Log-Likelihood" "Wald chi2" "Rho" "N"))





