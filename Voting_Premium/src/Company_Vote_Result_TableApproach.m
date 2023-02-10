%% Deal with company vote results in table format
% Load the data and add Support adjusted to the table
tic
clc
clear
load PermnosVote
%load CompanyVoteResults
load('./data/Vote_Results_2022.mat')
load SupportAdjusted  % Regular support
load ShareholderSupport   % The abnormal support
PermnosVote = array2table(PermnosVote);
s1 = SupportAdjusted';
s2 = ShareholderSupport';
SupportAdjusted = array2table(SupportAdjusted);    % Turn into table
ShareholderSupport = array2table(ShareholderSupport);  % Turn into table
Year = year(CompanyVoteResults.MeetingDate);     % Create Year Variable
Month = month(CompanyVoteResults.MeetingDate);  % Create month variable
YearMonth = Year*100+Month; % Make year-month
Year = array2table(Year);   % Turn into table format
Month = array2table(Month); % Turn into table format
YearMonth = array2table(YearMonth); % Turn into table format
CompanyVoteResults(:,cols(CompanyVoteResults)+1) = SupportAdjusted;    % Add them to the main table
CompanyVoteResults(:,cols(CompanyVoteResults)+1) = ShareholderSupport; % Add them to the main table
CompanyVoteResults(:,cols(CompanyVoteResults)+1) = Year; % Add them to the main table
CompanyVoteResults(:,cols(CompanyVoteResults)+1) = Month; % Add them to the main table
CompanyVoteResults(:,cols(CompanyVoteResults)+1) = YearMonth; % Add them to the main table
CompanyVoteResults(:,cols(CompanyVoteResults)+1) = PermnosVote; % Add them to the main table
CompanyVoteResults.Properties.VariableNames{31} = 'SupportAdjusted';    % Name the variable
CompanyVoteResults.Properties.VariableNames{32} = 'ASupport';    % Name the variable
CompanyVoteResults.ASupport(~isfinite(CompanyVoteResults.ASupport)) = nan;    % Turn infinity to no answer
CompanyVoteResults.Properties.VariableNames{33} = 'Year';    % Name the variable
CompanyVoteResults.Properties.VariableNames{34} = 'Month';    % Name the variable
CompanyVoteResults.Properties.VariableNames{35} = 'YearMonth';    % Name the variable
CompanyVoteResults.Properties.VariableNames{36} = 'Permno';    % Name the variable
T = CompanyVoteResults;
T.Participation = (T.votedFor+T.votedAgainst)./T.outstandingShare;  % Create participation
T.Participation(T.Participation == 0) = nan;    % Remove participation with 0
T.Participation(T.Participation > 1) = 1;   % More than 100% participation set to 100%
clearvars -except T

% Turn into categocial; it is turning them into dummies basically
T.AgendaGeneralDesc = categorical(T.AgendaGeneralDesc);   
T.ISSrec = categorical(T.ISSrec);   
T.MGMTrec = categorical(T.MGMTrec);   
T.sponsor = categorical(T.sponsor);   
T.MeetingType = categorical(T.MeetingType); 
T.Year = categorical(T.Year);
T.voteResult = categorical(T.voteResult);
T.DatePermno = T.YearMonth*1000000+T.Permno;    % Unique firm date identifier

%% Number of proposals per firm per year
% Run on the 427 000  resolution sample
% Itterate 'Management' and 'Shareholder'
Permnos= T.Permno(T.sponsor == 'Shareholder');
temp2 = T.MeetingDate(T.sponsor == 'Shareholder');
[year,~,~] = ymd(temp2);
for i =2003:2016
    TotalProposed(i-2002) = rows(Permnos(year==i));
    NumberOfFirms(i-2002) = rows(unique(Permnos(year==i)));
    AverNoResolutions(i-2002) = rows(Permnos(year==i))/rows(unique(Permnos(year==i)));
end

%% Investigate irregularities
topic = T.AgendaGeneralDesc(T.sponsor == 'Management' & T.MGMTrec == 'Against');
[~,types,c,~] = Text_to_dummy(topic);   % Agenda description
% Lots of say on pay topics

