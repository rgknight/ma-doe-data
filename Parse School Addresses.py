import os
from bs4 import BeautifulSoup
import csv
import re

# Note: Source file manually downloaded (not worth figuring out the get

os.chdir('C:/Users/rknight/Documents/GitHub/ma-doe-data')

f = open('data/Public School Address Source.html', 'r')

soup = BeautifulSoup(f)

orgcodes = []
addresses = []

snames = soup.find_all('span', attrs={'class': 'lg'})
for sname in snames:
    orgcode = re.findall('[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]', sname.getText())
    orgcodes.append(orgcode[0])

saddresses = soup.find_all('td', attrs={'class': 'searchindent'})
for saddress in saddresses:
    address = re.findall('(?<=\n)(.+)(?=\n)', saddress.getText())[1].strip()
    addresses.append(address)

assert len(orgcodes) == len(addresses)
output = list(zip(orgcodes, addresses))
header = ['orgcode', 'address']
with open('data/school addresses.csv', 'w', encoding='utf-8') as f:
    writer = csv.writer(f, lineterminator='\n')
    writer.writerow(header)
    for row in output:
        writer.writerow(row)
