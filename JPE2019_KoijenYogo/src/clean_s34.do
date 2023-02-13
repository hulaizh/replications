* information on insitutitions: typecode
import sas using "./data/tfn/s34type1.sas7bdat", case(lower) clear
keep mgrno fdate rdate typecode
compress
save "./temp/s34type1", replace


* information on stocks: header, price shares outstanding
import sas using "./data/tfn/s34type2.sas7bdat", case(lower) clear
gen double mv=prc*shrout1 // in millions
keep fdate cusip prc mv
compress
save "./temp/s34type2", replace


* portfolio holdings by institutions
import sas using "./data/tfn/s34type3.sas7bdat", case(lower) clear
merge m:1 mgrno fdate using "./temp/s34type1", nogen keep(match)
merge m:1 cusip fdate using "./temp/s34type2", nogen keep(match)

gen double dollar_holdings=abs(shares*prc)

rename cusip cusip8

bys cusip8 fdate: egen double tot_hold=sum(dollar_holdings)
replace tot_hold=tot_hold/1000000 // in millions
gen adj = tot_hold/mv if mv < tot_hold
replace adj = 1 if mi(adj)
// replace dollar_holdings=dollar_holdings/adj
* The outlier may come from one inst. -> missing it
gen double shr_hold=dollar_holdings/(tot_hold*1000000)

gen tag = 1 if adj>3
replace tag=1 if (adj>1&adj<=3)&shr_hold>.3
drop if tag==1

* corrected institutional holdings
keep mgrno cusip8 fdate dollar_holdings typecode
compress
save "./temp/s34type3", replace


* calculate household holdings
use "./temp/s34type3", clear
bys cusip8 fdate: egen double tot_hold=sum(dollar_holdings)
keep cusip8 fdate tot_hold
bys cusip8 fdate: keep if _n==1
rename cusip8 cusip
merge 1:1 cusip fdate using "./temp/s34type2"
replace tot_hold=0 if _m==2
gen double dollar_holdings=mv*1000000-tot_hold
replace dollar_holdings=0 if dollar_holdings<0
gen typecode=0
gen mgrno=0
rename cusip cusip8
keep mgrno cusip8 fdate dollar_holdings typecode
compress
save "./temp/household", replace