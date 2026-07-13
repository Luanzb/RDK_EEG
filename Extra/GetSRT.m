function [s] = GetSRT(sub)


addpath /usr/local/MATLAB/R2024b/toolbox/saccade_detection/
addpath(genpath('/usr/local/MATLAB/R2024b/toolbox/edfmex/'))

data_path = '/home/kaneda/Documents/Projects/PSA_RDK';
addpath(genpath(data_path));
%%

var = sprintf('%s/Data/S%d/Eye/%s.edf',data_path,sub.id_num,sub.data_fname);

eyedf = edfmex(fullfile(var));

eye = eyedf.RECORDINGS(1).eye;


%% get event times

eyedat = [];

for l = 1:length(eyedf.FEVENT)
    if strncmp(eyedf.FEVENT(l).message,sprintf('trial_onset_%1d',l),12)
        eyedat(1,l) = eyedf.FEVENT(l).sttime;
    elseif strncmp(eyedf.FEVENT(l).message,sprintf('cue_on_%1d', l),7)
        eyedat(2,l) = eyedf.FEVENT(l).sttime;
    elseif strncmp(eyedf.FEVENT(l).message,sprintf('cue_off_%1d', l),8)
        eyedat(3,l) = eyedf.FEVENT(l).sttime;
    elseif strncmp(eyedf.FEVENT(l).message,sprintf('targ_on_%1d', l),8)
        eyedat(4,l) = eyedf.FEVENT(l).sttime;
    elseif strncmp(eyedf.FEVENT(l).message,sprintf('targ_off_%1d', l),9)
        eyedat(5,l) = eyedf.FEVENT(l).sttime; %#ok<*AGROW>
    elseif strncmp(eyedf.FEVENT(l).message,sprintf('trl_off_%1d', l),8)
        eyedat(6,l) = eyedf.FEVENT(l).sttime;
    end
end


s.eyemat=eyedat(1,eyedat(1,1:size(eyedat,2))~=0);      % array on computer clock

s.eyemat(2,:)=eyedat(2,eyedat(2,1:size(eyedat,2))~=0);     % cue on computer clock
s.eyemat(3,:)=eyedat(2,eyedat(2,1:size(eyedat,2))~=0)-s.eyemat(1,:);       % cue on trial time

s.eyemat(4,:)=eyedat(3,eyedat(3,1:size(eyedat,2))~=0);     % cue off on computer clock
s.eyemat(5,:)=eyedat(3,eyedat(3,1:size(eyedat,2))~=0)-s.eyemat(1,:);       % cue off on trial time

s.eyemat(6,:)=eyedat(4,eyedat(4,1:size(eyedat,2))~=0);     % targ on on computer clock
s.eyemat(7,:)=eyedat(4,eyedat(4,1:size(eyedat,2))~=0)-s.eyemat(1,:);       % targ on on trial time

s.eyemat(8,:)=eyedat(5,eyedat(5,1:size(eyedat,2))~=0);     % target off on computer clock
s.eyemat(9,:)=eyedat(5,eyedat(5,1:size(eyedat,2))~=0)-s.eyemat(1,:);       % target off on trial time

s.eyemat(10,:)=eyedat(6,eyedat(6,1:size(eyedat,2))~=0);     % trl off on computer clock
s.eyemat(11,:)=eyedat(6,eyedat(6,1:size(eyedat,2))~=0)-s.eyemat(1,:);       %  trl off on trial time



%%
% epoch data based on events

ppd = 36;

s.eyeraw = [];

%%%%%%%%%%%
min_rt = 0;
max_rt = 400;
epoch_size = [min_rt max_rt];

for l=1:size(s.eyemat,2)
    
    %%%%%%%%%%%
    tt=find(eyedf.FSAMPLE.time==s.eyemat(2,l));   % begin time at cue onset
    if ~isempty(tt)
        s.eyeraw(l,1,:)=(eyedf.FSAMPLE.gx(eye,tt-abs(epoch_size(1)): tt+epoch_size(2))-1920/2)/ppd;
        s.eyeraw(l,2,:)=(eyedf.FSAMPLE.gy(eye,tt-abs(epoch_size(1)): tt+epoch_size(2))-1080/2)/ppd;
        s.eyeraw(l,3,:)=eyedf.FSAMPLE.pa(eye,tt-abs(epoch_size(1)): tt+epoch_size(2));
        
        %%% amplitude
        
        s.eyepos(l,:) = sqrt(s.eyeraw(l,1,:).^2 + s.eyeraw(l,2,:).^2);
    end
end

% s.eyeraw(s.eyeraw(:,1:2,:)>100)=nan;

s.eyemat_label = {'array on computer clock',...
                  'cue on computer clock',...
                  'cue on trial time',...
                  'cue off computer clock',...
                  'cue off trial time',...
                  'target on computer clock',...
                  'target on trial time',...
                  'target off computer clock',...
                  'target off trial time',...
                  'trl off computer clock',...
                  'trl off trial time'};

s.F = eyedf.RECORDINGS(1).sample_rate;
s.time = epoch_size(1):1000/s.F:epoch_size(2);
s.chans = {'Eye X','Eye Y','Eye Pupil'};

%%% create vector to receive rejected trials
s.badtrls = [];
s.fname = sub.data_fname;

%%
%

% do saccade detection

% sac(1:num,1)   onset of saccade
% sac(1:num,2)   offset of saccade
% sac(1:num,3)   peak velocity of saccade (vpeak)
% sac(1:num,4)   horizontal component     (dx)
% sac(1:num,5)   vertical component       (dy)
% sac(1:num,6)   horizontal amplitude     (dX)
% sac(1:num,7)   vertical amplitude       (dY)
% sac(1:num,8)   saccade magnitude        ()

MINDUR = 8;        % Minimum duration (number of samples)
VTHRES = 5;        % Velocity threshold
SAMPLING = s.F;    % Sampling rate
VTYPE = 2;         % Velocity types (2 = using moving average)

% macrosacvec1 = []; % mudar o número para cada sessão
macrosacvec = nan(size(s.eyeraw,1),8);

for l = 1:size(s.eyeraw,1)
    
    veltemp = vecvel(squeeze(s.eyeraw(l,1:2,:))',SAMPLING,VTYPE);
    if sum(abs(veltemp(:,1))) > 0
         sactemp = microsacc(squeeze(s.eyeraw(l,1:2,:))',veltemp,VTHRES,MINDUR);
    end

    if ~isempty(sactemp)
        sactemp(:,8) = sqrt(sactemp(:,7).^2 + sactemp(:,6).^2);
        strange = find(abs(sactemp(:,8)) > 18); %15
        sactemp(strange,:) = [];
    else
        sactemp = nan(1,8);
    end
    
    s.sac{l} = sactemp;
    s.vel{l} = veltemp;
    
    %%%%%%%%%%%
    min_amp = 2;
    if sum(abs(sactemp(:,8)) > min_amp) ~= 1
        macrosacvec(l,:) = nan(1,size(sactemp,2));
    else
        macrosacvec(l,:) = sactemp(abs(sactemp(:,8)) > min_amp,:);
    end
    
end

s.macrosacvec = macrosacvec;

end
