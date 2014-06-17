function [best, model_lls, IDX_len, best_with_ll_th] = test_single_data(x, y, z, t,accel,...
    models, noise_th,  ll_threshold)
% computes the log likelihood(s) for a single datasample. 


% pick a random gesture for the filtering as it is only done once.
% But useuall all gestures have the same filtering parameters anyway. 
[ x2,y2,z2] = filter_data_v1(x,y,z,t,accel, models{1}.idle_th, models{1}.dir_th);
IDX_len = size(x2, 2);

% model likelihoods
model_lls = [];

% the model test 
model_test = [];

for i=1:size(models, 2)
    
    % IDX is column vector, x2 ... are row vectors.
    [~, IDX] = assign_to_cluster(models{i}.cluster_centers, [x2.' y2.' z2.' ], '');
    
    
    if size(IDX, 1) < noise_th
        model_lls(i) = -Inf;
    else
        % !! It matters if you put {} around IDX or not
        % no {}, each values is passes into forward seperately
        % with {}, all values passed into forward
        model_lls(i) = dhmm_logprob({IDX}, models{i}.prior, ...
            models{i}.transmat, models{i}.obsmat);
    end
    
end

index = find(model_lls == max(model_lls));

% select the first value of index, in calse several paramters are maximum
best = models{index(1)}.gesture;

% Additionally check for the ll. threshold
if max(model_lls) < ll_threshold
    best_with_ll_th = -1;
else 
    best_with_ll_th = best;
end


% Check for exception when all likelihoods are -Inf
if max(model_lls) == -Inf    
    best = -1;
end


end

