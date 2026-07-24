function [resp_deg, err_deg, rt] = get_continuous_report(scr_win, scr_ppd, resp_on_deg, true_deg, show_fb, info, qtarget,RDK)
% GET_CONTINUOUS_REPORT
% Ajuste contínuo de Direcçao (0-360°) com setas esquerda/direita.
% Retorna: resp_deg (resposta), err_deg (erro em (-180,180]), rt (s).
%
% Parâmetros:
%   scr_win     : handle da janela PTB já aberta (win)
%   scr_ppd     : pixels por grau (1° -> px)
%   resp_on_deg : ângulo inicial do dial (graus)
%   true_deg    : ângulo "verdadeiro" (graus, 0-360)
%   show_fb     : lógico (true/false) para mostrar feedback visual
%
% Controles:
%   <- / -> : ajusta direção de movimento
%   SPACE   : confirma
%   q       : aborta (lança erro)

if nargin < 2 || isempty(scr_ppd),     scr_ppd = 47; end
if nargin < 3 || isempty(resp_on_deg), resp_on_deg = 45; end
if nargin < 4 || isempty(true_deg),    true_deg = 90; end
if nargin < 5 || isempty(show_fb),     show_fb = true; end

% ---------- Parâmetros do dial e aceleração ----------
velo_step      = scr_ppd/165;   % incremento base (graus)
velo_expo      = scr_ppd/50;    % expoente p/ aceleração
delta_velo_deg = velo_step;
exp_velo_deg   = velo_expo;
base_velo_deg  = delta_velo_deg;

% ---------- Centro e geometria ----------
[wpx, hpx] = Screen('WindowSize', scr_win);
scr_center = [wpx hpx] / 2;


%   Places the dial on the saccaded side
C = qtarget;
cx_target = round(C(1,1)); cy_target = round(C(1,2));

target_rect = [
    cx_target - RDK.rad, ...
    cy_target - RDK.rad, ...
    cx_target + RDK.rad, ...
    cy_target + RDK.rad];


% Tamanho do anel (diâmetro) e espessura do traço
circ_size   = 2 * RDK.rad;                 % diâmetro do anel (px)
ring_rad    = circ_size / 2;               % raio do anel
ring_thick  = max(2, round(scr_ppd/18));   % espessura do contorno (px) % 18


% ---------- Teclas ----------
KbName('UnifyKeyNames');
KEY_LEFT    = KbName('LeftArrow');
KEY_RIGHT   = KbName('RightArrow');
KEY_ABORT   = KbName('q');
KEY_CONFIRM = KbName('space');

% ---------- Mensagens ----------
line1 = 'Reporte a direção do movimento';
line2 = 'Use [<] e [>] para ajustar e [ESPAÇO] para confirmar.';


% ---------- Preparação visual inicial ----------
Screen('BlendFunction', scr_win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
DrawFormattedText(scr_win, line1, 'center', round(scr_center(2) - scr_ppd*7),[1 1 1]);
DrawFormattedText(scr_win, line2, 'center', round(scr_center(2) + scr_ppd*7), [1 1 1], [], [], [], 1.5);
% anel vazado (contorno branco)
Screen('FrameOval', scr_win, [255 103 0]/255, target_rect, ring_thick);

Screen('DrawDots', scr_win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_white, info.white_idx, [], 2,1);
Screen('DrawDots', scr_win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_black, info.black_idx, [], 2,1);

Screen('DrawingFinished', scr_win, 1);
Screen('Flip', scr_win, [], 1);  % dontclear on
Screen('DrawingFinished', scr_win);


% ---------- Espera pela 1ª seta para definir direção inicial ----------
FlushEvents;
while KbCheck; end

% resp_on_deg é direçao entre 0-360
resp_rad = deg2rad( mod(resp_on_deg, 360) );
resp_rad = wrapToPi(resp_rad);

% primeira seta só escolhe o sentido
while true
    [key_press, ~, key_code] = KbCheck;
    if key_press
        if key_code(KEY_LEFT)
            resp_rad = wrapToPi(resp_rad + deg2rad(1));
            break
        elseif key_code(KEY_RIGHT)
            resp_rad = wrapToPi(resp_rad - deg2rad(1));
            break
        elseif key_code(KEY_ABORT)
            error('ABORT KEY PRESSED !');
        end
    end
end
while KbCheck; end

% ---------- Loop de ajuste contínuo ----------
t0 = GetSecs;
while true
    % 1) desenha dial (anel vazado + dois pontos antipodais)
    xdot = ring_rad * cos(resp_rad);
    ydot = ring_rad * sin(resp_rad);
    
    Screen('BlendFunction', scr_win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % anel vazado
    Screen('FrameOval', scr_win, [255 103 0]/255, target_rect, ring_thick);

    % pontos antipodais (eixo de orientação)
    Screen('DrawDots', scr_win, [xdot; ydot], RDK.size_dot_pix*4, [255 103 0]/255, qtarget, 3, 1); % 14

    % textos
    DrawFormattedText(scr_win, line1, 'center', round(scr_center(2) - scr_ppd*7),[1 1 1]);
    DrawFormattedText(scr_win, line2, 'center', round(scr_center(2) + scr_ppd*7), [1 1 1], [], [], [], 1.5);

    Screen('DrawDots', scr_win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_white, info.white_idx, [], 2,1);
    Screen('DrawDots', scr_win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_black, info.black_idx, [], 2,1);

    Screen('DrawingFinished', scr_win);
    Screen('Flip', scr_win);

    % 2) teclado + aceleração
    [key_press, ~, key_code] = KbCheck;
    if key_press
        step_deg = base_velo_deg ^ exp_velo_deg;   % aceleração exponencial
        step_rad = deg2rad(step_deg);

        if key_code(KEY_LEFT)
            resp_rad = wrapToPi(resp_rad + step_rad);
        elseif key_code(KEY_RIGHT)
            resp_rad = wrapToPi(resp_rad - step_rad);
        elseif key_code(KEY_CONFIRM)
            rt = GetSecs - t0;
            break
        elseif key_code(KEY_ABORT)
            error('ABORT KEY PRESSED !');
        end

        base_velo_deg = base_velo_deg + delta_velo_deg;
        if base_velo_deg > 15
            base_velo_deg = delta_velo_deg;
        end
    else
        base_velo_deg = delta_velo_deg;
    end
