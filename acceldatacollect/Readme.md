
### Comments on using the new ndb Datastore



### Run the project locally from console

 	dev_appserver.py --host=0.0.0.0 acceldatacollect

the --host makes it available to all devices in local network...

### Deploy the project from console

	appcfg.py --no_cookies --email=lorenz.roman.gruber@gmail.com --passin update


### 5.5.14 Testing the continuous recognizer:

- Problem: The model likelihoods are lower when the sample is longer.
The is the nature of the forward as the longer the sequence is, the less likely it will become. 
Hence onece the sequence is larger than the noise_th, if it is just above the noise threshold its
ll will be quite high for any of the gestures. 

- Hence setting a ll threshold to find out whether a gesture works or not does not really make sense. 

- one possiblity would to not filter the data. The each sequence on which the forward algorithm is evaluated should have the same 




### the sampleData object for the gestureCollect page:
sampleData
Object {origSampleFrequ: 60, startTime: 1396897906944, repetitions: Array[3], gesture: "1", user: ""}
	gesture: "1"
	origSampleFrequ: 60
	repetitions: Array[3]
		0: Object
		alpha: Array[121]
		beta: Array[121]
		gamma: Array[121]
		rep: 0
		t: Array[121]
		x: Array[121]
		y: Array[121]
		z: Array[121]
		__proto__: Object
		1: Object
		2: Object
		length: 3
		__proto__: Array[0]
	startTime: 1396897906944
	user: ""


### Problem with incorrect sampling times:

At the moment, the sampling takes too long. 

Small error:
- the total duration measures by endTime - startTime variables that are passed in the json string 
is marginally longer that measuring t[-1] - t[0]. 

In the example (on the local machine)
5073077931081728 
endTime - startTime = 9780 ms
t[-1] - t[0] = 9521 ms

Number of samples: 227
f sample 1 = 227 / 9.780s = 23.2106 Hz 
f sample 2 = 227 / 9.521 = 23.842 Hz

Decision: on the server, go back to measuring the duration with t[-1] - t[0]


Data collection Time:
gyro.startTracking(function(acel) {
	var t = new Date().getTime();
	sampleData.dataPoints.t.push(t);
	...
	sampleData.dataPoints.gamma.push(acel.gamma);
	sampleID = sampleID + 1;
	var t2 = new Date().getTime(); 
	console.log( "data collection took:");
	console.log(t2 - t);

This code was added at the bottom of the collection loop. 
This result is indifferent from the sampling freq selected...
The result was:
	[Log] data collection took: 
	[Log] 0 
	[Log] data collection took: 
	[Log] 0 
	[Log] data collection took: 
	[Log] 1 
	[Log] data collection took: 
	[Log] 1 
	[Log] data collection took: 
	[Log] 1 
	[Log] data collection took: 
	[Log] 0 
All those values are in ms. Hence it meanse that on average it takes 0.5 ms which is insignificant. 


#### Measure the delay from gyro.js to the dataCollect.html

in gyro.js, added a timeing value:
	gyro.startTracking = function(callback) {
		interval = setInterval(function() {
			var t = new Date().getTime();
			console.log( "in gyro.js, t im ms:");
			console.log(t);
			callback(measurements);
		}, gyro.frequency);
	};

in dataCollect.html
	gyro.startTracking(function(acel) {
		var t = new Date().getTime();
		console.log( "in dataCollect.html, t im ms:");
		console.log(t);
		sampleData.dataPoints.t.push(t);
		...
		sampleID = sampleID + 1;
	})

[Log] gryo freq in ms:498
[Log] in gyro.js, t im ms: 
[Log] 1388099255033 
[Log] in dataCollect.html, t im ms: 
[Log] 1388099255038 
[Log] in gyro.js, t im ms: 
[Log] 1388099255552 
[Log] in dataCollect.html, t im ms: 
[Log] 1388099255564 
[Log] in gyro.js, t im ms: 
[Log] 1388099256048 
[Log] in dataCollect.html, t im ms: 
[Log] 1388099256062 
[Log] in gyro.js, t im ms: 
[Log] 1388099256550 
[Log] in dataCollect.html, t im ms: 
[Log] 1388099256560 
[Log] in gyro.js, t im ms: 
[Log] 1388099257052 
[Log] in dataCollect.html, t im ms: 
[Log] 1388099257060 
[Log] in gyro.js, t im ms: 
[Log] 1388099257550 
[Log] in dataCollect.html, t im ms: 
[Log] 1388099257561 
[Log] in gyro.js, t im ms: 
[Log] 1388099258059 
[Log] in dataCollect.html, t im ms: 
[Log] 1388099258066 
[Log] in gyro.js, t im ms: 
[Log] 1388099258605 
[Log] in dataCollect.html, t im ms: 
[Log] 1388099258610 






