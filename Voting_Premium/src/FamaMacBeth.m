%% Fama-Macbeth regressions and Voting
% Results are stronger if we compare to the full sample of firms
%% Investigate the impact of meetings on returns (4 sec)
tic
clear
clc
load MeetingType
load MeetingTypeCategories
load ret
load me
load dates
% Controls
load meFM
load signalBM
signalBM = signalm;
load CR
load sloan2
load signalOP
signalOP = signal;
load signalINV
signalINV = signal;
load NS
load USCommon
load rf
ret(isnan(USCommon)==1) = nan;
toc
%% Adjust the regressors (13 sec)
tic
MEFM = make_fmbwin(meFM);
% this lags log(me) one month, and "winsorizes" it at the 1 and 99% levels
% (also strips out infinite values-- useful, e.g., for log(bm), which is -infinity in Matlab for negative bm firms)
% Note: make_fmbwin also fills in missing data with previous months data (useful when running monthly return regressions on annual accounting variables like B/M)
% Note: make_fmbwin can also take a second arguement, the percent level to Winsorize on each side
% Note: make_fmbwin can also take a third arguement, if this third arguement is not zero it trims rather than Winsorizes
INVFM = make_fmbwin(signalINV);
SLOANFM = make_fmbwin(sloan2);
NSFM = make_fmbwin(NS);
BMFM = make_fmbwin(signalBM);
CRFM = make_fmbwin(CR);
OPFM = make_fmbwin(signalOP);
toc

%% Create meeting dummies (7 sec)
tic
Meeting= MeetingType;
Annual = Meeting;
Annual(Annual~=1) = 0;
Proxy = Meeting;
Proxy(Proxy~=5) = 0;
Proxy(Proxy==5) = 1;
Special = Meeting;
Special(Special~=6) = 0;
Special(Special==6) = 1;
Meeting(isfinite(Meeting)) = 1;
Meeting(~isfinite(Meeting)) = 0;
MeetingB = lagmatrix(Meeting,-1);
MeetingB2 = lagmatrix(Meeting,-2);
MeetingB3 = lagmatrix(Meeting,-3);
MeetingB4 = lagmatrix(Meeting,-4);
MeetingB5 = lagmatrix(Meeting,-5);
MeetingB6 = lagmatrix(Meeting,-6);
MeetingB7 = lagmatrix(Meeting,-7);
MeetingB8 = lagmatrix(Meeting,-8);
MeetingB9 = lagmatrix(Meeting,-9);
MeetingB10 = lagmatrix(Meeting,-10);
MeetingB11 = lagmatrix(Meeting,-11);
MeetingB12 = lagmatrix(Meeting,-12);
MeetingA1 = lagmatrix(Meeting,1);
MeetingA2 = lagmatrix(Meeting,2);
MeetingA3 = lagmatrix(Meeting,3);
MeetingA4 = lagmatrix(Meeting,4);
MeetingA5 = lagmatrix(Meeting,5);
MeetingA6 = lagmatrix(Meeting,6);
MeetingA7 = lagmatrix(Meeting,7);
MeetingA8 = lagmatrix(Meeting,8);
MeetingA9 = lagmatrix(Meeting,9);
MeetingA10 = lagmatrix(Meeting,10);
MeetingA11 = lagmatrix(Meeting,11);
MeetingA12 = lagmatrix(Meeting,12);
Before = MeetingB+MeetingB2+MeetingB3;
After = MeetingA1+MeetingA2+MeetingA3;
toc

%% Adjusted Ret (1 sec)
tic
[temp, ~] = find(Meeting~=0);
retLate = ret;
retLate(1:(temp-1),:) = nan;    % remove early sample years (sample reduced from 53 years to 13 years)
retAdj = retLate;
retAdj(:,find(nansum(Meeting)==0)) = nan;   % Keep only stocks that have voting data
% Cut early ret years
ret(1:451,:) = nan;
NoStocksUniverse = nansum(nansum(isfinite(ret))~=0)
NoStocksUniverseLate = nansum(nansum(isfinite(retLate))~=0)
NoStocksVotingUniverse = nansum(nansum(isfinite(retAdj))~=0)
toc

