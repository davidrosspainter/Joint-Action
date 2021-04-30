clear; clc; close all; restoredefaultpath


%% inputs - functions

number_subjects = 40;

start_time_loop = tic;
time_elapsed_subject = NaN(number_subjects,1);

%parpool(8)

for SUBJECT = 36:number_subjects   
    disp('*****************************************'); disp(SUBJECT); start_time_subject = tic;
	%synchrony(SUBJECT, 64)
    synchrony2(SUBJECT, 64)
    time_elapsed_subject(SUBJECT) = toc(start_time_subject); disp(time_elapsed_subject(SUBJECT))
end

elapsed_loop = toc(start_time_loop ); disp(elapsed_loop)


% synchronyGroup.m
% synchronyGroup2erp.m