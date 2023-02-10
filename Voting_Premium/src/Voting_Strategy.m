%% Making a Voting Strategy
% Step 1: Turn nine digit cusip to eight digit CUSIP (done)
% Step 2: Turn CUSIP to Permno for the merger with CRSP/COMPUSTAT  (done)
% Step 3: Make all dates end of month dates to match with other (monthly) databases (done)
% Step 4: Make the suprise disagreement measure (done)
% Step 5: Aggregate the shareholder support measure for firms with multiple resoulutions in the same month (done)
% Step 6: Put the data in the CRSP/COMPUSTAT signal format to prepare it for the sorts (done)

%% Load 'Company Vote Results' to save the variables we need for the analysis
clc
clear
load('data/Vote_Results_2022');
CUSIPVote = CUSIP;
save CUSIPVote CUSIPVote  % Save the CUSIP variable we need and clear the rest
save MeetingDate MeetingDate    % Save the dates
clear

%%  Step 1: Turn nine digit cusip to eight digit CUSIP
%% Find the unique CUSIP/PERMNO matches in Compustat (8 digit Cusip)
clear
clc
load Identifiers_Right
% There should be around 4 mil identifiers (if it is around 1mil it means it was capped when importing in excel; due to the excel size limit)
% Note the identifiers are repetitive as they come from CRSP

% Find the location of unique identifiers (takes a while)
UP = unique(PERMNO);
Location = nan(size(UP));
tic
for i = 1:size(UP,1)
    Location(i) = min(find(UP(i)==PERMNO));
end
toc
Location = Location';
save Location Location

% Select only the unique identifiers
PermnoU = PERMNO(Location);
CusipU = CUSIP(Location);
% Checked; matches are unique
clc
CUSIP(find(PERMNO==10007));

save PermnoU PermnoU
save CusipU CusipU

%% 
check = find(PERMNO==10000);
check2 = find(ismember(CUSIP,{'68391610'})==1);
check - check2      % It should be all zeros; all the locations where there is 10000 and '68391610' are the same

%% Turn the 9 digit identifier in the vote database to 8 digit; each company/issue is uniquely identified with 8 digit CUSIP (8th digit is zero for common stocks)
clear
clc
load CUSIPVote
ca = CUSIPVote; % This is the CUSIPS from the voting analytics dataset
temp = find(cellfun(@isempty,ca));  % Find the empty cusips (no cusip info)

for i=1:size(temp,1);
ca{temp(i)} = '000000000';      % Replace them with a generic 000000000 code (with 9 digits see below)
end
% Truncate the cusip to 8 digits
for k = 1:length(ca)
    cellContents = ca{k};
    % Truncate and stick back into the cell
    ca{k} = cellContents(1:8);  % Take only the first 8 characters
end
save ca ca

%%
check = find(ismember(ca, {'87254010'})==1);
CUSIPVote(check)

%% Step 2: Turn CUSIP to Permno for the merger with CRSP/COMPUSTAT
%% Find the matching permno
clear
clc
load ca
load PermnoU
load CusipU
[ISCommon, Where] = ismember(ca, CusipU);   % ca is the voting data identifier; CusipU are the CRSP identifiers
% IsCommon gives us whether 1 or 0 depending whether the element of A is in B
% Where gives us the lowest location where they match
GenericCodeLocation = find(ismember(ca, {'39365710'}));     % You need one generic code to put for all the zeros
Where(find(Where==0)) = 1; % Places a one instead of a zero; since you cannot index zero
PermnosVote = PermnoU(Where);    % Gives you the right permnos
PermnosVote(find(PermnosVote==[10000])) = 0;    % Replace the generic permno we used when there is no match with NaN
PermnosVote(GenericCodeLocation) = 10000;   % Add back the generic code
save PermnosVote PermnosVote

%% Step 3: Make all dates end of month dates to match with other (monthly) databases
%% Push the dates at the end of the month
load MeetingDate
temp = dateshift(MeetingDate, 'end', 'month');   % Shifts all values at the end of the month
[y,m] = ymd(temp);      % Gives you the year and the month
EndDate = y*100+m;  % Create an end date that matches the dates in CRSP/COMPUSTAT
save EndDate EndDate

