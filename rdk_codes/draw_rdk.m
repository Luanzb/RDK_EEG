function [dots] = draw_rdk(const,rdk,stimulusType)
% -------------------------------------------------------------------------
% draw_rdk(const,rdk,stimulusType)
% -------------------------------------------------------------------------
% Goal of the function :
% Draw random dot kinematogram stimulus masks (patches of randomly moving 
% dots), test item (patch with coherent motion), and distractor items 
% (patches of randomly moving dots).


% Function created by Nina M. Hanning (hanning.nina@gmail.com) 
% and Martin Szinte (martin.szinte@gmail.com)
% Last update : 09 / 04 / 2019
% Project :     StimtTest
% Version :     1.0
% -------------------------------------------------------------------------
% ADD THIS: Set dot color preference



% signal direction

% durBefSignal  = const.start_test_fr; % - 1;                                    % before the signal
% durAftSignal  =  0; %size(const.end_test_fr+1:const.max_fr ,2);                  % after the signal
 durDistractor = const.max_fr ;

% define matrix of distractor and test based on stimulusType parameter
if stimulusType == 1
    % Create only target stimulus
    dotSet.xyd              = [const.pos,rdk.rad*2];                   % x coord / y coord / diameter
    dotSet.durBef           = durBefSignal;
    dotSet.durAft           = durAftSignal;
    dotSet.dirS             = rdk.dirSignal;
    dotSet.kappaVal         = rdk.kappa;
    dots{1}                 = comp_randomDots1(const,dotSet);
elseif stimulusType == 0
    % Create only distractor stimulus
    dotSetDist.xyd          = [const.pos,rdk.rad*2];         % x coord / y coord / diameter (using first distractor position)
    dotSetDist.dur          = durDistractor;
    dots{1}                 = comp_randomDotsNoise(const,dotSetDist);

end

end
