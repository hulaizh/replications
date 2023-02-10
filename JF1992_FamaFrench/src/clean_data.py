# -*- coding: utf-8 -*-
"""
Created on Fri Aug  6 22:03:17 2021

@author: Hulai
"""

import pandas as pd
import wrds

db = wrds.Connection(wrds_username='lyzhou')



db.list_libraries()
db.list_tables('crsp')




fund_style = db.get_table(library='crsp_q_mutualfunds',table='fund_style',obs=5)
fund_sum = db.get_table(library='crsp_q_mutualfunds',table='fund_summary',obs=5)
fund_sum2 = db.get_table(library='crsp_q_mutualfunds',table='fund_summary2',obs=5)


s12 =

# set sample date range
begdate = '03/01/2015'
enddate = '12/31/2017'

# sql similar to crspmerge macro

crsp_m = db.raw_sql("""
                      select a.permno, a.date,
                      a.ret, a.vol, a.shrout, a.prc, a.cfacpr, a.cfacshr
                      from crsp.msf as a
                      left join crsp.msenames as b
                      on a.permno=b.permno
                      and b.namedt<=a.date
                      and a.date<=b.nameendt
                      where a.date between '{begdate}' and '{enddate}'
                      and b.shrcd between 10 and 11
                      """, date_cols=['date'])





