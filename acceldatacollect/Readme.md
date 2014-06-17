#### Run the acceldatacollect locally

- Download the Google App Engine Launcher for Python (I have 1.8.8 on Mac OSX 10.9).

- Dowload the 'MoGeRe' repository

- Open the local server via command line in Terminal (no external devices can access the site if it is 
launched directly from the app engine laucher)	

_
	$ cd MoGeRe
 	$ dev_appserver.py --host=0.0.0.0 acceldatacollect
 	the --host makes it available to all devices in local network...

- Open localhost in Browser. (I used Chrome and Safari Mobile)

- To open the site on a mobile phone

_
	Open new terminal window
	$ ifconfig 
	% ipconfig (fow windows I believe)
	Type the local IPv4 address into the mobile browser:
	e.g.  http://192.168.1.7:8080/

- The Recordings pages might result in an error if the databases are still empty.


- Can be run offline as well. Except fo the two sounds that are loaded from dropbox. 


#### Deploy the project on a google server. 

- One command / or from the app engine laucher. 

_
	$ appcfg.py --no_cookies --email=YOUR_EMAIL --passin update

- Note that the 'acceldatacollect.appspot.com' site is reserved. So if you want to make changes and 
upload it to Google. Then just change the name of the folder and the app.yaml file and it should work. 

_
	$ mv acceldatacollect newproject
	$ cd newproject
	$ nano app.yaml
	change the line
	application: acceldatacollect
	to 
	application: newproject
	Upload it using the appcfg.py
	And it should be live at:
	http://newproject.appspot.com








