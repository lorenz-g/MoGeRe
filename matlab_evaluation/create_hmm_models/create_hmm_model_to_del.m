% This demo creates an HMM model that can be used for online recogntion by
% the mobile web app. 

% It creates a .mat and a .json. To inspect the .json file it is best to
% open it in Sublime or Chrome they format the data. 

% All persons and all repetitions are selection to train the 5 movements. 
% In fact, only 80% of the data is used. And the remaind 20% are used to
% compute the average log likelihood which is useful when setting up the
% ll_threshold.

% SET MAJOR PARAMETERS ****************************************************

% Select Folder with training data 
dir_name = ['../datasets/discrete/csvData_20Hz/'];

% Select the model name. model_name.mat and model_name.json will be created
model_name = 'ALL_robust';

% Select Gestures that should be in the model (both as int and as char)
gestures_char = {'01' '02' '03' '04' '05'};
gestures = [01 02 03 04 05];
%gestures_char = {'06' '07' '08' '09' '10' '11' '12'};
%gestures = [06 07 08 09 10 11 12];

% Select which persons should be trained
% e.g. '..' -> everyone; '(L1)' -> L1 only; '(L1|L2)' -> L1 abd L2;
persons = '..';

% Select how many repetions per user
% e.g. '..' -> all; '(01)'->rep01; '(01|08)'->01 and 08; '.[1-5]'->rep 1 -5  
repetitions_cluster ='..';


% SET MINOR PARAMETERS ****************************************************

% HMM type (3 options)
% 'left to right', 'ergodic-random', 'ergodic-uniform'
hmm_type = 'left to right';


% Filtering thresholds
% either: 0.0 and 0.0, 0.05 and 0.05, 0.1 and 0.1
idle_th = 0.0;
dir_th = 0.0;

% Number of cluster
% either 5, 8, 14. --> did not affect results
no_of_clusters = 8;

% Number of states
% either 8, 14, 20. --> did not affect results
Q = 8; % no of states

% Maximum iterations for Baum Welch Algorithm. 
% It stops earlier if diff. between two consecutive ll is smaller than 1e-4
max_iter = 50;

% PARAMETERS for online recognition
% They are not used in the MATLAB script but by the online recognition that
% runs in the mobile brower. Those can be changed in the .json file
% afterwards, too. 

% Sampling Frequency
% Should match sampling frequency of the dataset in 'dir_name'
f_sample = 20;

% Window length (s)
window_length = 1.5;

% Noise threshold
% depends on window lenght 1.5s --> 15, 2s -- 20
noise_th = 15;

% Log likelihood threshold
% depends on window lenght 1.5s --> -40, 2s -- -60
ll_th = -60;



% CREATE .mat MODEL  ******************************************************
type = hmm_type; % model type
O = no_of_clusters; % no of output symbols 

%initial guess of parameters
if strcmp(type,'ergodic-uniform')
    prior1 = ones(Q,1) * (1/Q);
    transmat1 = ones(Q, Q)* (1/Q);
    obsmat1 = ones(Q, O)* (1/O);
 
elseif strcmp(type,'ergodic-random')
    prior1 = mk_stochastic(rand(Q,1));
    transmat1 = mk_stochastic(rand(Q,Q));
    obsmat1 = mk_stochastic(rand(Q,O));

else
    % left to right model
    prior1 = zeros(Q,1);
    prior1(1)= 1;
    
    % transistion limited to current and next state (one step l2r)
    transmat1 = zeros(Q);
    for i = 1:(Q-1)
        transmat1(i,i) = 0.5;
        transmat1(i,i+1) = 0.5;
    end
    transmat1(Q, Q) = 1;
    obsmat1 = ones(Q, O)* (1/O); 
end

% Variable will contain all model parameters. 
all_models = cell(size(gestures));

% Repeat the same process for every gesture
for i = 1 : max(size(gestures))
    
    % Read in single gesture and cluster the data. 
    % f contains info about every single sample
    regex = ['g(' gestures_char{i} ')_' persons '_t' repetitions_cluster '\.csv'];
    [cl_values, no_of_files, f] = prepare_cluster_v2(regex, dir_name, ...
        idle_th , dir_th);
    
    % Apply kmeans algorithm to find cluster centers.
    [~,C, sumd] = kmeans(cl_values, no_of_clusters, ...
        'display', 'final', 'replicates', 5);
    
    % Assign samples to cluster values
    [f, ~] = assign_to_cluster(C, cl_values, f);
    
    
    % Select 80% of data for training and 20% to find average likelihood. 
    k = 5; % how many folds i want
    N = size(f,1); % total number of observations
    % No cross validation is performed here. Used to create random
    % indices onyly
    indices = crossvalind('Kfold',N,k);

    % Split orignial set
    test = (indices == 1) ; % which points are in the test set
    train = ~test; % all points that are NOT in the test set
    
    test_set = f(test,:);
    train_set = f(train,:);
 
    
    % in this context, models contains only one model
    [ model ] = train_data(train_set, gestures(i), prior1, transmat1, obsmat1, max_iter);
    model(1).cluster_centers = C;
    model(1).idle_th = idle_th;
    model(1).dir_th = dir_th;
    model(1).hmm_type = hmm_type;
    model(1).f_sample = f_sample;
    
    [~, ~, prob_table] = test_data( test_set, gestures(i), model(1) );
    
    % check that only the correct gesture was tested. 
    assert(all([prob_table{:, 3}] == gestures(i)));
    
    % Compute the tested_ll_mean
    % need to exclude the -Inf, as it will get biased o/w. 
    tmp = [prob_table{:, 4}];
    model(1).tested_ll_mean = mean(tmp([prob_table{:, 4}] ~= -Inf));
           
    all_models{i} = model;
    
end

save(['create_hmm_models/' model_name], 'all_models');

% CREATE .json MODEL  *****************************************************
%%
% Seperate filter
if idle_th == 0
    sep_filter = 1;
else
    sep_filter = 0;
end

convert_model_to_json(model_name, all_models, window_length, noise_th, ll_th, sep_filter)

