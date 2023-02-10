%% Create the voting anomaly with restrictions
%% Load the data and remove irregular ovservations if necessary (2 sec)
tic
clear 
clc
load SignalVote
load dates
load me
load ret
load NYSE
load MeetingType
load MeetingTypeCategories
% Restricted date vector
RestrictedDates = dates(find(~isnan(nanmean(SignalVote,2)))); % Gives you the restricted dates for the anomaly
% All the non-common stock firms do not even have market capitlization data
% Therefore the sort only uses NYSE, amex and NASDAQ common stocks as in the literature
% All the firms wihout market capitalization data were removed in SignalTransformation script
toc

%% Select votes based on meeting type -(3/168 sec)
tic
MeetingType(MeetingType == 5) = 6; % Merge proxy contest and special
ConsiderOnly = 6; % 1 {'Annual'}; 2 {'Annual/Special'}; 3 {'Bondholder'}; 4 {'Court'}; 5 {'Proxy Contest'}; 6 {'Special'}; 7 {'Written Consent'}
SignalVote(MeetingType~=ConsiderOnly) = nan;       % Exclude everything not considered
SignalVoteFading = signal_transformation2(SignalVote,me);   % Adds x more month to the signal
NP = 5; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 4 for quintiles, 3 for terciles
indVOT = aprts(SignalVoteFading,NP,NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
toc

%% Number of firms
TotalSignals = nansum(nansum(isfinite(SignalVote)))     % This is the total number of abnormal support measures resulting from annual meetings (or special depending on what you select)
Number_Firms = number_of_firms(indVOT);  

%% Create portfolio (8 sec)
tic
[pretVOT] = get_portfolios(indVOT,ret,me,5);   % last argument is the number of portfolios (it should match ind number of portfolios)
[~,pretVOT2] = tsregs(ret,indVOT,dates,me,4);  % alternative method for confirming
toc

%% Do the proper regressions (1 sec)
tic
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[ResultSpec] = ts_benchmark_regression(pretVOT2, NumberOfFactors,dates);
toc

