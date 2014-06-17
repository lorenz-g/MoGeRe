import re


patterns = ['/sample/([0-9]+)(/.json)?',
            '/sample/([0-9]+)(?:\/.json)?',
            '/json_models/(\w){1,}(/.json)?',
            '/json_models/(\w){1,}'
            
            ]

strings = ["/sample/4980856393302016",
           "/sample/4980856393302016/.json",
           "/sample/4980856393302016/.jsonee",
           "/saample/4980856393302016/.jsonee",
           "/json_models/abc.json",
           "/json_models/abc",



         ]

for p in patterns:
    for s in strings:   
        if re.match(p, s):
            print p, " machtes ", s
        else:
            print p," does NOT match ", s