%% Step 4: Make the suprise disagreement measure
%% Make the disagreement measure
clear
load SupportAdjusted 
load AGD_dummy 
load AGD_types 

%% Main Code (takes a while to run; 70 min)
tic           % Measure the time for the code
ShareholderSupport = nan(size(SupportAdjusted)); % Preallocate for speed
for i = 1:size(SupportAdjusted,2)
    ResolutionType = find(AGD_dummy(i,:) ==1);  % Find the type of resolution that the specific vote is
    temp = AGD_dummy(:,ResolutionType);            % Select the resolutions of this particular type
    temp(find(temp==0)) = nan;               % Put no answer when the resolution is not used instead of zero so it is not used in the mean and standard deviation calculations
    SupportAdjustedResolutionSpecific = SupportAdjusted.*temp';    % Remove from the Support the observations for different votes
    ShareholderSupport(i) = (SupportAdjustedResolutionSpecific(i) - nanmean(SupportAdjustedResolutionSpecific(1:(i-1))))/nanstd(SupportAdjustedResolutionSpecific(1:(i-1)));   
    % Calculate the crude deviation measure which is the vote outcome minus
    % the histiorical resolution average divided by deviation in vote support
    % we take i-1 since we do not use the current observation in the benchmark
    % Matlab gives zero divided by zero as NaN; so all the first ellect
    % director votes will be NaN as answer
    % Infinity will appear when the new vote is not a 100% support but the
    % previous votes were; conseuqently, vote outcome minus average will
    % not be zero while the standard deviation of previous votes will be zero
end
toc

%% Save the result as it takes a while to make
save ShareholderSupport ShareholderSupport
%% Save alternative
ShareholderSupportRestricted = ShareholderSupport;
save ShareholderSupportRestricted ShareholderSupportRestricted

%% Step 5: Aggregate the shareholder support measures for firms with multiple resoulutions in the same month
%% Merge disagreeement in the same month
clear
% load ShareholderSupport     % Change SupportAdjusted to Shareholder Support when you generate it
load ShareholderSupportRestricted
ShareholderSupport = ShareholderSupportRestricted;
load EndDate
load PermnosVote

%% Basic analysis of shareholder support
ShareholderSupport(find(~isfinite(ShareholderSupport))) = nan;    % Replace the infinity with nan
temp = ShareholderSupport;  % Winsorize for some figures
temp(find(temp>10)) = 10;
temp(find(temp<-10)) = -10;
histogram(temp)
% xlabel('Shareholder Support')

%% Find the location where there is a switch between companies
for i = 2:size(PermnosVote,1) 
temp(i) = (PermnosVote(i)==PermnosVote(i-1));
end
temp = temp';  % Have one in the matrix when there is a repretitive firm
temp(1) = 0;
Location = find(~temp==1);  % Find the location when there is a switch
Location = Location';

%% Gives you the average for each repetitive consecutive firm 
% Consider using the three maximum shareholder support measures as an alternative
% Here you can itterate if you want to change the way you combine votes in the same date
for i = 1:(length(Location)-1)        
    Averages(i) = nanmean(ShareholderSupport(Location(i):(Location(i+1)-1)));   % It finds the average between two firms changes (nanmean to ignore when there is no support)
end
ShareholderSupportUnique = Averages';   % Checked in excel
ShareholderSupportUnique = [ShareholderSupportUnique; nanmean(ShareholderSupport(Location(end):length(ShareholderSupport)))];

%% Create the key measures that are date-firm unique
    
PermnosVoteUnique = PermnosVote(Location);
EndDateUnique = EndDate(Location);
Check = length(PermnosVoteUnique)==length(EndDateUnique)
Check = length(EndDateUnique)==length(ShareholderSupportUnique) % 1 means they are the same size (this is good)

%% Find additional overalps
tic
DatePermnoIdentifier = EndDateUnique*1000000+PermnosVoteUnique;
Check = length(unique(DatePermnoIdentifier,'stable')) - length(PermnosVoteUnique)   % Should be zero if they are all unique

