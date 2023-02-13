clear all

global lpath "D:\replications\JPE2019_KoijenYogo"
cd "$lpath"
cap mkdir "temp"


** clean data
quietly do "$src/clean_crsp.do"
quietly do "$src/clean_s34.do"

** analyze data
 

 
 
** delete temp folder
// rmdir "temp"