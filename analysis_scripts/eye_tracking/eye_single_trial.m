clear; clc; close all; restoredefaultpath

addpath('..\external\')
addpath('..\common\')

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = 'import_eyetracker_matlab2\';
load '..\data_manager\CheckFiles2\fname.mat'

is_load_fresh = true;
figure_visibility = 'off';
is_check_original_heatmaps = false;
is_recentre = false;
is_use_preprocessed_data = true;

generate_global_variables


%% triggers

sessions_to_use = [6 7 8 9 10 11 12 13 14 15 16 17 18 19 21 22 23]; % exclude 2 3 5

str.side = {'left', 'right'};
str.player = {'P1', 'P2'};
str.COND = { 'solo' 'joint' 'solo-joint'};
str.period =  {'pretask' 'premove' 'postmove'};

TRIG.fix = [1 2]; % Hz combo 1, 2
TRIG.task_cue = [3 4]; % solo, co-op
TRIG.move_cue = [5 6]; % left/right
TRIG.feedback = 7; % feedback onset

mon.res = [1920 1080];

vXEdge = 1:2:mon.res(1);
vYEdge = 1:2:mon.res(2);

fs = 120;
dpp = (53.2/1920);



%% check original gaze images

load 'eyetrack_heatmap_cond2_dist2\all\RESULT.mat'


if is_check_original_heatmaps

    for SESSION = 1:17

        close all
        h = figure('visible', figure_visibility);

        for PLAYER = 1:number_of_players

            for COND = 1:2
                subplot(2,2,(PLAYER-1)*2+COND)
                imagesc(RESULT.GAZEHIST.postmove(:,:,COND,PLAYER,SESSION))
                colorbar
                colormap('hot')
                title([str.player{PLAYER} ' ' str.COND{COND}])
            end

            suptitle(['gazehist.', STR.session{SESSION}])
            saveas(h, [OUT 'gazehist.', STR.session{SESSION} '.png'])

            
            sadfasdf
        end
    end
    
end


%% run analysis

if is_load_fresh

    results = struct('control', cell(number_of_sessions,1), ...
                     'gaze_distance', cell(number_of_sessions,1), ...
                     'GAZE_POST', cell(number_of_sessions,1));
        
    for SESSION = sessions_to_use
        
        close all
        
        SESSION_COUNT = strfndw(fname.behave, ['S' num2str(SESSION) ' test*']);
        disp(['IDX = ' num2str(SESSION_COUNT)])
        disp(fname.behave{SESSION_COUNT})
        
        TYPE = NaN(number_of_trials, number_of_players);
        
        h2 = figure('visible', figure_visibility);
        
        
        for PLAYER = 1:number_of_players
            
            %% ----- get data
            
            fname.EYE = ['S' num2str(SESSION) '.' str.player{PLAYER} '.eyeData.mat'];
            disp(fname.EYE)
            
     
            
            tic
            load([IN fname.EYE], 'samples', 'type', 'latency', 'header' )
            toc
            
            if is_use_preprocessed_data
                  load( [ 'preprocess_eye_data\' STR.session{SESSION_COUNT} '.' str.player{PLAYER} '.processedEye.mat' ], 'samples', 'GAZE', 'PUPIL', 'type' )
            end
            
            
            %% ----- get eye positions
            
            idx.x = [6 8];
            idx.y = [7 9];
            
            samples(samples == 0) = NaN; % raw data
            
            if is_use_preprocessed_data
                % GAZE == GAZE
            else
                GAZE = [nanmean(samples(:,idx.x),2) nanmean(samples(:,idx.y),2)]; % mean of left and right eyes
            end
            
            time = samples(:,1);
             
            h1 = figure('visible', figure_visibility);
            subplot(1,2,1); cla; hold on
            title('Raw Data')
            plot(GAZE(:,1))
            plot(GAZE(:,2))
            legend({'x', 'y'}, 'location', 'best')
            xlabel('Samples')
            ylabel('Pixels')
            
            % ----- recentre
            
            lim.s = [-1 0];
            lim.S = lim.s*1000000;
            f.trial = (lim.s(2) - lim.s(1))*fs;
            
            IDX = find(ismember(type, TRIG.task_cue));
            TYPE(:,PLAYER) = type(ismember(type, TRIG.task_cue));
            
            start_time = latency(IDX+1)+lim.S(1);
            stop_time = latency(IDX+1)+lim.S(2);
            
            gaze.x = nan(f.trial, length(start_time));
            gaze.y = nan(f.trial, length(start_time));
            
            for O = 1:length(start_time)
                idx.trial = find(time >= start_time(O) & time < stop_time(O));
                gaze.x(1:length(idx.trial),O) = GAZE(idx.trial, 1);
                gaze.y(1:length(idx.trial),O) = GAZE(idx.trial, 2);
            end

            GAZEIM = round([gaze.y(:) gaze.x(:)]);
            
            gazehist = hist2d( GAZEIM, vYEdge, vXEdge );
            
            [~, center.x] = max(max(gazehist, [], 1), [], 2);
            [~, center.y] = max(max(gazehist, [], 2), [], 1);
            
            if is_recentre
                disp('recentering')
                GAZE(:,1) = GAZE(:,1) - center.x + mon.res(1)/4;
                GAZE(:,2) = GAZE(:,2) - center.y + mon.res(2)/4;
            end
            
            figure(h1)
            ax(1) = subplot(1,2,2); cla; hold on
            title('Centred Data')
            plot(GAZE(:,1))
            plot(GAZE(:,2))
            legend({'x', 'y'}, 'location', 'best')
            xlabel('Samples')
            ylabel('Pixels')
            colormap('hot')
            suptitle(str.player{PLAYER})

            
            %% post-move cue
            
            % COND = TRIG.move_cue; (IDX+1)
            
            lim.s = [0 2.5];
            lim.S = lim.s*1000000;
            f.trial = (lim.s(2) - lim.s(1))*fs;
            
            start_time = latency(IDX+1) + lim.S(1);
            stop_time = latency(IDX+1) + lim.S(2);
            
            gaze.x = nan(f.trial, length(start_time));
            gaze.y = nan(f.trial, length(start_time));
            
            for O = 1:length(start_time)
                idx.trial = find(time >= start_time(O) & time < stop_time(O));
                gaze.x(1:length(idx.trial), O) = GAZE(idx.trial, 1);
                gaze.y(1:length(idx.trial), O) = GAZE(idx.trial, 2);
            end

            GAZE_POST.x(:,:,PLAYER) = gaze.x;
            GAZE_POST.y(:,:,PLAYER) = gaze.y;
 
            GAZEIM = round([gaze.y(:) gaze.x(:)]);
            vXEdge = 1:2:mon.res(1);
            vYEdge = 1:2:mon.res(2);

            gazehist = hist2d( GAZEIM, vYEdge, vXEdge );
            GAZEHIST.post(:,:,PLAYER) = gazehist;

            figure(h2)
            subplot(2,1,PLAYER)
            imagesc(gazehist)
            colorbar
            title(str.player{PLAYER})
            colormap('hot')
            suptitle(STR.session{SESSION_COUNT})
            saveas(h1, [OUT 'recentering.' STR.session{SESSION_COUNT} '.png'])
            
        end
        
        saveas(h1, [OUT 'centreing.', STR.session{SESSION_COUNT} '.png'])

        
        %% distances - post-move cue (P1 vs. P2)

        lim.s = [0 2.5];
        f.trial = (lim.s(2) - lim.s(1))*fs;

        gaze_distance = NaN(f.trial, number_of_trials);
        
        for TRIAL = 1:number_of_trials
            for FRAME = 1:f.trial
                gaze_distance(FRAME,TRIAL) = sqrt(abs((GAZE_POST.x(FRAME,TRIAL,1)*dpp-GAZE_POST.x(FRAME,TRIAL,2)*dpp))^2 + abs((GAZE_POST.y(FRAME,TRIAL,1)*dpp-GAZE_POST.y(FRAME,TRIAL,2)*dpp))^2);
            end
        end
        
        
        asfasdfsa
        
        
        %% condition means...
        
        if all(TYPE(:,1) == TYPE(:,2))
            TYPE = type(ismember(type, TRIG.task_cue));
        else
            error('players misaligned')
        end
        
        M = NaN(2,1);
        E = NaN(2,1);
        
        for CC = 1:2
            IDX = ismember(TYPE, TRIG.task_cue(CC));
            M(CC) = nanmean(nanmean(gaze_distance(:,IDX)));
            E(CC) = nanstd(nanmean(gaze_distance(:,IDX)))/sqrt(length(IDX));
        end
        
        
        %% plot
        
        h = figure('visible', figure_visibility);
        errorbar_groups(M', E', 'bar_colors', [0.9 0.9 0.9], 'FigID', h)
        set(gca, 'xtick', 1:2, 'xticklabel', str.COND);
        xlabel('Control')
        ylabel('Post Move Cue Inter-Gaze Distance (°)')
        title(['S.' STR.session{SESSION_COUNT}])
        axis('square')
        saveas(h, [OUT 'inter-gaze-distance.S' STR.session{SESSION_COUNT} '.png'])
        
        
        %% save results
        
        results(SESSION_COUNT).control = TYPE-2;
        results(SESSION_COUNT).gaze_distance = nanmean(gaze_distance)';
        results(SESSION_COUNT).GAZE_POST = GAZE_POST;
        
    end
    
    save([OUT 'results.mat'], 'results')
    
else
    load([OUT 'results.mat'], 'results')    
end


%% distance

gaze_distance = NaN(number_of_sessions,2);

for SESSION = 1:number_of_sessions
    
    for CC = 1:2
        IDX = results(SESSION).control == CC;
        gaze_distance(SESSION,CC) = nanmean(results(SESSION).gaze_distance(IDX));
    end
end

close all

M = nanmean(gaze_distance);
E = ws_bars(gaze_distance);

h = figure('visible', figure_visibility);
errorbar_groups(M, E, 'bar_colors', [0.9 0.9 0.9], 'FigID', h)
set(gca, 'xtick', 1:2, 'xticklabel', str.COND);
xlabel('Control')
ylabel('Post Move Cue Inter-Gaze Distance (°)')
title('Grand Mean')
axis('square')
saveas(h, [OUT 'grand_mean.png'])

[h,p,ci,stats] = ttest(gaze_distance(:,1), gaze_distance(:,2))
