%% Create the voting anomaly
%% Load the data and remove irregular ovservations if necessary (2 sec)
tic
clear 
clc
load SignalVote
% load SignalVoteRestricted
% load ResidualSupport
% load SVF
% load SignalRelativeToManagement
% SignalVote =SignalRelativeToManagement;
load dates
load me
load ret
load NYSE
load MeetingType
load MeetingTypeCategories
% Restricted date vector
% RestrictedDates = dates(find(~isnan(nanmean(SignalVote,2)))); % Gives you the restricted dates for the anomaly
% All the non-common stock firms do not even have market capitlization data
% Therefore the sort only uses NYSE, amex and NASDAQ common stocks as in the literature
% All the firms wihout market capitalization data were removed in SignalTransformation script
nansum(nansum(~isnan(SignalVote))); % total signals
toc

%% Fade the signal
SignalVote= signal_transformation(SignalVote,me);

%% Exclude stocks below me median
AltSignal = SignalVote;
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
AltSignal(me<BreakpoinT) = nan;    % Remove all companies with values below(above) the break point

%% Assign stocks into value weighted portfoloio and make voting portfolios (5 sec)
tic
% High shareholder upport is top; low support is bottom
signal= lagmatrix(SignalVote,-4);   
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
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,1,0);          % basic value-weighted 
% If the regression does not work it means it loads the wrong FF factors
% Number_Firms = number_of_firms(indVOT);  % Number of stocks

% Do the proper regressions
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
% Coeffient 1 is the constant, 2 is MKT, 3 is SMB, 4 is HML, 5 RMW, 6 is CMA, 7 is MOM
toc

%% Save
save indVOT indVOT
save pretVOT pretVOT

%% Number of signals
A = [nansum(Number_Firms,2),dates];

%% Alternative start dates (2 sec)
tic
signal(1:(find(dates==200401)),:) = nan;    % Select to kick out dates such as early sample years
NP = 2; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal,NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,4);          % basic value-weighted 
toc

%% Alternative Signal and Firm size Restrictions 
%% Load the alternative signal and place the size restrictions (1 sec)
tic
load SignalAfter1Fading
% Just load the faded signal from before to save time (from signal transformation script)
AltSignal2 = SignalAfter1Fading;

%% Exclude stocks below me median
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
AltSignal2(me>BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
toc

%% Assign to portfolios and do the regressions
tic
clc
NP = 3; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOTAlt = aprts(AltSignal2,NP,NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOTAlt,pretVOTAlt] = tsregs(ret,indVOTAlt,dates,me,4);          % basic value-weighted 
% Do the proper regressions
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result1] = ts_benchmark_regression(pretVOTAlt, NumberOfFactors,dates);
Number_Firms = number_of_firms(indVOTAlt);  % Number of stocks
nanmean(Number_Firms,1)
toc

%% Alternative Signal
%% Three month fading signal (1 sec)
tic
load SignalAfter3Fading
% Load the signal that has three more months of fading
% Exclude stocks
AltSignal = SignalAfter3Fading;
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
AltSignal(me>BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
toc

%% Assign to portfolios and do the regressions (4 sec)
tic
NP = 3; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOTAlt = aprts(AltSignal, NP); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOTAlt,pretVOTAlt] = tsregs(ret,indVOTAlt,dates,1,4);          % basic value-weighted 
% Do the proper regressions
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result3] = ts_benchmark_regression(pretVOTAlt, NumberOfFactors,dates);
Number_Firms = number_of_firms(indVOTAlt);  % Number of stocks
toc

%% Alternative signal
%% Six month fading signal (1 sec)
tic
load SignalAfter6Fading
% Load the signal that has six more months of fading
% Exclude stocks
AltSignal3 = SignalAfter6Fading;
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
AltSignal3(me>BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
toc

%% Assign to portfolios and do the regressions (4 sec)
tic
NP = 3; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOTAlt = aprts(AltSignal3, NP); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOTAlt,pretVOTAlt] = tsregs(ret,indVOTAlt,dates,me,4);          % basic value-weighted 
% Do the proper regressions
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result6] = ts_benchmark_regression(pretVOTAlt, NumberOfFactors,dates);
Number_Firms = number_of_firms(indVOTAlt);  % Number of stocks
toc

%% Consistency check (use an alternative code for portfolio assignment) (24 sec)
tic 
[pretVOTAlt2,xretLongShort] = univariate_decile_sort(indVOTAlt,ret,me); 
[Result2] = ts_benchmark_regression(pretVOTAlt2, NumberOfFactors,dates);
toc