%% Size Restriction
temp = repmat(nanmedian(me,2),1,cols(me));    % calculate the median
temp2 = (me>temp)+0;  % is it bigger than the average
temp2(temp2==0) = nan;  % turn zero to nan
retBig = ret.*(lagmatrix(temp2,1));
retAdjBig = retAdj.*(lagmatrix(temp2,1));

temp3 = (me<temp)+0;
temp3(temp3==0) = nan;
retSmall = ret.*(lagmatrix(temp3,1));
retAdjSmall = retAdj.*(lagmatrix(temp3,1));

%% Save
save VoteFamaMacBeth

%% Fama-MacBeth
% Intercept automatically included (displayed in FamaMacBeth2)
clc
R1 = FamaMacBeth2(100*ret,[MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM])
R2 = FamaMacBeth2(100*retAdj,[MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM])

%%
R3 = FamaMacBeth2(100*retAdj,[MeetingB12 MeetingB11 MeetingB10 MeetingB9 MeetingB8 MeetingB7 MeetingB6 MeetingB5 MeetingB4 MeetingB3 MeetingB2 MeetingB Meeting MeetingA1 MeetingA2 MeetingA3 MeetingA4 MeetingA5 MeetingA6 MeetingA7 MeetingA8 MeetingA9 MeetingA10 MeetingA11 MeetingA12])
R4 = FamaMacBeth2(100*retAdj,[MeetingB3 MeetingB2 MeetingB Meeting MeetingA1 MeetingA2 MeetingA3])
R5 = FamaMacBeth2(100*retAdj,[Before Meeting After])
R6 = FamaMacBeth2(100*retAdj,[MeetingB3 MeetingB2 MeetingB Meeting MeetingA1 MeetingA2 MeetingA3 MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM])
R7 = FamaMacBeth2(100*retAdj,[Before Meeting After MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM])
R8 = FamaMacBeth2(100*retAdj,[MeetingB Meeting MeetingA1 MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM])

%% Proxy Special Annual
AnnualA = lagmatrix(Annual,1)+lagmatrix(Annual,2)+lagmatrix(Annual,3);
AnnualB = lagmatrix(Annual,-1)+lagmatrix(Annual,-2)+lagmatrix(Annual,-3);
ProxyA = lagmatrix(Proxy,1)+lagmatrix(Proxy,2)+lagmatrix(Proxy,3);
ProxyB = lagmatrix(Proxy,-1)+lagmatrix(Proxy,-2)+lagmatrix(Proxy,-3);
SpecialA = lagmatrix(Special,1)+lagmatrix(Special,2)+lagmatrix(Special,3);
SpecialB = lagmatrix(Special,-1)+lagmatrix(Special,-2)+lagmatrix(Special,-3);
R8 = FamaMacBeth2(100*retAdj,[AnnualB Annual AnnualA ProxyB Proxy ProxyA SpecialB Special SpecialA ])

%% Proxy Sepcial Annual Expanded
R9 = FamaMacBeth2(100*retAdj,[MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM AnnualB Annual AnnualA ProxyB Proxy ProxyA SpecialB Special SpecialA])

%% Support Effects
load SignalVote
load NYSE
% Breakpoint = nanmedian(me,2);   % Breakpoint for all median
% BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
% SignalVote(me<BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
NP = 3; % Indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT = aprts(SignalVote, NP); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)

Low = indVOT;
Low(Low~=1) = 0;
Mid = indVOT;
Mid(Mid~=2) = 0;
Mid(Mid == 2) = 1;
High = indVOT;
High(High~=3) = 0;
High(High == 3) = 1;

LowA = lagmatrix(Low,1)+lagmatrix(Low,2)+lagmatrix(Low,3);
LowB = lagmatrix(Low,-1)+lagmatrix(Low,-2)+lagmatrix(Low,-3);
MidA = lagmatrix(Mid,1)+lagmatrix(Mid,2)+lagmatrix(Mid,3);
MidB = lagmatrix(Mid,-1)+lagmatrix(Mid,-2)+lagmatrix(Mid,-3);
HighA = lagmatrix(High,1)+lagmatrix(High,2)+lagmatrix(High,3);
HighB = lagmatrix(High,-1)+lagmatrix(High,-2)+lagmatrix(High,-3);

%%
R10 = FamaMacBeth2(100*retAdj,[MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM LowB Low LowA MidB Mid MidA HighB High HighA])
R11 = FamaMacBeth2(100*retAdj,[LowB Low LowA MidB Mid MidA HighB High HighA])
R12 = FamaMacBeth2(100*retAdjBig,[MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM LowB Low LowA MidB Mid MidA HighB High HighA])

