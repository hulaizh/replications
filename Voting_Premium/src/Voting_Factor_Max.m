%% Create the voting anomaly with MAX
% Same code as before just replace the average disagreement signal with MAX
clear 
clc
load SignalVoteMax
% When you load the data, change to SignalVoteMax2  (for the 2 extreme outcomes
% measure) and simple SignalVoteMax for the baseline case with 3 extreme outcomes
SignalVote = SignalVoteMax;
clear SignalVoteMax
load dates
load me
load ret
load NYSE

%% Remove firms without market capitalization data in this and previous period
SignalVote((isnan(me)))= nan;
SignalVote(isnan(lagmatrix(me,1))) = nan;  
SignalVote(isnan(lagmatrix(ret,-1))) = nan;  

% Restricted date vector
RestrictedDates = dates(find(~isnan(nanmean(SignalVote,2)))); % Gives you the restricted dates for the anomaly

%% Assign stocks into value weighted portfoloio %%
% (high disagreement is bottom; low disagreement is top portfolio)
% signal= SignalVote*(-1);   % Swith the sign so they apprear in the right order
% signal= lagmatrix(SignalVote*(-1),-2);   % If you want to lag or lead the signal; 1 to push it; -2 for the month before the vote
signal2 = lagmatrix(SignalVote,0);

%% Exclude stocks
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
signal2(me<BreakpoinT) = nan;    % Remove all companies with values below(above) the break point

%%
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal2,NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
% Breakpoints for the deciles are either based on 
% (1) all-firms (NYSE, AMEX and NASDAQ) or 
% (2) just NYSE firms.
% For the all-form breakpoint portfolios have an equal number of firms in each portfolio.
% For the NYSE breakpoint portfolio, there are an equal number of NYSE firms in each portfolio

% Number of stocks
Number_Firms = number_of_firms(indVOT);  

% Finally, make the voting portfolios
% obtain pretVOT which is the 10 decile portfolios and 11th portfolio which is the long short anomaly
% First with value-weights
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,4);          % basic value-weighted 

% Do the proper regressions
NumberOfFactors = 1;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result,SEHAC] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);

%% Save
save indVOT indVOT
save pretVOT pretVOT


%% Alternative start dates
signal= SignalVote*(-1);   % Swith the sign so they apprear in the right order
signal(1:(find(dates==200401)),:) = nan;
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal,NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,4);          % basic value-weighted 

%%
%%%%%%%%%%%%%%%%%%%%%
%% Signal Alternative (two month fading signal) %%
AltSignal = signal_transformation(SignalVote,me);   % Adds one more month to the signal
% AltSignal = AltSignal*(-1);
AltSignal2 = AltSignal;

%% Exclude stocks
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
AltSignal2(me<BreakpoinT) = nan;    % Remove all companies with values below(above) the break point

%%
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOTAlt = aprts(AltSignal2, NP,NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOTAlt,pretVOTAlt] = tsregs(ret,indVOTAlt,dates,me,4);          % basic value-weighted 

% Do the proper regressions
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOTAlt, NumberOfFactors,dates);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Signal Alternative 2 (six month fading signal) - not significant %%
AltSignal2 = signal_transformation2(SignalVote,me);   % Six month fading
AltSignal2 = AltSignal2*(-1);
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOTAlt = aprts(AltSignal2,NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOTAlt,pretVOTAlt] = tsregs(ret,indVOTAlt,dates,me,4);          % basic value-weighted 

%% Do the proper regressions
NumberOfFactors = 3;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOTAlt, NumberOfFactors,dates);

%%
%%%%%%%%%%%%%%%%%%%
% EW Weighted no NYSE break points 
%% Assign stocks into equally weighted portfoloios %%
% (high disagreement is bottom; low disagreement is top portfolio)
signal= SignalVote*(-1);   % Swith the sign so they apprear in the right order
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal,NP); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
% Breakpoints for the deciles are either based on 
% (1) all-firms (NYSE, AMEX and NASDAQ) or 
% (2) just NYSE firms.
% For the all-form breakpoint portfolios have an equal number of firms in each portfolio.
% For the NYSE breakpoint portfolio, there are an equal number of NYSE firms in each portfolio

