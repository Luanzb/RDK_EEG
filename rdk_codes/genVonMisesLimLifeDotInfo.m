function dinf = genVonMisesLimLifeDotInfo(const,xyd)
% Version 1.0, Feb 2012 by Martin Rolfs
% Modified by Martin Szinte, 14 Jan 2014
%           - add dotSize
%           - add scr as input and use my own conversion in pix
%           - add const as input to be used in my codes
% NH :      - took out scr; (9.4.2019)
%           - changed deg to pix

dinf.xyd = xyd;                                     % center and diameter of patch [deg]
dinf.spd_pix = const.dotSpeed_pix;                  % speed [pix/dec]
dinf.the = const.theta_noise;                       % theta parameter of von Mises, main direction [degrees]
dinf.kap = const.kappa_noise;                       % kappa parameter of von Mises, spread of direction [0 = evenly distributed]
dinf.dur = 1;                                       % maxDotTime [sec]
dinf.siz = const.dotRadSize;                        % dot size [pix]
dinf.lif = [const.numMinLife const.numMeanLife];	% life time parameters (minimum and mean) [frames]

% define number of dots based on density per deg^2.
% This value is taken from Ball & Sekuler (1987, Experiments 3 to 6).
dinf.num = const.numDots;

% we can make each dot have a different size by changing the siz matrix
dinf.siz = repmat(dinf.siz,1,dinf.num);
% % example of varying sizes: 
% dinf.siz = repmat(dinf.siz,1,dinf.num)+3*rand(1,dinf.num).*repmat(dinf.siz,1,dinf.num);
end