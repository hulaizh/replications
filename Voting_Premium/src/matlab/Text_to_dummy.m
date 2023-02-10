%% Text to dummy function
% Created by Filip Bekjarovski (05/07/2017)
% Used to transform text (data) into dummy variables
% Input (data) > the row of text data
% Output [dummy, unique, count,percent] > dummy variables for the unique number of elements,
% 'count' gives the frequency of observations and 'percent' gives how often   they appear in the data
% [dummy,Unique, count, percent] = text_to_dummy(data)

function [dummy,Unique, count, percent] = text_to_dummy(data)

Unique= unique(data);    % find the unique text files

for i=1:size(Unique,1)
    dummy(:,i) = ismember(data, Unique(i)); % gives you 1 when they match and zero otherwise
end

dummy = dummy+0;    % Transforms from logical to double

% Count the frequency with which the observation appears
for i=1:size(Unique,1)
    count(:,i)=sum(dummy(:,i),'omitnan');
end
count = count';

% Calculate how often the variable appears as percent
for i=1:size(Unique,1)
    percent(:,i)=sum(dummy(:,i),'omitnan')/size(dummy,1);
end
percent = percent';
end