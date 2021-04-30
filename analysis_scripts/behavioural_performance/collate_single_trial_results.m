close all; clear; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ext] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = '..\data_manager\CheckFiles2\';
load( [IN 'fname.mat'] )
fname.behave( cellfun( @isempty, fname.behave ) ) = [];

addpath('..\external')
addpath('..\common')

generate_global_variables


%% endpoint accuracy

load('endpoint_accuracy\results.mat', 'results');


%% get single trial accuracy...

results_new = struct('accuracy', cell(number_of_sessions,1));

for SESSION = 1:number_of_sessions

    disp(SESSION)
    load([fname.direct_behav fname.behave{SESSION}], 'data', 'D')
    
    results_new(SESSION).accuracy = data(:,D.correct);
    results_new(SESSION).MT = data(:,D.MT);
    results_new(SESSION).RT = data(:,D.RT);
    
end

is_use_python = true;

if ~is_use_python
    tmp = load('..\eye_tracking\eye_single_trial\results.mat'); % inter-gaze distance
    results_eye = tmp.results; clear tmp;
else
    tmp = load('..\python_analysis\eye_single_trial\gaze_results.mat'); % inter-gaze distance
	
    results_eye = struct('control', cell(number_of_sessions,1), ...
                         'endpoint_displacement', cell(number_of_sessions,1));
    
    for SESSION = 1:number_of_sessions
        results_eye(SESSION).control = tmp.control(:,SESSION);
        results_eye(SESSION).gaze_distance = tmp.gaze_distance(:,SESSION);
    end
    
end

tmp = load('..\behavioural_performance\accuracy3\results.mat'); % behavioral coupling
behavioral_coupling = tmp.results.behavioral_coupling; clear tmp


% ----- endpoint displacement & curvature

number_of_control = 2;

perm_results = load(['..\EEG_synchrony\partPermutation2\results.mat'], 'results'); % neural coupling

tmp = load('..\EEG_task_cue\task_cue_single_trial/task_cue_single_trial.mat');
task_cue_single_trial = tmp.task_cue_single_trial;

neural_coupling = perm_results.results.coupling;

accuracy = NaN(number_of_trials, number_of_sessions);
MT = NaN(number_of_trials, number_of_sessions);
RT = NaN(number_of_trials, number_of_sessions);
curvature = NaN(number_of_trials, number_of_sessions);
endpoint_displacement = NaN(number_of_trials, number_of_sessions);
gaze_distance = NaN(number_of_trials, number_of_sessions);
%behavioral_coupling
%task_cue_single_trial

CONTROL = NaN(number_of_trials, number_of_sessions);

r_displacement = NaN(number_of_sessions, number_of_control);
r_curvature = NaN(number_of_sessions, number_of_control);
r_accuracy = NaN(number_of_sessions, number_of_control);
r_MT = NaN(number_of_sessions, number_of_control);
r_RT = NaN(number_of_sessions, number_of_control);
r_gaze_distance = NaN(number_of_sessions, number_of_control);
r_behavioral_coupling = NaN(number_of_sessions, number_of_control);
r_task_cue_single_trial = NaN(number_of_sessions, number_of_control);

exclude_gaze_sessions = [0, 1, 2] + 1;

