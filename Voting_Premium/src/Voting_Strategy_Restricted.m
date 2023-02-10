%% Step 4: Make the suprise disagreement measure with restricted samples
clear
load SupportAdjusted 
load AGD_dummy 
load AGD_types 

%% Remove votes from the analyis
load Sponsor_dummy
load Sponsor_types

% Keep only managmenet proposals
SupportAdjusted(find(Sponsor_dummy(:,2)==0)) = nan;

%% Main Code (takes a while to run; 67min)
tic           % Measure the time for the code
ShareholderSupport = nan(size(SupportAdjusted)); % Preallocate for speed
for i = 1:rows(SupportAdjusted)
    ResolutionType = find(AGD_dummy(i,:) ==1);  % Find the type of resolution that the specific vote is
    temp = AGD_dummy(:,ResolutionType);            % Select the resolutions of this particular type
    temp(find(temp==0)) = nan;               % Put no answer when the resolution is not used instead of zero so it is not used in the mean and standard deviation calculations
    SupportAdjustedResolutionSpecific = SupportAdjusted.*temp;    % Remove from the Support the observations for different votes
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

%% Save
ShareholderSupportManagementOnly = ShareholderSupport;
save ShareholderSupportManagementOnly ShareholderSupportManagementOnly

%% Step 5: Aggregate the shareholder support measures for firms with multiple resoulutions in the same month
%% Merge disagreeement in the same month
clear
load ShareholderSupportManagementOnly     % Change SupportAdjusted to Shareholder Support when you generate it
load EndDate
load PermnosVote

ShareholderSupport = ShareholderSupportManagementOnly;
ShareholderSupport(~isfinite(ShareholderSupport)) = nan;

%% Find the location where there is a switch between companies (1 sec)
tic
for i = 2:rows(PermnosVote) 
temp(i) = (PermnosVote(i)==PermnosVote(i-1));
end
temp = temp';  % Have one in the matrix when there is a repretitive firm
temp(1) = 0;
Location = find(~temp==1);  % Find the location when there is a switch
Location = Location';
toc

%% Gives you the average for each repetitive consecutive firm (1 sec)
% Consider using the three maximum shareholder support measures as an alternative
% Here you can itterate if you want to change the way you combine votes in the same date
tic
for i = 1:(cols(Location)-1)        
Averages(i) = nanmean(ShareholderSupport(Location(i):(Location(i+1)-1)));   % It finds the average between two firms changes (nanmean to ignore when there is no support)
end
ShareholderSupportUnique = Averages';   % Checked in excel
ShareholderSupportUnique = [ShareholderSupportUnique; nanmean(ShareholderSupport(Location(end):rows(ShareholderSupport)))];
toc
%% Create the key measures that are date-firm unique
    
PermnosVoteUnique = PermnosVote(Location);
EndDateUnique = EndDate(Location);
Check = rows(PermnosVoteUnique)==rows(EndDateUnique)
Check = rows(EndDateUnique)==rows(ShareholderSupportUnique) % 1 means they are the same size (this is good)

%% Find additional overalps (9 sec)
tic
DatePermnoIdentifier = EndDateUnique*1000000+PermnosVoteUnique;
Check = rows(unique(DatePermnoIdentifier,'stable')) - rows(PermnosVoteUnique)   % Should be zero if they are all unique

% Make an average of all the overalpping permno-dates
for i = 1:rows(DatePermnoIdentifier);
    if rows(find(DatePermnoIdentifier==DatePermnoIdentifier(i))>1);
        Location = find(DatePermnoIdentifier==DatePermnoIdentifier(i));
        ShareholderSupportUnique(i) = nanmean(ShareholderSupportUnique(Location));
    end
end
toc

%% Remove all the rows that are overlapping
[C,IA] = unique(DatePermnoIdentifier,'stable');     % IA contains all the first rows when a unique date-permno appears; we can remover the non-unique as they are already part of the average
ShareholderSupportUnique = ShareholderSupportUnique(IA);
PermnosVoteUnique = PermnosVoteUnique(IA);
EndDateUnique = EndDateUnique(IA); 

ShareholderSupportUniqueManagement = ShareholderSupportUnique;
%% Save the data
save ShareholderSupportUniqueManagement ShareholderSupportUniqueManagement
save PermnosVoteUnique PermnosVoteUnique
save EndDateUnique EndDateUnique

%% Step 6: Put the data in the CRSP/COMPUSTAT signal format to prepare it for the sorts
clc
clear
load ShareholderSupportUniqueManagement
ShareholderSupportUnique = ShareholderSupportUniqueManagement;
% Current format
load PermnosVoteUnique
load EndDateUnique
% Format desired
load permno
load dates
DatePermnoIdentifier = EndDateUnique*1000000+PermnosVoteUnique;

%% Make the signal in the right format (10 min)
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

Check = nansum(nansum(~isnan(Signal)))  % The total number of signals
toc


%% Save the result
SignalVoteManagement = Signal;
save SignalVoteManagement SignalVoteManagement