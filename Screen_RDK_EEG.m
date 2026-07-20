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


%%

topPriorityLevel = MaxPriority(win);
Priority(topPriorityLevel);
HideCursor;
ListenChar(-1);


%%

block_counter = 0;

try



    for trial = 1:info.ntrials

        % condicional flipa a cada inicio de bloco (a cada 20 tentativas)
        if trl.onset_blocks(trial,1) == 1

            block_counter = block_counter + 1;

            txt_ = '-----------------';
            txt1 = 'Pressione a barra de espaço para iniciar o bloco!';
            txt3 = sprintf('Bloco %d/%d', block_counter, sum(trl.onset_blocks));

            DrawFormattedText(win, [txt_ txt_ txt_ txt_], 'center', info.scr_ycenter - 50,info.white_idx);
            DrawFormattedText(win, txt1, 'center', info.scr_ycenter -20, info.white_idx);
            DrawFormattedText(win, [txt_ txt_ txt_ txt_], 'center', info.scr_ycenter + 10,info.white_idx);
            DrawFormattedText(win, txt3, 'center', info.scr_ycenter + 40,info.white_idx);
            DrawFormattedText(win, txt_, 'center', info.scr_ycenter + 60,info.white_idx);

            Screen('Flip', win);

            RestrictKeysForKbCheck(KbName('space'));
            KbReleaseWait;
            KbWait;
            KbReleaseWait;
            RestrictKeysForKbCheck([]);


        end


        % RDk infos
        const.test_dur_fr = trl.targ_off(trial);

        RDK.dirSignal = info.matrix(trial,3); % LEFT RDK movement direction
        [dots]  = draw_rdk(const, RDK,1,trial,trl); % LEFT RDK

        RDK.dirSignal = info.matrix(trial,4); % RIGHT RDK movement direction
        [dots2] = draw_rdk(const, RDK,1,trial,trl); % RIGHT RDK


        % Shows the saccade side based on the dot's color
        Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        if info.matrix(trial,1) == 1
            Screen('DrawDots', win, [0 0], info.fp_size_pix, trl.cue_green, [info.scr_xcenter info.scr_ycenter], []);
        else
            Screen('DrawDots', win, [0 0], info.fp_size_pix, trl.cue_red, [info.scr_xcenter info.scr_ycenter], []);
        end
        time.fp_on(trial) = Screen('Flip', win);
        
        RestrictKeysForKbCheck(KbName('space'));
        KbReleaseWait;
        KbWait;
        KbReleaseWait;
        RestrictKeysForKbCheck([]);


        % minimum 500 ms fixation before RDK onset
        Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix, info.white_idx, [], 2,1);
        time.fp_on(trial) = Screen('Flip', win);
        WaitSecs(.5);


        tic


        for frame = 1:trl.targ_off(trial)


            Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix, info.white_idx, [], 2,1);


            Screen('DrawDots',win, round(dots{1,1}.posi{frame})', dots{1,1}.siz, [1 1 1], RDK.coordL,2);
            Screen('DrawDots',win, round(dots2{1,1}.posi{frame})', dots2{1,1}.siz, [1 1 1], RDK.coordR,2);



            Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

            % CUE ONSET
            if frame >= trl.cue_on(trial,1) && frame <= trl.cue_off(trial,1)

                if info.matrix(trial,1) == 1 % GREEN

                    if info.matrix(trial,2) ==1 % Green LEFT

                        Screen('FillArc', win, trl.cue_red, info.cue_position, 0, 180); % Right
                        Screen('FillArc', win, trl.cue_green, info.cue_position, 180, 180); % Left
                    else                        % Green RIGHT
                        Screen('FillArc', win, trl.cue_green, info.cue_position, 0, 180); % Right
                        Screen('FillArc', win, trl.cue_red, info.cue_position, 180, 180); % Left
                    end
                else                        % RED
                    if info.matrix(trial,2) ==1 % Red LEFT

                        Screen('FillArc', win, trl.cue_green, info.cue_position, 0, 180); % Right
                        Screen('FillArc', win, trl.cue_red, info.cue_position, 180, 180); % Left
                    else                        % Red RIGHT
                        Screen('FillArc', win, trl.cue_red, info.cue_position, 0, 180); % Right
                        Screen('FillArc', win, trl.cue_green, info.cue_position, 180, 180); % Left
                    end
                end

            end


            %             if frame == 1
            %                 time.trl_on(trial) = Screen('Flip', win);
            %                 %Eyelink('Message', sprintf('trial_onset_%1d', trial));
            %                 %Eyelink('Command', 'record_status_message "TRIAL %d', trial);
            %             elseif frame == trl.cue_on(trial,1)
            %                 time.cue_on(trial) = Screen('Flip', win);
            %                 %Eyelink('Message', sprintf('cue_on_%1d', trial));
            %             elseif frame == trl.cue_off(trial,1)
            %                 time.cue_off(trial) = Screen('Flip', win);
            %                 %Eyelink('Message', sprintf('cue_off_%1d', trial));
            %             elseif frame == trl.targ_on(trial,1)
            %                 time.targ_on(trial) = Screen('Flip', win);
            %                 %Eyelink('Message', sprintf('targ_on_%1d', trial));
            %             elseif frame == trl.targ_off(trial,1)
            %                 time.targ_off(trial) = Screen('Flip', win);
            %                 %Eyelink('Message', sprintf('targ_off_%1d', trial));
            %             elseif frame == trl.targ_off(trial)+24
            %                 time.trl_off(trial) = Screen('Flip', win);
            %                 %Eyelink('Message', sprintf('trl_off_%1d', trial));
            %             else
            Screen('Flip', win);
            %             end


        end


        Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('DrawDots', win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix, info.white_idx, [], 2,1);
        Screen('Flip', win);

        %% Orientation selector -----------------------------------------------

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
        resp.report_deg(trial) = resp_deg; % (0..360)
        resp.error_deg(trial) = err_deg;   % (-180, +180]
        resp.true_deg(trial) = true_dir;
        resp.rt_s(trial) = rt; % time (s)

        % Quick log (verification)
        % fprintf('T%04d | Q=%d | TRUE(ptb)=%.1f° -> axis=%.1f° | RESP=%.1f° | ERR=%.1f° | RT=%.3fs\n', ...
        %     trial, qcue, true_deg_ptb, true_axis, resp_deg, err_deg, rt);


        toc


        if trl.offset_blocks(trial,1) ~= 0

            if trial == size(trl.onset_blocks,1)
                txt = 'Voce completou todos os blocos da sessão. \n\n Parabéns!';
                DrawFormattedText(win, txt, 'center', info.scr_ycenter, info.white_idx);

            elseif trl.offset_blocks(trial,1) == 1

                txt = sprintf('Bloco %i/%i completo.', block_counter, sum(trl.onset_blocks));
                txt1 = 'Pressione a barra de espaço para continuar!';
                txt_ = '----------------------';

                DrawFormattedText(win, txt, 'center', info.scr_ycenter, info.white_idx);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter +30,info.white_idx);
                DrawFormattedText(win, txt1, 'center', info.scr_ycenter + 60, info.white_idx);
                DrawFormattedText(win, [txt_ txt_ txt_], 'center', info.scr_ycenter + 90,info.white_idx);

            elseif trl.offset_blocks(trial,1) == 2

                txt = sprintf('Bloco %i/%i completo.', block_counter, sum(trl.onset_blocks));
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


    FlushEvents;
    ListenChar(0);
    ShowCursor;
    Priority(0);

catch

    psychrethrow(psychlasterror);
    sca; close all;

end



end
