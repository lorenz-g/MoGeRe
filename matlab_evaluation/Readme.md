Matlab version used: R2013B on Mas OSX 10.9





### Howto:

- Make sure the matlab_evaluation is current dir. in matlab. 
- run the setup.m script to include the paths. 

- The folling 3 scripts be run as they are. To customise them, change the variables in the parameter
sections. 

`create_hmm_models/create_hmm_model_demo.m` : This demo creates an HMM model that can be 
used for online recogntion by the mobile web app. It creates a .mat and a .json. 
To inspect the .json file it is best to open it in Sublime or Chrome they format the data. 

`eval_continuous/evaluate_model_cont.m` : evaluates a model against noise. .mat model should contain
only one gesture. 

`eval_discrete/evaluate_model_disc.m` : inter gesture evaluation of model. Can take long to finish due 
to 5 fold cross validation.  

### Things that I learned / thought were useful


#### Use setup script to add subdirectories

The setup.m script automatically adds all the necessary files to the path. 


#### Stop debugger if error is encountered

Before Debugging, type following command

	dbstop if error

This stops the program on an error and one can inspect all variables. 
To clear the dbstop, type:

	dbclear if error


#### Cell arrays in MATLAB are a real pain

But I still used them. 
Careful when selecting ranges:
	
	cellarray(1,1:2)
	cellarray{1,1:1}
	are not the same...