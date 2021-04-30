clear; clc; close all; restoredefaultpath

addpath('..\common\')
basic_settings


%% inputs - functions

basic_settings
SRATE_EEG = 64;

subject_elapsed_time = NaN(1, number_of_subjects);
loop_start_time = tic;

for SUBJECT = 28
    
    disp('*****************************************'); disp(SUBJECT); subject_start_time = tic;
    
    check_alignment3(SUBJECT, SRATE_EEG);
    subject_elapsed_time(SUBJECT) = toc(subject_start_time); disp(subject_elapsed_time(SUBJECT))
    
end

loop_elapsed_time = toc(loop_start_time)