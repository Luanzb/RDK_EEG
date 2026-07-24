function  [resp,time,trl] = Screen_RDK_EEG(info,trl,sub,RDK,const)


%% Screen setup

FlushEvents;
PsychDefaultSetup(2);% default settings for setting up Psychtoolbox

Screen('Preference', 'SyncTestSettings', 0.01, 50, 0.25);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests', 1);

% Define black and white (white== 1 and black, 0).
info.white_idx = WhiteIndex(info.scr_num);
info.black_idx = BlackIndex(info.scr_num);
info.gray_idx = info.white_idx/2;

[win, info.scr_rect] = PsychImaging('OpenWindow', info.scr_num, info.black_idx, [], 32, 2, [], []); % RODA EM TELA TODA

%%
% Eyetracking general setup
EyelinkInit(0);
Eyelink('OpenFile', 'RDKeye');       % Open temporary Eyelink file

% Select which events are saved in the EDF file - include everything just in case
Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
% Select which events are available online for gaze-contingent experiments - include everything just in case
Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON,FIXUPDATE,INPUT');
% Select which sample data is saved in EDF file or available online - include everything just in case
Eyelink('Command', 'file_sample_data = LEFT,RIGHT,GAZE,HREF,RAW,AREA,HTARGET,GAZERES,BUTTON,STATUS,INPUT');
Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');

if sub.eye == 'E'
    eye_used = 1;
    Eyelink('Command', 'active_eye = LEFT');
elseif sub.eye == 'D'
    eye_used = 2;
    Eyelink('Command', 'active_eye = RIGHT');
end

el = EyelinkInitDefaults(win);
% Set calibration/validation/drift-check(or drift-correct) size as well as background and target colors
% It is important that this background colour is similar to that of the stimuli to prevent large luminance-based
% pupil size changes (which can cause a drift in the eye movement data)
el.calibrationtargetsize = 1.5;               % Outer target size as percentage of the screen
el.calibrationtargetwidth = 0.3;            % Inner target size as percentage of the screen
el.backgroundcolour = info.black_idx;        % RGB black
el.calibrationtargetcolour = [1 1 1];       % RGB white
% Set "Camera Setup" instructions text colour so it is different from background colour
el.msgfontcolour = [0 170 0]/255;                 % RGB green

% Use an image file instead of the default calibration bull's eye targets
% (commenting out the following two lines will use default targets)
% el.calTargetType = 'image';
% el.calImageTargetFilename = [pwd '/' 'Images/fixTargetXXX.jpg'];

% Set calibration beeps (0 = sound off, 1 = sound on)
el.targetbeep = 0;                          % Sound a beep when a target is presented
el.feedbackbeep = 0;                        % Sound a beep after calibration or drift check/correction

EyelinkUpdateDefaults(el);

Eyelink('Command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, info.scr_xsize-1, info.scr_ysize-1);
Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, info.scr_xsize-1, info.scr_ysize-1);

% Set number of calibration/validation dots and spread: horizontal-only(H) or horizontal-vertical(HV) as H3, HV3, HV5, HV9 or HV13
Eyelink('Command', 'calibration_type = HV9');           % Horizontal-vertical 9-points
Eyelink('command', 'generate_default_targets = NO');    % NO = Custom calibration
% Modify calibration and validation target locations
Eyelink('command', 'calibration_samples = 10');
Eyelink('command', 'calibration_sequence = 0,1,2,3,4,5,6,7,8,9');
Eyelink('command', 'calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d',...
    960,540, 960,205, 960,875, 442,540, 1478,540, 442,205, 1478,205, 442,875, 1478,875);
Eyelink('command', 'validation_samples = 10');
Eyelink('command', 'validation_sequence = 0,1,2,3,4,5,6,7,8,9');
Eyelink('command', 'validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d',...
    960,540, 960,205, 960,875, 442,540, 1478,540, 442,205, 1478,205, 442,875, 1478,875);

