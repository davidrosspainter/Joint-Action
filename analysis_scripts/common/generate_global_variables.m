%% numbers

number_of_sessions = 20;
number_of_players = 2;
number_of_subjects = number_of_sessions*number_of_players;

number_of_channels = 61; % EEG

number_of_trials = 960;
number_of_blocks = 15;
number_of_trials_per_block = number_of_trials/number_of_blocks;

number_of_triggers_per_trial = 5;
number_of_triggers_total = number_of_trials * number_of_triggers_per_trial + number_of_blocks + 1; % expected to be present in the EEG recordings


%% fnames

load('..\data_manager\CheckFiles2\fname.mat')


%% EEG, srate, channel selection & order

SRATE_RECORDING = 2000;

load chanlocs;

channel_to_use = [22 23 24 25 26 27 28 29 47 48 49 50 51 52 53 54 59 60 61];
number_of_best_channels = 4;

channel_order = {'Fp1', 'Fpz', 'Fp2', 'AF7', 'AF3', 'AF4', 'AF8', 'F7', 'F5', 'F3', 'F1', 'Fz', 'F2', 'F4', 'F6', 'F8', 'FT7', 'FC5', 'FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'FC6', 'FT8', 'T7', 'C5', 'C3', 'C1', 'Cz', 'C2', 'C4', 'C6', 'T8', 'TP7', 'CP5', 'CP3', 'CP1', 'CP2', 'CP4', 'CP6', 'TP8', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'PO7', 'PO5', 'PO3', 'POz', 'PO4', 'PO6', 'PO8', 'O1', 'Oz', 'O2'};

channel_order2 = NaN(number_of_channels,1);

for EE = 1:number_of_channels
    channel_order2(EE) = find( ismember( lab, channel_order{EE} ) );    
end

EEG_ARTIFACT_THREHOLD_RANGE = 200;


%% sessions

for SESSION_TMP = 1:number_of_sessions
    if SESSION_TMP < 10
        STR.session{SESSION_TMP} = [ '0' num2str(SESSION_TMP) ];
    else
        STR.session{SESSION_TMP} = num2str(SESSION_TMP);
    end
end


%% subjects 

subject_code = generate_subject_code;


%% triggers

TRIG.fix = [1 2]; % Hz combo 1, 2
TRIG.task_cue = [3 4]; % solo, co-op
TRIG.move_cue = [5 6]; % left/right
TRIG.feedback = 7; % feedback onset
TRIG.rest_trial = 8;
TRIG.rest_block = 255;

T.rest_trial = 1;
T.fix = 2;
T.task_cue = 3;
T.move_cue = 4;
T.feedback = 5;