% Communications MatLab <--> Energia

% in case in need to pause it in the beginning for n seconds
pause(3);

clc;
clear all;
close all;


numSec= 15;
v=[];
x=[];
y=[];
z=[];
t=[];
x_difference = [];
z_score = [];


%pausing in sec
pause(0.5);


s1 = serial('/dev/tty.uart-AEFF41E50F8B4518');    % define serial port
s1.BaudRate=4800;               % this changes dependig on msp430
set(s1, 'terminator', 'LF');    % define the terminator for println
fopen(s1);

try                             % use try catch to ensure fclose
                                % signal the arduino to start collection
w=fscanf(s1,'%s');              % must define the input % d or %s, etc.
if (w=='A')
    display(['Collecting data']);
    %pause(0.5);
    fprintf(s1,'%s\n','A');     % establishContact just wants 
                                % something in the buffer
end

i=0;
t0=tic;
while (toc(t0)<=numSec)
    i=i+1;
    if strcmp(fscanf(s1,'%s'), 'x')  
        % note that the order in which they are printed in must match the
        % order here
        % todo: find a way to 
        x(i)=fscanf(s1,'%f', [1,1]);
        %y(i)=fscanf(s1,'%f');
        z(i)=fscanf(s1,'%f', [1,1]);% must define the input % d, %f, %s, etc.
        x_difference(i)=fscanf(s1,'%f', [1,1]);
        z_score(i)=fscanf(s1,'%f', [1,1]);
        t(i)= toc(t0);
    else
        display('wait for x');
    end
    
end


catch exception
    fclose(s1);                 % always, always want to close s1
    throw (exception);
    display(exception);
end 


fclose(s1);

tested_f_s = max(size(x))/ numSec

%%
figure 
subplot(3,1,1);
%plot(t,x,'r',t,y,'g',t,z,'b');               % another interesting graph
plot(t,x,'r',t,z,'b');   
legend('x','z');                                % if you need precise timing                              
xlabel('t in seconds');                                % you better get it from the 
ylabel('voltage in V'); 
grid minor;

subplot(3,1,2);
plot(t,x_difference, 'r');            
legend('x - difference');                                                        
xlabel('t in seconds');                              
ylabel('x difference'); 
grid minor;

subplot(3,1,3);
plot(t,z_score, 'b');            
legend('z_score');                                                        
xlabel('t in seconds');                              
ylabel('z_score'); 
grid minor;

%%

%saving workspace to file
c = clock;
formatout = 'dd-mm-yy HH:MM';
dir_name = strcat('acc_tests/',datestr(c,formatout));
save(dir_name);

saveas(figure(1), dir_name, 'jpg');
saveas(figure(1), dir_name);

