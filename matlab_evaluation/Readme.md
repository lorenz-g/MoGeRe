
### Demo:

### Things that I learned / thought were useful


#### Stop debugger if error is encountered

Before Debugging, type following command

	dbstop if error

This stops the program when an error is and one can inspect all variables. 
To clear the dbstop, type:

	dbclear if error


#### Cell arrays in MATLAB are a real pain

But I still used them. 
Careful when selecting ranges:
	
	cellarray(1,1:2)
	cellarray{1,1:1}
	are not the same...