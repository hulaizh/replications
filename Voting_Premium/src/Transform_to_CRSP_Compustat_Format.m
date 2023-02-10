%% Transform all the voting data into the CRSP/COMPUSTAT format 
%% Load the data (3 sec)
clc
clear
tic   % Measure the time for the code
% Desired format
load permno
load dates
% Load the data container
load T
ShareholderSupport = T.ASupport;
DatePermnoIdentifier = T.YearMonth*1000000+T.Permno;
toc

%% Create a date permno matrix (12 sec)
tic
Start = find(dates==(min(T.YearMonth)));  % Find the earliest starting date; use it to cut the time on the loop
for i = Start:rows(dates);
    for j = 1:rows(permno);
        DatePermno(i,j) = dates(i)*1000000+permno(j);  % Create a unique identifier for that permno/date
    end
DatePermno(find(DatePermno==0)) = nan;  % Remove zeros in case permno is put as zero
end
clear i j Start
save DatePermno DatePermno
toc

%% Next variable
%% Meeting Type (1 sec)
tic
% Select the variable to be transformed into the CRSP/COMUSTAT format from the data container T
ToBeTransformed = T.MeetingType;
% Make it numerical; and see which number represents which category
[ToBeTransformed,Categories] = grp2idx(ToBeTransformed);
toc

%% Make the signal in the right format (3 sec)
tic 
Transformed = nan(rows(dates),rows(permno)); % prealocate for speed
[LIA,LOCB] = ismember(DatePermnoIdentifier,DatePermno); % Find the location where they overlapp
temp = [LOCB,ToBeTransformed];  
temp2 = unique(temp, 'rows');   % Remove non-unique rows
temp2(find(temp2(:,1)==0)) = 1; % Remove zeros as they cannot be indexed
Transformed(temp2(:,1)) = temp2(:,2);   % Transform the data
Transformed(1) = nan;   % Remove the generic result
% Save the result
MeetingType = Transformed;
MeetingTypeCategories = Categories;
save MeetingType MeetingType
save MeetingTypeCategories MeetingTypeCategories
Mismatch = rows(temp2)-rows(unique(temp2(:,1))); % Number of times there were more than one type of meetings in a month. 
toc
clearvars -except DatePermno permno dates T

%% Next Variable
%% Sponsor (1 sec)
tic
% Select the variable to select votes
Selector = T.sponsor;
% Make it numerical; and see which number represents which category
[Selector,Categories] = grp2idx(Selector);
% Remove votes you don't want
SupportAdjusted = T.SupportAdjusted;
Selector(Selector~=2) = nan;     % Remove all other votes
Selector(Selector==2) = 1;     % Make it only 1 or nan
SupportAdjusted = SupportAdjusted.*Selector;  % Select vote outcomes only for shareholder sponsored
SupportAdjusted(find(~isfinite(SupportAdjusted))) = nan;  % Remove infinite values
toc

%% Make a new average with shareholder support only (takes a while to run; 3.5h)(run at night)
tic
load AGD_dummy 
load AGD_types 
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




