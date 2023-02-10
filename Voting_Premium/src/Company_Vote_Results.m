%% Company vote restults 
% Import data from excel; save as a matlab file
clc
clear

%load('data/Vote_Results');
addpath 'src/matlab'

%% Read ISS csv datafile
T = readtable('data/vote_results.csv');
AgendaGeneralDesc = T{:,1};
BallotItemNumber = T{:,2}; 
base = T{:,3};
brokerNonVote = T{:,4};
CompanyID = T{:,5};
CountryOfInc = T{:,6};
CUSIP = regexprep(T{:,7}, {'@'}, {''});
ISSAgendaItemID = T{:,8};
ISSrec = T{:,9};
ItemDesc = T{:,10};
itemOnAgendaID = T{:,11};
MeetingDate = T{:,12};
MeetingID = T{:,13};
MeetingType = T{:,14};
MGMTrec = T{:,15};
Name = T{:,16};
outstandingShare = T{:,17};
Recorddate = T{:,18};
SeqNumber = T{:,19};
sponsor = T{:,20};
ticker = T{:,21};
votedAbstain = T{:,22};
votedAgainst = T{:,23};
votedFor = T{:,24};
VotedWithheld = T{:,25};
voteRequirement = T{:,26};
voteResult = T{:,27};
votes1yr = T{:,28};
votes2yr = T{:,29};
votes3yr = T{:,30};

clear T;
save('data/Vote_Results_2022.mat');

%% Year distribution   (make the figure for voting seasons)
[y,m,day] = ymd(MeetingDate); % Gives you the year, month and day

temp = m*100;
date = temp+day;
date = sortrows(date);  % Create the sorted dates
temp2 =sortrows(m);
histogram(temp2)
histogram(m)

save day day
%% Turn data into dummy
% Turn the text into dummy; (my own function)
% First output is the dummy (inclusive of a dummy for empty); 
% Second output is the possible types of responses
[Sponsor_dummy,Sponsor_types] = Text_to_dummy(sponsor);         % Sponsors of the proposal (sharholder or managment)    % There is 10184 non classified votes nansum(Sponsor_dummy(:,3))
[MgmtRec_dummy,mgmtrec_types] = Text_to_dummy(MGMTrec);   % Managment Recomendations {'Abstain';'Against';'Do Not Vote';'For';'None';'One Year';'Three Years';'Two Years';'Withhold'}
[CouInc_dummy,CouInc_types] = Text_to_dummy(CountryOfInc);   % Country of incorporation
[MType_dummy,Mtypes_types] = Text_to_dummy(MeetingType);   % Meeting type
[AGD_dummy,AGD_types] = Text_to_dummy(AgendaGeneralDesc);   % Agenda description
[ISSRec_dummy,ISSRec_types] = Text_to_dummy(ISSrec);   % ISS Recomendations
[VoteResult_dummy,VoteResult_types] = Text_to_dummy(voteResult);   % Vote result
SayOnPayFrequency = ~isnan(votes1yr);   % Select the votes on say on pay frequency if you would want to exclude them; in total there are 4964
Years = year(MeetingDate);
[year_dummy,year_types] = Text_to_dummy(Years);  % year dummy

%% Save data
save('AGD_dummy.mat', 'AGD_dummy', '-v7.3')
save AGD_types AGD_types
save Sponsor_dummy Sponsor_dummy
save Sponsor_types Sponsor_types
save VoteResult_dummy VoteResult_dummy
save VoteResult_types VoteResult_types
save MType_dummy MType_dummy
save Mtypes_types Mtypes_types
save MgmtRec_dummy MgmtRec_dummy
save mgmtrec_types mgmtrec_types

%% Number of unique firms in the data over time
Cusips = unique(CUSIP);
TotalUniqueFirms = size(Cusips)
U = unique(Years);
for i= 1:size(year_dummy,2)
    UniqueFirmsPerYear(i) = size(unique(CUSIP(find(year_dummy(:,i)==1))),1);
