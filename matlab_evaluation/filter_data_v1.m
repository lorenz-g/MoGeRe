function [ x2,y2,z2,t2,accel2, red_idle_state] = filter_data_v1(x,y,z,t,accel, idle_th, dir_th)
% filter described in the paper [2](schloemmer et al.) on page 13
    % idle_th rougly 0.1
    % dir_th roughly 0.1

% the inputs need to be row vectors
assert(size(x,1)==1);


%% idle state filter
%   neglect datapoints acceleration is below a threshold
%idle_th = 0.1; % in g.  

% create binary mask
mask = accel > (1 + idle_th) | accel < (1 - idle_th);


x1 = x(mask);
y1 = y(mask);
z1 = z(mask);
t1 = t(mask);
accel1 = accel(mask);

if isempty(accel1)
    %warning('Idle state filter for this motion resulted in no more datapoints');
    % just select the first of the original data to prevent errors..
    x2 = x(1); y2= y(1); z2 = z(1); t2 = t(1); accel2=accel(1); red_idle_state=0;
    return
    % comment the if statement, type: dbstop if error, and execute function
    % then one can analyse which one it is. 
end

%plot(t1,x1,'+', t1,y1,'+', t1,z1,'+');

%% directional equivalence filter
%   neglect datapoints if they are too similar to previous one. 

%dir_th = 0.1;

% this does not work, as it only comapres the 2 elements next to each other
%mask2 = diff(x1) > dir_th | diff(y1) > dir_th | diff(z1) > dir_th;

last = 1;
mask2 = false(size(x1));
% automatically include the first element. 
mask2(1) = 1;

for i=2:size(x1, 2)
    mask2(i) =  abs(x1(i)- x1(last)) >= dir_th |...
                abs(y1(i)- y1(last)) >= dir_th |...
                abs(z1(i)- z1(last)) >= dir_th;
                % note: this was accidently abs(y1(i)- y1(last)) >= dir_th;
                % I cleared that on 25.4.
                
    if mask2(i) == 1
        last = i;
    end
end

x2 = x1(mask2);
y2 = y1(mask2);
z2 = z1(mask2);
t2 = t1(mask2);
accel2 = accel1(mask2);

%display(size(x,2));
%display(size(x2,2));

% samples taken away by idle state
red_idle_state = size(x,2) - size(x1, 2);
%plot(t2,x2,'+', t2,y2,'+', t2,z2,'+');

end