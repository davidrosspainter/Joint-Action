clear; clc; close all; restoredefaultpath

addpath('..\common')

generate_global_variables


%% ----- get data, first time

sessions_to_use = [2 3 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 21 22 23];





for SESSION = sessions_to_use

    disp('%%%%%%%%%%%%%%%%%%')
    disp(SESSION)

    if SESSION == 3; continue; end

    for PLAYER = 1:number_of_players
        tic
        import_eyetracker_matlab2(SESSION, PLAYER)
        toc
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