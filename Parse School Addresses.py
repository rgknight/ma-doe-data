import os
import csv
import re
from bs4 import BeautifulSoup
from geopy import geocoders
import itertools

googleapi = os.environ['GoogleV3_API']
# Note: Source file manually downloaded (not worth figuring out the get
geobing = geocoders.Bing('Ar4KNveNEw0iusi93C-XLWPTIslIoiX4Y26uDb6GPMzqeFmuKHhV1vHCgzktIQ43')
geogoog = geocoders.GoogleV3(api_key=googleapi)

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
    try:
        location = geobing.geocode(address, timeout=10)
        addout = [address, location.latitude, location.longitude]
    except:
        addout = [address, '', '']
    addresses.append(addout)

assert len(orgcodes) == len(addresses)
output = list(zip(orgcodes, addresses))
output_copy = output.copy()

for coderow, addressrow in zip(orgcodes, addresses):
    addressrow.insert(0, coderow)

for row in addresses:
    if row[2] == '':
        print(row[1])
        location = geogoog.geocode(row[1], timeout=10, sensor=False)
        try:
            row[2] = location.latitude
            row[3] = location.longitude
        except:
            print('Address not found')

header = ['orgcode', 'address', 'latitude', 'longitude']

with open('data/address-source/school addresses.csv', 'w', encoding='utf-8') as f:
    writer = csv.writer(f, lineterminator='\n')
    writer.writerow(header)
    for row in addresses:
        writer.writerow(row)

# Closed Charter Addresses
outrows = []
r = open('data/address-source/closed charter school addresses.csv', 'r')
reader = csv.reader(r)
for row in reader:
    if row[0] == 'orgcode':
        continue
    if row[3] == '':
        print(row[2])
        location = geogoog.geocode(row[2], timeout=10, sensor=False)
        try:
            row[3] = location.latitude
            row[4] = location.longitude
        except:
            print('Address not found')
    outrows.append(row)
r.close()


header = ['orgcode', 'school', 'address', 'latitude', 'longitude']
with open('data/address-source/closed charter school addresses.csv', 'w', encoding='utf-8') as f:
    writer = csv.writer(f, lineterminator='\n')
    writer.writerow(header)
    for row in outrows:
        writer.writerow(row)

# Closed BPS addresses
outrows = []
r = open('data/address-source/closed BPS school addresses.csv', 'r')
reader = csv.reader(r)
for row in reader:
    if row[0] == 'orgcode':
        continue
    if row[3] == '':
        print(row[2])
        location = geogoog.geocode(row[2], timeout=10, sensor=False)
        try:
            row[3] = location.latitude
            row[4] = location.longitude
        except:
            print('Address not found')
    outrows.append(row)
r.close()

header = ['orgcode', 'school', 'address', 'latitude', 'longitude']
with open('data/address-source/closed BPS school addresses.csv', 'w', encoding='utf-8') as f:
    writer = csv.writer(f, lineterminator='\n')
    writer.writerow(header)
    for row in outrows:
        writer.writerow(row)


