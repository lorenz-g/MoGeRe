% Add folder and subfolders

% not all of HMMall was included as some function are overwrite common
% matlab function such as as assert or strsplit. 
% The functions that are neeeded are copied into the /needed folder. 
path(genpath('external_scripts/HMMall/HMM'), path);
path(genpath('external_scripts/HMMall/needed'), path);

path(genpath('external_scripts/jsonlab'), path);

path(genpath('eval_discrete'), path);
path(genpath('eval_continuous'), path);
path(genpath('create_hmm_models'), path);

% Adds all the subfolders of v1_tests folder to path
%path(genpath('v2_tests'), path);

% this is for cell2csv.m and allcomb.m
addpath('external_scripts');

addpath('misc');


display('make sure that external_scripts/HMMall/netlab3.3 KPMtools KPMstats are NOT part of path. But this should be the default');

