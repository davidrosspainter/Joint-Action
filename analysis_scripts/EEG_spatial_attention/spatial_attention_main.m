close all; clear; clc; restoredefaultpath


%% 

basicSettings
delete(gcp('nocreate'));

tt = tic;

for SUB = 1:40
    
    disp('*****************************************'); disp(SUB); ss = tic;
	spatialAttention(SUB) % adjusted with respect to movement offset
    toc(ss)
    
end

toc(tt)


%% ---- group

spatialAttentionGroup