topic2 = T.AgendaGeneralDesc(T.sponsor == 'Shareholder' & T.MGMTrec == 'For' & T.Year == '2008');
[~,types2,c2,~] = Text_to_dummy(topic2);   % Agenda description

clc
topic3 = T.AgendaGeneralDesc(T.sponsor == 'Shareholder' &  T.AgendaGeneralDesc == 'Elect Directors (Opposition Slate)' & T.Year == '2005');
[~,types3,c3,~] = Text_to_dummy(topic3);   % Agenda description

%% Create Industry
T(T.Permno==0,:) = [];  % Remove firms without a permno
load SICCD
load permno

[~,temp2] = ismember(T.Permno,permno);
T.SICCD = SICCD(temp2);

%% Save
save T T

%% Merge responses - Management Recomendation
% Management recomendation
load T
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

%% Basics table
NumberOfResolutions = rows(T);
temp = T.MeetingType(T.sponsor=='Shareholder');
temp2 = T.MeetingType(T.sponsor=='Management');
summary(temp)       % Meeting type shareholder
summary(temp2)      % Meeting type management
rows(unique(T.CUSIP))       % Unique firms
summary(categorical(T.voteRequirement(T.sponsor=='Shareholder')))
summary(categorical(T.voteRequirement(T.sponsor=='Management')))
summary(T.MGMTrec(T.sponsor=='Shareholder'))
summary(T.MGMTrec(T.sponsor=='Management'))
summary(T.ISSrec(T.sponsor=='Management'))
summary(T.ISSrec(T.sponsor=='Shareholder'))
summary(categorical(T.base(T.sponsor=='Management')))
summary(categorical(T.base(T.sponsor=='Shareholder')))
summary(categorical(T.voteResult(T.sponsor=='Management')))
summary(categorical(T.voteResult(T.sponsor=='Shareholder')))
summary(T.AgendaGeneralDesc(T.sponsor=='Shareholder' & T.MGMTrec=='For'));      % Resolutions that management supports and are proposed by shareholders
sum(T.sponsor=='Shareholder')
sum(T.sponsor=='Management')
summary(T.AgendaGeneralDesc)

%% Subsamples
% Shareholder proposals when management is for
temp = T;
temp = temp(find(temp.sponsor == 'Shareholder'),:);
temp = temp(temp.MGMTrec == 'For',:);

%% Frequency of resolutions
% Itterate the selection criteria to obtain the table
% T.MeetingType == 'Proxy Contest'
% T.sponsor == 'Shareholder'
A = T.AgendaGeneralDesc(T.MeetingType == 'Proxy Contest');
S = T.SupportAdjusted(T.MeetingType == 'Proxy Contest');
[dummy, Result, Unique] =  text_to_dummy_extended(A,S);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Other Analysis %%
%% Number of firms per year
temp = categories(T.Year)';
for i = 1:cols(temp)
Companies(i) = rows(unique(T.CompanyID(T.Year == temp(i))));
end
clearvars -except Companies T

%% Export in excel
writetable(T, 'CompanyVoteResultsEdited.xlsx')

%% See data summary
summary(T)

%% Some commands
% Select a subset of observations from a table
clc
temp = categories(T.ISSrec)
temp2 = categories(T.sponsor)
T.SupportAdjusted(and(T.ISSrec == temp(4),T.sponsor(2)))
TypesOfVotes = categories(T.AgendaGeneralDesc);    % See which types of agenda items we have; use function mergecats to merge categories
summary(T.sponsor)  % Shows you how often it appears
SponsorTypes = findgroups(T.sponsor)

%% Hisogram support adjusted and participation
% Support
figure
subplot(2,2,1)
hist(T.SupportAdjusted(T.sponsor == {'Management'}),10);
title('Support Management Sponsored')
subplot(2,2,3)
hist(T.SupportAdjusted(T.sponsor == {'Shareholder'}),10);
title('Support Shareholder Sponsored')

% Participation
subplot(2,2,2)
hist(T.Participation(T.sponsor == {'Management'}),10)
title('Participation Management Sponsored')
subplot(2,2,4)
hist(T.Participation(T.sponsor == {'Shareholder'}),10)
title('Participation Shareholder Sponsored')

