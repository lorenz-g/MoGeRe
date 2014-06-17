function [ s ] = train_data(train_set, gestures, prior1, transmat1, obsmat1, max_iter)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% Example init
% O = 14; % no of output symbols 
% Q = 5; % no of states
% initial guess of parameters
% prior1 = normalise(rand(Q,1));
% transmat1 = mk_stochastic(rand(Q,Q));
% obsmat1 = mk_stochastic(rand(Q,O));
%gestures = [12,13,14,15,16];

data = cell(size(gestures));
%data = {data12, data13, data14, data15};

tmp = cellfun(@(x) x(2:3), train_set(:,1), 'UniformOutput', false);
gest_mask = cellfun(@str2num, tmp);


tmp = train_set(:,6);
for i=1:size(gestures,2)
    sel = gest_mask == gestures(i);
    data{i} = tmp(sel);
end

%assert(isequal(train_set{1,6}, data{1}{1}));
%assert(isequal(train_set{22,6}, data{1}{22}));

% http://www.cs.ubc.ca/~murphyk/Software/HMM/hmm.html
% http://www.cs.ubc.ca/~murphyk/Software/HMM/hmm_usage.html

s = struct([]);

for i=1:size(gestures, 2)
    s(i).gesture = gestures(i);
    [s(i).LL, s(i).prior, s(i).transmat, s(i).obsmat] =...
        dhmm_em(data{i}, prior1, transmat1, obsmat1, 'max_iter', max_iter);
end

end