%% Decile FM
load SignalVote
load NYSE
load me
% Breakpoint = nanmedian(me,2);   % Breakpoint for all median
% BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
% SignalVote(me<BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
NP = 10; % Indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
indVOT2 = aprts(SignalVote,  NP); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
Low = indVOT2;
Low(Low~=1) = 0;
LowA = lagmatrix(Low,1);
LowA2 = lagmatrix(Low,2);
LowA3 = lagmatrix(Low,3);
LowAfter = LowA+LowA2+LowA3;
LowB = lagmatrix(Low,-1);
LowB2 = lagmatrix(Low,-2);
LowB3 = lagmatrix(Low,-3);
LowBefore = LowB+LowB2+LowB3;
High = indVOT2;
High(High~=10) = 0;
High(High == 10) = 1;
HighA = lagmatrix(High,1);
HighA2 = lagmatrix(High,2);
HighA3 = lagmatrix(High,3);
HighAfter = HighA+HighA2+HighA3;
HighB = lagmatrix(High,-1);
HighB2 = lagmatrix(High,-2);
HighB3 = lagmatrix(High, -3);
HighBefore = HighB + HighB2 + HighB3;

%%
RBig = FamaMacBeth2(100*retAdjBig,[LowB3 LowB2 LowB Low LowA LowA2 LowA3 HighB3 HighB2 HighB High HighA HighA2 HighA3])
RSmall = FamaMacBeth2(100*retAdjSmall,[LowB3 LowB2 LowB Low LowA LowA2 LowA3 HighB3 HighB2 HighB High HighA HighA2 HighA3])

RAll = FamaMacBeth2(100*retAdj,[LowBefore LowAfter HighBefore HighAfter MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM])
RAll = FamaMacBeth2(100*retAdj,[LowB3 LowB2 LowB Low LowA LowA2 LowA3 HighB3 HighB2 HighB High HighA HighA2 HighA3])
%% With controls
% Here the returns are cleaned of a subsample and the sort is on the full sample
% Alternatively, you can have the full sample but the sort is on the restricted sample
% You can also have bot
RBig = FamaMacBeth2(100*retAdjBig,[MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM LowB3 LowB2 LowB Low LowA LowA2 LowA3 HighB3 HighB2 HighB High HighA HighA2 HighA3])
RSmall = FamaMacBeth2(100*retAdjSmall,[MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM LowB LowB3 LowB2 LowB Low LowA LowA2 LowA3 HighB3 HighB2 HighB High HighA HighA2 HighA3])

%%
RBig = FamaMacBeth2(100*retAdjBig,[MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM LowBefore Low LowAfter HighBefore High HighAfter])

%% The signal
load SignalAfter3Fading
VoteFM = make_fmbwin(SignalAfter3Fading);
A1 = FamaMacBeth2(100*retAdjBig,[lagmatrix(VoteFM,0)])

%% Interacton terms
% Special
SpecialBL = SpecialB.*LowB;
SpecialBL(isnan(SpecialBL)) = 0;
SpecialBM = SpecialB.*MidB;
SpecialBM(isnan(SpecialBM)) = 0;
SpecialBH = SpecialB.*HighB;
SpecialBH(isnan(SpecialBH)) = 0;
SpecialL = Special.*Low;
SpecialL(isnan(SpecialL)) = 0;
SpecialM = Special.*Mid;
SpecialM(isnan(SpecialM)) = 0;
SpecialH = Special.*High;
SpecialH(isnan(SpecialH)) = 0;
SpecialAL = SpecialA.*LowA;
SpecialAL(isnan(SpecialAL)) = 0;
SpecialAM = SpecialA.*MidA;
SpecialAM(isnan(SpecialAM)) = 0;
SpecialAH = SpecialA.*HighA;
SpecialAH(isnan(SpecialAH)) = 0;

% Proxy 
ProxyBL = ProxyB.*LowB;
ProxyBL(isnan(ProxyBL)) = 0;
ProxyBM = ProxyB.*MidB;
ProxyBM(isnan(ProxyBM)) = 0;
ProxyBH = ProxyB.*HighB;
ProxyBH(isnan(ProxyBH)) = 0;
ProxyL = Proxy.*Low;
ProxyL(isnan(ProxyB)) = 0;
ProxyM = Proxy.*Mid;
ProxyM(isnan(ProxyM)) = 0;
ProxyH = Proxy.*High;
ProxyH(isnan(ProxyH)) = 0;
ProxyAL = ProxyA.*LowA;
ProxyAL(isnan(ProxyAL)) = 0;
ProxyAM = ProxyA.*MidA;
ProxyAM(isnan(ProxyAM)) = 0;
ProxyAH = ProxyA.*HighA;
ProxyAH(isnan(ProxyAH)) = 0;

% Annual
AnnualBL = AnnualB.*LowB;
AnnualBL(isnan(AnnualBL)) = 0;
AnnualBM = AnnualB.*MidB;
AnnualBM(isnan(AnnualBM)) = 0;
AnnualBH = AnnualB.*HighB;
AnnualBH(isnan(AnnualBH)) = 0;
AnnualL = Annual.*Low;
AnnualL(isnan(AnnualB)) = 0;
AnnualM = Annual.*Mid;
AnnualM(isnan(AnnualM)) = 0;
AnnualH = Annual.*High;
AnnualH(isnan(AnnualH)) = 0;
AnnualAL = AnnualA.*LowA;
AnnualAL(isnan(AnnualAL)) = 0;
AnnualAM = AnnualA.*MidA;
AnnualAM(isnan(AnnualAM)) = 0;
AnnualAH = AnnualA.*HighA;
AnnualAH(isnan(AnnualAH)) = 0;

%% Reg
R4 = FamaMacBeth2(100*retAdj,[SpecialBL SpecialBM SpecialBH SpecialL SpecialM SpecialH SpecialAL SpecialAM SpecialAH MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM])
R41 = FamaMacBeth2(100*retAdj,[ProxyBL ProxyBM ProxyBH ProxyL ProxyM ProxyH ProxyAL ProxyAM ProxyAH ])
R42 = FamaMacBeth2(100*retAdj,[AnnualBL AnnualBM AnnualBH AnnualL AnnualM AnnualH AnnualAL AnnualAM AnnualAH MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM])
R43 = FamaMacBeth2(100*retAdj,[SpecialBL SpecialBM SpecialBH SpecialL SpecialM SpecialH SpecialAL SpecialAM SpecialAH AnnualBL AnnualBM AnnualBH AnnualL AnnualM AnnualH AnnualAL AnnualAM AnnualAH MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM])
R44 = FamaMacBeth2(100*retAdjBig,[SpecialBL SpecialBM SpecialBH SpecialL SpecialM SpecialH SpecialAL SpecialAM SpecialAH AnnualBL AnnualBM AnnualBH AnnualL AnnualM AnnualH AnnualAL AnnualAM AnnualAH])
R45 = FamaMacBeth2(100*retAdjSmall,[SpecialBL SpecialBM SpecialBH SpecialL SpecialM SpecialH SpecialAL SpecialAM SpecialAH AnnualBL AnnualBM AnnualBH AnnualL AnnualM AnnualH AnnualAL AnnualAM AnnualAH])

%% Test
% Other months
OtherMeeting = lagmatrix(Meeting,4)+lagmatrix(Meeting,5)+lagmatrix(Meeting,6)+lagmatrix(Meeting,7)+lagmatrix(Meeting,8);
OtherAnnual = lagmatrix(Annual,4)+lagmatrix(Annual,5)+lagmatrix(Annual,6)+lagmatrix(Annual,7)+lagmatrix(Annual,8);
NextYear = lagmatrix(Annual,12)+lagmatrix(Annual,24)+lagmatrix(Annual,36);
R6 = FamaMacBeth2(100*retAdj,[Before Meeting After OtherMeeting])
R61 = FamaMacBeth2(100*retAdj,[NextYear])
R62 = FamaMacBeth2(100*retAdj,[MEFM BMFM CRFM INVFM OPFM SLOANFM NSFM OtherMeeting])

%%
clc
for i = -12:12
Predictive = lagmatrix(Meeting,i);
R = FamaMacBeth2(100*retAdj,[Predictive])
beta(i+13,:) = R.bhat;
tstat(i+13,:) = R.t;
end
temp = [-12:12];
X = [temp',tstat(:,2)]
bar(X)
