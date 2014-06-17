mat_filename = 'g00_B1_t01.mat';
fs_ideal = 60;
[ x,y,z,t,accel,fs] = read_6dmg_data(mat_filename, fs_ideal );


idle_th= 0.1; 
dir_th=0.1;
[ x2,y2,z2,t2,accel2, f_ratio] = filter_data_v1(x,y,z,t,accel, idle_th, dir_th);


%% Create charts for gestures based on filter parameters

%[s] = all_gestures_summary( idle_th, dir_th );
% need to select the data directory in the all_gestures function
%[s0] = all_gestures_summary_v2( 0.05, 0.05 );
[s1] = all_gestures_summary_v2( 0.0, 0.0 );
[s2] = all_gestures_summary_v2( 0.1, 0.1 );
[s3] = all_gestures_summary_v2( 0.2, 0.2 );
%[s4] = all_gestures_summary_v2( 0.2, 0.1 );
%[s5] = all_gestures_summary_v2( 0.0, 0.0 );

tt = [s1;s2;s3];


%%
t = 0:(size(s0, 1)-1);



plot(t, [s0{:,8}], t,[s1{:,8}], t,[s2{:,8}], t, [s3{:,8}], t, [s4{:,8}] );

legend('( 0.05, 0.05 )', ...
    '( 0.1, 0.1 )', ...
    '( 0.2, 0.2 )', ...
    '( 0.1, 0.2 )', ...
    '( 0.2, 0.1 )', ...
    'Location','EastOutside')

xlabel('Gesture. (5 in total.) ');
ylabel('Perc. of samples remaining after filtering');
title('Comaparisons of filtering parameters for entire lg dataset sampled at 15 Hz (idle th, dir th)');
grid on; 

saveas(gcf, 'plots/correct_filt_ratio_plots/gesture_vs_filt_ratio_1Hz', 'jpg') %Save figure
 
figure;
plot(t, [s0{:,4}], t,[s1{:,4}], t,[s2{:,4}], t, [s3{:,4}], t, [s4{:,4}], t,[s5{:,4}]);

legend('( 0.05, 0.05 )', ...
    '( 0.1, 0.1 )', ...
    '( 0.2, 0.2 )', ...
    '( 0.1, 0.2 )', ...
    '( 0.2, 0.1 )', ...
    '( 0.0, 0.0 )', ...
    'Location','EastOutside')

xlabel('Gesture. (5 in total.) ');
ylabel('Av. number of samples after filtering');
title('Comaparisons of filtering parameters for entire lg dataset sampled at 15 Hz (idle th, dir th)');
grid on; 

saveas(gcf, 'plots/correct_filt_ratio_plots/gesture_vs_av_no_samples_15Hz', 'jpg') %Save figure

    
%% Analyse multiple participants for single or multiple gestures (for 6dmg) 

idle_th= 0.2; 
dir_th=0.1;
% use multiple gesture by combining them with | e.g. 01|02|15
persons_array = {'S2'; 'S1'; 'M3'; 'M2'; 'T1'; 'T2'; 'W1'; 'Y1'; 'Y3'...
    ; 'B2'; 'B1'; 'C1'};

gesture = '12';
%gesture_array = {'00'; '01'};
% create summary
s = persons_array;

for i= 1:size(persons_array,1)
    
    person = persons_array{i};
    regex = ['g(' gesture ')_' person '_t..\.mat'];

    [cl_values, no_of_files, f] = prepare_cluster(regex, idle_th, dir_th);
    
    s(i, 2) = {no_of_files};

    av_sample_size = mean([f{:,2}]);
    s(i, 3) = {av_sample_size};
    
    av_filtered_sample_size = mean([f{:,3}]);
    s(i, 4) = {av_filtered_sample_size};
    
    min_fil = min([f{:,3}]);
    s(i, 5) = {min_fil};
    
    max_fil = max([f{:,3}]);
    s(i, 6) = {max_fil};
    
    std_dev_fil = std([f{:,3}]);
    s(i, 7) = {std_dev_fil};

    av_filter_ratio = av_filtered_sample_size / av_sample_size;
    s(i, 8) = {av_filter_ratio};
    
    av_idle_dir = mean([f{:,5}]);
    s(i, 9) = {av_idle_dir};
end


%% Analyse a single or multiple gestures. 

idle_th= 0.1; 
dir_th=0.1;
% use multiple gesture by combining them with | e.g. 01|02|15
gesture = '15';
%regex = ['g(' gesture ')_.._t..\.mat'];
regex = ['g(' gesture ')_.._t.[0-1]\.mat'];

[cl_values, no_of_files, f] = prepare_cluster(regex, idle_th, dir_th);

av_sample_size = mean([f{:,2}]);
av_filtered_sample_size = mean([f{:,3}]);
min_fil = min([f{:,3}]);
max_fil = max([f{:,3}]);
std_dev_fil = std([f{:,3}]);

av_filter_ratio = av_filtered_sample_size / av_sample_size;
av_idle_dir = mean([f{:,5}]);

% plot the no. of th filtered sample size as a hist. 
hist([f{:,3}]);




    

%%

TRANS_GUESS = transmat1;
EMIS_GUESS = obsmat1;

one_string = [];
for i=1:size(data12,1)
    one_string = [one_string data12{i}.'];
end

%%

seq = one_string;
% use matlabs internal functions
[TRANS_EST2, EMIS_EST2] = hmmtrain(seq, TRANS_GUESS, EMIS_GUESS, 'Maxiterations',50,'Verbose',true );







