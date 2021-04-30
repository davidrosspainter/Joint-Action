clear; clc; close all; restoredefaultpath

SRATE_EEG = 64;

addpath('..\common\')
addpath('..\external\topoplot_hack')
    
p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );
    
IN = 'synchrony2\';


addpath('..\common\')
addpath('..\external\topoplot_hack')
addpath('..\external\morlet_transform_hack')
addpath(genpath('..\external\kakearney-boundedline-pkg-50f7e4b'))
addpath(genpath('..\external\'))

is_load_fresh = true;

generate_global_variables
synchrony_settings


%% ----- load epoch data

tic

data = cell( number_of_subjects, 1);

for SUBJECT = 1:number_of_subjects

    disp(SUBJECT)

    [SESSION, PLAYER, STR2] = generate_subject_string(SUBJECT, subject_code);
    data{SUBJECT} = load( [ 'synchrony2\' STR2.SUBJECT '.epoch.' num2str(SRATE_EEG) '.mat' ] );
 
end

toc


%% ------ epoch

% nWorkers = 2;
% parpool(nWorkers)

nPERM = 1000;

time_index = t >= -.5 & t <= 1.5;
t2 = t(time_index);

difference_wave = cell(nPERM, 1);

% close all
% figure;
% hold on

tic

for PERM = 1:nPERM
    difference_wave{PERM} = synchronyGroup2erp_permutation_function(PERM, data, n, number_of_channels, number_of_subjects, EEG_ARTIFACT_THREHOLD_RANGE, t, lab, TRIG, number_of_trials);

    %M = mean(difference_wave{PERM});
    %E = ws_bars(difference_wave{PERM});
    %boundedline(t2, M',E')
    
    %plot(difference_wave{PERM})
end

toc

save([OUT 'difference_wave.mat'], '-v6')
