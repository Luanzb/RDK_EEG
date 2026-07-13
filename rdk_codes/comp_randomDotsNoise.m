function dots = comp_randomDotsNoise(const,dotSet)
% ----------------------------------------------------------------------
% dots = comp_randomDotsNoise(const,dotSet)
% ----------------------------------------------------------------------
% Goal of the function :
% Compute details of random dot stimuli corresponding to the noise 
% signal.
% ----------------------------------------------------------------------
% Input(s) :
% const = constant of the experiment
% dotSet.dur = duration of the noise
% ----------------------------------------------------------------------
% Output(s):
% dots : struct containing all dots informations
% ----------------------------------------------------------------------
% Function created by Martin SZINTE (martin.szinte@gmail.com)
% edited by Nina HANNING (hanning.nina@gmail.com)
% Last update : 09 / 04 / 2019
% Project :     StimTest
% Version :     1.0
% ----------------------------------------------------------------------

% Create information for dots in first motion phase
dinf1       = genVonMisesLimLifeDotInfo(const,dotSet.xyd);
dinf1.dur   = const.frame_dur*dotSet.dur;
dinf1.nfr   = dotSet.dur;
dots(1)     = getVonMisesLimLifeDotData(const,dinf1);

end