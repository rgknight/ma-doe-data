import os
import csv
import re
from bs4 import BeautifulSoup
from geopy.geocoders import Nominatim
import itertools

# Note: Source file manually downloaded (not worth figuring out the get

os.chdir('C:/Users/rknight/Documents/GitHub/ma-doe-data')

f = open('data/Public School Address Source.html', 'r')

soup = BeautifulSoup(f)

orgcodes = []
addresses = []
geolocator = Nominatim()

snames = soup.find_all('span', attrs={'class': 'lg'})
for sname in snames:
    orgcode = re.findall('[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]', sname.getText())
    orgcodes.append(orgcode[0])

saddresses = soup.find_all('td', attrs={'class': 'searchindent'})
for saddress in saddresses:
    address = re.findall('(?<=\n)(.+)(?=\n)', saddress.getText())[1].strip()
    try:
        location = geolocator.geocode(address, timeout=10)
        addout = [address, location.latitude, location.longitude]
    except:
        addout = [address, '', '']
    addresses.append(addout)

assert len(orgcodes) == len(addresses)
output = list(zip(orgcodes, addresses))
output = list(zip(testb, testa))
header = ['orgcode', 'address', 'latitude', 'longitude']
with open('data/school addresses.csv', 'w', encoding='utf-8') as f:
    writer = csv.writer(f, lineterminator='\n')
    writer.writerow(header)
    for coderow, addressrow in zip(orgcodes, addresses):
        addressrow.insert(0, coderow)
        writer.writerow(addressrow)
