%% Special Meeting and Proxy Fight
%% Load the data and remove irregular ovservations if necessary (2 sec)
tic
clear 
clc
load SignalVote
% load SignalVoteRestricted
% load ResidualSupport
% load SVF
% SignalVote =SVF;
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
nansum(nansum(~isnan(SignalVote))); % total signals
toc

%% Restrict sample based on meeting type
MeetingType(MeetingType~=1) = nan;
MeetingType(MeetingType==1) = 1;    
% Keep only a particular type of a meeting
SignalVote = SignalVote.*MeetingType;
nansum(nansum(~isnan(SignalVote))); % total signals

%% Fade the signal
SignalVoteTwo = signal_transformation(SignalVote,me); 

%% Assign stocks into value weighted portfoloio and make voting portfolios (5 sec)
tic
% High shareholder support is top; low support is bottom
signal= lagmatrix(SignalVote,0);   
NP = 10; % Indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal, NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
% Breakpoints for the deciles are either based on 
% (1) all-firms (NYSE, AMEX and NASDAQ) or 
% (2) just NYSE firms.
% For the all-form breakpoint portfolios have an equal number of firms in each portfolio.
% For the NYSE breakpoint portfolio, there are an equal number of NYSE firms in each portfolio

% Finally, make the voting portfolios
% obtain pretVOT which is the 10 decile portfolios and 11th portfolio which is the long short anomaly
% First with value-weights
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,1);          % basic value-weighted 
% If the regression does not work it means it loads the wrong FF factors
Number_Firms = number_of_firms(indVOT);  % Number of stocks

% Do the proper regressions
NumberOfFactors = 1;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
% Coeffient 1 is the constant, 2 is MKT, 3 is SMB, 4 is HML, 5 RMW, 6 is CMA, 7 is MOM
toc
