%% ----- TASK CUE!

close all; clear; clc; restoredefaultpath


%% ----- 1 ----- %% task_cue2

nSUB = 40; tt = tic;

for SUB = 1:nSUB
    disp('*****************************************'); disp(SUB); ss = tic;
    task_cue2(SUB)
end

tic(tt)


%% ----- 2 ----- %% task_cue_group2

tic; task_cue_group2; toc


%% ----- 3 ----- %% task_cue_epoch

nSUB = 40; tt = tic;

for SUB = 1:nSUB
    disp('*****************************************'); disp(SUB); ss = tic;
    task_cue_epoch(SUB)
    tic(ss)
end 
 
toc(tt)


%% ----- 4 ----- %% task_cue_perm

task_cue_perm


%% ----- 5 ----- %% task_cue_group2

tic; task_cue_group2; toc