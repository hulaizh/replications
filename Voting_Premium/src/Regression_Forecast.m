%% Predict vote support from a regression
clear
clc
load T
T(T.Permno==0,:) = []; % Remove rows without permno
T(isnan(T.SupportAdjusted),:) = []; % Remove rows without data on support adjusted 

%% Remove ambigous resolutions
summary(T.voteResult)
% Remove pending without support
temp = T.voteResult == {'Pending'};
temp2 = (T.SupportAdjusted==0);
Select = logical(temp.*temp2);
T(Select,:) = [];
% Remove withdrawn without participation
temp = T.voteResult == {'Withdrawn'};
temp2 = (T.SupportAdjusted==0);
Select = logical(temp.*temp2);
T(Select,:) = [];
T(T.voteResult == {'Not Disclosed'},:) = [];
T(T.voteResult == {'Not Applicable'},:) = [];
clear temp temp2 Select
summary(T.voteResult)

%% Merge responses - Management Recomendation
% Management recomendation
clc
categories(T.MGMTrec)   
T.MGMTrec(T.MGMTrec == 'None') = 'Against';
T.MGMTrec(T.MGMTrec == 'Do Not Vote') = 'Against';
T.MGMTrec(T.MGMTrec == 'Withhold') = 'Against';
T.MGMTrec(T.MGMTrec == 'Abstain') = 'Against';
T.MGMTrec(T.MGMTrec == 'One Year') = ' ';   % Put the say on pay frequency into undefined
T.MGMTrec(T.MGMTrec == 'Three Years') = ' ';
T.MGMTrec(T.MGMTrec == 'Two Years') = ' ';
T.MGMTrec = removecats(T.MGMTrec,{'None','Do Not Vote','Withhold','Abstain','One Year','Three Years','Two Years'});
summary(T.MGMTrec)

%% Merge responses - ISS Recomendation
clc
categories(T.ISSrec)
T.ISSrec(T.ISSrec== 'Abstain') = 'Against';
T.ISSrec(T.ISSrec== 'Do Not Vote') = 'Against';
T.ISSrec(T.ISSrec== 'None') = 'Against';
T.ISSrec(T.ISSrec== 'Withhold') = 'Against';
T.ISSrec(T.ISSrec== 'Refer') = ' ';
T.ISSrec(T.ISSrec== 'One Year') = ' ';
T.ISSrec = removecats(T.ISSrec,{'Abstain','Do Not Vote','None','Withhold','Refer','One Year'});
summary(T.ISSrec)

%% Make categorical and select subsample for faster regressions
T.Month = categorical(T.Month);
T.Permno = categorical(T.Permno);
T.MeetingType = categorical(T.MeetingType);
T.SICCD = categorical(T.SICCD);
S = T(:,[10,31,33,17:18,12,34,8,36,39]);

%% Fit linear model (topic dummies)
clc
lmTopic = fitlm(S, 'SupportAdjusted ~ 1+ AgendaGeneralDesc')    % The linear model

%% Fit linear model (only dummies)
clc
lmFE = fitlm(S, 'SupportAdjusted ~ 1+ AgendaGeneralDesc + Month + Year + MeetingType')    % The linear model

%% Fit linear model (Eveything)
clc
lmEvery = fitlm(S, 'SupportAdjusted~ 1+MGMTrec + ISSrec  + ISSrec* MGMTrec +  sponsor  + sponsor*MGMTrec + sponsor*ISSrec + sponsor*ISSrec*MGMTrec + AgendaGeneralDesc + Month + Year + MeetingType + SICCD')

%% Fit linear model (topic dummies and recomendation dummies)
clc
lmFullModel = fitlm(S, 'SupportAdjusted~ 1+MGMTrec + ISSrec  + ISSrec* MGMTrec +  sponsor  + sponsor*MGMTrec + sponsor*ISSrec + sponsor*ISSrec*MGMTrec + AgendaGeneralDesc')

%% Understand the residuals
plotResiduals(lmFullModel)
plotResiduals(lmFullModel,'fitted')

%% Save the residuals
% Add restrictions that they cannot be above 1 or below 0
clc
Fitted = lmFullModel.Fitted;
Fitted(Fitted<0) = 0;
Fitted(Fitted>1) = 1;
ResidualsAbnormalSupport = lmFullModel.Variables.SupportAdjusted-Fitted;
PermnoResiduals = S.Permno;
DateResiduals = T.YearMonth;
DatePermnoResiduals = DateResiduals*1000000+PermnoResiduals;
Topic = T.AgendaGeneralDesc;
save DatePermnoResiduals DatePermnoResiduals
save ResidualsAbnormalSupport ResidualsAbnormalSupport
save Topic Topic

%% Match Format
clear
load ResidualsAbnormalSupport
load Topic

%% Calculate standard deviation of residuals (17 min)
tic
[G,GN] = grp2idx(Topic);  % Turns topic into numeric values
Sd = nan(size(ResidualsAbnormalSupport)); % Prealocate
for i = 1:rows(G)
    Sd(i) = nanstd(ResidualsAbnormalSupport(G==G(i)));  % Calculate sd for residuals in each topic
