clear all

global lpath "D:\Replication\JPE2019_KoijenYogo"
global src "$lpath/src"
global data "$lpath/data"

cd "$lpath/temp"



** clean data
quietly do "$src/clean_crsp.do"
quietly do "$src/clean_s34.do"

** analyze data
 
