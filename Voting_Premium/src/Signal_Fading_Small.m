%% Signal Fading Small
% Check the signal fading effect on samll stocsk
clear 
clc
load SignalVote; load dates; load me; load ret; load NYSE

% Set-up
NP = 3; % indicate the number of portfolios in which you will sort stocks; 10 for deciles, 5 for quintiles, 3 for terciles
method = 1; % or 1 for ew
NumberOfFactors = 6;    % 3 for FF3, 5 for FF5 and 6 for FF5+mom
Breakpoint = nanmedian(me,2);   % Breakpoint for all median
BreakpoinT = repmat(Breakpoint,1,cols(me)); % Make the array the same size as market capitalization

% One month fading 
SignalVote(isnan(SignalVote)) = 0;
% SignalVote = SignalVote;    % No fading
% SignalVote = SignalVote + lagmatrix(SignalVote,+1);  % Two month fading
% SignalVote = SignalVote+lagmatrix(SignalVote,1)+lagmatrix(SignalVote,2)+lagmatrix(SignalVote,3);  % Four month fading
SignalVote = SignalVote+lagmatrix(SignalVote,1)+lagmatrix(SignalVote,2)+lagmatrix(SignalVote,3)+lagmatrix(SignalVote,4)+lagmatrix(SignalVote,5); % Six month fading 
% SignalVote = SignalVote+lagmatrix(SignalVote,1)+lagmatrix(SignalVote,2)+lagmatrix(SignalVote,3)+lagmatrix(SignalVote,4)+lagmatrix(SignalVote,5)+lagmatrix(SignalVote,6)+lagmatrix(SignalVote,7)+lagmatrix(SignalVote,8)+lagmatrix(SignalVote,9)+lagmatrix(SignalVote,10)+lagmatrix(SignalVote,11)+lagmatrix(SignalVote,12); % Twelve month fading 
SignalVote(me>BreakpoinT) = nan;    % Remove all companies with values below(above) the break point
SignalVote(SignalVote==0) = nan;
indVOTAlt = aprts(SignalVote,NP); % assigns ret break points that form TEN portfolios using NYSE BREAKS (the optional third argument)
[resultsvwVOTAlt,pretVOTAlt] = tsregs(ret,indVOTAlt,dates,method,4,0);          % basic value-weighted 
% Do the proper regressions
[Result] = ts_benchmark_regression(pretVOTAlt, NumberOfFactors,dates);