end
UniqueFirmsPerYear

%% Code does not work for vote requirement (finds Nan as unique?) do it manually
clc
temp1 = unique(voteRequirement);
temp1(find(isnan(temp1))) = [];
for i=1:size(temp1,1);
    dummy(:,i) = ismember(voteRequirement, temp1(i)); % gives you 1 when they match and zero otherwise
end
UniqueVoteRequirements = temp1'
Mean = mean(dummy,1)
Sum = sum(dummy,1)

%% Calculate descriptives
% Sponsor types and the number of propoosals
Mean = mean(Sponsor_dummy,1)
Sum = sum(Sponsor_dummy,1)

%% Managment Recomendations
Mean = mean(MgmtRec_dummy,1)
Sum = sum(MgmtRec_dummy,1)

%% Country Incorporation
Mean = mean(CouInc_dummy,1)
Sum = sum(CouInc_dummy,1)

%% Agenda description
Mean = mean(AGD_dummy,1)
Sum = sum(AGD_dummy,1)

%% ISS Recomendations
Mean = mean(ISSRec_dummy,1)
Sum = sum(ISSRec_dummy,1)

%% Vote Results
Mean = mean(VoteResult_dummy,1)
Sum = sum(VoteResult_dummy,1)
Empty = find(VoteResult_dummy(:,1)==1); % Location of empty cells

%% Vote Base
% Mean = mean(VoteBase_dummy,1)
% Sum = sum(VoteBase_dummy,1)
% Empty = find(VoteBase_dummy(:,1)==1); % Location of empty cells

%% Evolution through time
% Calculates the number of proposals though time
clc
Years = year(MeetingDate);
U = unique(Years);
for i=1:size(U,1);
 NumberResoultions(i)= sum(Years == U(i));
end
NumberResoultions

%% Calculates the number of sharholder proposals per year
SponsorSher = Sponsor_dummy(:,2);
for j = 1:size(U,1)
NumberSharholder(j) = sum(SponsorSher(find(Years == U(j))));
end
NumberSharholder

%% Vote result statistics

FO = votedFor./outstandingShare;
FO(find(isfinite(FO)==0)) = nan;
FFA = votedFor./(votedFor+votedAgainst);
Participation = (votedFor+votedAgainst)./outstandingShare;
Participation(find(isfinite(Participation)==0)) = nan;  % Remove inifinite values; when you divide by nan or zero for example

% The average support and participation rates
AveFO = mean(FO,'omitnan')
AveFFA = mean(FFA,'omitnan')
AvePart = mean(Participation,'omitnan')

%% Plot support
histogram(FFA,10)

%% Support based on indicated base
% Find how much support there is given the information on what is the
% appropriate base for caclulating the denominator in support

tic
[base_dummy,base_types] = Text_to_dummy(base);   % Vote base
base_types
for i=1:size(base,1)
    if  isequal(base(i), base_types(1));     % No answer use F/F+A (default)
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i));
    elseif isequal(base(i), base_types(2));  % No answe again use F/F+A (default)
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i));
    elseif isequal(base(i), base_types(3));   %  'Capital Represe' use F/F+A (default) ?
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i));
    elseif isequal(base(i), base_types(4));  %     'F A' use F/F+A 
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i));
    elseif isequal(base(i), base_types(5));  %  'F A AB'  use F/F+A+AB
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i)+ votedAbstain(i));
    elseif isequal(base(i), base_types(6));  %   'F+A'  use F/F+A
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i));
    elseif isequal(base(i), base_types(7));  %   'F+A+AB'  use F/F+A+AB
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i) + votedAbstain(i));
    elseif isequal(base(i), base_types(8));  %   'F+A+B'  use F/F+A+B
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i) + brokerNonVote(i));
    elseif isequal(base(i), base_types(9));  %  'NA'  use F/F+A
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i));        
    elseif isequal(base(i), base_types(10));  %   'Outstanding'  use F/O
          SupportAdjusted(i) = votedFor(i)./(outstandingShare(i));          
    elseif isequal(base(i), base_types(11));  %   'Votes Represent'  use F/F+A
          SupportAdjusted(i) = votedFor(i)./(votedFor(i) + votedAgainst(i));         
    end
