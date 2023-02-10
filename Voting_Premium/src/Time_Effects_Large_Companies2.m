%% Time effects for large compaines 
tic
clear
clc
load dates; load me; load ret; load NYSE; load SignalVote  
toc % (2 sec)

%% Set up the analysis 
tic
NP = 10; % Indicate the number of portfolios in which you will sort stocks; '10' for deciles, '5' for quintiles, '3' for terciles
PortfolioWeights = me; % Use 'me' for value weighted and '1' for equally wegithed
NumberOfFactors = 6;    % Number of factors for benchmarking; '3' for FF3, '5' for FF5 and '6' for FF5+mom
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization
toc % (1 sec)

%% Aggregated Before Signal
tic
SignalVote(isnan(SignalVote)) = 0;
SignalBefore = lagmatrix(SignalVote,-1) + lagmatrix(SignalVote,-2) + lagmatrix(SignalVote,-3) ; % The signal in the base period is set up for investments in t+1
SignalBefore(SignalBefore == 0) = nan;
SignalBefore(me<BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
indVOT = aprts(SignalBefore, NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,PortfolioWeights,4,0);          % basic value-weighted 
% Do the proper regressions
[ResultBefore] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
Number_Firms = number_of_firms(indVOT);  % There should be the same number of stocks per portfolio
toc % (5 sec)

%% Aggregated After Signal
tic
SignalAfter = SignalVote + lagmatrix(SignalVote,1)+ lagmatrix(SignalVote,2); % The signal in the base period is set up for investments in t+1
SignalAfter(SignalAfter == 0) = nan;
SignalAfter(me<BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
indVOT = aprts(SignalAfter, NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,PortfolioWeights,4,0);          % basic value-weighted 
% Do the proper regressions
[ResultAfter] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
Number_Firms = number_of_firms(indVOT);  % There should be the same number of stocks per portfolio
toc % (5 sec)

%% Period Effects
tic
Signal = lagmatrix(SignalVote,-5); % Itterate the lag to get the period you want (0 is the month after the vote)
Signal(Signal == 0) = nan;
% Signal(me>BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
indVOT = aprts(Signal, NP, NYSE); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOT,pretVOT] = tsregs(ret,indVOT,dates,PortfolioWeights,4,0);          % basic value-weighted 
% Do the proper regressions
[Result] = ts_benchmark_regression(pretVOT, NumberOfFactors,dates);
% Number_Firms = number_of_firms(indVOT);  % There should be the same number of stocks per portfolio
toc % (5 sec)