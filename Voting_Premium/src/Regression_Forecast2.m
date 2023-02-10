%% Predict vote support from a regression 2
clear
clc
load T
T(T.Permno==0,:) = []; % Remove rows without permno
T(isnan(T.SupportAdjusted),:) = []; % Remove rows without data on support adjusted 

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
T.MeetingType = categorical(T.MeetingType);
S = T(:,[10,31,33,17:18,12,34,8,36]);

%% Fit linear model (topic dummies)
clc
lmTopic = fitlm(S, 'SupportAdjusted ~ 1+ AgendaGeneralDesc')    % The linear model

%% Save the residuals
% Add restrictions that they cannot be above 1 or below 0
clc
Fitted = lmTopic.Fitted;
Fitted(Fitted<0) = 0;
Fitted(Fitted>1) = 1;
ResidualsAbnormalSupport2 = lmTopic.Variables.SupportAdjusted-Fitted;
PermnoResiduals = S.Permno;
DateResiduals = T.YearMonth;
DatePermnoResiduals2 = DateResiduals*1000000+PermnoResiduals;
Topic2 = T.AgendaGeneralDesc;
save DatePermnoResiduals2 DatePermnoResiduals2
save ResidualsAbnormalSupport2 ResidualsAbnormalSupport2
save Topic2 Topic2

%% Match Format
clear
load ResidualsAbnormalSupport2
load Topic2

%% Calculate standard deviation of residuals (17 min)
tic
[G,GN] = grp2idx(Topic2);  % Turns topic into numeric values
Sd2 = nan(size(ResidualsAbnormalSupport2)); % Prealocate
for i = 1:rows(G)
    Sd2(i) = nanstd(ResidualsAbnormalSupport2(G==G(i)));  % Calculate sd for residuals in each topic
end
toc

%% Save
SdResidual2 = Sd2;
save SdResidual2 SdResidual2

%% The signal is the residual divided by standard deviaiton
clc
clear
load PermnoDate
load DatePermnoResiduals2
load ResidualsAbnormalSupport2
load Topic2
load SdResidual2
% ResidualsAbnormalSupport2 = ResidualsAbnormalSupport2./SdResidual2;

%% Divide abnormal support by deviation of abnormal support per topic
J = array2table(ResidualsAbnormalSupport2);
J.DatePermnoResiduals = DatePermnoResiduals2;
J = sortrows(J,'DatePermnoResiduals','ascend');
PermnoDate(1:925,:) = [];
[matched, location] = ismember(DatePermnoResiduals2,PermnoDate); % Gives you the location of the match

%% Find the switch between companies
% First we need to average abnormal support in the same period
% You lose the first and last signal with the code
for i = 2:rows(location)
 temp(i) = ~(location(i)==location(i-1));
end
temp = find((temp'+0)==1);

for i = 1:(rows(temp)-1)
ARAS(i) = nanmean(ResidualsAbnormalSupport2(temp(i):(temp(i+1)-1)));
end
% ARAS is the signal
% ARAS(end+1) = nanmean(ResidualsAbnormalSupport(338335:end));    % Add the final number
DPRU = DatePermnoResiduals2(temp);
DPRU(end) = [];


%% Transform the residuals into wide format
[~,location] = ismember(DPRU,PermnoDate);
ResidualSupport2 = nan(size(PermnoDate));
ResidualSupport2(location)= ARAS;
temp = nan((1093-168),cols(ResidualSupport2));   % Match the size to normal signals
ResidualSupport2 = [temp;ResidualSupport2];
save ResidualSupport2 ResidualSupport2

%% Assign stocks into value weighted portfoloio and make voting portfolios (5 sec)
clc
load dates
load me
load ret
load NYSE
load MeetingType
load MeetingTypeCategories
load ResidualSupport2
SignalVote = ResidualSupport2;

%% High shareholder upport is top; low support is bottom
signal= lagmatrix(SignalVote,0);   
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
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,me,1);          % basic value-weighted 
% If the regression does not work it means it loads the wrong FF factors
Number_Firms = number_of_firms(indVOT);  % Number of stocks

% Do the proper regressions
NumberOfFactors = 1;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
% Coeffient 1 is the constant, 2 is MKT, 3 is SMB, 4 is HML, 5 RMW, 6 is CMA, 7 is MO
