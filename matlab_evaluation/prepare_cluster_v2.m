function [cl_values, no_of_files, f] = prepare_cluster_v2(regex, dir_name, idle_th, dir_th)
%   Matches the regular expression, reads the data in and filters it.
%   To get raw data only withoug filtering, use idle_th = 0 and dir_th = 0

%  Sample Call:
%  dir_name = '../datasets/discrete/csvData_20Hz/';
%  works with .csv files only
%  regex = ['g(01)_.._t..\.csv'];
%  [cl_values, no_of_files, f] = prepare_cluster_v2(regex, dir_name, 0,0)


assert(ischar(regex));

f = dir(dir_name);
f = regexpi({f.name}, regex ,'match');
f = [f{:}];
f = f.';
no_of_files = numel(f);

% filtering parameters. 
%idle_th= 0.1; 
%dir_th=0.1;

x_conc = [];
y_conc = [];
z_conc = [];

for i=1:no_of_files
%for i=1:20  
    % when accessing a cell array: f(i,1) returns a cell,
    % f{i,1} returns a string
    
    % to use datasets that are formated differently. Replace the read
    % function here. 
    [ x,y,z,t,accel,fs] = read_lgdb_data([dir_name f{i, 1}]);
    [ x2,y2,z2,t2,accel2, red_idle_state] = filter_data_v1(x,y,z,t,accel, idle_th, dir_th);
    % add 
    f(i, 2) = {size(x, 2)};
    f(i, 3) = {size(x2, 2)};
    f(i, 4) = {size(x2, 2)/size(x, 2)};
    f(i, 5) = {red_idle_state};
    
    %size(x2) % 1 49
    
    % TODO: this is a very slow implementation, however the dim. are unknow
    % in advance. But even with 200 files, it is still very quick...
    x_conc = [x_conc x2];
    y_conc = [y_conc y2];
    z_conc = [z_conc z2];
end

cl_values = [x_conc.' y_conc.' z_conc.' ];


end

