% create a copy of dataset with lower sampling rate

dir_name = '../raw_data/dataset_8_4_14/csvNoise_60Hz/';
regex = 'g.._.._t..\.csv';

%regex = 'g02_V1_t07\.csv';
assert(ischar(regex));

f = dir(dir_name);
f = regexpi({f.name}, regex ,'match');
f = [f{:}];
f = f.';
no_of_files = numel(f);

% filtering parameters. 
fs_ideal = 60;



% every d_sample_factor sample is selected
d_sample_factor = 4;
to_dir_name = '../raw_data/dataset_8_4_14/csvNoise_15Hz/';

for i=1:no_of_files
%for i=1:2 
    % when accessing a cell array: f(i,1) returns a cell,
    % f{i,1} returns a string
    
    % changed from 6dmg to lgdb
    [x,y,z,t, accel, fs, t_abs, alpha1,beta1,gamma1] = read_lgdb_data([dir_name f{i, 1}]);
    
    % note that the t above is called tRel in the csv file. 
    % and the t_abs above is called t
    names =     {'t'    , 'tRel', 'x', 'y', 'z', 'alpha', 'beta', 'gamma'};
    % x is col vector
    all_vars_col =  [t_abs;   t; x; y; z; alpha1; beta1; gamma1];
    
    % convert them all to row vectors:
    all_vars_row = all_vars_col.';
    d_sampled = downsample(all_vars_row, d_sample_factor);
    
    
    final = [names ; num2cell(d_sampled)];
    
    cell2csv([to_dir_name f{i,1}], final);
    

end

%% test:

%[x,y,z,t, accel, fs, t_abs, alpha1,beta1,gamma1] = read_lgdb_data([to_dir_name '30.csv']);