end
SupportAdjusted = SupportAdjusted';
toc

%% Clear the infinities
SupportAdjusted(find(~isfinite(SupportAdjusted))) = nan;
Max = max(SupportAdjusted);  % To find errors
temp = find(SupportAdjusted==(max(SupportAdjusted)));    % Location of error - There are less shares outstanding than total votes for some resolutions!!!
temp2 = find(SupportAdjusted>1);
SupportAdjusted(temp2) = nan;   % Remove the problematic observations

%%
save SupportAdjusted SupportAdjusted
%% Calculate the adjusted support over time
clc
for i = 1:size(year_dummy,2)
    SupportAdjustedOverTime(i) = mean(SupportAdjusted(find(year_dummy(:,i) == 1)),'omitnan');
end
SupportAdjustedOverTime
%% Analyze the adjusted support results

SupportAdjusted(find(isfinite(SupportAdjusted)~=1)) = nan;    % Displays all the nan; make sure the infinity values are transformed into nan; you can get infinity if base is 0
AverageAdjustedSupport = mean(SupportAdjusted,'omitnan') 
TotalVotedA = sum(isfinite(SupportAdjusted))        % This has more data; which is normal given that the base can be outstanding and Against data may not be available as it is not needed
% TotalVotedFFA = sum(isfinite(FFA))

%% Standard deviation of vote support
SDSupportAdjusted = std(SupportAdjusted,'omitnan')
for i = 1:size(year_dummy,2)
    SDSupportAdjustedOverTime(i) = std(SupportAdjusted(find(year_dummy(:,i) == 1)),'omitnan');
end
SDSupportAdjustedOverTime

%% Total voted resolutions over time

for i= 1:size(year_dummy,2)
    TotalVotedAPerYear(i) = sum(isfinite(SupportAdjusted(find(year_dummy(:,i)==1))));
end
TotalVotedAPerYear
% It matches the total voted number
%% Most common resolutions in the data

[D, Result,U1] = text_to_dummy_extended(AgendaGeneralDesc,SupportAdjusted);

%% Most common sharholder resolutions in the data
clc
AgendaGeneralDescS = AgendaGeneralDesc;
AgendaGeneralDescS(find(Sponsor_dummy(:,3)~=1)) = [];
SupportAdjustedS = SupportAdjusted;
SupportAdjustedS(find(Sponsor_dummy(:,3)~=1)) = [];

[D2, Result2,U2] = text_to_dummy_extended(AgendaGeneralDescS,SupportAdjustedS);

%% Most common management resolutions in the data
clc
AgendaGeneralDescS = AgendaGeneralDesc;
AgendaGeneralDescS(find(Sponsor_dummy(:,2)~=1)) = [];
SupportAdjustedS = SupportAdjusted;
SupportAdjustedS(find(Sponsor_dummy(:,2)~=1)) = [];

[D3, Result3,U3] = text_to_dummy_extended(AgendaGeneralDescS,SupportAdjustedS);

%% Most common proxy resolutions in the data
clc
AgendaGeneralDescS = AgendaGeneralDesc;
AgendaGeneralDescS(find(MType_dummy(:,5)~=1)) = [];
SupportAdjustedS = SupportAdjusted;
SupportAdjustedS(find(MType_dummy(:,5)~=1)) = [];

[D4, Result4,U4] = text_to_dummy_extended(AgendaGeneralDescS,SupportAdjustedS);


