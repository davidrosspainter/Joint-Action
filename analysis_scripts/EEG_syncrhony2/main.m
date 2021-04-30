clear; clc; close all; restoredefaultpath


%% inputs - functions

addpath('..\common')
generate_global_variables % number_of_subjects

SRATE_EEG = 64;

start_time_loop = tic;
time_elapsed_subject = NaN(number_of_subjects, 1);

for SUBJECT = 1:number_of_subjects
    disp('*****************************************'); disp(SUBJECT); start_time_subject = tic;
    synchrony_epoch_data(SUBJECT, SRATE_EEG) % epoch data for analysis
    erp_epoch_data(SUBJECT, SRATE_EEG) % epoch data for analysis - referenced to movement offset time
    time_elapsed_subject(SUBJECT) = toc(start_time_subject); disp(time_elapsed_subject(SUBJECT))
end

elapsed_loop = toc(start_time_loop ); disp(elapsed_loop)


%% ----- correlations between individuals

synchrony_group % get correlations
generate_trial_correlation_matrix % get correlations

permutation_test3 % permutation test
permutation_test_plots % permutation test

group_erp % erp analysis