% Make an average of all the overalpping permno-dates
for i = 1:length(DatePermnoIdentifier);
    if length(find(DatePermnoIdentifier==DatePermnoIdentifier(i))>1);
        Location = find(DatePermnoIdentifier==DatePermnoIdentifier(i));
        ShareholderSupportUnique(i) = nanmean(ShareholderSupportUnique(Location));
    end
end
toc
%% Remove all the rows that are overlapping
tic
[C,IA] = unique(DatePermnoIdentifier,'stable');     % IA contains all the first rows when a unique date-permno appears; we can remover the non-unique as they are already part of the average
ShareholderSupportUnique = ShareholderSupportUnique(IA);
PermnosVoteUnique = PermnosVoteUnique(IA);
EndDateUnique = EndDateUnique(IA); 
toc
%% Save the data
ShareholderSupportUniqueRestricted = ShareholderSupportUnique;
save ShareholderSupportUniqueRestricted ShareholderSupportUniqueRestricted
save PermnosVoteUnique PermnosVoteUnique
save EndDateUnique EndDateUnique
% Output matches till here

%% Step 6: Put the data in the CRSP/COMPUSTAT signal format to prepare it for the sorts
%% Make the signal in the right format (3 sec)
tic 
clc
clear
% load ShareholderSupportUnique
load ShareholderSupportUniqueRestricted
ShareholderSupportUnique = ShareholderSupportUniqueRestricted;
% Current format
load PermnosVoteUnique
load EndDateUnique
% DesiredFormat
load permno
load dates
DatePermnoIdentifier = EndDateUnique*1000000+PermnosVoteUnique;
load DatePermno
ToBeTransformed = ShareholderSupportUnique;
Transformed = nan(rows(dates),rows(permno)); % prealocate for speed
[LIA,LOCB] = ismember(DatePermnoIdentifier,DatePermno); % Find the location where they overlapp
temp = [LOCB,ToBeTransformed];  
temp2 = unique(temp, 'rows');   % Remove non-unique rows
temp2(find(temp2(:,1)==0)) = 1; % Remove zeros as they cannot be indexed (this is where they do not overlap)
Transformed(temp2(:,1)) = temp2(:,2);   % Transform the data
Transformed(1) = nan;   % Remove the generic result
toc

%%
SignalVoteT =Transformed;
save SignalVoteT SignalVoteT
Check = nansum(nansum(~isnan(SignalVoteT)))  % The total number of signals


%%
SignalVoteRestricted = Transformed;
save SignalVoteRestricted SignalVoteRestricted
%% Make the signal in the right format (10 min)
clc
clear
load ShareholderSupportUniqueOld
% Current format
load PermnosVoteUnique
load EndDateUnique
% Format desired
load permno
load dates
DatePermnoIdentifier = EndDateUnique*1000000+PermnosVoteUnique;
tic
Start = find(dates==(min(EndDateUnique)));  % Find the earliest starting date; use it to cut the time on the loop
Signal = nan(rows(dates),rows(permno)); % prealocate
for i = Start:rows(dates);
    for j = 1:rows(permno);
        temp = dates(i)*1000000+permno(j);  % Create a unique identifier for that permno/date
        if  ismember(temp, DatePermnoIdentifier);    % If a particular date-permno has a corresponding date-permno in the voting data
            Location = find(DatePermnoIdentifier==temp);    % Find where the corresponding voting data is
            Signal(i,j) = ShareholderSupportUnique(Location);   % Assign the correct vote result to the signal
      end
    end
end

%%
Check = nansum(nansum(~isnan(Signal)))  % The total number of signals
SignalVote = Signal;
save SignalVote SignalVote
toc

%% Code check
clear
load SignalVote
load SignalVoteT
A = SignalVote-SignalVoteT;
A(A==0) = nan;
find(~isnan(A))     % Are the two methods giving the same result (empty matrix means they give the same signal)
A = nansum(isfinite(SignalVote)-isfinite(SignalVote))

%% Set up PermnoDate for matrix reformating
clear
load permno
load dates
Permno = repmat(permno',rows(dates),1);
PermnoDate = bsxfun(@plus,Permno,(1000000*dates));
save PermnoDate PermnoDate