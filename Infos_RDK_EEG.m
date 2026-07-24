
git_path = '/home/kaneda/Documents/GitHub/RDK_EEG';
addpath(genpath(git_path));

pc_path = '/home/kaneda/Documents/Projects/RDK_EEG';
addpath(genpath(pc_path));

% Ask subject number
answer = inputdlg({'Numero voluntario'}, '', [1 25]);
sub.id = answer{1}; sub.id_num = str2double(answer{1});

%% INFORMAÇÕES SOBRE O TECLADO
KbName('UnifyKeyNames');
info.espaceKey = KbName('space');

%% Screen setup
Screen('Preference', 'SyncTestSettings', 0.01, 50, 0.25);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests', 1);

% Seed the random number generator. Here we use an older way to be
% compatible with older systems.
rng('shuffle')

screens = Screen('Screens');% Get the screen numbers.
info.scr_num = max(screens);% draw to the externalscreen.

% Define black and white (white== 1 and black, 0).
info.white_idx = WhiteIndex(info.scr_num);
info.black_idx = BlackIndex(info.scr_num);
info.gray_idx = info.white_idx/2;

% Open an screen window
[win, info.scr_rect] = PsychImaging('OpenWindow', info.scr_num, info.black_idx, [], 32, 2, [], []); % RODA EM TELA TODA

% Inter-flip interval
info.scr_ifi = Screen('GetFlipInterval', win);

sca; clc;

%% Get the size of the screen window in pixels

[scr_xsize_mm, scr_ysize_mm] = Screen('DisplaySize', info.scr_num);
info.scr_xsize_cm = scr_xsize_mm/10;
info.scr_ysize_cm = scr_ysize_mm/10;

% Screen size in pixels
%or, by:[scrX,scrY] = Screen('WindowSize',info.scr_num); % in  pixels
info.scr_xsize = info.scr_rect(3);
info.scr_ysize = info.scr_rect(4);

% Centre coordinate of the window
[info.scr_xcenter, info.scr_ycenter] = RectCenter(info.scr_rect); % in pixels
info.scr_rrate = round(1/info.scr_ifi);     % Refresh rate
info.scr_dist_cm = 57;          % Viewing distance from screen (cm)

% parameters for fixation period before every trial onset.
info.fix_dur_sec = 0.5;         % Duration of fixation at ROI to start trial in secs
info.roi_fix_dva = 1.5;           % size of fixation window ROI
info.roi_fix_pix = dva2pix(info.scr_dist_cm,info.scr_xsize_cm,info.scr_xsize,info.roi_fix_dva);

%% Infos Fixation Dot
info.fp_size_dva_black = 0.25;        % fixation Dot diameter
info.fp_size_pix_black = round(dva2pix(info.scr_dist_cm, info.scr_xsize_cm, info.scr_xsize, info.fp_size_dva_black));

info.fp_size_dva_white = 0.4;        % fixation Dot diameter white
info.fp_size_pix_white = round(dva2pix(info.scr_dist_cm, info.scr_xsize_cm, info.scr_xsize, info.fp_size_dva_white));
%%
% create rectangle area in an arc format to be used as the saccadic cue
info.cue_size = info.fp_size_pix_white; % diameter in pixels, same as the white fixaiton point
base_cue_size = [0 0 info.cue_size info.cue_size];
info.cue_position = CenterRectOnPointd(base_cue_size, info.scr_xcenter, info.scr_ycenter);

%% Tamanho, velocidade e Posicoes dos RDK

% tamnho do estimulo RDK
RDK.size_dva = 5;
RDK.size_pix = dva2pix(info.scr_dist_cm,info.scr_xsize_cm,info.scr_xsize,RDK.size_dva);
% tamanho dos pontos do RDK
RDK.size_dot_dva = .14;
RDK.size_dot_pix = dva2pix(info.scr_dist_cm,info.scr_xsize_cm,info.scr_xsize,RDK.size_dot_dva);

% velocidade de movimento dos pontos por segundo. uma velocidade de 5 dva,
% equvale a um deslocamento de XX pixels por segundo.
RDK.speed_dot = 4; % 5
RDK.speed_dot_pix = dva2pix(info.scr_dist_cm,info.scr_xsize_cm,info.scr_xsize,RDK.speed_dot);

RDK.kappa = 100;

% RDK Eccentricity
RDK.EccDVA = 8;
RDK.Ecc = round(dva2pix(info.scr_dist_cm,info.scr_xsize_cm,info.scr_xsize,RDK.EccDVA));

% RDK coordinates on the left and right side from FP
RDK.coordL = [info.scr_xcenter-RDK.Ecc info.scr_ycenter];
RDK.coordR = [info.scr_xcenter+RDK.Ecc info.scr_ycenter];

% Random dot kinematograms
RDK.rad         = RDK.size_pix/2;               % item radius
const.stimRad   = RDK.rad;          % item size

RDK.dottype = 2;

RDK.durBefSignal = 0;
RDK.durAftSignal = 0;

trl.cue_green = [0  155   0]/255;  % Green
trl.cue_red = [250 0 0]/255;  % Red



