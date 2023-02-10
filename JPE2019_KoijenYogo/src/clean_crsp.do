*********************
* CRSP
* full set monthly returns
import sas using "$data/crsp/msenames.sas7bdat", case(lower) clear

keep if inlist(shrcd,10,11)
keep if inlist(exchcd,1,2,3)
replace siccd=. if siccd==0
format namedt nameendt %td
keep permno namedt nameendt siccd ncusip ticker exchcd
* replace missing ulinkenddt with today
gen t="$S_DATE"
gen t1=date(t, "DMY")
format t1 %td
replace nameendt=t1 if mi(nameendt)
drop t t1

sort permno namedt nameendt, stable
gen gap=nameendt-namedt+1
expand gap
bys permno namedt nameendt: gen date=namedt+_n-1
format date %td

gen ym=mofd(date)
format ym %tm
sort permno ym date
by permno ym: keep if _n==_N
keep permno ym ncusip ticker siccd exchcd
compress
save msenames, replace


** delisted returns
import sas using "$data/crsp/msedelist.sas7bdat", case(lower) clear
replace dlret=-.3 if mi(dlret)&( inlist(dlstcd,500,520,580,584)|(dlstcd>=551&dlstcd<=574))
replace dlret=-1 if mi(dlret)
gen ym=mofd(dlstdt)
format ym %tm
keep permno ym dlret
compress
save msedelist, replace


** monthly returns
import sas using "$data/crsp/msf.sas7bdat", case(lower) clear
gen ym=mofd(date)
format ym %tm
keep permco permno ym ret prc shrout vol hsiccd cfacpr cfacshr
replace prc=abs(prc)
merge 1:1 permno ym using msedelist

replace ret=dlret if _m==3
drop _m

merge 1:1 permno ym using msenames.dta, nogen keep(match)

replace siccd=hsiccd if mi(siccd)
replace siccd=. if siccd==0

gen me=abs(prc*shrout)/1000 // in millions

bys permco ym: egen me_comp=sum(me)

keep permco permno ym ret prc shrout vol siccd exchcd cfacpr cfacshr ncusip ticker me me_comp
compress
save msf, replace