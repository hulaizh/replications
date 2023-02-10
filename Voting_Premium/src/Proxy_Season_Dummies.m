%% Proxy season dummies
% Check if there are higher alphas in proxy seasons or outside of proxy seasons
clear
load pretVOT; load MeetingDatePremium; load dates
FF_load_script;   

MeetingDatePremium(1:926) = [];
dates(1:926) = [];
pretVOT(1:926,:) = [];
FFFactors(1:475,:) = [];
FFFactors(168:end,:) = [];
Rf = table2array(FFFactors(:,end));
factors = table2array(FFFactors(:,2:7));

%% April, May and June dummy (04, 05, 06)
Month = [1,2,3,4,5,6,7,8,9,10,11,12];
Month = repmat(Month,1,15)';
Month(1) = [];
Month(168:end) = [];
Month(Month==1) = 0;
Month(Month ==4 | Month ==5 | Month == 6) = 1;
Month(Month~=1) = 0;
InvertedMonth = Month;
InvertedMonth(InvertedMonth == 0) = 2;
InvertedMonth(InvertedMonth == 1) = 0;
InvertedMonth(InvertedMonth == 2) = 1;

%% Regressions Meeting Month
y = MeetingDatePremium-FFFactors.RF;
x = [Month, factors];
Reg = fitlm(x,y)

%% Regressions Abnormal Support Long Short
y = -pretVOT(:,11);
x = [Month, factors];
Reg2 = fitlm(x,y)

%% Regressions Abnormal Support Short
y = pretVOT(:,10)-Rf;
x = [ factors];
Reg3 = fitlm(x,y)

%% Mixed Bet
y = [MeetingDatePremium-pretVOT(:,10)];
x = [factors];
Reg4 = fitlm(x,y)

%% Average Bet
y = nanmean([MeetingDatePremium - Rf, -pretVOT(:,11)],2);
x = [factors];
Reg5 = fitlm(x,y)

%% Independence
y = -pretVOT(:,11);
x =  [FFFactors.MKT,MeetingDatePremium-FFFactors.RF];
Reg6 = fitlm(x,y)

%% Independence
y = MeetingDatePremium;
x =  [FFFactors.MKT,-pretVOT(:,11)];
Reg7 = fitlm(x,y)

%% On the other factors (ittarate y)
nanmean(FFFactors.MKT)
[~,~,~,stat] = ttest(FFFactors.MKT)

%
y = FFFactors.MKT;
x = [MeetingDatePremium-FFFactors.RF];
Reg7 = fitlm(x,y)

%% Mean
nanmean(FFFactors.MKT)
[~,~,~,stat] = ttest(FFFactors.MKT)

nanmean(MeetingDatePremium-FFFactors.RF)
[~,~,~,stat] = ttest(MeetingDatePremium-FFFactors.RF)

nanmean(-pretVOT(:,11))
[~,~,~,stat] = ttest(-pretVOT(:,11))

%%
y = FFFactors.MKT;
x = [MeetingDatePremium-FFFactors.RF,-pretVOT(:,11),FFFactors.SMB,FFFactors.HML,FFFactors.RMW,FFFactors.CMA,FFFactors.MOM];
Reg7 = fitlm(x,y)