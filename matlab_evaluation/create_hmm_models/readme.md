### all_models_21_4

- fsample = 60
- ergodic model
- !!! with old filter_v1 version, where z was not compared to previouse

### all_models_23_4
- fsample = 20
- left to right model
- clusters are all the same
- 5 states
- !!! with old filter_v1 version, where z was not compared to previouse

### all_models_23_4_ic
- fsample = 20
- left to right model
- individual clusters
- 5 states
- !!! with old filter_v1 version, where z was not compared to previouse

### all_models_25_4
- fsample = 20
- left to right model
- clusters are all the same
- 5 states

### all_models_g2_g3_6_5
- contains only g2 and g3
- fsample = 20
- left to right model
- individual clusters
- 5 states
- no filtering at all.... (however that means that as start and end of a gesture often has just g as acceleration, many of the cluster centers might tend to be towards gravity..., but I plotted the cluster centers of this model for g2 and of all_models_25_4 for g2 there is no real trend that more of them are centered around gravity. 

### m_g4_no_f_8_5
- contains g4
- fsample = 20
- left to right model
- individual clusters
- 5 states
- no filtering at all

### m_g3_no_f_8_5
- contains g3
- fsample = 20
- left to right model
- individual clusters
- 5 states
- no filtering at all

- for the json model, a noise th of 15 is better than 20. 

### m_g4_fil1_8_5
- contains g4
- fsample = 20
- left to right model
- individual clusters
- 5 states
- idle_th = 0.1, dir_th = 0.1

### m_g3_fil1_8_5
- contains g3
- fsample = 20
- left to right model
- individual clusters
- 5 states
- idle_th = 0.1, dir_th = 0.1


### m_g2_no_f_L1_only_8_5.mat
- contains g2
- fsample = 20
- left to right model
- individual clusters
- 5 states
- no filtering at all
- only use person L1 

### m_all_no_f_9_5.mat
- contains all gestures
- fsample = 20
- left to right model
- individual clusters
- 5 states
- no filtering at all


### Todo: try an ergodic model fro 20 Hz as well. this might be better for continious recogintion
http://jbloit.com/dwnld/phd/bloit_icasspPaper08_stviterbi.pdf
