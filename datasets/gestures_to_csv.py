from __future__ import division
import os
import json
import urllib2
import csv

""" This script downloads one big Json object containing multiple gestures either from the
local server of from accelldatacollect.appspot.com. 
It then creates a csv file for each data recorded in the format:


Note: It and creates a tRel variable that is just in seconds from the start
instead of the epoch time in ms. 

Diffeent URLs can be used:

Secure mode means that data can only be from Iphone with 6.1 opering sytem :)

fetches the last 15 elements in secure mode. 
"http://localhost:8080/downloadGestures?secure=1&fetch=15"

#in case the json gets too big, it is prob. best to query individual users.
"http://localhost:8080/downloadGestures?user=L1"
"http://localhost:8080/downloadGestures?secure=1&user=L1"
 "http://www.acceldatacollect.appspot.com/downloadGestures?user="+ u_name + "&secure=1"

User has priority over fetch, in case they are combined...
"""


### PARAMS
u_name = "L3"
url = "http://localhost:8080/downloadGestures?user=" + u_name
csvDir = "csvDataNew/"
os.mkdir(csvDir)


### SCRIPT
print url
d = json.load(
    urllib2.urlopen(url, timeout=5.5))

# save the entire json file...
with open(csvDir + '/all_json.json', 'w') as outfile:
  json.dump(d, outfile)


for i in d:
    print "User:",  i["user"], "\t G", i["gesture"]

# loop through the data
for i in d:
    print i["user"]

    # loop through each repetion. 
    for dP in i["repetitions"]:

        # format the filename correctly
        if len(i["user"]) == 0:
            csvuser = "NN"
        elif len(i["user"]) == 1:
            csvuser = "Y" + i["user"][0]
        elif len(i["user"]) == 2:
            csvuser = i["user"]
        elif len(i["user"]) > 2:
            csvuser = i["user"][0:2]  

        if dP["rep"] > 9:
            csvrep = str(dP["rep"])
        else:
            csvrep = "0" + str(dP["rep"])
        
        # select only the first two letters
        csvgest = i["gesture"][0:2]

        csvname = "g" + csvgest + "_" + csvuser + "_t" + csvrep + ".csv"

         # convert the abolute time to relative times in seconds   
        tRel = []
        for item in dP["t"]:
           tRel.append((item - dP["t"][0]) / 1000)


        with open(csvDir + csvname, 'wb') as csvfile:
            w = csv.writer(csvfile)
            #if dP["alpha"] != []:
            w.writerow(["t", "tRel", "x", "y", "z", "alpha", "beta", "gamma"])
            
            for j in range(len(dP["t"])):
                w.writerow([dP["t"][j] , tRel[j], dP["x"][j],
                             dP["y"][j] , dP["z"][j], dP["alpha"][j],
                             dP["beta"][j], dP["gamma"][j]]) 




