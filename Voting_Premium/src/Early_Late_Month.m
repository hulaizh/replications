% Early and late month
% Restrict sample to a set of firms that have a meeting in an eary part of the month

tic 
clc
clear
% load ShareholderSupportUnique
load T
[~,~,day] = ymd(T.MeetingDate);
% Date Permno Structure
load permno
load dates
temp=repmat(permno',rows(dates),1);
temp2 = repmat(dates,1,rows(permno));
DatePermno = temp2*1000000+temp;
clear temp temp2

% Create the day matrix
% All days are the same so you don't have to worry about overlapp; it
% inputs the last day with overlap
[LIA,LOCB] = ismember(T.DatePermno,DatePermno);
Day = nan(size(DatePermno));
Day(LOCB) = day;
clearvars -except Day
toc

%% Create the restricted factors
load SignalVote
load dates
load me
load ret
load NYSE
load MeetingType
load MeetingTypeCategories
% Restricted date vector
% All the non-common stock firms do not even have market capitlization data
% Therefore the sort only uses NYSE, amex and NASDAQ common stocks as in the literature
% All the firms wihout market capitalization data were removed in SignalTransformation script
Total = nansum(nansum(~isnan(SignalVote))); % total signals

%% Early is the first 15 days, late is after
Early = Day;
temp = find(Early>15);
Early(temp) = nan;
Early(isfinite(Early)) = 1;
Late = Day;
temp = find(Late<16);
Late(temp) = nan;
Late(isfinite(Late)) = 1;
SignalVoteEarly = SignalVote.*Early;
Early =  nansum(nansum(~isnan(SignalVoteEarly))); % total signals
SignalVoteLate = SignalVote.*Late;

%%  Assign stocks into value weighted portfoloio and make voting portfolios (5 sec)
tic
% High shareholder upport is top; low support is bottom
signal= lagmatrix(SignalVoteEarly,-2);   
NP = 3; % Indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
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
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
% Coeffient 1 is the constant, 2 is MKT, 3 is SMB, 4 is HML, 5 RMW, 6 is CMA, 7 is MOM
toc