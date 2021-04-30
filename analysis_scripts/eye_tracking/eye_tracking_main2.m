clear; clc; close all; restoredefaultpath

addpath('..\common')

generate_global_variables

str.player = {'P1', 'P2'};
str.side = {'left', 'right'};


%% ----- get data, first time

% sessions to exclude:
% #02 missing data for both participants

sessions_to_use = 1:number_of_sessions;
sessions_to_use(2) = [];
%sessions_to_use = sessions_to_use(1);

for SESSION = sessions_to_use
    
	disp('%%%%%%%%%%%%%%%%%%')
    disp(SESSION)

    load( [fname.direct_behav fname.behave{SESSION}],  'triggers', 'TRIG', 'n', 'data', 'D', 'btriggers' )
    
    session_label = fname.behave{SESSION}(1:3);
    
    if session_label(3) == ' '
        session_label = [session_label(1) '0' session_label(2)];
    end
    
    disp(session_label)
    
%     for PLAYER = 1:2
%         DD = dir([fname.direct_eyeSamples tmp '_' str.side{PLAYER} '*Samples.txt']);
% 
%         fname.samples = DD.name;
%         fname.events = DD.name;
% 
%         fileID = fopen([fname.direct_eyeSamples fname.samples]);
%         disp(fileID)
%         fileID = fopen([fname.direct_eyeEvents fname.events]);
%         disp(fileID)
%     end

    for PLAYER = 1:number_of_players
        import_eyetracker_matlab3(SESSION, PLAYER, session_label)
        preprocess_eye_data2(SESSION, PLAYER)
    end

end


%% ----- get data, again?

% for SUBJECT = 1:number_of_subjects
%     
%     disp('%%%%%%%%%%%%%%%%%%')
%     
%     disp(SUBJECT)
%     tic
% 	import_eye_data(SUBJECT)
%     toc
%     
% end


%% ----- analyse
% 
% eyetrack_heatmap_cond2_dist2
% eyetrack_movement_epoch