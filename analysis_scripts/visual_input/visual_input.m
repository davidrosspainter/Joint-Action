close all; clear; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ext] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = '..\data_manager\CheckFiles2\';
load( [IN 'fname.mat'] )

addpath('..\external')
addpath('..\common')

is_figure_visible = 'off';
is_load_fresh = true;
is_visualise = false;

generate_global_variables


%% ---- load trial correlation matrix

disp('loading trial correlation matrix...')

tic
load('..\EEG_synchrony\generate_trial_correlation_matrix\r4.mat', 'r4')
toc

% beware - depends on SRATE_EEG
load('..\EEG_synchrony\generate_trial_correlation_matrix\i.mat', 'i') % index of peak correlation


%% ----- draw

if is_visualise

    addpath('..\external\Cogent2000v1.33\Toolbox\')
    cgopen(1000, 1000, 0, 144, 0)

    colors = {[1 0 0], [0 1 0], [0 1 1]};
    cgpenwid(2)

    cgfont('Lucida Console', sizes.font)
    cgpencol(1,1,1)

    speed_multipler = 5; % integer 1 or greater

end


%% outcome variables

R = [];
P = [];


%% analyse

STR.control = {'Solo' 'Joint'};


for SESSION = 1:number_of_sessions

    % ---- load session behavioural data...
    
    disp('****************************')
    disp(num2str(SESSION))

    load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer', 'array', 'sizes');



    %% ----- calculate

    DISTANCE.results = cell(n.trials,1); % distance between cursors represents degree of visual similarity on joint trials
    DISTANCE.max = NaN(n.trials,1);
    DISTANCE.mean = NaN(n.trials,1);

    for TRIAL = 1:n.trials

        %disp([num2str(TRIAL) '.' str.cond{data(TRIAL,D.cond)}])

        last_frame = find(isnan(cursor.xy(1, :, TRIAL, 1)),1,'first')-1;

        if isempty(last_frame)
            last_frame = f.trial_max;
        end

        distance_results = NaN(last_frame,1);

        for FRAME = 1:last_frame

            distances = diff(squeeze(cursor.xy(:, FRAME, TRIAL, :)),[],2);
            

            
            distances = distances(:,1);

            distances = sqrt( distances(1)^2 + distances(2)^2 );
            distance_results(FRAME) = distances;


            %% ----- draw

            if is_visualise

                if (fix(FRAME/speed_multipler)==FRAME/speed_multipler)

                    str.player{3} = 'Joint';

                    cgdraw( cursor.xy(1, FRAME, TRIAL, 1), ...
                            cursor.xy(2, FRAME, TRIAL, 1), ...
                            cursor.xy(1, FRAME, TRIAL, 2), ...
                            cursor.xy(2, FRAME, TRIAL, 2) )
                        
                    cgtext(['ICD = ' num2str(round(distances)) ],mean(cursor.xy(1, FRAME, TRIAL, :)),mean(cursor.xy(2, FRAME, TRIAL, :)))
                    
                    for PLAYER = 1:n.player+1
                        X = cursor.xy(1, FRAME, TRIAL, PLAYER);
                        Y = cursor.xy(2, FRAME, TRIAL, PLAYER);
                        cgellipse(X, Y, sizes.cursor, sizes.cursor, colors{PLAYER}, 'f')
                        
                        cgtext(str.player{PLAYER}, X, Y+30)
                        
                    end

                    for position = 1:n.positions
                        cgellipse(array.x(position), array.y(position), sizes.target, sizes.target, [1 1 1]) % radius =  292.0774
                    end

                    cgtext(['Pair Number = ' num2str(SESSION)], 0, 450)
                    cgtext(['Trial = ' num2str(TRIAL) ', Control = ' STR.control{data(TRIAL,D.cond)}], 0, 400)                    
                    cgtext(['Time = ' num2str(FRAME/mon.ref) ' s'], 0, 350)                    
                    
                    
                    %YY = [-300 -350 -400]-50;
                    
                    
                    
%                     for PLAYER = 1:n.player+1
%                         cgellipse(-450, YY(PLAYER), sizes.cursor, sizes.cursor, colors{PLAYER}, 'f')                        
%                     end
                    
                    cgflip(0,0,0)

                end

            end

        end

        DISTANCE.results{TRIAL} = distance_results;
        DISTANCE.max(TRIAL) = nanmax(distance_results);
        DISTANCE.mean(TRIAL) = nanmean(distance_results);

    %     figure(1); cla
    %     plot(distance_results)
    %     drawnow

    end

    % figure(1); cla; hold on
    % plot(DISTANCE.max, 'r')
    % plot(DISTANCE.mean)
    %  
    % %%
    % 
    % figure;
    % [M, E] = grpstats(DISTANCE.max,data(:,D.cond),{'mean' 'sem'});
    % errorbar(M,E)

    e2use = find( ismember(lab,'Cz') );
    synchrony = r4(:, SESSION, i, e2use);

    IDX = data(:,D.cond) == 1; % solo trials

    [r(1), p(1)] = corr(DISTANCE.max(IDX), synchrony(IDX), 'rows', 'complete');
    [r(2), p(2)] = corr(DISTANCE.mean(IDX), synchrony(IDX), 'rows', 'complete');

    IDX = data(:,D.cond) == 2; % solo trials

    [r(3), p(3)] = corr(DISTANCE.max(IDX), synchrony(IDX), 'rows', 'complete');
    [r(4), p(4)] = corr(DISTANCE.mean(IDX), synchrony(IDX), 'rows', 'complete');

    R = [R; r];
    P = [P; p];

    
   
    %% visual similarity on solo correct vs. incorrect trials...
    
    IDX = data(:,D.cond) == 1 & sum(data(:,D.correct(1:2)),2) == 2; % solo, both correct
    soloInput(SESSION,1) = nanmean(DISTANCE.max(IDX));
    
    IDX = data(:,D.cond) == 1 & sum(data(:,D.correct(1:2)),2) ~= 2; % solo, not both correct
    soloInput(SESSION,2) = nanmean(DISTANCE.max(IDX));
    
    
    
    %% motoric similarity on joint correct vs. incorrect trials...
    
    IDX = data(:,D.cond) == 2 & data(:,D.correct(3)); % joint correct
    jointInput(SESSION,1) = nanmean(DISTANCE.max(IDX));
    
    IDX = data(:,D.cond) == 2 & ~data(:,D.correct(3)); % joint incorrect
    jointInput(SESSION,2) = nanmean(DISTANCE.max(IDX));
    
    
end



%% Correlation Between Inter-Cursor Distance &' 'Inter-Brain Neural Correlations

close all
hf = figure; cla; hold on

M = mean(R(:,[1 3]));
E = ws_bars(R(:,[1 3]));

barwitherr(E, M, 'facecolor', [.75 .75 .75], 'barwidth', .5); hold on

rng(0)

for CC = 1:n.cond
    scatter( CC*ones(number_of_sessions,1)+(rand(number_of_sessions,1)*2-1)*.1, sort(R(:,CC)), [], 'k')
end

set(gca,'box','off')
set(gca,'tickdir','out', 'fontsize', 8)
set(gca, 'xtick', 1:2, 'xticklabel', {'Solo', 'Joint'}, 'fontsize', 10)
xlabel('Control', 'fontsize', 12)
ylabel({'Correlation Between Inter-Cursor Distance &' 'Inter-Brain Neural Correlations ({\itr})'}, 'fontsize', 12)


[h, p, ci, stats] = ttest(R(:,1), R(:,3))

text(1.5,-.08,['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

[h, p, ci, stats] = ttest( R(:,1), 0)

text(1.25,-.04,['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

[h, p, ci, stats] = ttest( R(:,3), 0)
text(2.3,-.07,['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

line([1 2],[-.09 -.09], 'color', 'k')

TIT = 'Effect of Visual Input';
suptitle(TIT)
saveas(hf, [OUT TIT '.png'])


%% visual similarity on solo correct vs. incorrect trials...

dataToUse = soloInput;

hf = figure; cla; hold on

M = mean(dataToUse);
E = ws_bars(dataToUse);

barwitherr(E, M, 'facecolor', [.75 .75 .75], 'barwidth', .5); hold on

rng(0)

for CC = 1:n.cond
    scatter( CC*ones(number_of_sessions,1)+(rand(number_of_sessions,1)*2-1)*.1, sort(dataToUse(:,CC)), [], 'k')
end

set(gca,'box','off')
set(gca,'tickdir','out', 'fontsize', 8)
set(gca, 'xtick', 1:2, 'xticklabel', {'Both Correct', 'Not Both Correct'}, 'fontsize', 10)
xlabel('Accuracy on Solo Trials', 'fontsize', 12)
ylabel({'Maximum Inter-Cursor Distance (Pixels)'}, 'fontsize', 12)


[h, p, ci, stats] = ttest(dataToUse(:,1), dataToUse(:,2))

text(1.5, mean(dataToUse(:)),['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

[h, p, ci, stats] = ttest( dataToUse(:,1), 0)

text(1.25 ,mean(dataToUse(:,1)),['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

[h, p, ci, stats] = ttest( dataToUse(:,2), 0)
text(2.3,mean(dataToUse(:,2)),['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

line([1 2],[-.09 -.09], 'color', 'k')

TIT = 'Visual Similarity';
suptitle(TIT)
saveas(hf, [OUT TIT '.png'])


%% motoric similarity on joint correct vs. incorrect trials

dataToUse = jointInput;


hf = figure; cla; hold on

M = mean(dataToUse);
E = ws_bars(dataToUse);

barwitherr(E, M, 'facecolor', [.75 .75 .75], 'barwidth', .5); hold on

rng(0)

for CC = 1:n.cond
    scatter( CC*ones(number_of_sessions,1)+(rand(number_of_sessions,1)*2-1)*.1, sort(dataToUse(:,CC)), [], 'k')
end

set(gca,'box','off')
set(gca,'tickdir','out', 'fontsize', 8)
set(gca, 'xtick', 1:2, 'xticklabel', {'Correct', 'Incorrect'}, 'fontsize', 10)
xlabel('Accuracy on Joint Trials', 'fontsize', 12)
ylabel({'Maximum Inter-Cursor Distance (Pixels)'}, 'fontsize', 12)


[h, p, ci, stats] = ttest(dataToUse(:,1), dataToUse(:,2))

text(1.5, mean(dataToUse(:)),['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

[h, p, ci, stats] = ttest( dataToUse(:,1), 0)

text(1.25 ,mean(dataToUse(:,1)),['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

[h, p, ci, stats] = ttest( dataToUse(:,2), 0)
text(2.3,mean(dataToUse(:,2)),['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

line([1 2],[-.09 -.09], 'color', 'k')

TIT = 'Motoric Similarity';
suptitle(TIT)
saveas(hf, [OUT TIT '.png'])



%%

save([OUT 'input.mat'], 'soloInput', 'jointInput', '-v7')