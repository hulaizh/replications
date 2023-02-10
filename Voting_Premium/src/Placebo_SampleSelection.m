%% Sample Selection and Placebo

tic
clear
clc
load MeetingType; load MeetingTypeCategories
load ret; load me; load dates; load Rf
toc

%% Meeting 
Meeting = MeetingType;
Meeting(isfinite(Meeting)) = 1;
Meeting(~isfinite(Meeting)) = 0;

%% Portfolio of stocks with data
% The value weighted return of the portfolio consisting of firms that have voting data
Select = find(nansum(Meeting)>0);
ind = zeros(size(Meeting));
ind(:,Select) = 1;
ind(~isfinite(ret)) = nan;
ind(~isfinite(me)) = nan;
meX= me.*ind;  % the market cap of firms in portfolio x; checked
meTot = nansum(me.*ind,2);  % the total market cap of firms in portfolio x; it sums the market cap of all firms in portfolio x
vw = bsxfun(@rdivide,meX,meTot);     % we right divide the rows of m1 by meTot1 to get the value weight of each stock in the portfoli; cheked
Check = nansum(vw,2);   % sums the weights ignoring missing values (should be 100%)
ind2 = ind;
ind2(1:926,:) = 0;
ind2(isnan(ind2)) = 0;

RetSample = nansum(ret.*lagmatrix(vw,1),2)-rf; 
RetSample2 = RetSample;
RetSample2(1:926) = nan;

%% Sample selection bias of  0.020% monthly
FF_load_script;   
[Result] = ts_benchmark_regression(RetSample2,2,dates)
[results,pret] = tsregs(ret,ind2,dates,vw,3);

%% Placebo (1h)
tic
for s = 1:2000;
for i = 1:1093
Placebo(i,:) = rand(1,31599)>.9;    % 0.9 means 10% with a pseudo meeting
end
Placebo = Placebo+0;
Placebo(~isfinite(ret)) = nan;
Placebo(~isfinite(me)) = nan;
Placebo = lagmatrix(Placebo,-3);
Placebo(isnan(Placebo)) = 0;
Placebo(1:926,:) = 0;
meX= me.*Placebo;  % the market cap of firms in portfolio x; checked
meTot = nansum(me.*Placebo,2);  % the total market cap of firms in portfolio x; it sums the market cap of all firms in portfolio x
vw = bsxfun(@rdivide,meX,meTot);     % we right divide the rows of m1 by meTot1 to get the value weight of each stock in the portfoli; cheked
% Restricted ret
RetSample3 = nansum(ret.*lagmatrix(vw,1),2)-rf;
RetSample3(1:926) = nan;
RetSample3(1091:end) = nan;
[Result] = ts_benchmark_regression(RetSample3,1,dates);
Alphas(s) = Result.Coefficients1;
Tstats(s) = Result.Tstat1;
end
toc

%%
A = histogram(Tstats)
SimAlphas = Alphas;
save SimAlphas SimAlphas
SimTstats = Tstats;
save SimTstats SimTstats

%% Placebo
for s = 1:100;
for i = 1:1093
Placebo(i,:) = rand(1,31599)>.8;
end
Placebo = Placebo+0;
Placebo(~isfinite(ret)) = nan;
Placebo(~isfinite(me)) = nan;
Placebo = lagmatrix(Placebo,-3);
Placebo(isnan(Placebo)) = 0;
Placebo(1:926,:) = 0;
% Restricted ret
[results,pret] = tsregs(ret,Placebo,dates,vw,1,0);
Alphas(s) = results.alpha(1);
Tstats(s) = results.talpha(1);
end

%% Meetings alpha
clear
clc
load MeetingType; load MeetingTypeCategories
load ret; load me; load dates; load Rf