end

% ---------- Resposta e erro ----------
resp_deg = mod(rad2deg(resp_rad), 360);
true_deg = mod(true_deg, 360);

% erro circular (menor distância angular) → (-180, +180]
err_deg = angdiff360(true_deg, resp_deg);

% ---------- Feedback opcional ----------
if show_fb
    % true direction dot
    true_rad = deg2rad(true_deg);

    x_true = ring_rad * cos(true_rad);
    y_true = ring_rad * sin(true_rad);

    % draw ring
    Screen('FrameOval', scr_win, [255 103 0]/255, target_rect, ring_thick);

    % draw TRUE direction dot (e.g., blue)
    Screen('DrawDots', scr_win, [x_true; y_true], RDK.size_dot_pix*4, [1 1 1], qtarget, 3, 1);

    % pontos da resposta
    xdot = ring_rad * cos(resp_rad);
    ydot = ring_rad * sin(resp_rad);
    Screen('DrawDots', scr_win, [xdot; ydot], RDK.size_dot_pix*4, [255 103 0]/255, qtarget, 3, 1);

    DrawFormattedText(scr_win, line1, 'center', round(scr_center(2) - scr_ppd*7),[1 1 1]);
    if abs(err_deg) < 20
        DrawFormattedText(scr_win, 'Excelente!', 'center', round(qtarget(2) - scr_ppd*4.7),[1 1 1]);
    elseif abs(err_deg) < 30
        DrawFormattedText(scr_win, 'Muito bom!', 'center', round(qtarget(2) - scr_ppd*4.7),[1 1 1]);
    elseif abs(err_deg) < 40
        DrawFormattedText(scr_win, 'Foi perto!', 'center', round(qtarget(2) - scr_ppd*4.7),[1 1 1]);
    else
        DrawFormattedText(scr_win, sprintf('Erro: %0.1f°', err_deg), 'center', round(qtarget(2) - scr_ppd*4.7),[1 1 1]);
    end
    DrawFormattedText(scr_win, 'Pressione [ESPAÇO] para continuar', 'center', round(scr_center(2) + scr_ppd*7), [1 1 1], [], [], [], 1.5);

    Screen('DrawDots', scr_win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_white, info.white_idx, [], 2,1);
    Screen('DrawDots', scr_win, [info.scr_xcenter info.scr_ycenter], info.fp_size_pix_black, info.black_idx, [], 2,1);

    Screen('DrawingFinished', scr_win);
    Screen('Flip', scr_win);

    while KbCheck; end
    while true
        [kp, ~, kc] = KbCheck;
        if kp
            if kc(KEY_CONFIRM)
                break
            elseif kc(KEY_ABORT)
                error('ABORT KEY PRESSED !');
            end
        end
    end
    while KbCheck; end
end

Screen('DrawingFinished', scr_win);
Screen('Flip', scr_win);
end

% =================== SUBFUNÇÕES LOCAIS ===================

function th = wrapToPi(th)
th = mod(th, 2*pi);
th(th > pi) = th(th > pi) - 2*pi;
end


function d = angdiff360(a_deg, b_deg)
d = mod((a_deg - b_deg + 180), 360) - 180;
end

