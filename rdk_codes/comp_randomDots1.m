function dots = comp_randomDots1(const,dotSet)
% ----------------------------------------------------------------------
% dots = comp_randomDots1(const,dotSet)
% ----------------------------------------------------------------------
% Goal of the function :
% Compute details of random dot stimuli corresponding to the probe
% signal. Made for only one signal inside noise.
% ----------------------------------------------------------------------
% Input(s) :
% const = constant of the experiment
% dotSet.dirSignal = direction of the signal
% dotSet.posAngle = angle of the centre of the patch to compute
% dotSet.durBef = duration of first motion phase
% dotSet.durAft = duration of second motion phase
% dotSet.kappaVal = kappa value of the von misses distribution of direction
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
dinf1 = genVonMisesLimLifeDotInfo(const,dotSet.xyd);
dinf1.dur = const.frame_dur*dotSet.durBef;
dinf1.nfr = dotSet.durBef;

% Create information for dots in second motion phase
dinf2 = genVonMisesLimLifeDotInfo(const,dotSet.xyd);
dinf2.dur = const.frame_dur*const.test_dur_fr;
dinf2.nfr = const.test_dur_fr;

% Change kappa for test patch (randomly chose above)
dinf2.kap = dotSet.kappaVal;   % kappa of 10 should be clearly visible
dinf2.the = dotSet.dirS;
dinf2.spd = const.dotSpeed_pix * const.sigDotSpeedMulti;

% Create information for dots in second motion phase
dinf3 = genVonMisesLimLifeDotInfo(const,dotSet.xyd);
dinf3.dur = const.frame_dur*dotSet.durAft;
dinf3.nfr = dotSet.durAft;

% Generate integrated motion paths for dots (comprising all three phases)
dots1  = getVonMisesLimLifeDotData(const,dinf1);
dots2  = addVonMisesLimLifeDotData(const,dinf2,dots1);

if dotSet.durAft ~= 0
    dots(1) = addVonMisesLimLifeDotData(const,dinf3,dots2);
else
    dots(1) = dots2(1);
end
end