%% Step 4: Make the suprise disagreement measure relative to the management recomendation
clear
load SupportAdjusted 
load AGD_dummy 
load AGD_types 
load MgmtRec_dummy 
load mgmtrec_types
load ShareholderSupport
load EndDate
load PermnosVote
ManagementFor = MgmtRec_dummy(:,5);
ManagementAgainst = MgmtRec_dummy(:,2)+MgmtRec_dummy(:,3)+MgmtRec_dummy(:,4)+MgmtRec_dummy(:,6)+MgmtRec_dummy(:,10);
% For recomendations are positive and against recomendations are negative
Management = ManagementFor-ManagementAgainst;

%% Switch the sign
for i = 1:rows(ShareholderSupport);
    if ShareholderSupport(i)>0 & Management(i)<0;   % They disagree, sign from positive to negative sign
        ShareholderSupport(i) = ShareholderSupport(i)*(-1);
    elseif ShareholderSupport(i)<0 & Management(i)<0;   % They agree, sign from negative to positive 
        ShareholderSupport(i) = ShareholderSupport(i)*(-1);
    elseif ShareholderSupport(i)<0 & Management(i)>0;   % They disagree, sign remains negative
        ShareholderSupport(i) = ShareholderSupport(i);
    end
end
ShareholderSupport(find(~isfinite(ShareholderSupport))) = nan;

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

ShareholderSupportRelativeToManagement = ShareholderSupportUnique;

%% Step 6: Put the data in the CRSP/COMPUSTAT signal format to prepare it for the sorts
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
SignalRelativeToManagement = Signal;
save SignalRelativeToManagement SignalRelativeToManagement