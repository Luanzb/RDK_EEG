function  [resp,time,srt,trl] = Screen_RDK(info,trl,sub,RDK,circle1,dots,dots2,dots3,dots4)

% First column  = Hits;
% Second column = False Alarms
% Third column  =  Correct rejections
% fourth column = Miss
% fifth column  = target direction
resp = zeros(info.ntrials,1);

ResponsePixx('Close');
ResponsePixx('Open');


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


trl.new_sat1 = trl.dotcolor1_high_sat;
trl.new_sat2 = trl.dotcolor2_high_sat;
%%

try

    block_counter = 0;

    trial = 1;


    abort = false;

    
    % movieName = 'trial_recording_slow_RDK_green.mp4';
    % moviePtr = Screen('CreateMovie', win, movieName, [], [], 20);


    while trial <= info.ntrials

        %const.max_fr = trl.targ_off(trial);

        SRT2 = 2; resp_trng = 2;


        Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode before drawing Host PC graphics and before recording

        % Create only distractor stimulus

        % [dots]  = draw_rdk(const, RDK,0); % green left
        % [dots2] = draw_rdk(const, RDK,0); % red left
        % [dots3] = draw_rdk(const, RDK,0); % green right
        % [dots4] = draw_rdk(const, RDK,0); % red right



        % condicional flipa a cada inicio de bloco (a cada 30 tentativas)
        if trl.onset_blocks(trial,1) == 1

            block_counter = block_counter + 1;


            if trial == 421

                Screen('TextSize',win, 45);
                texto1 = 'Cor mais provável mudou!' ;
                texto2 = 'Chame o pesquisador!';
                texto3 = '(Pressione o botão branco para continuar)';
                DrawFormattedText(win, [texto1 '\n' texto2 '\n' texto3], 'center', info.scr_ycenter,[1 1 1]);
                Screen('FrameRect',win,[1 1 1], [960-500 540-400 960+500 540+400],4);

                Screen('Flip', win);


                ResponsePixx('StartNow', 1, [0 0 0 0 1], 1);
                while 1
                    [buttons, ~, ~] = ResponsePixx('GetLoggedResponses', 1, 1, 2000);
                    if ~isempty(buttons)
                        if buttons(1,5) == 1         % White button
                            break;
                            % elseif buttons(1,4) == 1     % Blue button
                            %     abort = true;
                            %     break;
                        end
                    end
                end
                ResponsePixx('StopNow', 1, [0 0 0 0 0], 0);

            end


            Screen('TextSize',win, 24);
            % show colored dots depending on the most probable color in the
            % Draw dashed circle around central stimulus
            drawDashedCircle(win, 960, 400, circle1.rad_pix-12, circle1.Color, circle1.lineWidth, circle1.linegap);
            drawDashedCircle(win, 960, 680, circle1.rad_pix-12, circle1.Color, circle1.lineWidth, circle1.linegap);

            colorg = trl.color1_lsat;
            colorgg = trl.color1_lsat;
            colorr = trl.color2_lsat;
            colorrr = trl.color2_lsat;


            if trial <= 420

                col_idx1 = dots{1,1}(1).posi{1,1}(:,2) < 0; % upper quadrant
                colorg(:, col_idx1) = repmat(trl.new_sat1', 1, sum(col_idx1));

                col_idx2 = dots{1,1}(1).posi{1,60}(:,2) < 0; % upper quadrant
                colorgg(:, col_idx2) = repmat(trl.new_sat1', 1, sum(col_idx2));


                col_idx3 = dots2{1,1}(1).posi{1,1}(:,2) < 0; % upper quadrant
                colorr(:, col_idx3) = repmat(trl.new_sat2', 1, sum(col_idx3));

                col_idx4 = dots2{1,1}(1).posi{1,60}(:,2) < 0; % upper quadrant
                colorrr(:, col_idx4) = repmat(trl.new_sat2', 1, sum(col_idx4));


                if trl.colorRDK(1,1) == 1

                    txt20 = 'VERDE';
                    colors = trl.new_sat1;

                    Screen('DrawDots',win, round(dots{1}(1).posi{1})', dots{1}(1).siz, colorg,[960 400],2);
                    Screen('DrawDots',win, round(dots{1}(1).posi{60})', dots{1}(1).siz, colorgg,[960 400],2);

                    Screen('DrawDots',win, round(dots2{1}(1).posi{1})', dots2{1}(1).siz, colorr, [960 680],2);
                    Screen('DrawDots',win, round(dots2{1}(1).posi{60})', dots2{1}(1).siz, colorrr, [960 680],2);
                else
                    txt20 = 'VERMELHO';
                    colors = trl.new_sat2;
                    Screen('DrawDots',win, round(dots{1}(1).posi{1})', dots{1}(1).siz, colorg,[960 680],2);
                    Screen('DrawDots',win, round(dots{1}(1).posi{60})', dots{1}(1).siz, colorgg,[960 680],2);

                    Screen('DrawDots',win, round(dots2{1}(1).posi{1})', dots2{1}(1).siz, colorr, [960 400],2);
                    Screen('DrawDots',win, round(dots2{1}(1).posi{60})', dots2{1}(1).siz, colorrr, [960 400],2);

                end
            else

                col_idx1 = dots{1,1}(1).posi{1,1}(:,2) < 0; % upper quadrant
                colorg(:, col_idx1) = repmat(trl.new_sat1', 1, sum(col_idx1));

                col_idx2 = dots{1,1}(1).posi{1,60}(:,2) < 0; % upper quadrant
                colorgg(:, col_idx2) = repmat(trl.new_sat1', 1, sum(col_idx2));


                col_idx3 = dots2{1,1}(1).posi{1,1}(:,2) < 0; % upper quadrant
                colorr(:, col_idx3) = repmat(trl.new_sat2', 1, sum(col_idx3));

                col_idx4 = dots2{1,1}(1).posi{1,60}(:,2) < 0; % upper quadrant
                colorrr(:, col_idx4) = repmat(trl.new_sat2', 1, sum(col_idx4));

                if trl.colorRDK(1,2) == 1
                    txt20 = 'VERDE';
                    colors = trl.new_sat1;

                    Screen('DrawDots',win, round(dots{1}(1).posi{1})', dots{1}(1).siz, colorg,[960 400],2);
                    Screen('DrawDots',win, round(dots{1}(1).posi{60})', dots{1}(1).siz, colorgg,[960 400],2);

                    Screen('DrawDots',win, round(dots2{1}(1).posi{1})', dots2{1}(1).siz, colorr, [960 680],2);
                    Screen('DrawDots',win, round(dots2{1}(1).posi{60})', dots2{1}(1).siz, colorrr, [960 680],2);
                else
                    txt20 = 'VERMELHO';
                    colors = trl.new_sat2;
                    Screen('DrawDots',win, round(dots{1}(1).posi{1})', dots{1}(1).siz, colorg,[960 680],2);
                    Screen('DrawDots',win, round(dots{1}(1).posi{60})', dots{1}(1).siz, colorgg,[960 680],2);

                    Screen('DrawDots',win, round(dots2{1}(1).posi{1})', dots2{1}(1).siz, colorr, [960 400],2);
                    Screen('DrawDots',win, round(dots2{1}(1).posi{60})', dots2{1}(1).siz, colorrr, [960 400],2);
                end
            end


            txt_ = '-----------------';
            txt4 = 'COR MAIS PROVÁVEL:';
            txt5 = '';

            DrawFormattedText(win, [txt_ txt_ txt_ txt_ '\n' txt5 '\n' txt_ txt_ txt_ txt_], 'center', info.scr_ycenter - 390, info.white_idx);
            DrawFormattedText(win, [txt5 '\n' txt4 '\n' txt5], 'center', info.scr_ycenter - 390, info.white_idx);
            DrawFormattedText(win, [txt5 '\n' txt20 '\n' txt5], info.scr_xcenter + 140, info.scr_ycenter - 390, colors);


            txt1 = 'Pressione o botão            para iniciar!';
            txt2 = ' branco';
            txt3 = sprintf('Bloco %d/%d', block_counter, sum(trl.onset_blocks));
            DrawFormattedText(win, [txt_ txt_ txt_ txt_], 'center', info.scr_ycenter +300,info.white_idx);
            DrawFormattedText(win, txt1, 'center', info.scr_ycenter + 330, info.white_idx);
            DrawFormattedText(win, txt2, info.scr_xcenter - 8, info.scr_ycenter + 330, [1 1 1]);
            DrawFormattedText(win, [txt_ txt_ txt_ txt_], 'center', info.scr_ycenter + 350,info.white_idx);
            DrawFormattedText(win, txt3, 'center', info.scr_ycenter + 380,info.white_idx);
            DrawFormattedText(win, txt_, 'center', info.scr_ycenter + 400,info.white_idx);


            if ismember(trial,[1 31 421 451])

                texto1 = 'HORA DO TREINO!' ;
                DrawFormattedText(win, texto1, 'center', info.scr_ycenter - 450,info.white_idx);
                Screen('FrameRect',win,info.white_idx, [960-550 540-500 960+550 540+500],4);

            end

            Screen('Flip', win);


            ResponsePixx('StartNow', 1, [0 0 0 0 1], 1);
            while 1
                [buttons, ~, ~] = ResponsePixx('GetLoggedResponses', 1, 1, 2000);
                if ~isempty(buttons)
                    if buttons(1,5) == 1         % White button
                        break;
                        % elseif buttons(1,4) == 1     % Blue button
                        %     abort = true;
                        %     break;
                    end
                end
            end
            ResponsePixx('StopNow', 1, [0 0 0 0 0], 0);

            if abort == false
                EyelinkDoDriftCorrection(el, [info.scr_xcenter, info.scr_ycenter]);      % Run eyetracker drift correction
                WaitSecs(1);
            end

        end


        Eyelink('Command', 'clear_screen 0');       % Clear Host PC display from any previus drawing
        Eyelink('ImageTransfer', '/home/kaneda/Documents/GitHub/PSA_RDK/Images/trl_on.bmp', 0, 0, 0, 0, 0, 0);
        Eyelink('StartRecording');
        Eyelink('Command', 'record_status_message "TRIAL %d/%d"', trial, size(info.ntrials,1));


        Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('DrawDots', win, [0 0], info.fp_size_pix, info.white_idx, [info.scr_xcenter info.scr_ycenter], RDK.dottype);
        % Draw dashed circle around left stimulus
        drawDashedCircle(win, circle1.leftCirclePos(1,1), circle1.leftCirclePos(1,2), ...
            circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);
        % Draw dashed circle around right stimulus
        drawDashedCircle(win, circle1.rightCirclePos(1,1), circle1.rightCirclePos(1,2), ...
            circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);

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


        for frameIdx = 1:trl.targ_off(trial)+24

            color11 = trl.color1_lsat;
            color22 = trl.color2_lsat;
            color33 = trl.color3_lsat;
            color44 = trl.color4_lsat;

            times = GetSecs;

            if Eyelink('NewFloatSampleAvailable') > 0
                evt = Eyelink('NewestFloatSample');                     % Get the sample in the form of an event structure
                x_gaze = evt.gx(eye_used);                              % Get current gaze position from sample
                y_gaze = evt.gy(eye_used);
            end

            Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            Screen('DrawDots', win, [0 0], info.fp_size_pix, info.white_idx, [info.scr_xcenter info.scr_ycenter], RDK.dottype);

            if frameIdx <= trl.targ_off(trial)

                if frameIdx >= trl.targ_on(trial)

                    if info.matrix(trial,2) == 1 && info.matrix(trial,5) == 1

                        if info.matrix(trial,6) == 2 % lower quadrant
                            col_idx = dots{1,trial}(1).posi{1,frameIdx}(:,2) > 0;
                            color11(:, col_idx) = repmat(trl.new_sat1', 1, sum(col_idx));
                        else
                            col_idx = dots{1,trial}(1).posi{1,frameIdx}(:,2) < 0; % upper quadrant
                            color11(:, col_idx) = repmat(trl.new_sat1', 1, sum(col_idx));
                        end

                    elseif info.matrix(trial,2) == 2 && info.matrix(trial,5) == 1

                        if info.matrix(trial,6) == 2 % lower quadrant
                            col_idx = dots2{1,trial}(1).posi{1,frameIdx}(:,2) > 0;
                            color22(:, col_idx) = repmat(trl.new_sat2', 1, sum(col_idx));
                        else
                            col_idx = dots2{1,trial}(1).posi{1,frameIdx}(:,2) < 0;
                            color22(:, col_idx) = repmat(trl.new_sat2', 1, sum(col_idx));
                        end

                    elseif info.matrix(trial,2) == 1 && info.matrix(trial,5) == 2

                        if info.matrix(trial,6) == 2 % lower quadrant
                            col_idx = dots3{1,trial}(1).posi{1,frameIdx}(:,2) > 0;
                            color33(:, col_idx) = repmat(trl.new_sat1', 1, sum(col_idx));
                        else
                            col_idx = dots3{1,trial}(1).posi{1,frameIdx}(:,2) < 0;
                            color33(:, col_idx) = repmat(trl.new_sat1', 1, sum(col_idx));
                        end

                    elseif info.matrix(trial,2) == 2 && info.matrix(trial,5) == 2

                        if info.matrix(trial,6) == 2 % lower quadrant

                            col_idx = dots4{1,trial}(1).posi{1,frameIdx}(:,2) > 0;
                            color44(:, col_idx) = repmat(trl.new_sat2', 1, sum(col_idx));
                        else
                            col_idx = dots4{1,trial}(1).posi{1,frameIdx}(:,2) < 0;
                            color44(:, col_idx) = repmat(trl.new_sat2', 1, sum(col_idx));
                        end
                    end

                else
                    color11 = trl.color1_lsat;
                    color22 = trl.color2_lsat;
                    color33 = trl.color3_lsat;
                    color44 = trl.color4_lsat;
                end

                Screen('DrawDots',win, round(dots{trial}(1).posi{frameIdx})', dots{trial}(1).siz, color11, RDK.coordL,2);
                Screen('DrawDots',win, round(dots2{trial}(1).posi{frameIdx})', dots2{trial}(1).siz,color22, RDK.coordL,2);

                Screen('DrawDots',win, round(dots3{trial}(1).posi{frameIdx})', dots3{trial}(1).siz, color33, RDK.coordR,2);
                Screen('DrawDots',win, round(dots4{trial}(1).posi{frameIdx})', dots4{trial}(1).siz, color44, RDK.coordR,2);

            end

            % Draw dashed circle around left stimulus
            drawDashedCircle(win, circle1.leftCirclePos(1,1), circle1.leftCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);

            % Draw dashed circle around right stimulus
            drawDashedCircle(win, circle1.rightCirclePos(1,1), circle1.rightCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);


            Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

            % CUE ONSET
            if frameIdx >= trl.cue_on(trial,1) && frameIdx <= trl.cue_off(trial,1)
                if info.matrix(trial,4) == 2
                    Screen('DrawLine', win, info.white_idx, info.scr_xcenter,info.scr_ycenter ...
                        ,info.scr_xcenter + info.cue_length_px,info.scr_ycenter, info.cue_width_px);
                else
                    Screen('DrawLine', win, info.white_idx, info.scr_xcenter,info.scr_ycenter ...
                        ,info.scr_xcenter - info.cue_length_px,info.scr_ycenter, info.cue_width_px);
                end
            end


            if (trial >= 61 && trial <= 420) || (trial >= 481)

                if frameIdx == 1
                    time.trl_on(trial) = Screen('Flip', win);
                    Eyelink('Message', sprintf('trial_onset_%1d', trial));
                    Eyelink('Command', 'record_status_message "TRIAL %d', trial);
                elseif frameIdx == trl.cue_on(trial,1)
                    time.cue_on(trial) = Screen('Flip', win);
                    Eyelink('Message', sprintf('cue_on_%1d', trial));
                elseif frameIdx == trl.cue_off(trial,1)
                    time.cue_off(trial) = Screen('Flip', win);
                    Eyelink('Message', sprintf('cue_off_%1d', trial));
                elseif frameIdx == trl.targ_on(trial,1)
                    time.targ_on(trial) = Screen('Flip', win);
                    Eyelink('Message', sprintf('targ_on_%1d', trial));
                elseif frameIdx == trl.targ_off(trial,1)
                    time.targ_off(trial) = Screen('Flip', win);
                    Eyelink('Message', sprintf('targ_off_%1d', trial));
                elseif frameIdx == trl.targ_off(trial)+24
                    time.trl_off(trial) = Screen('Flip', win);
                    Eyelink('Message', sprintf('trl_off_%1d', trial));
                else
                    Screen('Flip', win);
                end

            else
                if frameIdx == 1
                    time.trl_on(trial) = Screen('Flip', win);
                    %Eyelink('Message', sprintf('trial_onset_%1d', trial));
                    %Eyelink('Command', 'record_status_message "TRIAL %d', trial);
                elseif frameIdx == trl.cue_on(trial,1)
                    time.cue_on(trial) = Screen('Flip', win);
                    %Eyelink('Message', sprintf('cue_on_%1d', trial));
                elseif frameIdx == trl.cue_off(trial,1)
                    time.cue_off(trial) = Screen('Flip', win);
                    %Eyelink('Message', sprintf('cue_off_%1d', trial));
                elseif frameIdx == trl.targ_on(trial,1)
                    time.targ_on(trial) = Screen('Flip', win);
                    %Eyelink('Message', sprintf('targ_on_%1d', trial));
                elseif frameIdx == trl.targ_off(trial,1)
                    time.targ_off(trial) = Screen('Flip', win);
                    %Eyelink('Message', sprintf('targ_off_%1d', trial));
                elseif frameIdx == trl.targ_off(trial)+24
                    time.trl_off(trial) = Screen('Flip', win);
                    %Eyelink('Message', sprintf('trl_off_%1d', trial));
                else
                    Screen('Flip', win);
                end

                % if frameIdx >= trl.targ_on(trial) && frameIdx <= trl.targ_off(trial)
                %     WaitSecs(.1);
                % end

            end


            if frameIdx >= trl.cue_on(trial,1)
                if ~inFixWindow(x_gaze,y_gaze,fix_win_center)
                    if SRT2 == 2
                        SRT2 = times - time.cue_on(trial);
                        srt(trial) = SRT2; %#ok<AGROW>
                    end
                end
            end

        % if info.matrix(trial,3) == 1 && info.matrix(trial,2) == 1 && info.matrix(trial,4) == 1 && info.matrix(trial,6) == 1
        %     % Add frame to movie
        %     Screen('AddFrameToMovie', win);
        % end

        end


        Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('DrawDots', win, [0 0], info.fp_size_pix, info.white_idx, [info.scr_xcenter info.scr_ycenter], RDK.dottype);


        if info.matrix(trial,5) == 1
            % Draw dashed circle around left stimulus
            drawDashedCircle(win, circle1.leftCirclePos(1,1), circle1.leftCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth*2, circle1.linegap);
            % Draw dashed circle around right stimulus
            drawDashedCircle(win, circle1.rightCirclePos(1,1), circle1.rightCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);
        else
            % Draw dashed circle around left stimulus
            drawDashedCircle(win, circle1.leftCirclePos(1,1), circle1.leftCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);
            % Draw dashed circle around right stimulus
            drawDashedCircle(win, circle1.rightCirclePos(1,1), circle1.rightCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth*2, circle1.linegap);
        end

        Screen('Flip', win);

        % if info.matrix(trial,3) == 1 && info.matrix(trial,2) == 1 && info.matrix(trial,4) == 1 && info.matrix(trial,6) == 1
        %     % Add frame to movie
        %     Screen('AddFrameToMovie', win);
        % end


        toc


        % ResponsePixx color mapping
        %%% red    [1] = right
        %%% yellow [2] = front
        %%% green  [3] = left
        %%% blue   [4] = bottom
        %%% white  [5] = middle


        ResponsePixx('StartNow', 1, [0 1 0 1 0], 1);
        while 1
            [buttons, ~, ~] = ResponsePixx('GetLoggedResponses', 1, 1, 2000);
            if ~isempty(buttons)
                if buttons(1,2) == 1         % Yellow button up
                    resp(trial,1) = 1;
                    break;
                elseif buttons(1,4) == 1     % Blue button down
                    resp(trial,1) = 2;
                    break;
                end
            end
        end
        ResponsePixx('StopNow', 1, [0 0 0 0 0], 0);



        if (trial >= 1 && trial <= 60) || (trial >= 421 && trial <= 480)

            color1 = trl.dotcolor1_reduc_sat;
            color2 = trl.dotcolor2_reduc_sat;

            Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            if info.matrix(trial,2) == 1 && info.matrix(trial,6) == 1 % green up
                Screen('DrawLine', win, color1, info.scr_xcenter,info.scr_ycenter ...
                    ,info.scr_xcenter,info.scr_ycenter - info.cue_length_px, info.cue_width_px);
            elseif info.matrix(trial,2) == 1 && info.matrix(trial,6) == 2 % green down
                Screen('DrawLine', win, color1, info.scr_xcenter,info.scr_ycenter ...
                    ,info.scr_xcenter,info.scr_ycenter + info.cue_length_px, info.cue_width_px);
            elseif info.matrix(trial,2) == 2 && info.matrix(trial,6) == 1 % red up
                Screen('DrawLine', win, color2, info.scr_xcenter,info.scr_ycenter ...
                    ,info.scr_xcenter,info.scr_ycenter - info.cue_length_px, info.cue_width_px);
            elseif info.matrix(trial,2) == 2 && info.matrix(trial,6) == 2 % red down
                Screen('DrawLine', win, color2, info.scr_xcenter,info.scr_ycenter ...
                    ,info.scr_xcenter,info.scr_ycenter + info.cue_length_px, info.cue_width_px);
            end
            Screen('DrawDots', win, [0 0], info.fp_size_pix, [1 1 1], [info.scr_xcenter info.scr_ycenter], RDK.dottype);

            % Draw dashed circle around left stimulus
            drawDashedCircle(win, circle1.leftCirclePos(1,1), circle1.leftCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);

            % Draw dashed circle around right stimulus
            drawDashedCircle(win, circle1.rightCirclePos(1,1), circle1.rightCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);

            Screen('Flip', win); WaitSecs(0.4);

        end

        % if info.matrix(trial,3) == 1 && info.matrix(trial,2) == 1 && info.matrix(trial,4) == 1 && info.matrix(trial,6) == 1
        %     % Add frame to movie
        %     Screen('AddFrameToMovie', win);
        %     Screen('FinalizeMovie', moviePtr);
        % end

        if  SRT2 > 0.33

            Screen('DrawDots', win, [0 0], info.fp_size_pix, [1 0.65 0], [info.scr_xcenter info.scr_ycenter], RDK.dottype);
            % Draw dashed circle around left stimulus
            drawDashedCircle(win, circle1.leftCirclePos(1,1), circle1.leftCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);
            % Draw dashed circle around right stimulus
            drawDashedCircle(win, circle1.rightCirclePos(1,1), circle1.rightCirclePos(1,2), ...
                circle1.rad_pix, circle1.Color, circle1.lineWidth, circle1.linegap);
            Screen('Flip', win); WaitSecs(0.3);
        end


        %--------------------------------------------------------------------------

        if trial == 60 || trial == 480

            txt6 = 'Deseja realizar o treino novamente?';
            txt7 = 'Sim \n [Botão Amarelo]';
            txt8 = 'Não \n [Botão Azul]';

            txt_1 = '-----------------';
            txt_2 = '';

            DrawFormattedText(win, [txt_1 txt_1 txt_1 '\n' txt_2 '\n' txt_1 txt_1 txt_1], 'center', info.scr_ycenter - 100, info.white_idx);
            DrawFormattedText(win, [txt_2 '\n' txt6 '\n' txt_2], 'center', info.scr_ycenter - 100, info.white_idx);

            DrawFormattedText(win, txt7, 'center', info.scr_ycenter+10, [1 1 0]);
            DrawFormattedText(win, txt8, 'center', info.scr_ycenter + 100, [0 0 1]);

            % Draw dashed circle around right stimulus
            drawDashedCircle(win, 960, 540, ...
                270, circle1.Color, circle1.lineWidth+1, 2);

            Screen('Flip', win);



            ResponsePixx('StartNow', 1, [0 1 0 1 0], 1);
            while 1
                [buttons, ~, ~] = ResponsePixx('GetLoggedResponses', 1, 1, 2000);
                if ~isempty(buttons)
                    if buttons(1,2) == 1         % Yellow button (training again)
                        resp_trng = 0;
                        break;
                    elseif buttons(1,4) == 1     % Blue button (go to experiment)
                        resp_trng = 1;
                        break;
                        % elseif ~isempty(buttons)
                        %     if buttons(1,2) == 1     % Yellow button
                        %         abort = true;
                        %         break;
                        %     end
                    end
                end
            end
            ResponsePixx('StopNow', 1, [0 0 0 0 0], 0);



            if resp_trng == 0
                if trial == 60
                    trl.repeated_blk(1,1) = 1;
                elseif trial == 480
                    trl.repeated_blk(1,2) = 1;
                end
            end


        end


        %--------------------------------------------------------------------------


        if trl.offset_blocks(trial,1) ~= 0

            if trial == size(trl.onset_blocks,1)
                txt = 'Voce completou todos os blocos da sessão. \n\n Parabéns!';
                DrawFormattedText(win, txt, 'center', info.scr_ycenter - 250, info.white_idx);

            elseif trl.offset_blocks(trial,1) == 1

                txt = sprintf('Bloco %i/%i completo.', block_counter, sum(trl.onset_blocks));
                txt1 = 'Pressione o botão            para continuar!';
                txt2 = ' branco';

                txt_ = '----------------------';
                DrawFormattedText(win, txt, 'center', info.scr_ycenter, info.white_idx);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter +100,info.white_idx);
                DrawFormattedText(win, txt1, 'center', info.scr_ycenter + 130, info.white_idx);
                DrawFormattedText(win, txt2, info.scr_xcenter - 24, info.scr_ycenter + 130, [1 1 1]);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter + 150,info.white_idx);

            elseif trl.offset_blocks(trial,1) == 2

                txt = sprintf('Bloco %i/%i completo.', block_counter, sum(trl.onset_blocks));
                txt1 = 'Pressione o botão            para continuar!';
                txt2 = ' branco';
                txt3 = 'Hora do descanso!';

                txt_ = '----------------------';
                DrawFormattedText(win, txt, 'center', info.scr_ycenter, info.white_idx);
                DrawFormattedText(win, txt3, 'center', info.scr_ycenter+65, info.white_idx);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter +100,info.white_idx);
                DrawFormattedText(win, txt1, 'center', info.scr_ycenter + 130, info.white_idx);
                DrawFormattedText(win, txt2, info.scr_xcenter - 24, info.scr_ycenter + 130, [1 1 1]);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter + 150,info.white_idx);

            end
            Screen('Flip', win);


            ResponsePixx('StartNow', 1, [0 0 0 0 1], 1);
            while 1
                [buttons, ~, ~] = ResponsePixx('GetLoggedResponses', 1, 1, 2000);
                if ~isempty(buttons)
                    if buttons(1,5) == 1         % White button
                        break;
                    end
                end
            end
            ResponsePixx('StopNow', 1, [0 0 0 0 0], 0);

            if abort == true
                break;
            end

        end

        if resp_trng == 0

            trial = abs(trial - 60);

            block_counter = block_counter - 2;
        end

        trial = trial + 1;



    end

    Screen('CloseAll');
    ResponsePixx('Close');

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