%% Most common special resolutions in the data
clc
AgendaGeneralDescS = AgendaGeneralDesc;
AgendaGeneralDescS(find(MType_dummy(:,6)~=1)) = [];
SupportAdjustedS = SupportAdjusted;
SupportAdjustedS(find(MType_dummy(:,6)~=1)) = [];

[D5, Result5,U5] = text_to_dummy_extended(AgendaGeneralDescS,SupportAdjustedS);

%% Support Sharholder proposals , number of voted proposals, standard deviation and participation over time
ShareholderSupportAdjusted = Sponsor_dummy(:,2).*SupportAdjusted;
ShareholderSupportAdjusted(find(ShareholderSupportAdjusted == 0)) = nan;
AverageSharholderSupport = mean(ShareholderSupportAdjusted,'omitnan')

SDSharholderProposals = std(ShareholderSupportAdjusted,'omitnan')
NumberOfSharholderProposals = sum(isfinite(ShareholderSupportAdjusted))

ParticipationSharholderProposals = Sponsor_dummy(:,2).*Participation
ParticipationSharholderProposals(find(ParticipationSharholderProposals == 0)) = nan;
ParticipationSharholderProposals(find(ParticipationSharholderProposals == Inf)) = nan;
AverageSharholderParticipation = mean(ParticipationSharholderProposals,'omitnan')

for i = 1:size(year_dummy,2)
    SupportAdjustedOverTimeSharholder(i) = mean(ShareholderSupportAdjusted(find(year_dummy(:,i) == 1)),'omitnan');
end
SupportAdjustedOverTimeSharholder

for i = 1:size(year_dummy,2)
    SupportAdjustedOverTimeSharholderSD(i) = std(ShareholderSupportAdjusted(find(year_dummy(:,i) == 1)),'omitnan');
end
SupportAdjustedOverTimeSharholderSD

for i = 1:size(year_dummy,2)
    VotedAdjustedResolutions(i) = sum(isfinite(ShareholderSupportAdjusted(find(year_dummy(:,i) == 1))),'omitnan');
end
VotedAdjustedResolutions

for i = 1:size(year_dummy,2)
    ParticipationSharholderOverTime(i) = mean(ParticipationSharholderProposals(find(year_dummy(:,i) == 1)),'omitnan');
end
ParticipationSharholderOverTime

%% Support managment proposals , number of voted proposals, standard deviation and participation over time
ManagmentSupportAdjusted = Sponsor_dummy(:,2).*SupportAdjusted; % 2 is the managment dummy
ManagmentSupportAdjusted(find(ManagmentSupportAdjusted == 0)) = nan;
AverageManagmentSupport = mean(ManagmentSupportAdjusted,'omitnan')

SDManagmentProposals = std(ManagmentSupportAdjusted,'omitnan')
NumberOfManagmentProposals = sum(isfinite(ManagmentSupportAdjusted))

ParticipationManagmentProposals = Sponsor_dummy(:,2).*Participation;
ParticipationManagmentProposals(find(ParticipationManagmentProposals == 0)) = nan;
ParticipationManagmentProposals(find(ParticipationManagmentProposals == Inf)) = nan;
AverageManagmentParticipation = mean(ParticipationManagmentProposals,'omitnan')

for i = 1:size(year_dummy,2)
    SupportAdjustedOverTimeManagment(i) = mean(ManagmentSupportAdjusted(find(year_dummy(:,i) == 1)),'omitnan');
end
SupportAdjustedOverTimeManagment

for i = 1:size(year_dummy,2)
    SupportAdjustedOverTimeManagmentSD(i) = std(ManagmentSupportAdjusted(find(year_dummy(:,i) == 1)),'omitnan');
end
SupportAdjustedOverTimeManagmentSD

for i = 1:size(year_dummy,2)
    VotedAdjustedResolutions(i) = sum(isfinite(ManagmentSupportAdjusted(find(year_dummy(:,i) == 1))));
