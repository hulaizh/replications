%% Meeting Period
clear 
clc
load SignalVote
load dates
load me
load ret
load NYSE
load MeetingType
load MeetingTypeCategories

% All meetings
All = MeetingType;
All(isfinite(All)) = 1;

% Annual
MeetingType(MeetingType~=1) = nan;
for i = 1:1093
    Time(i) = i;
end
Time = Time';
Time = repmat(Time,1,31599);

%%
Time = Time.*All;
[r,c] = find(~isnan(All));
Diff = nan(size(c));
for i = 2:rows(c)
    if c(i) == c(i-1)
        Diff(i) = r(i) - r(i-1);
    end
end
Average = nanmean(Diff)

%% Predictive reg (needs logit)
y = MeetingType;
y(isnan(MeetingType)) = 0;
x = +lagmatrix(y,-11)+lagmatrix(y,-12)+lagmatrix(y,-13);
x(isnan(x)) = 0;
Reg = fitlm(x,y)