for SESSION = 1:number_of_sessions
    
    disp(SESSION)
    load(['curvature_runner\' STR.session{SESSION} '.curvature_results.mat'], 'curvature_results', 'control')

	% check eye alignment
    
    if all(isnan(results_eye(SESSION).control))
        warning('missing eye data')
    else
        if ~all(results(SESSION).control == results_eye(SESSION).control)
            error('eye misaligned')
        end
        
        if ~ismember(SESSION, exclude_gaze_sessions) % keep NaNs for those sessions
            gaze_distance(:,SESSION) = results_eye(SESSION).gaze_distance;
        end
    end   

    if ~all(results(SESSION).control == tmp.control(:,SESSION))
        error('misaligned')
    end
    
    % extract variables...
    
    for TRIAL = 1:number_of_trials
        if results(SESSION).control(TRIAL) == 1
            endpoint_displacement(TRIAL,SESSION) = nanmean(results(SESSION).endpoint_displacement(TRIAL, 1:2));
            curvature(TRIAL,SESSION) = nanmean(curvature_results(TRIAL, 1:2));
            accuracy(TRIAL,SESSION) = nanmean(results_new(SESSION).accuracy(TRIAL, 1:2));
            MT(TRIAL,SESSION) = nanmean(results_new(SESSION).MT(TRIAL, 1:2));
            RT(TRIAL,SESSION) = nanmean(results_new(SESSION).RT(TRIAL, 1:2));
        else
            endpoint_displacement(TRIAL,SESSION) = results(SESSION).endpoint_displacement(TRIAL, 3);
            curvature(TRIAL,SESSION) = curvature_results(TRIAL, 3);
            accuracy(TRIAL,SESSION) = results_new(SESSION).accuracy(TRIAL, 3);
            MT(TRIAL,SESSION) = results_new(SESSION).MT(TRIAL, 3);
            RT(TRIAL,SESSION) = results_new(SESSION).RT(TRIAL, 3);
        end
    end
    
    % correlate with neural coupling
    
    for CC = 1:number_of_control
        
        [r_displacement(SESSION, CC), ~] = corr(perm_results.results.coupling(results(SESSION).control == CC, SESSION), endpoint_displacement(results(SESSION).control == CC, SESSION), 'rows','complete');
        [r_curvature(SESSION, CC), ~] = corr(perm_results.results.coupling(results(SESSION).control == CC, SESSION), curvature(results(SESSION).control == CC, SESSION), 'rows','complete');
        [r_accuracy(SESSION, CC), ~] = corr(perm_results.results.coupling(results(SESSION).control == CC, SESSION), accuracy(results(SESSION).control == CC, SESSION), 'rows','complete');
        [r_MT(SESSION, CC), ~] = corr(perm_results.results.coupling(results(SESSION).control == CC, SESSION), MT(results(SESSION).control == CC, SESSION), 'rows','complete');
        [r_RT(SESSION, CC), ~] = corr(perm_results.results.coupling(results(SESSION).control == CC, SESSION), RT(results(SESSION).control == CC, SESSION), 'rows','complete');
        [r_gaze_distance(SESSION, CC), ~] = corr(perm_results.results.coupling(results(SESSION).control == CC, SESSION), gaze_distance(results(SESSION).control == CC, SESSION), 'rows','complete');
        [r_behavioral_coupling(SESSION, CC), ~] = corr(perm_results.results.coupling(results(SESSION).control == CC, SESSION), behavioral_coupling(results(SESSION).control == CC, SESSION), 'rows','complete');
        
        [r_task_cue_single_trial(SESSION, CC), ~] = corr(perm_results.results.coupling(results(SESSION).control == CC, SESSION), task_cue_single_trial(results(SESSION).control == CC, SESSION), 'rows','complete');
        
    end
    
    CONTROL(:,SESSION) = results(SESSION).control;
    
end


%% -----


str_measure = {'Accuracy', 'RT', 'MT', 'Cuvature', 'Displacement', 'Gaze Distance', 'Behavioral Coupling', 'Task Cue'};
measure = cat(3, r_accuracy, r_RT, r_MT, r_curvature, r_displacement, r_gaze_distance, r_behavioral_coupling, r_task_cue_single_trial);

close all

x = 1;
y = 1;

for MM = 1:size(measure,3)

    disp('***********************************')
    disp(str_measure)
    r = measure(:,:,MM);
    
    [h, p, ci, stats] = ttest(r, 0)
    
    p_values = p;
    
    [h, p, ci, stats] = ttest(r(:,1), r(:,2))
    
    p_values = [p_values p];
    p_string = [];
    
    for P = 1:3
        p_string{P} = sprintf('%.3f', p_values(P));
    end
        
    M = nanmean(r);
    E = ws_bars(r);

    h = figure;
    errorbar_groups(M, E, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)
    xlabel('Control')
    set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')
    ylabel('Correlation with Neural Coupling')
    title(str_measure{MM})
    ylim([-0.10847384173267931, 0.10847384173267931])
    
    for P = 1:2
        text(P, M(P), p_string{P})
    end
    
    text(1.5, mean(M), p_string(3))   
    saveas(h, [OUT 'Neural_' str_measure{MM} '.png'])
    
    IM{y, x} = imread([OUT 'Neural_' str_measure{MM} '.png']);
    
    x = x + 1;
    
    if x == 3
        x = 1;
        y = y + 1;
    end
    
end

imwrite(cell2mat(IM), [OUT 'single_trial_correlations.png'])


% accuracy (DONE), MT (DONE), RT (DONE), curvature (DONE), endpoint displacement (DONE), behavioural coupling - offsets (DONE), inter-gaze distance (DONE), control cue SSVEP

save([OUT 'r_results.mat'], 'r_accuracy', 'r_RT', 'r_MT', 'r_curvature', 'r_displacement', 'r_gaze_distance' , 'r_behavioral_coupling', 'r_task_cue_single_trial', '-v6')
save([OUT 'single_trial_measures.mat'], 'neural_coupling', 'accuracy', 'MT', 'RT', 'curvature', 'endpoint_displacement', 'gaze_distance', 'behavioral_coupling', 'task_cue_single_trial', 'CONTROL', '-v6')