end
VotedAdjustedResolutions

for i = 1:size(year_dummy,2)
    ParticipationManagmentOverTime(i) = mean(ParticipationManagmentProposals(find(year_dummy(:,i) == 1)),'omitnan');
end
ParticipationManagmentOverTime

Managment = Sponsor_dummy(:,2);
for i = 1:size(year_dummy,2)
    VotedManagmentOverTime(i) = sum(Managment(find(year_dummy(:,i) == 1)));
end
VotedManagmentOverTime

%% Not Discolosed resolutions over time
[VoteResult_dummy,VoteResult_types] = Text_to_dummy(voteResult);   % Vote result
NotDisclosed = VoteResult_dummy(:,4);
TotalNotDisclosed = sum(NotDisclosed)

for i = 1:size(year_dummy,2)
    NotDisclosedOverTime(i) = sum(NotDisclosed(find(year_dummy(:,i) == 1)));
end
NotDisclosedOverTime

%% Participation on shareholder proposals over time
clc
for i = 1:size(year_dummy,2)
    ParticipationSharholderOverTime(i) = mean(ParticipationSharholderProposals(find(year_dummy(:,i) == 1)),'omitnan');
end
ParticipationSharholderOverTime

%% Calculates the support per year
for k = 1:size(U,1)
    Support(k) = mean(FFA(find(Years==U(k))),'omitnan')
end
Support
%% Calculates participation per year
for k = 1:size(U,1)
    ParticipationT(k) = mean(Participation(find(Years==U(k))),'omitnan')
end
ParticipationT
%% Sharholder proposal support and participation (validated in excel)
SPS = SponsorSher.*FFA;
SPS(SPS ==0) = [];
nanmean(SPS)    % Sharholder proposal suport

SPP = SponsorSher.*Participation;
SPP(SPP ==0) = [];
AverageParticipationSharehodlerProposals = nanmean(SPP)    % Sharholder proposal participation

%% Calculates sharholder support per year (validated in excel)
temp2 = SponsorSher.*FFA;  % calculates support for sharhoolder proposals
temp2(temp2==0) = nan;  % replaces zeros with nan so you can calculate the nanmean
for k = 1:rows(U)
    SPST(k) = nanmean(temp2(find(Years==U(k))));
end

%% Average managment recomendation for shareholder proposals per year
SponsorSher = Sponsor_dummy(:,3);
temp3 = MgmtRec_dummy(:,5);   % Selects the managment recomendations that are supportive
temp3 = SponsorSher.*temp3;      % puts a zero for managment sponsored proposals
temp3(SponsorSher==0) = nan;   % replaces zeros with nan when there is a managment proposal so you can calculate the nanmean
MgmtRecSher = nanmean(temp3)
for k = 1:rows(U)
    MgmtSheT(k) = nanmean(temp3(find(Years==U(k))));
end
MgmtSheT

%% Average ISS for recomendation for shareholder proposals per year
temp4 = ISSRec_dummy(:,5);        % Selects the ISS recomendations that are supportive
temp4 = SponsorSher.*temp4;       % puts a zero for managment sponsored proposals
temp4(SponsorSher==0) = nan;    % replaces zeros with nan when there is a managment proposal so you can calculate the nanmean
ISSRecSher = nanmean(temp4)
for k = 1:rows(U)
    ISSSheT(k) = nanmean(temp4(find(Years==U(k))));
end
ISSSheT

%% Average managment recomendation for managment proposals per year
SponsorSher = Sponsor_dummy(:,3);
temp3 = MgmtRec_dummy(:,5);   % Selects the managment recomendations that are supportive
SponsorMgmt = Sponsor_dummy(:, 2);    % Get the managment proposals
temp3 = SponsorMgmt.*temp3;      % puts a zero for managment sponsored proposals
temp3(SponsorMgmt==0) = nan;   % replaces zeros with nan when there is a shareholder proposal so you can calculate the nanmean
MgmtRecMgmt = nanmean(temp3)
for k = 1:rows(U)
    MgmtMgmtT(k) = nanmean(temp3(find(Years==U(k))));
