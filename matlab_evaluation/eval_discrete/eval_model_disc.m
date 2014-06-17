function [avg_rec_rate, exec_time] =  eval_model_disc(id, fs, idle_th, dir_th, M, type, N)


% SET MAJOR PARAMETERS ****************************************************

% Select Folder with training data 
dir_name = ['../datasets/discrete/csvData_' fs 'Hz/'];

% Select Gestures that should be in the model (both as int and as char)
gestures_char = {'01' '02' '03' '04' '05'};
gestures = [01 02 03 04 05];

% Select which persons should be trained
% e.g. '..' -> everyone; '(L1)' -> L1 only; '(L1|L2)' -> L1 abd L2;
persons = '..';

% Select how many repetions per user
% e.g. '..' -> all; '(01)'->rep01; '(01|08)'->01 and 08; '.[1-5]'->rep 1 -5  
repetitions_cluster ='..';



%  CROSS VALIDATION RESULTS ***********************************************
% take time
tic();
no_of_clusters = M;
% for train_data()
O = no_of_clusters; % no of output symbols 
Q = N; % no of states

max_iter = 50;

% reps must be the same number as the k in the cross validation
reps = 5;

% variables for results
s_all = cell(reps, 1);
overall_all = s_all;
results_table_all = s_all;
no_train_samples_all = s_all;

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
    
    % transistion limited to current and next state
    transmat1 = zeros(Q);
    for i = 1:(Q-1)
        transmat1(i,i) = 0.5;
        transmat1(i,i+1) = 0.5;
    end
    transmat1(Q, Q) = 1;
    obsmat1 = ones(Q, O)* (1/O); 
end



% create multiple clusters
f = {};
for i=1:size(gestures_char,2)
    regex = ['g(' gestures_char{i} ')_' persons '_t' repetitions_cluster '\.csv'];
    [cl_values, no_of_files, f_tmp] = prepare_cluster_v2(regex, dir_name, ...
        idle_th , dir_th);

    [~,C, sumd] = kmeans(cl_values, no_of_clusters, ...
        'display', 'final', 'replicates', 5);
    [f_tmp, ~] = assign_to_cluster(C, cl_values, f_tmp);
    f = [f; f_tmp];
end

% k-crossvalidation: 
k = 5;                              % how many folds i want
N = size(f,1);                       % total number of observations
indices = crossvalind('Kfold',N,k); % divide test set into k random subsets

for i = 1 : k
    % cross validation:
    test = (indices == i) ; % which points are in the test set
    train = ~test; % all points that are NOT in the test set
    
    test_set = f(test,:);
    train_set = f(train,:);
   
    
    % s contains   gesture, log-likelihood, prior probability, transition
    % matrix, and obervation matrix for each gesture    
    [ s ] = train_data(train_set, gestures, prior1, transmat1, obsmat1, max_iter);
      
    s_all{i} = s;
    [results_table, overall, prob_table] = test_data( test_set, gestures, s );
    overall_all{i} = overall;
    results_table_all{i} = results_table;
    no_train_samples_all{i}= size(train_set,1);
    
end

% works only with 5 fold cross validation.
avg_rec_rate = sum([overall_all{1} overall_all{2} overall_all{3} overall_all{4} overall_all{5}])/5;

exec_time = toc();

% To keep track of individual results...
% save (['DIA_final_report/2_model_comparison/individual_results/' id]);