info.roi_sacc_dva = RDK.size_dva / 2;           % size of fixation window (RDK size) ROI at the saccade location 
info.roi_sacc_pix = dva2pix(info.scr_dist_cm,info.scr_xsize_cm,info.scr_xsize,info.roi_sacc_dva);

RDK.fix_rect = [0 0 RDK.size_pix RDK.size_pix];
    
% Left rect position for fixation after saccade
RDK.fix_left = CenterRectOnPointd(RDK.fix_rect, RDK.coordL(1), RDK.coordL(2));

% Right rect position for fixation after saccade
RDK.fix_right = CenterRectOnPointd(RDK.fix_rect, RDK.coordR(1), RDK.coordR(2));

%% General settings
% Ajust screen size and specify item positions and trial timing
% space between stimuli

const.pos = [960 540]; % it will be changed to the right and left side.

% Temporal configurations
%trl.trial_dur_t = 1.4;                        % trial duration (in seconds)
const.frame_dur = 1/info.scr_rrate;                     % frame duration in seconds (e.g. 1/60 for screen refresh rate of 60 Hz)
const.start_fr = 1; 

% See genVonMisesDotInfo for details
const.dotRadSize = RDK.size_dot_pix;   %%%% GOOD PROXY? %%%
const.theta_noise = 100;
const.kappa_noise = 0;

const.numDots = 50;
const.dotSpeed_pix = RDK.speed_dot_pix;   % dot speed [pix/dec] %%%% GOOD PROXY? %%%
const.sigDotSpeedMulti = 1; % acceleration (put 1 for without)

const.durMinLife = 0.083;           const.numMinLife = (round(const.durMinLife/const.frame_dur)); % 0.083
const.numMeanLife = 0.150;          const.numMeanLife = (round(const.numMeanLife/const.frame_dur));



%% Matrix of trials

%  Side Color      Cue side       Ori Left     Ori Right  Direction report        
%------------------------------------------------------------------------
% 1 [Green]    1=Left  2=Right                             1 = report
% 2 [Red]      1=Left  2=Right                             0 = no report

info.ntrials = 600;

% 60 trials in sequence for an specific color (red or green).
% the color sequence (green=1; red=2 or red=2; green=1) will be set based
% on the participant's number. Odd participant's number will have the
% [green=1; red=2] sequence. Even participant's number will have the
% [red=2; green=1] sequence. 

if rem(sub.id_num,2) == 1
    pre_side_color = repmat(repelem([1 2],60),1,5)';
else
    pre_side_color = repmat(repelem([2 1],60),1,5)';
end

cue_side = [Shuffle(repelem([1 2],150))'; Shuffle(repelem([1 2],150))'];

pre_ori_left = [0:360 Shuffle(0:360)]';   
ori_left = Shuffle(pre_ori_left(1:info.ntrials,1));

pre_ori_right = [0:360 Shuffle(0:360)]';   
ori_right = Shuffle(pre_ori_right(1:info.ntrials,1));

% direction report will occur only in trials with number one. there is 120
% direction reports in total out of 600 trials, all randomly sorted.
trial_report = Shuffle(repmat([1, repelem(0,4)],1,120),1)';

info.matrix = [pre_side_color  cue_side  ori_left  ori_right   trial_report];

%%


    % ones mark the beginning of a block of trials.
    trl.onset_blocks = repmat([1 repelem(0,19)],1,30)';

    % twos mark the beginning of a new color block
    trl.onset_blocks(1:60:600,1) = 2;

    % ones mark the end of a block of trials.
    trl.offset_blocks = repmat([repelem(0,19) 1],1,30)';

    % twos mark the resting block
    trl.offset_blocks(60:60:600,1) = 2;
    


% defines trial onset and offset. the onsets are randomized to occur
% between 800 ms (96 frames) - 1.200 seconds (144 frames) ms after fixation onset to avoid temporal
% expectation.
        trl.cue_on = randi([96 144],1,info.ntrials)';
        trl.cue_off = trl.cue_on + 11; % cue offset after 100 ms

        trl.targ_on = repelem(1,info.ntrials);

        trl.trial_off = trl.cue_on + 83; % the RDK will be removed after 700 ms of cue onset. (trial offset)


% initial dial angle (random to avoid bias)
info.resp_on = rand(info.ntrials, 1) * 360;

    %% Create data directories

    if ~exist(sprintf('%s/Data/S%d/Task/', pc_path, sub.id_num), 'dir')
        mkdir(sprintf('%s/Data/S%d/Task/', pc_path, sub.id_num))
    end
    if ~exist(sprintf('%s/Data/S%d/Eye/', pc_path, sub.id_num), 'dir')
        mkdir(sprintf('%s/Data/S%d/Eye/', pc_path, sub.id_num))
    end


    %%
    %%% Save files

    % Save trials information
    sub.trlinfo_fname = sprintf('trlinfo_sub_%d_%s', sub.id_num, datestr(now,'yymmdd-HHMM')); %#ok<*TNOW1,*DATST>
    save(fullfile(sprintf('%s/Data/S%d/%s', pc_path, sub.id_num), [sub.trlinfo_fname, '.mat']), 'info', 'trl', 'sub','RDK','const', '-v7.3');


    fprintf('\nFeito!\n')




