function [results_table, overall, prob_table] = test_data( test_set, gestures, s )

% prob_table: name, gesture, most likely gesture, loglik gesture 1, 2, 3 ...
prob_table= test_set(:,1);

for j=1:size(test_set,1)  
    prob_table{j,2} = str2num(test_set{j,1}(2:3));
    for i=1:size(gestures, 2)
        % here it is important to have test_set(j, 6) and not test_set{j,6}
        % i.e need to pass a cell. o/w it would compute a different dhmm_logprob       
        prob_table{j, i + 3} = dhmm_logprob(test_set(j, 6), s(i).prior, s(i).transmat, s(i).obsmat);
    end
    index = find([prob_table{j, 4:end}] ==max([prob_table{j, 4:end}]));
 
    prob_table{j,3} = gestures(index);
    
    % Check for exception when all likelihoods are -Inf
    if max([prob_table{j, 4:end}]) == -Inf
        % assign it to a random value
        prob_table{j,3} = datasample(gestures, 1);
        warning('likelihood is all -Inf for %s',prob_table{j,1});
    end
end


%%
orig = [prob_table{:, 2}];
det = [prob_table{:, 3}];

% results table is normally rerferred to as confusion table
% results_table(i,j) is a count of observations known to be in group i but predicted to be in group j
results_table = zeros(size(gestures,2));

for i=1:size(gestures, 2)
    g_orig = orig==gestures(i);
    for j=1:size(gestures, 2)
        g_det = det==gestures(j);
        results_table(i,j) = sum(g_orig & g_det) / sum(g_orig);
    end
end



overall = sum(orig==det) / size(prob_table, 1);
indivual = diag(results_table);

end

