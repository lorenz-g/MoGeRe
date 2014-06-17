function [ x,y,z,t,accel,fs] = read_6dmg_data(mat_filename, fs_ideal )
% Read .mat file from database. Need to run setup.m file to work. 
    % fs ideal in hertz
    % mat_filename example: 'g00_B1_t01.mat'

load(mat_filename, '-mat', 'gest');

t = gest(1,:);
fs = 1000/mean(diff(t));
% tolerate 20% error in the sampling frequency. 
assert(abs((fs - fs_ideal) / fs_ideal) < 0.2, ' assertion failed: wron sampling frequ.');

ms_duration = t(end);
x = gest(9,:);
y = gest(10,:);
z = gest(11,:);

% total acceleration
accel = sqrt(x.^2 + y.^2 + z.^2);

%plot(t,x, t,y, t,z);



end

