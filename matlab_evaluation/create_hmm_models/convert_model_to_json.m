function [b] = convert_model_to_json(model_name, all_models, window_length, noise_th, ll_th, sep_filter)
%CONVERT_MODEL_TO_JSON Summary of this function goes here
%   Detailed explanation goes here
    
    % CAREFUL: if the model only contains one gesture, json_data.models
    % becomes an object directly instead of a list of objects. The
    % Javascript code expects a list/array of objects. 
    % Quick fix: open the created model in sublime and insert box brackets
    % around the model. 
    
    % model_name = 'm_all_no_f_9_5.mat';
    % load model_name
    
    % parameters for continious model only
    window_length_ms = window_length * 1000; % in milliseconds
    %noise_th = 21;
    %ll_th = -100;
    % is a seperate filter used to keep all the samples the same length.  0
    % -> no, 1 - > yes
    %sep_filter = 1;
    
    
    % path to save it to:
    %to_path = '/Users/lorenzgruber/Documents/Testing_Programs/app_engine/accel/acceldatacollect/templates/json_models/';
    to_path = 'create_hmm_models/';

       
    % turn the prior into a row vector for the JS hmm
    for i=1:size(all_models,2)
    all_models{i}.prior = all_models{i}.prior.';
    end
    
    json_data= struct();
    json_data.info.matlab_name = model_name;
    json_data.info.f_sample = all_models{i}.f_sample;
    json_data.info.window_length = window_length_ms;
    json_data.info.noise_th = noise_th;
    json_data.info.ll_th = ll_th;
    json_data.info.sep_filter = sep_filter;
    json_data.models = all_models;
    
    
    json_name = [model_name '.json'];
    
    savejson('', json_data, [to_path json_name]);
    
    b=0;


end

