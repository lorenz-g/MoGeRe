% Use this to test different sets of initial parameters. 
% Creates a table RT with all combinations. 

% The default dataset is the discrete one with all persons all repetitions.
% To change that, need to change parameters in eval_model_disc.m

% Column names of RT
% 1. Sampling frequency
% 2. Filter thrisholds (idle_th = dir_th)
% 3. No of clusters
% 4. HMM type
% 5. NO of stats
% 6. Result: Average recognition rate
% 7. Result: Execution time 


% SET MAJOR PARAMETERS ****************************************************
%test_name = ['example_rand_' num2str(randi([1 1000])) '_'];
test_name = ['demo_results'];

fs = {'20'};
idle_th = {0.1};
dir_th = {0.1};
M = {20}; % no of clusters
type = {'left-to-right'};
N = {5, 8, 15}; % no of states


% COMPUTE RESULTS *********************************************************
a = {fs, idle_th , M, type, N};
% results table
RT = allcomb(a{:});

for i=1:size(RT,1)
%for i=4
    display(i);
    % note as idle and dir th are always the same the RT only has one col
    % for them
    id = [test_name '_' num2str(i)];
    [avg_rec_rate, exec_time] =  func_eval_model(id , RT{i,1}, RT{i,2}, RT{i,2}...
                                                ,RT{i,3}, RT{i,4}, RT{i,5});
    RT{i,6} = avg_rec_rate;
    RT{i,7} = exec_time;
    display(exec_time);
    
    
end

save(['eval_discrete/' test_name]);