%% Histogram abnormal support
T.ASupportTrimmed = T.ASupport;
T.ASupportTrimmed(T.ASupportTrimmed > 10) = 10;
T.ASupportTrimmed(T.ASupportTrimmed < -10) = -10;
figure
subplot(2,1,1)
hist(T.ASupportTrimmed(T.sponsor == {'Management'}),40);
title('Management')
subplot(2,1,2)
hist(T.ASupportTrimmed(T.sponsor == {'Shareholder'}),40);
title('Shareholder')

%% Hisogram proxy season 
clear
load T
clc

%%
categories(T.MeetingType)
T.MeetingType(T.MeetingType== 'Annual/Special') = 'Other';
T.MeetingType(T.MeetingType== 'Bondholder') = 'Other';
T.MeetingType(T.MeetingType== 'Court') = 'Other';
T.MeetingType(T.MeetingType== 'Written Consent') = 'Other';
T.MeetingType = removecats(T.MeetingType,{'Annual/Special','Bondholder','Court','Written Consent'});
summary(T.MeetingType)

figure
subplot(2,2,1)
hist(T.Month(T.MeetingType == {'Annual'}),12)
title('Annual')

subplot(2,2,2)
hist(T.Month(T.MeetingType == {'Proxy Contest'}),12)
title('Proxy Contest')

subplot(2,2,3)
hist(T.Month(T.MeetingType == {'Special'}),12)
title('Special')

subplot(2,2,4)
hist(T.Month(T.MeetingType == {'Other'}),12)
title('Other')

%% Incidence of new signals
S = T;
S.Signal = isfinite(S.ASupport);
S(find(S.Signal==0),:) = [];

%% Summary statistics per group
clc
Group = T.sponsor;
categories(Group);
[mean,min,max,count,std, confidence]=grpstats(T.SupportAdjusted, Group, {'mean', 'min', 'max','numel','std','meanci'})



%% Junk Code
%% Double approach for clustered SE
y = T.SupportAdjusted;
[Year,Year_types] = Text_to_dummy(T.Year); 
[Month,Month_types] = Text_to_dummy(T.Month); 
[AgendaGeneralDesc,AgendaGeneralDesc_types] = Text_to_dummy(T.AgendaGeneralDesc); 
[sponsor,sponsor_types] = Text_to_dummy(T.sponsor); 
[MeetingType,MeetingType_types] = Text_to_dummy(T.MeetingType); 
[MGMTrec,MGMTrec_types] = Text_to_dummy(T.MGMTrec); 
[ISSrec,ISSrec_types] = Text_to_dummy(T.ISSrec); 
x = [Year,Month,sponsor,AgendaGeneralDesc,sponsor, MeetingType, MGMTrec];

h = [S.Year];
ret = clusterreg(y, X, g, h)
%% Apple example
clear
clc
load T
A = 'The Walt Disney Company';
Disney = T(find(strcmp(A, T.Name)==1),:);
Disney = sortrows(Disney,'ASupport','ascend');
Disagreement = min(Disney.ASupport);
load ret
load permno
load dates
temp = find(permno == Disney.Permno(1));
ReturnDisney = ret(:,temp);
temp2 = find(dates == 200802);
ReturnDisney = ReturnDisney(temp2:end);
Time = nan(size(ReturnDisney));
for i = 1:rows(Time)
    Time(i) = 0+i;
end
Time = Time-2;
ExactDates = dates;
ExactDates = ExactDates(temp2:end);
clearvars -except ExactDates ReturnDisney Time Disney
scatter(Time, ReturnDisney)

%% Mixed Effects
clc
lme = fitlme(S,'SupportAdjusted~1+sponsor + (1+sponsor|Year)')

%% Compare
lm = fitlm(S,'SupportAdjusted~1+sponsor')
compare(lm,lme)

%% Remove topics with less than 10 observations
lm.CoefficientNames(find(lm.Coefficients.Estimate == 0))
%Topics = lm.coefficients(find(lm.coefficients(:,4);
