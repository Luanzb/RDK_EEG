
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
info_path = fullfile(sprintf('%s/Data/S%d/Training/training_sub_%d*', pc_path, sub_id, sub_id));
info_file = dir(info_path);
load([info_file.folder '/' info_file.name])


% Ask (more) subject information
answer = inputdlg({'Número sujeito','Olho Dominante'}, '', [1 26], {sub.id,''});

sub.eye = answer{2};


%% Run experiment

[time,trl,info] = Screen_Training(info,trl,sub,RDK,const);
