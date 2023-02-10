* information on insitutitions: typecode
import sas using "$data/tfn/s34type1.sas7bdat", case(lower) clear
keep mgrno fdate rdate
compress
save s34type1, replace


* information on stocks: header, price shares outstanding
import sas using "$data/tfn/s34type2.sas7bdat", case(lower) clear
gen double mv=prc*shrout1 // in millions
keep fdate cusip prc mv
compress
save s34type2, replace


* portfolio holdings by institutions
import sas using "$data/s34/s34type3.sas7bdat", case(lower) clear
merge m:1 mgrno fdate using s34type1, nogen keep(match)
merge m:1 cusip fdate using s34type2, nogen keep(match)

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

keep mgrno cusip8 fdate dollar_holdings
compress
save s34type3, replace


*********
* stock returns to merge
* DGTW adjusted returns
use dgtw_vwret, clear
tsset dgtw_port ym
gen logret=log(dgtw_vwret+1)
tsegen double dgtw_retq_fwd=rowtotal(F(1/3).logret,1)
replace dgtw_retq_fwd = exp(dgtw_retq_fwd) - 1
keep dgtw_port ym dgtw_retq_fwd
save temp, replace

* raw returns
use permno ncusip ym siccd prc ret me carbon energy ff48 using msf, clear
destring, replace

merge 1:1 permno ym using dgtw_port.dta, nogen keep(master match)
merge m:1 dgtw_port ym using temp.dta, nogen keep(master match)

gen logret=log(ret+1)
tsset permno ym
tsegen double retq_fwd = rowtotal(F(1/3).logret,1)
replace retq_fwd=exp(retq_fwd)-1

keep ncusip ym siccd prc retq_fwd dgtw_port dgtw_retq_fwd me carbon energy ff48
drop if mi(ncusip, ym)
rename ncusip cusip8
save temp, replace
*********

use s34type3, clear
gen ym=mofd(fdate)
format ym %tm
merge m:1 cusip8 ym using temp.dta, nogen keep(match)

keep mgrno cusip8 fdate prc retq_fwd  dgtw_port dgtw_retq_fwd siccd dollar_holdings carbon energy ff48
compress
save s34, replace



* quarterly holdings
use msf, clear
keep ncusip ym ret
drop if mi(ncusip)
rename ncusip cusip8
save t1, replace
*
use s34type3, clear
gen ym=mofd(fdate)
format ym %tm
merge m:1 cusip8 ym using t1.dta, keep(match)
gen yq=qofd(fdate)
format yq %tq
keep mgrno cusip8 yq dollar_holdings
sort mgrno yq cusip8
compress
save s34_q, replace



 
 
****************************
* monthly holdings: keep the lastest quarterly holdings to m+1 m+2 m+3
use temp, clear
keep cusip8 ym retq_fwd dgtw_port dgtw_retq_fwd
save temp, replace


use s34type3, clear
keep mgrno fdate
duplicates drop
gen yq=qofd(fdate)+1
format yq %tq
gen n=3
expand n
sort mgrno fdate yq
by mgrno fdate: gen ym=mofd(dofq(yq))+_n-1
format ym %tm
keep mgrno ym fdate
joinby mgrno fdate using s34type3.dta
keep mgrno ym fdate cusip8 dollar_holdings
save t1, replace

* shares adjusted
use msf, clear
keep ncusip ym cfacshr cfacpr
drop if mi(ncusip, ym)
rename ncusip cusip8
save temp1, replace

*
use ncusip ym ff48 using msf, clear
rename ncusip cusip8
drop if mi(cusip8, ym)
save t1_msf, replace

use t1, clear
rename ym rym
gen ym=mofd(fdate)
merge m:1 cusip8 ym using temp1.dta, keep(master match) nogen
rename cfacshr cfacshr0
rename cfacpr cfacpr0
replace ym=rym-1
merge m:1 cusip8 ym using temp1.dta, keep(master match) nogen
rename cfacshr cfacshr1
rename cfacpr cfacpr1
gen dollar_holdings_adj=dollar_holdings*(cfacshr1/cfacshr0)*(cfacpr1/cfacpr0)
replace dollar_holdings_adj=dollar_holdings if mi(dollar_holdings_adj)
replace ym=rym
merge m:1 cusip8 ym using t1_msf.dta, nogen keep(match)
merge m:1 cusip8 ym using temp.dta, nogen keep(match)
keep mgrno fdate rym dollar_holdings_adj cusip8 ff48 retq_fwd dgtw_port dgtw_retq_fwd
sort mgrno rym cusip8
compress
save s34type3_m, replace



****************************
* monthly holdings: keep the lastest quarterly holdings to m+1 m+2
use msf, clear
keep ncusip ym ret
drop if mi(ncusip)
rename ncusip cusip8
save t1, replace

*
use s34type3, clear
gen ym=mofd(fdate)+1
format ym %tm
merge m:1 cusip8 ym using t1, keep(match) nogen
gen double dollar_holdings_adj=dollar_holdings*(1+ret)
keep mgrno cusip8 ym dollar_holdings_adj
rename dollar_holdings_adj dollar_holdings
compress
save s34_m1, replace

*
use s34type3, clear
gen ym=mofd(fdate)+1
format ym %tm
merge m:1 cusip8 ym using t1, keep(master match) nogen
rename ret ret1
replace ym=ym+1
merge m:1 cusip8 ym using t1, keep(master match) nogen 
rename ret ret2
gen double dollar_holdings_adj=dollar_holdings*(1+ret1)*(1+ret2)
keep mgrno cusip8 ym dollar_holdings_adj
rename dollar_holdings_adj dollar_holdings
drop if mi(dollar_holdings)
compress
save s34_m2, replace

*
use s34type3, clear
gen ym=mofd(fdate)
format ym %tm
drop fdate
append using s34_m1
append using s34_m2
merge m:1 cusip8 ym using t1.dta, keep(master match)
keep if _m==3
keep mgrno cusip8 ym dollar_holdings
sort mgrno ym cusip8
compress
save s34_m, replace

cap erase s34_m1 
cap erase s34_m2







