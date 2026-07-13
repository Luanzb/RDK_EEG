
close all; clear; clc;

git_path = '/home/kaneda/Documents/GitHub/PSA_RDK';
addpath(genpath(git_path));

pc_path = '/home/kaneda/Documents/Projects/PSA_RDK';
addpath(genpath(pc_path));


cd(git_path);


% Ask subject information
answer = inputdlg({'Número sujeito', 'Número sessão','Sat Verde', 'Sat Vermelho'}, '', [1 26], {'', '','',''});
sub_id = str2double(answer{1});
sub.ses_num = str2double(answer{2}); 


%%
% Load trial infos for this session
info_path = fullfile(sprintf('%s/Data/S%d/ses_%d_trlinfo_sub_%d*', pc_path, sub_id,sub.ses_num, sub_id));
info_file = dir(info_path);
load([info_file.folder '/' info_file.name])

sub.ses = answer{2};
sub.ses_num = str2double(answer{2});
sub.targ_verde = str2double(answer{3});
sub.targ_vermelho = str2double(answer{4});

if trl.feature_ses(1,sub.ses_num) == 1
    sub.RDK_color = 'Verde-Vermelho';
    trl.colorRDK = [1 2]; % 1 for green; 2 for red
else
    sub.RDK_color = 'Vermelho-Verde';
    trl.colorRDK = [2 1]; % 2 for red; 1 for green
end

% Ask (more) subject information
[sub] = Inputsubject(sub);


full_saturation_green = sub.targ_verde / 100;
full_saturation_red = sub.targ_vermelho / 100;

[full_sat_green] = adjust_chroma(full_saturation_green, trl.baseline_green_lab);
[full_sat_red] = adjust_chroma(full_saturation_red, trl.baseline_red_lab);


trl.dotcolor1_high_sat = full_sat_green;
trl.dotcolor2_high_sat = full_sat_red;

%% Run experiment

[resp,time,srt,trl] = Screen_RDK(info,trl,sub,RDK,circle1,dots,dots2,dots3,dots4);

%%

% Save data files
sub.data_fname = sprintf('data_sub_%d_ses_%d_%s', sub.id_num, sub.ses_num, datestr(now,'yymmdd-HHMM')); %#ok<TNOW1,DATST>
save(fullfile(sprintf('%s/Data/S%d/Task/%s', pc_path, sub.id_num), [sub.data_fname, '.mat']), 'resp', 'time', 'info','trl','sub','RDK','const','circle1','srt', '-v7.3'); % resp

sub.eye_fname = 'RDKeye.edf';
if exist(sub.eye_fname, 'file')
    movefile(sub.eye_fname, sprintf('%s/Data/S%d/Eye/%s.edf', pc_path, sub.id_num, sub.data_fname));
else
    error('Eye-tracker data file not found!');
end

 
 [s] = GetSRT(sub);
% 
save(fullfile(sprintf('%s/Data/S%d/Task/%s', pc_path, sub.id_num), [sub.data_fname, '.mat']), 'resp', 'time', 'info','trl','sub','RDK','const','circle1','srt','s','dots','dots2','dots3','dots4', '-v7.3'); % resp
