% Use this to test a model against road noise. The gesture_end_times.mat
% file contains the gesture end times needed to decide if sth was a correct
% or a false detection. 


% SET MAJOR PARAMETERS ****************************************************

% Load a model that has been trained by create_hmm_model.m
% Model should only contain one Gesture
% Demo model contains gesture 2 only
all_models_char = 'demo_model_cont.mat';

% Choose the dataset. Does not work with the discrete dataset
dir_name = '../datasets/continuous/csvNoise_20Hz/';

% Choose the filename.
% 'g02_L1_t03.csv' -> correct detections
% 'g00_T1_t02.csv' -> road noise
filename = 'g00_T1_t02.csv';

% SET MINOR PARAMETERS ****************************************************
% sample size is desired window lenght in s time sampling frequency
f_sample = 20;
sample_size = 41; 
noise_th = 25;
ll_threshold = -60;

% no filtering at all for hmm decoding but use filter to decide when to
% decode
sep_pre_processing = 0;


% CALCULATE HMM LL AT EACH TIME INSTANCE **********************************
% how many seconds are skipped once gesture is detected. 
skip_length = 1.5; % in s
skip_size = skip_length * f_sample;

% how much time on either side of the gesture end times is still acceptable
% for a correct detection 
acceptance_limit = 0.5; % in s

rec_f_char = dir_name(end-4:end-1);
% load file, loads the all_models variable...
load(all_models_char);
[x,y,z,t, accel, fs] = read_lgdb_data([dir_name filename]);

% intialize arrays and counters
total_l = max(size(x));
best = zeros(size(x));
best_with_ll_th = best;
IDX_len = zeros(size(x));
model_ll = zeros(size(all_models, 2), size(x, 2));

wrong_det_counter = 0;
correct_det_counter = 0;

% 0 -> nothing detected, -1 -> wrong detection, 1-> correct detection
detections_array = best;

% loads a variabe gestureendtimes
load('gesture_end_times.mat');
tmp = find(strcmp(filename, gestureendtimes(:,1)));
if tmp
    % only for the one that is selceted. Note that here only one gesture can be
    % present per file....
    gest_end_times = [gestureendtimes{tmp, 2:end}];
else
    gest_end_times = 0;
end


if sep_pre_processing == 0
    for i = sample_size + 1 : (total_l - skip_size)
    %for i = 2302 : total_l
        %display(i);
        [best(i), model_ll(:, i), IDX_len(i), best_with_ll_th(i)] = ...
                            test_single_data(x(i - sample_size : i-1),...
                                            y(i - sample_size : i-1),...
                                            z(i - sample_size : i-1),...
                                            t(i - sample_size : i-1),...
                                            accel(i - sample_size : i-1),...
                                            all_models, noise_th, ll_threshold);       
    end
    
else 

    % this should only be used with the origianal dir_th = 0 and idle_th=0
    % because then when evaluating the HMM, all samples have the same
    % length
    sep_idle_th = 0.1;
    sep_dir_th = 0.1;
    sep_noise_th = 20;
    for i = sample_size + 1 : total_l       
        [x2] = filter_data_v1(x(i - sample_size : i-1),...
                                y(i - sample_size : i-1),...
                                z(i - sample_size : i-1),...
                                t(i - sample_size : i-1), ...
                                accel(i - sample_size : i-1),...
                                sep_idle_th, sep_dir_th);
        IDX_len(i) = size(x2, 2);
        if size(x2, 2) > sep_noise_th        
            [best(i), model_ll(:, i),~ , best_with_ll_th(i)] = ...
                                test_single_data(x(i - sample_size : i-1),...
                                                y(i - sample_size : i-1),...
                                                z(i - sample_size : i-1),...
                                                t(i - sample_size : i-1),...
                                                accel(i - sample_size : i-1),...
                                                all_models, noise_th, ll_threshold);
        end
    end
end

% go over the sample again, to calculate the detections array. 
for i = sample_size + 1 : (total_l - skip_size)
    % check that no detection occured previouly
    if detections_array(i) == 0
         if best_with_ll_th(i) ~= -1
            if min(abs(gest_end_times - t(i))) < acceptance_limit
                correct_det_counter = correct_det_counter + 1;
                detections_array(i:(i+skip_size)) = 1;
            else
                wrong_det_counter = wrong_det_counter + 1;
                detections_array(i:(i+skip_size)) = -1;
            end
         end
    end        
end

wrong_det_per_m = 60 * wrong_det_counter / t(end);
perc_wrong_on_time = wrong_det_per_m * skip_length / 60;
display(['Wrong detections per minute: ' num2str(wrong_det_counter)]);


%% CREATE SUBPLOTS ********************************************************
figure
% make the plot high
pos = get(gcf,'Position');
pos(3:4) = [700 800];
set(gcf,'Position',pos);


% New subplot ************
subplot(5,1,1);
plot(t, x, 'r', t, y, 'g', t, z, 'b');
% the underscore is interpreted by matlab
title(['Evaluation of Noise. Model used:  ' strrep(all_models_char, '_', '  ')...
    '   Noise File:   ' strrep(filename, '_', '  ') '   sample size:' ...
    num2str(sample_size) '  recorded at ' rec_f_char]);
legend('x axis','y axis','z axis');
xlabel('time in s');
ylabel('acceleration in g');
xlim([t(1), t(end)]); % need to match the other plots

hold on;
scatter(gest_end_times, -2 * ones(size(gest_end_times)), 'bx');
hold off;
grid on;

% New subplot ************
subplot(5,1,2);
plot(t, IDX_len);
hline = refline(0,noise_th);
set(hline,'Color','r');

title('No of Samples after filtering. Point indicates Last 2 seconds.');
ylabel('No of Samples');
xlim([t(1), t(end)]); % need to match the other plots
grid on;

% New subplot ************
subplot(5,1,3);
plot(t, detections_array);
xlim([t(1), t(end)]); % need to match the other plots
ylim([-1.2 1.2]);
title('detections array, -1 -> falst detectino, +1 correct detection');

hold on;
scatter(gest_end_times, ones(size(gest_end_times)), 'rx');
hold off;
grid on;

% New subplot ************
subplot(5,1,4);
% replace all the -Inf values by the minimum value in order to plot it
model_ll2 = model_ll;
model_ll2(model_ll== - Inf) = 0;

model_ll_row = 1;
tmp = model_ll(model_ll_row,:);
tmp(tmp== - Inf) = min(model_ll2(model_ll_row, :));

plot(t, tmp, 'o');
title('Model log likelihood for gesture of interest; If no of samples < noise th, ll is not calculated');
legend(['g' num2str(all_models{model_ll_row}.gesture)]);
ylabel('Log likelihood');
xlim([t(1), t(end)]); % need to match the other plots
grid on;

hline = refline(0,ll_threshold);
set(hline,'Color','r');

% New subplot ************
subplot(5,1,5);
title('Not used');