%% Number of stocks
Number_Firms = number_of_firms(indVOT);  % There should be the same number of stocks per portfolio

%% Finally, make the voting portfolios
% obtain pretVOT which is the 10 decile portfolios and 11th portfolio which is the long short anomaly
clc
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,1,4,0);          % basic value-weighted 

%% Do the proper regressions
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
%%% Quintile Portfolios with NYSE %%%

%% Assign stocks into value weighted quintile portfolios  %%
% (high disagreement is bottom; low disagreement is top portfolio)
signal= SignalVote*(-1);   % Swith the sign so they apprear in the right order
NP = 5; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal,NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
% Breakpoints for the deciles are either based on 
% (1) all-firms (NYSE, AMEX and NASDAQ) or 
% (2) just NYSE firms.
% For the all-form breakpoint portfolios have an equal number of firms in each portfolio.
% For the NYSE breakpoint portfolio, there are an equal number of NYSE firms in each portfolio

%% Number of stocks
Number_Firms = number_of_firms(indVOT);  

%% Finally, make the voting portfolios
% obtain pretVOT which is the 10 decile portfolios and 11th portfolio which is the long short anomaly
clc
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,4);          % basic value-weighted 

%% Do the proper regressions
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
%%% Quintile Portfolios with NYSE %%%

%% Without small stocks %%
signal= SignalVote*(-1);   % Swith the sign so they apprear in the right order
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
signal(me<BreakpoinT) = nan;    % Remove all companies with values below the break point
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal,NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
% Breakpoints for the deciles are either based on 
% (1) all-firms (NYSE, AMEX and NASDAQ) or 
% (2) just NYSE firms.
% For the all-form breakpoint portfolios have an equal number of firms in each portfolio.
% For the NYSE breakpoint portfolio, there are an equal number of NYSE firms in each portfolio

%% Number of stocks
Number_Firms = number_of_firms(indVOT);  

%% Finally, make the voting portfolios
% obtain pretVOT which is the 10 decile portfolios and 11th portfolio which is the long short anomaly
clc
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,4);          % basic value-weighted 

%% Do the proper regressions
NumberOfFactors =1;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result,SEHAC] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
%%% Quintile Portfolios with NYSE %%%


%% Small stocks on longer horrizon
signal= SignalVote*(-1);   % Swith the sign so they apprear in the right order
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
signal(me>BreakpoinT) = nan;    % Remove all companies with values below the break point
AltSignal = signal_transformation2(signal,me); % Make it into a six month fading signal
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(AltSignal,NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
% Breakpoints for the deciles are either based on 
% (1) all-firms (NYSE, AMEX and NASDAQ) or 
% (2) just NYSE firms.
% For the all-form breakpoint portfolios have an equal number of firms in each portfolio.
% For the NYSE breakpoint portfolio, there are an equal number of NYSE firms in each portfolio
% Finally, make the voting portfolios
% obtain pretVOT which is the 10 decile portfolios and 11th portfolio which is the long short anomaly
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,4);          % basic value-weighted 

%% Do the proper regressions
NumberOfFactors =1;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result,SEHAC] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);









%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Characteristics values 
signal= SignalVote*(-1);   % Swith the sign so they apprear in the right order
NP = 10; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal,NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
% Calculate the value weights
[vwVOT1,Check] = value_weights(1,me,indVOT);
[vwVOT10,Check] = value_weights(10,me,indVOT);
clc
VoteFirst = nansum(signal.*vwVOT1,2);
VoteFirst(VoteFirst == 0) = []
Bottom_vw_mean = mean(VoteFirst)
% Calculate the average value in the bottom portfolio (value weighted CS)

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