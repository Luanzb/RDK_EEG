
close all; clear; clc;

git_path = '/home/kaneda/Documents/GitHub/RDK_EEG';
addpath(genpath(git_path));

pc_path = '/home/kaneda/Documents/Projects/RDK_EEG';
addpath(genpath(pc_path));


cd(git_path);


% Ask subject information
answer = inputdlg({'Número sujeito'}, '', [1 26], {''});
sub_id = str2double(answer{1});


%%
% Load trial infos for this session
info_path = fullfile(sprintf('%s/Data/S%d/trlinfo_sub_%d*', pc_path, sub_id, sub_id));
info_file = dir(info_path);
load([info_file.folder '/' info_file.name])


% Ask (more) subject information
[sub] = Inputsubject(sub);


%% Run experiment

[resp,time,trl] = Screen_RDK_EEG(info,trl,sub,RDK,const);

%%

% Save data files
sub.data_fname = sprintf('data_sub_%d_%s', sub.id_num, datestr(now,'yymmdd-HHMM')); %#ok<TNOW1,DATST>
save(fullfile(sprintf('%s/Data/S%d/Task/%s', pc_path, sub.id_num), [sub.data_fname, '.mat']), 'resp', 'time', 'info','trl','sub','RDK','const', '-v7.3'); % resp

sub.eye_fname = 'RDKeye.edf';
if exist(sub.eye_fname, 'file')
    movefile(sub.eye_fname, sprintf('%s/Data/S%d/Eye/%s.edf', pc_path, sub.id_num, sub.data_fname));
else
    error('Eye-tracker data file not found!');
end


 [s] = GetSRT(sub);
% 
save(fullfile(sprintf('%s/Data/S%d/Task/%s', pc_path, sub.id_num), [sub.data_fname, '.mat']), 'resp', 'time', 'info','trl','sub','RDK','const','s', '-v7.3'); % resp
