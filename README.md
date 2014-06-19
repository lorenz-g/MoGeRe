MoGeRe
======

Mobile hand gesture recognition for phones using accelerometer data and HMM.

![banner image](hardware_prototypes/banner.jpg?raw=true)

### Overview
This repository is part of my final year project at Imperial College London.
Below the link to my final report (it is quite large, 13MB):

https://dl.dropboxusercontent.com/u/14163800/fyp/FYP_final_smaller_size.pdf

It has 3 major parts:

- `/acceldatacollect`: Mobile web application that can record and recognize acceleration data from 
most modern smartphones. The live version can be found at http://acceldatacollect.appspot.com.
More detais in `/acceldatacollect/Readme.md`. 

- `/matlab_evaluation`: Uses Hidden Markov Models and the datasets in `dataset` to create models that 
recognize hand gestures. More detais in `/matlab_evaluation/Readme.md`.

- `hardware_prototypes`: Plans and schematics of mobile indication unit for cyclists that was 
developed as part of the project. The devie can be worn by a cylist at night and he lifts the arm
it starts flashing. 


### How to create creage a working gesture model:
This step by step guide explains how to create your own gesture models. Here, we create a two gesture 
model with gesture A and B. 

Required Software:
- Matlab
- Python (pip, jinja2, numpy packages)
- Google App Engine Launcher

Required Hardware:
- Smartphone (wiht internet connection)

###### 0 Download the repository

###### 1 Record the gestures 
- Two options: Record gestures on localhost or on acceldatacollect.appspot.com
- To record locally: `/acceldatacollect/Readme.md` - guide to start the server locally
- Opend a mobile web browser on you phone such Safari Mobil or Chrome Mobil navigate to the "Discrete Recorder" page.
- Enter your a name and call your first gestue 01. 
- Then load the two sounds at the bottom of the page. 
- Press the start button and once you hear the first sound, write an A into the air with the phone in your hand. (takes 40 seconds).
- Post it to the server and record the second gesture B, and call it 02. 
- On the "Discrete Recordings" page you can check if you find your name in the list. 

###### 2 Dowload the gestures
- open the `datasets/gestures_to_csv.py` file.
- Change the variable `u_name` to the name you entered before (might have to change the url if you are recording locally)
- Execute the srcipt (e.g. `$ pytyon gestures_to_csv.py` in the command line).
- This should download all the files and put it into the directory `datasets/csvDataNew`. 
- You should have 20 files in there now. with the format:

		g01_XX_t0Y --> Gesture A, with xx the fist two letters of your name, and y the repetition
		g02_XX_t0Y --> Gesture B ...

###### 3 Create the model
- Open the `/matlab_evaluation/create_hmm_models.create_hmm_model_s_by_s.m` file in Matlab. 
- Run it. If the data format in the `datasets/csvDataNew` directory is correct, the file 
`Model_A_and_B.json' is created the this directory.  

###### 3 Use the model in the Bookmarks demo (works only for localhost). 
- Copy the json file from 3 into `acceldatacollect/templates/json_models/demo`
- Next, open `acceldatacollect/templates/demoSingle.html` and change the `modelName` variable such that it points to your json file. 
- Also in `acceldatacollect/templates/demoSingle.html` change

		"1" : "double knock" to "1" : "A"
  		"2" : "tick move"    to "2" : "B"
  		
- Finally, navigate to the single Demo page, hold the button pressed, draw one of your gesture is the air and your phone should recognize it. 









#### Links to continuous and discrete dataset as zip files. 
https://dl.dropboxusercontent.com/u/14163800/fyp/accel_datasets/continuous.zip
https://dl.dropboxusercontent.com/u/14163800/fyp/accel_datasets/discrete.zip

