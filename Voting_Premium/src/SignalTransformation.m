%% Transform the signal
%% Load the data and exclude firms (4 sec)
tic
clear 
clc
load SignalVote
load me
load ret
% Remove firms without market capitalization data in this, following and previous period
SignalVote((isnan(me)))= nan;
SignalVote(isnan(lagmatrix(me,1))) = nan;  
SignalVote(isnan(lagmatrix(ret,-1))) = nan;  
save SignalVote SignalVote
toc

%% Crate a time effect in the signal (15 sec)
tic
% High shareholder support is top; low shareholder support is bottom
% If you want to lag or lead the signal; 1 to push it; 
SignalFourBefore = lagmatrix(SignalVote,-4);
SignalThreeBefore = lagmatrix(SignalVote,-3);
SignalTwoBefore = lagmatrix(SignalVote,-2);   
SignalBefore = lagmatrix(SignalVote,-1);   
SignalSameMonth= SignalVote;
SignalAfter = lagmatrix(SignalVote,1);   
SignalTwoAfter = lagmatrix(SignalVote,2);   
SignalThreeAfter = lagmatrix(SignalVote,3);  
SignalFourAfter = lagmatrix(SignalVote,4);

save SignalFourBefore SignalFourBefore
save SignalThreeBefore SignalThreeBefore
save SignalTwoBefore SignalTwoBefore
save SignalBefore SignalBefore
save SignalSameMonth SignalSameMonth
save SignalAfter SignalAfter
save SignalTwoAfter SignalTwoAfter
save SignalThreeAfter SignalThreeAfter
save SignalFourAfter SignalFourAfter
toc

%% Create the fading signals (628 sec)
tic
SignalAfter1Fading = signal_transformation(SignalAfter,me);   % Adds one more month to the signal
SignalAfter3Fading = signal_transformation3(SignalAfter,me);   % Adds three more month to the signal
SignalAfter6Fading = signal_transformation6(SignalAfter,me);   % Adds six more month to the signal
SignalAfter12Fading = signal_transformation12(SignalAfter,me);   % Adds twelve more month to the signal

save SignalAfter1Fading SignalAfter1Fading
save SignalAfter3Fading SignalAfter3Fading
save SignalAfter6Fading SignalAfter6Fading
save SignalAfter12Fading SignalAfter12Fading
toc
