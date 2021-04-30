close all; clear; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ext] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

addpath('..\external')
addpath('..\common')

is_figure_visible = 'on';
is_load_fresh = true;

generate_global_variables



%% load fresh

if is_load_fresh == true

    %parpool(7)

    parfor SESSION = 1:number_of_sessions
        disp(SESSION)
        curvature_function(SESSION)
    end

end


%%

close all

RESULTS = cell(2,2);

for CC = 1:2

    clc

    group_results = NaN(number_of_sessions, 3);
    group_results2 = NaN(number_of_sessions, 3);

    if CC == 1
        COND = [1 2];
        TIT = 'Original Averaging';
    else
        COND = [2 1];
        TIT = 'Reversed Averaging';
    end
    
    for SESSION = 1:number_of_sessions

        load([OUT STR.session{SESSION} '.curvature_results.mat'], 'curvature_results', 'control') 

        group_results(SESSION,1:2) = sort(nanmean(curvature_results(control == COND(1), 1:2)), 'ascend');
        group_results(SESSION,3) = nanmean(curvature_results(control == COND(2), 3));


        %% ----- race model

        tmp = curvature_results(control == COND(1), 1:2);

        for TRIAL = 1:size(tmp,1)
           tmp(TRIAL,:) =  sort(tmp(TRIAL, :), 'ascend');
        end

        group_results2(SESSION,1:2) = nanmean(tmp);
        group_results2(SESSION,3) = nanmean(curvature_results(control == COND(2), 3));

    end

    RESULTS{CC,1} = group_results;
    RESULTS{CC,2} = group_results2;
    
    h = figure;
    
    ax = subplot(1,2,1);
    M = nanmean(group_results);
    E = ws_bars(group_results);
    errorbar_groups(M, E, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'HP' 'LP' 'Joint'}, 'FigID', h, 'AxID', ax)
    ylim([0 60])
    title('Experiment-Level Sorting')
    
    xlabel('Control')
    ylabel('Absolute Sum of Curvature (°)')

    set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

    [H,P,CI,stats] = ttest(group_results(:,1),  group_results(:,2))
    [H,P,CI,stats] = ttest(group_results(:,1),  group_results(:,3))
    [H,P,CI,stats] = ttest(group_results(:,2),  group_results(:,3))

    ax = subplot(1,2,2);
    M = nanmean(group_results2);
    E = ws_bars(group_results2);
    errorbar_groups(M, E, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'HP' 'LP' 'Joint'}, 'FigID', h,  'AxID', ax)

    xlabel('Control')
    ylabel('Absolute Sum of Curvature (°)')
    ylim([0 60])
    set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')
    title('Trial-Level Sorting')
       
    [H,P,CI,stats] = ttest(group_results2(:,1),  group_results2(:,2))
    [H,P,CI,stats] = ttest(group_results2(:,1),  group_results2(:,3))
    [H,P,CI,stats] = ttest(group_results2(:,2),  group_results2(:,3))

    suptitle(TIT)
    saveas(h, [OUT TIT '.png'])

    if CC == 1
        curvature_experiment_sorting_original = group_results;
        curvature_trial_sorting_original = group_results2;
    elseif CC == 2
        curvature_experiment_sorting_reversed = group_results;
        curvature_trial_sorting_reversed = group_results2;
    end

end

save([OUT 'results.mat'], 'group_results', 'group_results2', '-v6')
save([OUT 'curvature_results.mat'], 'curvature_experiment_sorting_original', 'curvature_trial_sorting_original', 'curvature_experiment_sorting_reversed', 'curvature_trial_sorting_reversed', '-v6')


%% trial-level data

curvature_single_trial = NaN(number_of_trials, number_of_sessions);

for SESSION = 1:number_of_sessions   
    load([OUT STR.session{SESSION} '.curvature_results.mat'], 'curvature_results', 'control') 
    curvature_single_trial(:,SESSION) = curvature_results(:,3);  
end

save([OUT 'curvature_single_trial.mat'], 'curvature_single_trial')


%% save curvature results for R Figure 2 plot

collated_curvature_results = NaN(number_of_trials, 3, number_of_sessions);
collated_control = NaN(number_of_trials, number_of_sessions);

for SESSION = 1:number_of_sessions
    load([OUT STR.session{SESSION} '.curvature_results.mat'], 'curvature_results', 'control') 
    collated_curvature_results(:,:,SESSION) = curvature_results;
    collated_control(:,SESSION) = control;
end

save([OUT 'collated_curvature_results.mat'], 'collated_curvature_results', 'collated_control', '-v6')


%%



joint = [79.58333 88.95833 78.33333 76.04167 28.12500 81.45833 80.20833 87.29167 81.25000 87.50000 90.83333 80.41667 70.00000 81.45833 83.33333 68.33333 83.54167 82.91667 90.20833 84.37500];
endpoint_displacement = [-0.11417689 -0.08029167 -0.36443501 -0.06083442 -0.35736164 -0.12477169 -0.03414030 -0.06541933 -0.15562977 -0.08564423  0.01934588 -0.09543706 -0.07852356 -0.17238765 -0.07173578 -0.10415717 -0.07119621 -0.39899607 -0.06915578 -0.19067984];


[r,p] = corr(joint', endpoint_displacement')

