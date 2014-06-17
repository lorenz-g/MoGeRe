function [ IDX, C, f ] = static_cluster( idle_th, dir_th, gestures, persons, repetitions, no_of_clusters, r )
% create static clusters intstead of random clusters for k-means
%   gesture = '00|01', combine them with or sign
%   persons = either 'A-Z' for all of them or ACZ e.g for A C Z 
%                   does not differentiate between e.g. person A1 and A2
%   repetitions = '01|02|03|04|05|06|08|09|10' for all. Any subset for fewer... 
%   ALL VARS ABOVE MUST BE STRINGS
%   no_of_clusters = integer, for kmeans algorithm
%   r = radius of cluster circle / squere. From k-means, around 1.5 is ok. 

% example: [ IDX, C, f ] = static_cluster( 0.1, 0.1, '12|13|14|15', 'A-Z', '01|02', 14, 1.5);


k = no_of_clusters;

C = [   1       0       0;
        0       1       0;
        -1      0       0;
        0       -1      0;
        0.71    0.71    0;
        -0.71   0.71    0;
        -0.71   -0.71   0;
        0.71    -0.71   0;
        0       0       1;
        0       0      -1;
        0       0.71    0.71;
        0       -0.71   0.71;
        0       -0.71   -0.71;
        0       0.71    -0.71;
        0.71    0       0.71;
        -0.71   0       0.71;
        -0.71   0       -0.71;
        0.71    0       -0.71;
    ];

C = C.*r;

if k == 8
    % k = 8, one othorgonal circles. on x-y 
    C = C(1:8, :);
elseif k == 14
    % k = 14, two othorgonal circles. on x-y and y-z plane. 
    C = C(1:14, :);
elseif k == 18
    % k = 18, three othorgonal circles on all planes.  
    C = C(1:18, :);
else
    error('k must be 8, 14 or 18');
end
    

%% receive filtered data
regex = ['g(' gestures ')_[' persons ']._t(' repetitions ')\.mat'];

[cl_values, no_of_files, f] = prepare_cluster(regex, idle_th, dir_th);


%% static cluster

% find euclidian distance to each point of C and the assign to point with
% min distance
IDX = zeros(size(cl_values, 1), 1);

for i = 1: size(IDX, 1)
    min_dis = 10;
    for j = 1:k
        tmp_d = sqrt((cl_values(i,1) - C(j,1))^2 + ...
            (cl_values(i,2)- C(j,2))^2 + (cl_values(i,3)- C(j,3))^2);
        if tmp_d < min_dis
            min_dis = tmp_d;
            IDX(i,1) = j;
        end
    end
end
   

%% add the IDX values to f
%   IDX is an array of the clustered datapoints
tmp = 1;
for i = 1: (size(f,1))
    f(i, 6) = {IDX(tmp: (tmp + f{i,3} -1))};
    tmp = tmp + f{i,3};
end

% check that first sample is correct
assert(isequal(f{1,6}, IDX(1:f{1,3})));
% check that last sample is correct
assert(isequal(f{end,6}, IDX(end - f{end,3} +1  : end)));


%%  3 d scatter plot with centres... 
%scatter3(cl_values(:, 1), cl_values(:, 2), cl_values(:, 3))
%hold on;
%axh = gca;
%set(axh,'XGrid','on');
%grid on;
%scatter3(C(:, 1), C(:, 2), C(:, 3), 'r+');
%hold off;


end
