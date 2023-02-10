# -*- coding: utf-8 -*-
"""
Created on Fri Oct 15 23:23:10 2021

@author: hulai
"""

import pandas as pd
import wrds

db = wrds.Connection(wrds_username='lyzhou')
# db.create_pgpass_file()

# get familiar with datasets
db.list_libraries()
db.list_tables('crsp')
db.list_tables('factset_common')
db.describe_table('crsp', 'msf')


# get datasets
temp = db.get_table('crsp', 'ccmxpf_linktable', obs=5)
temp1 = db.get_table('crsp', 'ccmxpf_lnkhist', obs=5)
temp2 = db.get_table('crsp', 'ccmxpf_lnkhist', obs=5)





