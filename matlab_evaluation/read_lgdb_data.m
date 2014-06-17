function [x,y,z,t, accel, fs, t_abs, alpha1,beta1,gamma1] = read_lgdb_data(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as column vectors.
%   [T,TREL,X,Y,Z,ALPHA1,BETA1,GAMMA1] = IMPORTFILE(FILENAME) Reads data
%   from text file FILENAME for the default selection.
%
%   [T,TREL,X,Y,Z,ALPHA1,BETA1,GAMMA1] = IMPORTFILE(FILENAME, STARTROW,
%   ENDROW) Reads data from rows STARTROW through ENDROW of text file
%   FILENAME.
%
% Example:
%   [t,t_abs,x,y,z,alpha1,beta1,gamma1] = importfile('g03_L1_t08.csv',2,
%   122);

%% Initialize variables.
delimiter = ',';
if nargin<=2
    startRow = 2;
    endRow = inf;
end

%% Format string for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
%	column4: double (%f)
%   column5: double (%f)
%	column6: double (%f)
%   column7: double (%f)
%	column8: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%f%f%f%f%f%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Allocate imported array to column variable names\

% note that here, I change tRel to t. and t becomes t_abs
t_abs = dataArray{:, 1}.';
t = dataArray{:, 2}.';
x = dataArray{:, 3}.';
y = dataArray{:, 4}.';
z = dataArray{:, 5}.';
alpha1 = dataArray{:, 6}.';
beta1 = dataArray{:, 7}.';
gamma1 = dataArray{:, 8}.';

% total acceleration
accel = sqrt(x.^2 + y.^2 + z.^2);
fs = 1/mean(diff(t));
