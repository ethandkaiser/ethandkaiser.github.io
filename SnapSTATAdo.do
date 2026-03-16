cd "/Users/ethankaiser/Desktop/Public Sector Econ/Snap Project"
import delimited using "URBRURDATA_ds172_2010_county.csv", clear
describe
*keeping counties and total and urban population
keep gisjoin state county h7w001 h7w002
*generate urban share
gen urban_share = h7w001 / h7w002
summarize urban_share h7w001 h7w002
save "urban_2010.dta", replace

*now housing values- Key variable is jfje001 = medium home value (dollars)
import delimited "HOUSEVALDATA_ds175_2010_county.csv", clear
keep gisjoin state county jfje001
summarize jfje001
save "houseval_2010.dta", replace

*merge
use "/Users/ethankaiser/Desktop/Public Sector Econ/Snap Project/houseval_2010.dta"
use "urban_2010.dta", clear
merge 1:1 gisjoin using "houseval_2010.dta"
tab _merge
drop if _merge != 3
drop _merge
save "county_base_2010.dta", replace

*z score

use "county_base_2010.dta", clear
egen home_z = std(jfje001)
summarize home_z



*START FROM HERE
*SNAP DATA Jan 2010
import excel "Jan 2010.xls", firstrow clear
describe
rename Jan2010 substate
replace substate = trim(substate)
gen code7 = substr(substate, 1, 7)
gen state_fips  = real(substr(code7, 1, 2))
gen county_fips = real(substr(code7, 3, 3))
rename N snap_jan 
keep state_fips county_fips snap_jan
save "snap_jan_2010.dta", replace
*SNAP data JULY 2010
import excel "JUL 2010.xls", cellrange(A3) firstrow clear
rename Jul2010 substate 
replace substate = trim(substate)
gen code7 = substr(substate, 1, 7)
gen state_fips  = real(substr(code7, 1, 2))
gen county_fips = real(substr(code7, 3, 3))
rename N snap_jul
keep state_fips county_fips snap_jul
save "snap_jul_2010.dta", replace
duplicates report state_fips county_fips
*needed to destring snap data to merge the two files
destring snap_jan, replace ignore(",") force
summarize snap_jan
list state_fips county_fips snap_jan in 1/5
collapse (sum) snap_jan, by(state_fips county_fips)
save "snap_jan_2010_collapse.dta", replace
use "snap_jul_2010.dta", clear
destring snap_jul, replace ignore(",") force
collapse (sum) snap_jul, by(state_fips county_fips)
save "snap_jul_2010_collapse.dta", replace
use "snap_jan_2010_collapse.dta", clear
merge 1:1 state_fips county_fips using "snap_jul_2010_collapse.dta"
tab _merge
drop if _merge ==2
drop _merge
*get avg snap in 2010
gen snap_avg = (snap_jan + snap_jul) / 2
save "snap_2010.dta", replace

*regenerate z-score with County FIPS
use "county_base_2010.dta", clear
describe state county
clear
import delimited "URBRURDATA_ds172_2010_county.csv", clear
keep gisjoin stusab state statea county countya h7w001 h7w002
gen urban_share = h7w002 / h72001
gen urban_share = h7w002 / h7w001
save "urban_2010.dta", replace
clear
import delimited "HOUSEVALDATA_ds175_2010_county.csv", clear
keep gisjoin stusab state statea county countya jfje001
save "houseval_2010.dta", replace
use "urban_2010.dta", clear
merge 1:1 GISJOIN using "houseval_2010.dta"
tab _merge
keep if _merge == 3
drop _merge
merge 1:1 gisjoin using "houseval_2010.dta"
egen home_z = std(jfje001)
save "county_base_2010.dta", replace

*merge z score to SNAP to get real SNAP
use "county_base_2010.dta", clear
rename statea state_fips
rename countya county_fips
describe state_fips county_fips
duplicates report state_fips county_fips 
use "county_base_2010.dta", clear
rename statea state_fips
rename countya county_fips
merge 1:1 state_fips county_fips using "snap_2010.dta"
drop _merge
merge 1:1 state_fips county_fips using "snap_2010.dta"
keep if _merge == 3
drop _merge
save "county_base_snap_2010.dta", replace
use "county_base_snap_2010.dta", clear
*generate REAl SNAP
gen real_snap = snap_avg / home_z

