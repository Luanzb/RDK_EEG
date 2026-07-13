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

% % Set dot colors based on const.dotColorType
% if const.dotColorType == 1
%     % All cyan dots - same format as white (0-255 range)
%     dinf.col = repmat(const.dotcolor1a, dinf.num, 1)';
% elseif const.dotColorType == 2
%     % All pink dots - same format as white (0-255 range)
%     dinf.col = repmat(const.dotcolor2a, dinf.num, 1)';
% else
%     % Mixed cyan and pink dots - same format as white (0-255 range)
%     cyan_color = const.dotcolor1a;
%     pink_color = const.dotcolor2a;
%     color_choice = round(rand(1,dinf.num));
%     dinf.col = zeros(3,dinf.num);
%     dinf.col(:,color_choice==0) = repmat(cyan_color',1,sum(color_choice==0));
%     dinf.col(:,color_choice==1) = repmat(pink_color',1,sum(color_choice==1));
% end

% we can make each dot have a different size by changing the siz matrix
dinf.siz = repmat(dinf.siz,1,dinf.num);
% % example of varying sizes: 
% dinf.siz = repmat(dinf.siz,1,dinf.num)+3*rand(1,dinf.num).*repmat(dinf.siz,1,dinf.num);
end