%% Alternative signal
%% Twelve month fading signal (1 sec)
tic
load SignalAfter12Fading
% Load the signal that has six more months of fading
% Exclude stocks
AltSignal3 = SignalAfter12Fading;
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
AltSignal3(me>BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
toc

%% Assign to portfolios and do the regressions (4 sec)
tic
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOTAlt = aprts(AltSignal3, NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOTAlt,pretVOTAlt] = tsregs(ret,indVOTAlt,dates,me,4);          % basic value-weighted 
% Do the proper regressions
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result12] = ts_benchmark_regression(pretVOTAlt, NumberOfFactors,dates);
Number_Firms = number_of_firms(indVOTAlt);  % Number of stocks
nanmean(Number_Firms,1)
toc

%% Consistency check (use an alternative code for portfolio assignment) (24 sec)
tic 
[pretVOTAlt2,xretLongShort] = univariate_decile_sort(indVOT,ret,me); 
[Result2] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
toc

%% EW without NYSE break points 
%% Assign stocks into equally weighted portfoloios (3 sec)
tic
load SignalVote
signal = SignalVote;
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal,NP); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
Number_Firms = number_of_firms(indVOT);  % There should be the same number of stocks per portfolio
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,1,4,0);          % EW 
% Do the proper regressions
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
toc

%% Investigate the features of the disagreement measure
%% Characteristics values (6 sec)
tic
clc
clear 
load me
load ret
load NYSE
load SignalVote
signal= SignalVote;   % Swith the sign so they apprear in the right order
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal,NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
% Calculate the value weights
[vwVOT1,Check] = value_weights(1,me,indVOT);
[vwVOT10,Check] = value_weights(10,me,indVOT);
clc
VoteFirst = nansum(signal.*vwVOT1,2);
VoteFirst(VoteFirst == 0) = [];
Bottom_vw_mean = mean(VoteFirst);
% Calculate the average value in the bottom portfolio (value weighted CS)
toc
%% Calculate the value weighted characteristic top 
clc
VoteTenth = nansum(signal.*vwVOT10,2);
VoteTenth(VoteTenth == 0) = []
Top_vw_mean = mean(VoteTenth)
% Calculate the average value in the top portfolio (value weighted CS)

%% The equally weighted CS & TS average of the characteristics in the data
clc
SignalMean = nanmean(signal,2);
SignalMean (isnan(SignalMean)==1) = []
Std = std(SignalMean)
SignalMean2 = mean(SignalMean)

%% Cross sectional dispersion
CSDispersion = nanstd(signal,0,2)
CSDispersion2 = nanmean(CSDispersion)


%% Time distribution of returns
clear
clc
load pretVOT
load dates
load mkt
Returns = pretVOT(~isnan(nanmean(pretVOT,2)),:);
Dates = dates(~isnan(nanmean(pretVOT,2)),:);
MKT = mkt(~isnan(nanmean(pretVOT,2)));

temp = 100;
r = mod(Dates,temp);    %Get the months

ReturnJan = Returns(find(r==1),:);
ReturnFeb = Returns(find(r==2),:);
ReturnMar = Returns(find(r==3),:);
ReturnApr = Returns(find(r==4),:);
ReturnMay = Returns(find(r==5),:);
ReturnJune = Returns(find(r==6),:);
ReturnJuly = Returns(find(r==7),:);
ReturnAug = Returns(find(r==8),:);
ReturnSep = Returns(find(r==9),:);
ReturnOct = Returns(find(r==10),:);
ReturnNov = Returns(find(r==11),:);
ReturnDec = Returns(find(r==12),:);

MKTJan = nanmean(MKT(find(r==1),:));
MKTFeb = nanmean(MKT(find(r==2),:));
MKTMar = nanmean(MKT(find(r==3),:));
MKTApr = nanmean(MKT(find(r==4),:));
MKTMay = nanmean(MKT(find(r==5),:));
MKTJune = nanmean(MKT(find(r==6),:));
MKTJuly = nanmean(MKT(find(r==7),:));
MKTAug = nanmean(MKT(find(r==8),:));
MKTSep = nanmean(MKT(find(r==9),:));
MKTOct = nanmean(MKT(find(r==10),:));
MKTNov = nanmean(MKT(find(r==11),:));
MKTDec = nanmean(MKT(find(r==12),:));
MKTYear = [MKTJan;MKTFeb;MKTMar;MKTApr;MKTMay;MKTJune;MKTJuly;MKTAug;MKTSep;MKTOct;MKTNov;MKTDec];

YearDistribution = [nanmean(ReturnJan);nanmean(ReturnFeb);nanmean(ReturnMar);nanmean(ReturnApr);....
    nanmean(ReturnMay);nanmean(ReturnJune);nanmean(ReturnJuly);nanmean(ReturnAug);...
    nanmean(ReturnSep);nanmean(ReturnOct);nanmean(ReturnNov);nanmean(ReturnDec)];

clearvars -except YearDistribution MKTYear

%% Calendar effects