*scatter plots
twoway (scatter snap_avg urban_share) (lfit snap_avg urban_share), xtitle("Urban Population Share") ytitle("Nominal SNAP Issuance (2010)") title("Urban Share vs Nominal SNAP, County Level (2010)")
twoway (scatter real_snap urban_share) (lfit real_snap urban_share), xtitle("Urban Population Share") ytitle("Real SNAP (SNAP / Housing Z-score)") title("Urban Share vs Real SNAP Issuance (2010)")

*binscatter

binscatter real_snap urban_share, line(lfit) xtitle("Urban Share") ytitle("Real SNAP (Adjusted for Housing Market)") title("Urban Share vs Real SNAP Purchasing Power")
binscatter snap_avg urban_share, line(lfit) xtitle("Urban Share") ytitle("Nominal SNAP Issuance (2010)") title("Urban Share vs Nominal SNAP")



*Controls
import delimited "snapcontrols.csv", clear
rename statea state_fips
rename countya county_fips
gen pct_white = ihye002 / ihye001
gen pct_black = ihye003 / ihye001
gen ba_plus = ixme022 + ixme023 + ixme024 + ixme025
gen pct_ba = ba_plus / ixme001
gen poverty_rate = iyte002 / iyte001
gen median_income = i25e001
egen employed = rowtotal(i9ce007 i9ce014 i9ce021 i9ce028 i9ce035 i9ce042 i9ce049 i9ce056 i9ce063 i9ce070 i9ce075 i9ce080 i9ce085 i9ce093 i9ce100 i9ce107 i9ce114 i9ce121 i9ce128 i9ce135 i9ce142 i9ce149 i9ce156 i9ce161 i9ce166 i9ce171)
egen unemployed = rowtotal(i9ce008 i9ce015 i9ce022 i9ce029 i9ce036 i9ce043 i9ce050 i9ce057 i9ce064 i9ce071 i9ce076 i9ce081 i9ce086 i9ce094 i9ce101 i9ce108 i9ce115 i9ce122 i9ce129 i9ce136 i9ce143 i9ce150 i9ce157 i9ce162 i9ce167 i9ce172)
gen labor_force = employed + unemployed
gen employment_rate = employed / labor_force
gen unemployment_rate = unemployed / labor_force
keep gisjoin state_fips county_fips pct_white pct_black pct_ba poverty_rate median_income employment_rate unemployment_rate
save snap_controls_clean.dta, replace

*merge with SNAP
use "/Users/ethankaiser/Desktop/Public Sector Econ/Snap Project/county_base_snap_2010.dta"
merge 1:1 state_fips county_fips using snap_controls_clean.dta
keep if _merge == 3
drop _merge
save "snap_final_2010_controls.dta", replace

reg real_snap urban_share, robust
reg real_snap urban_share pct_white pct_black pct_ba poverty_rate median_income employment_rate unemployment_rate, robust
reg real_snap urban_share pct_white pct_black pct_ba poverty_rate median_income employment_rate unemployment_rate i.state_fips, robust
reg real_snap urban_share pct_white pct_black pct_ba poverty_rate median_income employment_rate unemployment_rate i.county_fips, robust


*summary stats
tabstat real_snap snap_avg urban_share pct_white pct_black pct_ba poverty_rate median_income employment_rate unemployment_rate, stats(mean sd p25 p50 p75)


*needed to readjust real snap for cost of living so I divde nominal snap by county population for snap/capita

gen snap_percap = snap_avg / totalpop

*then I create real snap per capita by dividing snap per capita by median home price

gen real_snap_percap = snap_percap/ medhomeprice

*new summary stats and regressions

tabstat real_snap_percap nominal_snap urban_share pct_white pct_black pct_ba poverty_rate median_income employment_rate unemployment_rate, stats(mean sd p25 p50 p75)