%% Value weights
clc
for i = -4:2; 
Meeting = MeetingType;
Meeting(isfinite(Meeting)) = 1;
Meeting = lagmatrix(Meeting,i);
Meeting(~isfinite(Meeting)) = 0;
meX= me.*Meeting;  % the market cap of firms in portfolio x; checked
meTot = nansum(me.*Meeting,2);  % the total market cap of firms in portfolio x; it sums the market cap of all firms in portfolio x
vw = bsxfun(@rdivide,meX,meTot);     % we right divide the rows of m1 by meTot1 to get the value weight of each stock in the portfoli; cheked
RetSample4 = nansum(ret.*lagmatrix(vw,1),2)-rf; 
RetSample4(1:926) = nan;
Ivol(i+5,:) = nanstd(RetSample4);
[Result(i+5,:)] = ts_benchmark_regression(RetSample4,1,dates)
end

%%
MeetingDatePremium = RetSample4;
save MeetingDatePremium MeetingDatePremium
%% Equal Weights
clc
for i = -3:3;
Meeting = MeetingType;
Meeting(isfinite(Meeting)) = 1;
Meeting = lagmatrix(Meeting,i);
Meeting(~isfinite(Meeting)) = nan;
Meeting(Meeting==0) = nan;
RetSample5 = nanmean(ret.*Meeting,2)-rf; 
RetSample5(1:926) = nan;
Ivol(i+4,:) = nanstd(RetSample5);
[Result2(i+4,:)] = ts_benchmark_regression(RetSample5,1,dates)
end

%% Ansence of meeting alpha
NoMeeting = MeetingType;
NoMeeting(isnan(NoMeeting)) = 0;
NoMeeting = NoMeeting + lagmatrix(NoMeeting,-1) + lagmatrix(NoMeeting,-2) + lagmatrix(NoMeeting,-3);
NoMeeting(NoMeeting==0) = nan;
NoMeeting(isfinite(NoMeeting)) = 0;
NoMeeting(isnan(NoMeeting)) = 1;
NoMeeting(isnan(ret)) = nan;
% NoMeeting(:,nansum(MeetingType,1)==0)= nan;
% 1 when there is no meeting; zero when there is meeting; nan otherwise
meX= me.*NoMeeting;  % the market cap of firms in portfolio x; checked
meTot = nansum(me.*NoMeeting,2);  % the total market cap of firms in portfolio x; it sums the market cap of all firms in portfolio x
vw = bsxfun(@rdivide,meX,meTot);     % we right divide the rows of m1 by meTot1 to get the value weight of each stock in the portfoli; cheked
RetSample = nansum(ret.*lagmatrix(vw,1),2)-rf; 
RetSample(1:926) = nan;
Ivol = nanstd(RetSample);
[Result] = ts_benchmark_regression(RetSample,1,dates)

%% Percent of firms with a shareholder meeting relative to number of firms with a single meeting in the data
temp = nansum(NoMeeting,2);
Meeting = MeetingType;
Meeting(isfinite(Meeting)) = 1;
temp2 = nansum(Meeting,2);
temp3 = temp2./temp;
temp3(1:926) = [];
 bar(temp3)
 
%% SD Market
load mkt
mkt(1:926) = nan;
nanstd(mkt)
%%
%%%%%%%%%%%%%%%%%%%%
%% Figure
Alphas = Alphas/100;
%%
R61 = FamaMacBeth2(100*retAdj,[Placebo])

%%
r = round(-24 + (24-(-24)).*rand(rows(find(Meeting ==1)),1));

Placebo = Meeting;
Placebo(Placebo==1) = Placebo(Placebo==1) + r;

%% Sample selection ????
SampleVoteData = isfinite(retAdj)+0;    % Sample of firms that have data
ret2 = ret;
ret2(1:926,:) = nan;    % Sample of all firms
R61 = FamaMacBeth2(100*ret,[SampleVoteData])

%% Sample selection Investment 2 ?????
SampleINVData = isfinite(signalINV)+0;
SampleBMData = isfinite(signalBM)+0;
SampleMomentumData = isfinite(CR) + 0;
SampleNSData = isfinite(NS) + 0;
SS2 = FamaMacBeth2(100*ret,[SampleINVData SampleBMData SampleVoteData SampleMomentumData ])



%% Survivorship bias