% Allow a supported EyeLink Host PC button box to accept calibration or drift-check/correction targets via button 5
Eyelink('Command', 'button_function 5 "accept_target_fixation"');
Eyelink('Command', 'clear_screen 0');       % Clear Host PC display from any previus drawing

%%

topPriorityLevel = MaxPriority(win);
Priority(topPriorityLevel);
HideCursor;
ListenChar(-1);


% Put EyeLink Host PC in Camera Setup mode for participant setup/calibration
EyelinkDoTrackerSetup(el);

% Create central square fixation window
fix_win_center = [-info.roi_fix_pix -info.roi_fix_pix info.roi_fix_pix info.roi_fix_pix];
fix_win_center = CenterRect(fix_win_center, info.scr_rect);

% Create central square on the left side
fix_win_left = RDK.fix_left;

% Create central square on the right side
fix_win_right = RDK.fix_right;
%%

block_counter = 0;
dir_report_count = 0;

try



    for trial = 1:120 %info.ntrials


        SRT2 = 2;
        saccade_left = 2;
        saccade_right = 2;
        abort_dir_report = 2;

        Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode before drawing Host PC graphics and before recording

        % condicional flipa a cada inicio de bloco (a cada 20 tentativas)
        if trl.onset_blocks(trial,1) ~= 0

            block_counter = block_counter + 1;

            txt_ = '-----------------';
            txt1 = 'Pressione a barra de espaço para iniciar o bloco!';
            txt3 = sprintf('Bloco %d/%d', block_counter, nnz(trl.onset_blocks));

            DrawFormattedText(win, [txt_ txt_ txt_ txt_], 'center', info.scr_ycenter - 50,info.white_idx);
            DrawFormattedText(win, txt1, 'center', info.scr_ycenter -20, info.white_idx);
            DrawFormattedText(win, [txt_ txt_ txt_ txt_], 'center', info.scr_ycenter + 10,info.white_idx);
            DrawFormattedText(win, txt3, 'center', info.scr_ycenter + 40,info.white_idx);
            DrawFormattedText(win, txt_, 'center', info.scr_ycenter + 60,info.white_idx);


            % Shows the saccade side based on the square's color
            Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            if info.matrix(trial,1) == 1
                Screen('DrawDots', win, [0 0], info.fp_size_pix_white*3, trl.cue_green, [info.scr_xcenter info.scr_ycenter-110], []);
            else
                Screen('DrawDots', win, [0 0], info.fp_size_pix_white*3, trl.cue_red, [info.scr_xcenter info.scr_ycenter-110], []);
            end


            if trl.onset_blocks(trial,1) == 2
                if trial ~= 1
                    if info.matrix(trial,1) == 1
                        txt6 = 'ATENÇÃO À MUDANÇA DE COR!';
                        DrawFormattedText(win, txt6, 'center', info.scr_ycenter -160, trl.cue_green);
                    else
                        txt6 = 'ATENÇÃO À MUDANÇA DE COR!';
                        DrawFormattedText(win, txt6, 'center', info.scr_ycenter -160, trl.cue_red);
                    end
                else
                    txt6 = 'ATENÇÃO À COR!';
                    DrawFormattedText(win, txt6, 'center', info.scr_ycenter -160, info.white_idx);
                end
            elseif trl.onset_blocks(trial,1) == 1
                txt6 = 'ATENÇÃO À COR!';
                DrawFormattedText(win, txt6, 'center', info.scr_ycenter -160, info.white_idx);
            end


            Screen('Flip', win);

            RestrictKeysForKbCheck(KbName('space'));
            KbReleaseWait;
            KbWait;
            KbReleaseWait;
            RestrictKeysForKbCheck([]);


            EyelinkDoDriftCorrection(el, [info.scr_xcenter, info.scr_ycenter]);      % Run eyetracker drift correction
            WaitSecs(1);

        end


        % RDk infos
        const.test_dur_fr = trl.trial_off(trial);

        RDK.dirSignal = info.matrix(trial,3); % LEFT RDK movement direction
        [dots]  = draw_rdk(const, RDK,1,trial,trl); % LEFT RDK

        RDK.dirSignal = info.matrix(trial,4); % RIGHT RDK movement direction
        [dots2] = draw_rdk(const, RDK,1,trial,trl); % RIGHT RDK



        Eyelink('Command', 'clear_screen 0');       % Clear Host PC display from any previus drawing
        Eyelink('ImageTransfer', '/home/kaneda/Documents/GitHub/PSA_RDK/Images/trl_on.bmp', 0, 0, 0, 0, 0, 0);
        Eyelink('StartRecording');
        Eyelink('Command', 'record_status_message "TRIAL %d/%d"', trial, size(info.ntrials,1));

        % minimum 500 ms fixation before RDK onset
        Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_white, info.white_idx, [], 2,1);
        Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_black, info.black_idx, [], 2,1);
        time.fp_on(trial) = Screen('Flip', win);

        tic

        % Wait until participant is fixating for info.fix_dur_sec
        while 1
            damn = Eyelink('CheckRecording');
            if(damn ~= 0)
                break;
            end
            if Eyelink('NewFloatSampleAvailable') > 0
                evt = Eyelink('NewestFloatSample');                     % Get the sample in the form of an event structure
                x_gaze = evt.gx(eye_used);                              % Get current gaze position from sample
                y_gaze = evt.gy(eye_used);
                if inFixWindow(x_gaze, y_gaze, fix_win_center)          % If gaze sample is within fixation window (see inFixWindow function below)
                    if (GetSecs - time.fp_on(trial)) >= info.fix_dur_sec     % If gaze duration >= minimum fixation window time (fxateTime)
                        break;
                    end
                elseif ~inFixWindow(x_gaze, y_gaze, fix_win_center)     % If gaze sample is not within fixation window
                    [time.fp_on(trial)] = GetSecs;                         % Reset fixation window timer
                end
            end
        end



        for frame = 1:trl.trial_off(trial)


            times = GetSecs;

            if Eyelink('NewFloatSampleAvailable') > 0
                evt = Eyelink('NewestFloatSample');                     % Get the sample in the form of an event structure
                x_gaze = evt.gx(eye_used);                              % Get current gaze position from sample
                y_gaze = evt.gy(eye_used);
            end



            % Present the RDK clouds before and after saccade cue onset. If
            % eye position is deviated from the central FP after saccade
            % onset, RDK clouds are removed.
            if frame < trl.cue_on(trial,1)
                Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('DrawDots',win, round(dots{1,1}.posi{frame})', dots{1,1}.siz, [1 1 1], RDK.coordL,2);
                Screen('DrawDots',win, round(dots2{1,1}.posi{frame})', dots2{1,1}.siz, [1 1 1], RDK.coordR,2);
            elseif frame >= trl.cue_on(trial,1) && SRT2 == 2
                Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('DrawDots',win, round(dots{1,1}.posi{frame})', dots{1,1}.siz, [1 1 1], RDK.coordL,2);
                Screen('DrawDots',win, round(dots2{1,1}.posi{frame})', dots2{1,1}.siz, [1 1 1], RDK.coordR,2);
            end



            %     Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

            % CUE ONSET. It ill remain on screen up to saccade execution or
            % time limit (700 ms)
            if frame >= trl.cue_on(trial,1) && SRT2 == 2

                if info.matrix(trial,1) == 1 % GREEN

                    if info.matrix(trial,2) ==1 % Green LEFT
                        Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                        Screen('FillArc', win, trl.cue_red, info.cue_position, 0, 180); % Right
                        Screen('FillArc', win, trl.cue_green, info.cue_position, 180, 180); % Left
                    else                        % Green RIGHT
                        Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                        Screen('FillArc', win, trl.cue_green, info.cue_position, 0, 180); % Right
                        Screen('FillArc', win, trl.cue_red, info.cue_position, 180, 180); % Left
                    end
                else                        % RED
                    if info.matrix(trial,2) ==1 % Red LEFT
                        Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                        Screen('FillArc', win, trl.cue_green, info.cue_position, 0, 180); % Right
                        Screen('FillArc', win, trl.cue_red, info.cue_position, 180, 180); % Left
                    else                        % Red RIGHT
                        Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                        Screen('FillArc', win, trl.cue_red, info.cue_position, 0, 180); % Right
                        Screen('FillArc', win, trl.cue_green, info.cue_position, 180, 180); % Left
                    end
                end

                Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_black, info.black_idx, [], 2,1);

            elseif frame < trl.cue_on(trial,1)
                Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_white, info.white_idx, [], 2,1);
                Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_black, info.black_idx, [], 2,1);
            end


            if frame == 1
                time.trl_on(trial) = Screen('Flip', win);
                Eyelink('Message', sprintf('trial_onset_%1d', trial));
                Eyelink('Command', 'record_status_message "TRIAL %d', trial);
            elseif frame == trl.cue_on(trial,1)
                time.cue_on(trial) = Screen('Flip', win);
                Eyelink('Message', sprintf('cue_on_%1d', trial));
            elseif frame == trl.cue_off(trial,1)
                time.cue_off(trial) = Screen('Flip', win);
                Eyelink('Message', sprintf('cue_off_%1d', trial));
            elseif frame == trl.trial_off(trial)
                time.trial_off(trial) = Screen('Flip', win);
                Eyelink('Message', sprintf('trial_off_%1d', trial));
            else
                Screen('Flip', win);
            end



            if frame >= trl.cue_on(trial,1)
                if ~inFixWindow(x_gaze,y_gaze,fix_win_center)
                    if SRT2 == 2
                        SRT2 = times - time.cue_on(trial);
                    end
                end

                if info.matrix(trial,2) == 1
                    if inFixWindow(x_gaze,y_gaze,fix_win_left)
                        saccade_left = 1;
                    end
                else
                    if inFixWindow(x_gaze,y_gaze,fix_win_right)
                        saccade_right = 1;
                    end
                end

            end

        end


        Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_white, info.white_idx, [], 2,1);
        Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_black, info.black_idx, [], 2,1);
        Screen('Flip', win);


        % shows delayed saccade onset message in case saccade was slow but
        % executed to the corect side
        if SRT2 >= .35 && info.matrix(trial,1) == 1 && saccade_left == 1 || ...
                SRT2 >= .35 && info.matrix(trial,1) == 2 && saccade_right == 1

            Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            txt1 = 'Movimento lento!';
            DrawFormattedText(win, txt1, 'center', info.scr_ycenter, info.white_idx);
            Screen('Flip', win); WaitSecs(.3);
            abort_dir_report = 1;


            RestrictKeysForKbCheck(KbName('space'));
            KbReleaseWait;
            KbWait;
            KbReleaseWait;
            RestrictKeysForKbCheck([]);

            % shows message in case the saccade was not executed to the correct
            % side
        elseif info.matrix(trial,2) == 1 && saccade_left == 2 || ...
               info.matrix(trial,2) == 2 && saccade_right == 2

            Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            if info.matrix(trial,1) == 1
                txt2 = 'Olhe para o objeto indicado pela cor verde!';
                DrawFormattedText(win, txt2, 'center', info.scr_ycenter, trl.cue_green);
            else
                txt2 = 'Olhe para o objeto indicado pela cor vermelha!';
                DrawFormattedText(win, txt2, 'center', info.scr_ycenter, trl.cue_red);
            end

   
            Screen('Flip', win); WaitSecs(.3);
            abort_dir_report = 1;

            RestrictKeysForKbCheck(KbName('space'));
            KbReleaseWait;
            KbWait;
            KbReleaseWait;
            RestrictKeysForKbCheck([]);

        end


        % enters the next conditional in case saccade latency and saccade
        % sides meet the specified requirements.
        if abort_dir_report == 2
            % only shows the dial direciton report if info.matrix(trial,5) == 1
            if info.matrix(trial,5) == 1

                dir_report_count = dir_report_count + 1;
                % Orientation selector -----------------------------------------------

                % Continuous report (correcting angle convention)
                if info.matrix(trial,2) == 1
                    qtarget = RDK.coordL;         % 1..4
                    % angle used in DrawTexture
                    true_deg_ptb = info.matrix(trial,3); % LEFT RDK movement direction;
                else
                    qtarget = RDK.coordR;
                    % angle used in DrawTexture
                    true_deg_ptb = info.matrix(trial,4); % RIGHT RDK movement direction;
                end



                % *** CRITICAL CONVERSION ***
                % PTB effectively rotates clockwise; dial uses counter-clockwise.
                % So we reverse the sign and treat it as an axis. (0..360):

                true_dir = mod(-true_deg_ptb, 360); % keep your PTB sign correction


                % pixels per degree (1° -> px)
                ppd = dva2pix(info.scr_dist_cm, info.scr_xsize_cm, info.scr_xsize, 1);

                [resp_deg, err_deg, rt] = get_continuous_report(win, ppd, info.resp_on(trial), true_dir, true, info, qtarget,RDK);

                %     % Screen('FrameOval', win, info.white_idx, rect, info.bar_thickness_px/2);
                %     % coleta (get_continuous_report retorna: resp_deg, err_deg, rt)
                %     % guardar
                resp.report_deg(dir_report_count) = resp_deg; % (0..360)
                resp.error_deg(dir_report_count) = err_deg;   % (-180, +180]
                resp.true_deg(dir_report_count) = true_dir;
                resp.rt_s(dir_report_count) = rt; % time (s)

            end

        end

        toc




        if trl.offset_blocks(trial,1) ~= 0

            if trial == size(trl.onset_blocks,1)
                txt = 'Voce completou todos os blocos da sessão. \n\n Parabéns!';
                DrawFormattedText(win, txt, 'center', info.scr_ycenter, info.white_idx);

            elseif trl.offset_blocks(trial,1) == 1

                txt = sprintf('Bloco %i/%i completo.', block_counter, nnz(trl.onset_blocks));
                txt1 = 'Pressione a barra de espaço para continuar!';
                txt_ = '----------------------';

                DrawFormattedText(win, txt, 'center', info.scr_ycenter, info.white_idx);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter +30,info.white_idx);
                DrawFormattedText(win, txt1, 'center', info.scr_ycenter + 60, info.white_idx);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter + 90,info.white_idx);

            elseif trl.offset_blocks(trial,1) == 2

                txt = sprintf('Bloco %i/%i completo.', block_counter, nnz(trl.onset_blocks));
                txt1 = 'Pressione a barra de espaço para continuar!';
                txt3 = 'Hora do descanso!';

                txt_ = '----------------------';
                DrawFormattedText(win, txt, 'center', info.scr_ycenter, info.white_idx);
                DrawFormattedText(win, txt3, 'center', info.scr_ycenter+65, [255 103 0]/255);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter +100,info.white_idx);
                DrawFormattedText(win, txt1, 'center', info.scr_ycenter + 130, info.white_idx);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter + 150,info.white_idx);

            end

            Screen('Flip', win);

            RestrictKeysForKbCheck(KbName('space'));
            KbReleaseWait;
            KbWait;
            KbReleaseWait;
            RestrictKeysForKbCheck([]);

        end


    end

    Screen('CloseAll');

    Eyelink('CloseFile');

    ntimes = 1;
    while ntimes <= 10
        status = Eyelink('ReceiveFile');
        if status > 0
            break
        end
        ntimes = ntimes + 1;
    end
    if status <= 0
        warning('EyeLink data has not been saved properly.');
    else
        fprintf('EyeLink data saved properly on attempt %d.\n',ntimes);
    end
    Eyelink('ShutDown');

    FlushEvents;
    ListenChar(0);
    ShowCursor;
    Priority(0);

catch

    psychrethrow(psychlasterror);
    sca; close all;

end

    function fix = inFixWindow(mx,my,fix_window)
        fix = mx > fix_window(1) &&  mx <  fix_window(3) && ...
            my > fix_window(2) && my < fix_window(4) ;
    end


end