end
MgmtMgmT

%% Average ISS for recomendation for managment proposals per year
temp4 = ISSRec_dummy(:,5);        % Selects the ISS recomendations that are supportive
temp4 = SponsorMgmt.*temp4;       % puts a zero for shareholder sponsored proposals
temp4(SponsorMgmt==0) = nan;    % replaces zeros with nan when there is a managment proposal so you can calculate the nanmean
ISSRecMgmt = nanmean(temp4)
for k = 1:rows(U)
    ISSMgmtT(k) = nanmean(temp4(find(Years==U(k))));
end
ISSMgmtT

%% Average managment recomendation for proposals
temp3 = MgmtRec_dummy(:,5);   % Selects the managment recomendations that are supportive
MgmtRec = nanmean(temp3)
for k = 1:rows(U)
    MgmtForT(k) = nanmean(temp3(find(Years==U(k))));
end

%% Average ISS for recomendation per year
temp4 = ISSRec_dummy(:,5);        % Selects the ISS recomendations that are supportive
ISSRec = nanmean(temp4)
for k = 1:rows(U)
    ISSForT(k) = nanmean(temp4(find(Years==U(k))));
end

%% ISS & Managment disagreement
MgmtFor   = MgmtRec_dummy(:,5);      % Selects the managment recomendations that are supportive
MgmtAgainst = MgmtRec_dummy(:,2) + MgmtRec_dummy(:,3) + MgmtRec_dummy(:,10);   % Selects the managment recomendations that against, abstain or withold
ISSFor = ISSRec_dummy(:,5);        % Selects the ISS recomendations that are supportive
ISSAgainst = ISSRec_dummy(:,2) + ISSRec_dummy(:,3) + ISSRec_dummy(:,9);        % Selects the ISS recomendations that against, abstain or withold

AgreementFor = sum(MgmtFor & ISSFor);    % Gives the number of times both managment and ISS supported a proposal
AgreementAgainst = sum(MgmtAgainst & ISSAgainst);
MgmtForISSAgainst = sum(MgmtFor & ISSAgainst);
MgmtAgainstISSFor = sum(MgmtAgainst & ISSFor);

%% Pass rate for disagreement
clc
Pass = VoteResult_dummy(:,6); % Votes that pass
Fail  = VoteResult_dummy(:,2);  % Votes that fail

AgreementFor_Pass = sum((MgmtFor & ISSFor) & Pass);      % when ISS and managment recomend for and the proposal passes
AgreementFor_Fail = sum((MgmtAgainst & ISSAgainst) & Fail);  % when ISS and managment recomend for and the proposal fails

AgreementAgainst_Pass = sum((MgmtAgainst & ISSAgainst) & Pass); % when ISS and managment recomend against and the proposal passes
AgreementAgainst_Fail = sum((MgmtAgainst & ISSAgainst) & Fail);

MgmtForISSAgainst_Pass = sum((MgmtFor & ISSAgainst) & Pass);
MgmtForISSAgainst_Fail = sum((MgmtFor & ISSAgainst) & Fail);

MgmtAgainstISSFor_Pass =  sum((MgmtAgainst & ISSFor) & Pass)
MgmtAgainstISSFor_Fail =  sum((MgmtAgainst & ISSFor) & Fail)

%% Pass rate for disagreement on sharholder proposals
clc
Pass = VoteResult_dummy(:,6); % Votes that pass
Fail  = VoteResult_dummy(:,2);  % Votes that fail

