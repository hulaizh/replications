*********************
* link CRSP with Compustat
import sas using "./data/crsp/ccmxpf_lnkused.sas7bdat", clear case(lower)	
keep if inlist(ulinktype,"LU","LC")
keep if usedflag==1
rename ugvkey gvkey
destring gvkey, replace
rename upermno permno

gen t="$S_DATE"
gen t1=date(t, "DMY")
format t1 %td
replace ulinkenddt=t1 if mi(ulinkenddt)

keep gvkey permno ulinkdt ulinkenddt
format ulinkdt ulinkenddt %td
compress
save "./temp/ccmxpf_lnkused", replace


***********************************
* clean compustat: get book equity, annually
import sas using "./data/comp/funda.sas7bdat", clear case(lower)	

keep if indfmt=="INDL"
keep if datafmt=="STD"
keep if popsrc=="D"
keep if consol=="C"
	
destring gvkey, replace

gen year=year(datadate)
sort gvkey year datadate, stable
by gvkey year: keep if _n==_N


* book equity
gen pref=pstkrv
replace pref=pstkl if mi(pref)
replace pref=pstk if mi(pref)
replace pref=0 if mi(pref)

replace txdb=0 if mi(txdb)
replace itcb=0 if mi(itcb)

gen be=seq+txdb+itcb-pref
replace be=. if be<0

keep gvkey datadate be sich
format datadate %td

save temp/t1, replace


use temp/t1, clear

joinby gvkey using "./temp/ccmxpf_lnkused"
keep if datadate>=ulinkdt&datadate<=ulinkenddt
drop ulinkdt ulinkenddt

save "./temp/funda", replace




***********************************
* clean compustat: get book equity, quarterly
import sas using "./data/comp/fundq.sas7bdat", clear case(lower)	

keep if indfmt=="INDL"
keep if datafmt=="STD"
keep if popsrc=="D"
keep if consol=="C"
	
destring gvkey, replace

gen year=year(datadate)
sort gvkey year datadate, stable
by gvkey year: keep if _n==_N


* book equity
gen pref=pstkrv
replace pref=pstkl if mi(pref)
replace pref=pstk if mi(pref)
replace pref=0 if mi(pref)

replace txdb=0 if mi(txdb)
replace itcb=0 if mi(itcb)

gen be=seq+txdb+itcb-pref
replace be=. if be<0

keep gvkey datadate be sich
format datadate %td

save temp/t1, replace


use temp/t1, clear

joinby gvkey using ccmxpf_lnkused.dta
keep if datadate>=ulinkdt&datadate<=ulinkenddt
drop ulinkdt ulinkenddt

save fundq, replace