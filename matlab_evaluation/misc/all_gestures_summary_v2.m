function [s] = all_gestures_summary_v2( idle_th, dir_th )
% Analyse the filter behaviour of the gesturess

%idle_th= 0.2; 
%dir_th=0.1;

% use multiple gesture by combining them with | e.g. 01|02|15
gesture_array = {'01'; '02'; '03'; '04'; '05'};

%gesture_array = {'00'; '01'};
% create summary
s = gesture_array;
dir_name = '../raw_data/dataset_8_4_14/csvData/';

for i= 1:size(gesture_array,1)
    
    gesture = gesture_array{i};
    regex = ['g(' gesture ')_.._t..\.csv'];

    %[cl_values, no_of_files, f] = prepare_cluster(regex, idle_th, dir_th);
    [cl_values, no_of_files, f] = prepare_cluster_v2(regex, dir_name, idle_th, dir_th);
    
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



end

