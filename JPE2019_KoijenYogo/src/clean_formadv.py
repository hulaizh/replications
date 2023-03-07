# -*- coding: utf-8 -*-
import zipfile
import pandas as pd
from pathlib import Path

cwd = Path.cwd()
dir_adv = Path('data/form adv')

#  unzip all downloaded zip files
# for file in dir_adv.glob('*.zip'):
#     fn = cwd.joinpath(file)
#     with zipfile.ZipFile(fn, 'r') as f:
#         f.extractall(dir_adv)

# all files to append
file_list = []
for ex in ['*.csv', '*.xlsx', '*.txt']:
    for file in dir_adv.glob(ex):
        file_list.append(str(file))
file_list = [x for x in file_list if 'README' not in x]

# empty dataframe
ADV = pd.DataFrame()

# try first one
file = '2009-12-1 IA FOIA Download.csv'
fn = dir_adv.joinpath(file)
# df = pd.read_excel(zip.ZipFile(fn).open(name))
df = pd.read_csv(fn, low_memory=False, encoding='unicode_escape')
df1 = df[['Primary Business Name', 'Legal Name']]
df2 = df.filter(like='Effective Date')
df = df1.join(df2)
ADV = ADV.append(df)

# Form ADV registered investment advisers
for file in file_list:
    print(file)
    fn = cwd.joinpath(file)
    if file.endswith('.xlsx'):
        df = pd.read_excel(fn)
    elif file.endswith('.csv'):
        df = pd.read_csv(fn, low_memory=False, encoding='unicode_escape')
    elif file.endswith('.txt'):
        df = pd.read_csv(fn, delimiter='|', low_memory=False, encoding='unicode_escape', on_bad_lines='skip')
    try:
        df1 = df[['Primary Business Name', 'Legal Name']]
        df2 = df.filter(like='Effective Date')
        df = df1.join(df2)
        ADV = ADV.append(df)
    except:
        print(file + ': Fail')

# drop duplicates
ADV.drop_duplicates()

# save ADV
file = 'Form ADV.csv'
fn = dir_adv.joinpath(file)
ADV.to_csv(fn, index=False)

# file = '4006782_10044_00050000_00050000.txt'
# fn = dir_adv.joinpath(file)
# df = pd.read_csv(fn, delimiter='|', low_memory=False, encoding= 'unicode_escape',on_bad_lines='skip')
