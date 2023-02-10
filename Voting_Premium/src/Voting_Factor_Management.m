%% Create the voting anomaly with management or shareholder proposals only
%% Load the data and remove irregular ovservations if necessary (2 sec)
tic
clear 
clc
load SignalVoteManagement
load SignalVoteTShareholder
load dates
load me
load ret
load NYSE
load MeetingType
load MeetingTypeCategories
% Itterate for shareholder (SignalVoteTShareholder) or managment (SignalVoteManagement)
SignalVoteS= SignalVoteTShareholder;       
SignalVoteM= SignalVoteManagement; 
% Restricted date vector
RestrictedDates = dates(find(~isnan(nanmean(SignalVoteS,2)))); % Gives you the restricted dates for the anomaly
% All the non-common stock firms do not even have market capitlization data
% Therefore the sort only uses NYSE, amex and NASDAQ common stocks as in the literature
% All the firms wihout market capitalization data were removed in SignalTransformation script
ShareholderSignals = nansum(nansum(~isnan(SignalVoteS))) % total signals
ManagementSignals = nansum(nansum(~isnan(SignalVoteM))) % total signals
toc

%% Assign stocks into value weighted portfoloio and make voting portfolios for shareholder (5 sec)
tic
signal= lagmatrix(SignalVoteS,2);   
% SignalAfter1Fading = signal_transformation(signal,me);   % Adds one more month to the signal
% SignalAfter3Fading = signal_transformation3(signal,me);   % Adds three more month to the signal
NP = 3; % Indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal, NP); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,1,3,0);          % basic value-weighted 
Number_Firms = number_of_firms(indVOT);  % Number of stocks
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
% Coeffient 1 is the constant, 2 is MKT, 3 is SMB, 4 is HML, 5 RMW, 6 is CMA, 7 is MOM
toc

%% Assign stocks into value weighted portfoloio and make voting portfolios for management (5 sec)
tic
signal= lagmatrix(SignalVoteM,2);
NP = 10; % Indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal, NP,NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,3,0);          % basic value-weighted 
% Number_Firms = number_of_firms(indVOT);  % Number of stocks
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
% Coeffient 1 is the constant, 2 is MKT, 3 is SMB, 4 is HML, 5 RMW, 6 is CMA, 7 is MOM
toc