end
toc

%% Save
SdResidual = Sd;
save SdResidual SdResidual

%% The signal is the residual divided by standard deviaiton
clc
clear
load PermnoDate
load DatePermnoResiduals
load ResidualsAbnormalSupport
load Topic
load SdResidual
% ResidualsAbnormalSupport = ResidualsAbnormalSupport./SdResidual;

%% Divide abnormal support by deviation of abnormal support per topic
J = array2table(ResidualsAbnormalSupport);
J.DatePermnoResiduals = DatePermnoResiduals;
J = sortrows(J,'DatePermnoResiduals','ascend');
PermnoDate(1:925,:) = [];
[matched, location] = ismember(DatePermnoResiduals,PermnoDate); % Gives you the location of the match

%% Find the switch between companies
% First we need to average abnormal support in the same period
% You lose the first and last signal with the code
for i = 2:rows(location)
 temp(i) = ~(location(i)==location(i-1));
end
temp = find((temp'+0)==1);

for i = 1:(rows(temp)-1)
ARAS(i) = nanmean(ResidualsAbnormalSupport(temp(i):(temp(i+1)-1)));
end
% ARAS is the signal
% ARAS(end+1) = nanmean(ResidualsAbnormalSupport(338335:end));    % Add the final number
DPRU = DatePermnoResiduals(temp);
DPRU(end) = [];


%% Transform the residuals into wide format
[~,location] = ismember(DPRU,PermnoDate);
ResidualSupport = nan(size(PermnoDate));
ResidualSupport(location)= ARAS;
temp = nan((1093-168),cols(ResidualSupport));   % Match the size to normal signals
ResidualSupport = [temp;ResidualSupport];
save ResidualSupport ResidualSupport

%% Assign stocks into value weighted portfoloio and make voting portfolios (5 sec)
clc
load dates
load me
load ret
load NYSE
load ResidualSupport
SignalVote = ResidualSupport;

%% High shareholder upport is top; low support is bottom
signal= lagmatrix(SignalVote,-4);   
NP = 10; % Indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(signal, NP,NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
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
% Coeffient 1 is the constant, 2 is MKT, 3 is SMB, 4 is HML, 5 RMW, 6 is CMA, 7 is MO

%% Before 
clc
clear
load dates
load me
load ret
load NYSE
load ResidualSupport
SignalVote = ResidualSupport;
NP = 5; 
signal= lagmatrix(SignalVote,-4);   
indVOT4 = aprts(signal, NP); 
signal= lagmatrix(SignalVote,-3); 
indVOT3 = aprts(signal, NP); 
signal= lagmatrix(SignalVote,-2); 
indVOT2 = aprts(signal, NP); 
signal= lagmatrix(SignalVote,-1); 
indVOT1 = aprts(signal, NP); 

%%  Select all stocks that have fallen in a portfolio 1 in each month
indVOT = nan(size(indVOT4));
indVOT(indVOT4==1|indVOT3==1|indVOT2==1|indVOT1==1) = 1;
indVOT(indVOT4==2|indVOT3==2|indVOT2==2|indVOT1==2) = 2;
indVOT(indVOT4==3|indVOT3==3|indVOT2==3|indVOT1==3) = 3;
indVOT(indVOT4==4|indVOT3==4|indVOT2==4|indVOT1==4) = 4;
indVOT(indVOT4==5|indVOT3==5|indVOT2==5|indVOT1==5) = 5;

%%
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,1,0);          % basic value-weighted 
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
% Coeffient 1 is the constant, 2 is MKT, 3 is SMB, 4 is HML, 5 RMW, 6 is CMA, 7 is MO
Number_Firms = number_of_firms(indVOT);  % Number of stocks

%% After
clc
clear
load dates
load me
load ret
load NYSE
load ResidualSupport
SignalVote = ResidualSupport;
NP = 5; 
signal= lagmatrix(SignalVote,0);   
indVOT1 = aprts(signal, NP); 
signal= lagmatrix(SignalVote,1); 
indVOT2 = aprts(signal, NP); 
signal= lagmatrix(SignalVote,2); 
indVOT3 = aprts(signal, NP); 

%%  Select all stocks that have fallen in a portfolio 1 in each month
indVOT = nan(size(indVOT1));
indVOT(indVOT1==1|indVOT2==1|indVOT3==1) = 1;
indVOT(indVOT1==2|indVOT2==2|indVOT3==2) = 2;
indVOT(indVOT1==3|indVOT2==3|indVOT3==3) = 3;
indVOT(indVOT1==4|indVOT2==4|indVOT3==4) = 4;
indVOT(indVOT1==5|indVOT2==5|indVOT3==5) = 5;

%%
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,1,0);          % basic value-weighted 
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
% Coeffient 1 is the constant, 2 is MKT, 3 is SMB, 4 is HML, 5 RMW, 6 is CMA, 7 is MO
