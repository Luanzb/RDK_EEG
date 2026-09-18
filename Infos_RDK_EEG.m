
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
info.roi_fix_dva = 2;           % size of fixation window ROI
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
RDK.speed_dot = 5; % 5
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

% trl.cue_green = [0  155   0]/255;  % Green
% trl.cue_red = [250 0 0]/255;  % Red

trl.cue_blue = [0 93 255];  % Blue
trl.cue_pink = [215 0 157];  % Pink

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

%  Side Color      Cue side       Ori Left     Ori Right        
%-------------------------------------------------------
% 1 [blue]      1=Left  2=Right                          
% 2 [pink]      1=Left  2=Right                        

info.ntrials = 800;

% 60 trials in sequence for an specific color (red or green).
% the color sequence (blue=1; pink=2 or pink=2; blue=1) will be set based
% on the participant's number. Odd participant's number will have the
% [blue=1; pink=2] sequence. Even participant's number will have the
% [pink=2; blue=1] sequence. 

if rem(sub.id_num,2) == 1
    pre_side_color = repmat(repelem([1 2],80),1,5)';
else
    pre_side_color = repmat(repelem([2 1],80),1,5)';
end


left_cue = repelem(1,40)';
right_cue = repelem(2,40)';
cue_side = [];

left_target = repelem(1,40)';
right_target = repelem(2,40)';
target_side = [];


for dd = 1:10 
    pre_cue_side = Shuffle([left_cue; right_cue]);
    cue_side = [cue_side; pre_cue_side];

    pre_target_side = Shuffle([left_target; right_target]);
    target_side = [target_side; pre_target_side];
end

% 1 = congruent cue and target sides
% 0 = incongruent cue and target sides
cue_validity = cue_side == target_side;


pre_ori = [repmat(repelem([1:360],1),1,2)  Shuffle(1:360)]';   
motion_dir = Shuffle(pre_ori(1:info.ntrials,1));


% ones mark the beginning of a block of trials.
    trl.onset_blocks = repmat([1 repelem(0,19)],1,40)';

    % twos mark the beginning of a new color block
    trl.onset_blocks(1:80:info.ntrials,1) = 2;

    % ones mark the end of a block of trials.
    trl.offset_blocks = repmat([repelem(0,19) 1],1,40)';

    % twos mark the resting block
    trl.offset_blocks(80:80:800,1) = 2;
    


% defines trial onset and offset. the onsets are randomized to occur
% between 1 second (120 frames) - 1.3 ms (156 frames) ms after fixation onset to avoid temporal
% expectation.
        trl.cue_on = randi([120 156],1,info.ntrials)';
        trl.cue_off = trl.cue_on + 11; % cue offset after 100 ms


        trl.trial_off = trl.cue_on + 83; % the RDK will be removed after 700 ms of cue onset. (trial offset)


% initial dial angle (random to avoid bias)
info.resp_on = rand(info.ntrials, 1) * 360;

repeated_trial = zeros(info.ntrials,1);

report_deg = NaN(info.ntrials,1);
error_deg =  NaN(info.ntrials,1);
true_deg =   NaN(info.ntrials,1);
rt_s =       NaN(info.ntrials,1);

   
% Info Matrix
% Column number:
% (1) - [saccade to a specific color side] 1 = blue; 2 = pink 
% (2) - [Saccadic cue side] 1 = left; 2 = right
% (3) - [Target side] 1 = left; 2 = right
% (4) - [Target motion direction] any within 360º
% (5) - [marks short block onset (20 trials each)]
%       1 = short block onset
%       2 = short block onset + new color block onset (lasting 80 trials)
% (6) - [marks short block ending (20 trials each)]
%       1 = short block ends
%       2 = marks rest block (after every 80 trials)
% (7) - Saccadic cue onset in frames
% (8) - Trial offset in frames
% (9) - Initial dial angle for each trial
% (10)- Currently, this trial contains only 0 values. After the experiment,
%       this matrix will be updated and will receive 1 or two in case: 
%       1 = marks the trial that will be repeated at the end of the short
%       block
%       2 = marks the repeated trial at the end of the short block
% (11)- It will receive the participant's motion direction report
% (12)- It will receive the participant's report error in degrees
% (13)- It will receive the target degrees converted to matlab (need to confirm that)
% (14)- It will receive the participant's manual reaction time relative to
%       the motion direction report confirmation
% (15)- Cue validity. That is, if cue and target sides are congruent.
%       1 = Congruent; 0 = Incongruent

matrix = [pre_side_color     ... 1 
          cue_side           ... 2
          target_side        ... 3
          motion_dir         ... 4
          trl.onset_blocks   ... 5
          trl.offset_blocks  ... 6
          trl.cue_on         ... 7
          trl.trial_off      ... 8
          info.resp_on       ... 9
          repeated_trial     ... 10
          report_deg         ... 11
          error_deg          ... 12
          true_deg           ... 13
          rt_s               ... 14                
          cue_validity];       % 15


info.matrix = matrix;
%%


    

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




