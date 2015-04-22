import requests
import os
from bs4 import BeautifulSoup
import csv

os.chdir('C:/Users/rknight/Documents/GitHub/ma-doe-data')

modes = ['school']
years = list(range(1996, 2015+1))

for mode in modes:
    for year in years:
        url = 'http://profiles.doe.mass.edu/state_report/enrollmentbygrade.aspx?mode={0}&year={1}&Continue.x=11&Continue.y=9&export_excel=yes'.format(mode, year)

        r = requests.get(url)

        soup = BeautifulSoup(r.text)

        table = soup.find('table')
        rows = []
        for row in table.find_all('tr'):
            rows.append([val.getText() for val in row.find_all('td')])

        with open('data/enrollmentbygrade/enrollmentbygrade {0} {1}.csv'.format(mode, year), 'w', encoding='utf-8') as f:
            writer = csv.writer(f, lineterminator='\n')
            writer.writerows(rows)
            