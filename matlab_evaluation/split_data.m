function [ train_set, test_set ] = split_data(f, persons, repetitions)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%persons = 'A-Z';
%repetitions = '00|01|02|10';

% if repetition 0 is selected, 10 will be selected as well....
regex = ['g(..)_[' persons ']._t(' repetitions ')\.mat'];

% need some samples for training, others for validation
train_set = {};
test_set= {};
train_counter = 1;
test_counter = 1;

% 'start' in regexpi returns the index
% 'match' in regexpi returns the string that matched
for i=1: size(f,1)
    if regexpi(f{i,1}, regex ,'start') == 1
        train_set(train_counter, :) = f(i,:);
        train_counter = train_counter + 1;
    else 
        test_set(test_counter, :) = f(i,:);
        test_counter = test_counter + 1;
    end
end

assert(size(f,1) == (size(test_set,1) + size(train_set, 1)));


end