AgreementFor_Pass_Sheer = sum((MgmtFor & ISSFor) & Pass & SponsorSher)
AgreementFor_Fail_Sher = sum((MgmtAgainst & ISSAgainst) & Fail & SponsorSher)
AgreementAgainst_Pass_Sher = sum((MgmtAgainst & ISSAgainst) & Pass & SponsorSher)
AgreementAgainst_Fail_Sher = sum((MgmtAgainst & ISSAgainst) & Fail & SponsorSher)
MgmtForISSAgainst_Pass_Sher = sum((MgmtFor & ISSAgainst) & Pass & SponsorSher)
MgmtForISSAgainst_Fail_Sher = sum((MgmtFor & ISSAgainst) & Fail & SponsorSher)
MgmtAgainstISSFor_Pass_Sher =  sum((MgmtAgainst & ISSFor) & Pass & SponsorSher)
MgmtAgainstISSFor_Fail_Sher =  sum((MgmtAgainst & ISSFor) & Fail & SponsorSher)

%% Contentious resolutions
% The resolutions where both managment and iss are against and they still pass
MAIAResolutionPass = AgendaGeneralDesc(find((MgmtAgainst & ISSAgainst & Pass)==1))

%% Most common resolutions in contentious issues
% Managment For ISS For
AgendaGeneralDescFF = AgendaGeneralDesc(find((MgmtFor & ISSFor)==1));
SupportAdjustedFF = SupportAdjusted(find((MgmtFor & ISSFor)==1));
% Managment For ISS Against
AgendaGeneralDescFA = AgendaGeneralDesc(find((MgmtFor & ISSAgainst)==1));
SupportAdjustedFA = SupportAdjusted(find((MgmtFor & ISSAgainst)==1));
% Managment Against ISS Against
AgendaGeneralDescAA = AgendaGeneralDesc(find((MgmtAgainst & ISSAgainst)==1));
SupportAdjustedAA = SupportAdjusted(find((MgmtAgainst & ISSAgainst)==1));
% Managment Against ISS FOR
AgendaGeneralDescAF = AgendaGeneralDesc(find((MgmtAgainst & ISSFor)==1));
SupportAdjustedAF = SupportAdjusted(find((MgmtAgainst & ISSFor)==1));

[D3, Result3,U3] = text_to_dummy_extended(AgendaGeneralDescFF,SupportAdjustedFF);
[D4, Result4,U4] = text_to_dummy_extended(AgendaGeneralDescFA,SupportAdjustedFA);
[D5, Result5,U5] = text_to_dummy_extended(AgendaGeneralDescAA,SupportAdjustedAA);
[D6, Result6,U6] = text_to_dummy_extended(AgendaGeneralDescAF,SupportAdjustedAF);

%% Basic Regressions 
clc
% Regress percentge support on characteristics
% Remove 'say on pay frequency' votes first
ShareholderSponsored = Sponsor_dummy(:,2);
ShareholderSponsored(find(SayOnPayFrequency==1)) = [];      
ISSAgainst2 = ISSAgainst;
ISSAgainst2(find(SayOnPayFrequency==1)) = []; 
MgmtAgainst2 = MgmtAgainst;
MgmtAgainst2(find(SayOnPayFrequency==1)) = []; 
FFA2 = FFA;
FFA2(find(SayOnPayFrequency==1)) = []; 
RecInteraction = ISSAgainst2.*MgmtAgainst2;

Table = table(ShareholderSponsored, ISSAgainst2, MgmtAgainst2, RecInteraction, FFA2, 'VariableNames', { 'SharholderSponsored', 'ISSAgainst', 'MgmtAgainst', 'ISSAgainstMgmtAgainst', 'VotedForVsForAgainst'});
Model = fitlm(Table) 
plot(Model) 

%% Model 2 with all the cross-interaction terms

Table2 = table(ShareholderSponsored, ISSAgainst2, MgmtAgainst2, FFA2, 'VariableNames', { 'SharholderSponsored', 'ISSAgainst', 'MgmtAgainst', 'VotedForVsForAgainst'}); 
Model2 = fitlm(Table2, 'interactions')
