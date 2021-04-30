%% ----- TASK CUE!

close all; clear; clc; restoredefaultpath

addpath('..\external\')
addpath('..\external\morlet_transform_hack')
addpath('..\external\topoplot_hack')

addpath('..\common\')

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );

generate_global_variables
subject_code = generate_subject_code();

SRATE_EEG = 256; fs = SRATE_EEG;
taskCueSettings

is_save_ERP = false;


%% get critical timepoint...

load('task_cue_group2\BEST.mat', 'BEST')
timepoint = load('taskCuePerm\peak_time_point.mat', 't', 'i'); % t = 1.1484, i = 295

return

%% task_cue2

if is_save_ERP
    ERP = single(NaN(n.x, number_of_channels, 2, number_of_subjects));
    AMP = single(NaN(n.x, number_of_channels, 2, number_of_subjects));

    CONTROL = NaN(number_of_trials, number_of_subjects);
    IS_MISSING = NaN(number_of_trials, number_of_subjects);
    IS_REJECTED = NaN(number_of_trials, number_of_subjects);
end
    
results = struct('control', cell(number_of_subjects,1), ...
                 'wavelet_amplitude', cell(number_of_subjects,1), ...
                 'SESSION', cell(number_of_subjects,1), ...
                 'SUBJECT', cell(number_of_subjects,1), ...
                 'PLAYER', cell(number_of_subjects,1));

for SUBJECT = 1:number_of_subjects
    
    %% ----- load data
    
    disp('*****************************************')
    disp(SUBJECT)

    IN = ['..\EEG_preprocessing\check_alignment3\SRATE_EEG_' num2str(SRATE_EEG) '\'];
    [SESSION, PLAYER, STR] = generate_subject_string(SUBJECT, generate_subject_code);
    
    results(SUBJECT).SUBJECT = SUBJECT;
    results(SUBJECT).SESSION = SESSION;
    results(SUBJECT).PLAYER = PLAYER;
    
    USE_THIS = [ IN STR.SUBJECT '.EEG.mat' ];
    disp( ['loading...' USE_THIS] )
    
    tic
    load( USE_THIS, 'EEG_RS', 'trig', 'estimatedAlignmentError', 'eyeLatency', 'SRATE_EEG' )
    toc
    
    
    %% ----- epoch data
    
    TYPE = trig.type(:,T.task_cue);
    LATENCY = trig.latency(:,T.task_cue);

    if length(TYPE) ~= number_of_trials
        error('misalignment')
    end
    
    is_missing = false(number_of_trials,1);
    is_rejected = false(number_of_trials,1);
    
    start = round(LATENCY + lim.x(1));
    stop = round(LATENCY + lim.x(2));

    epoch = NaN(n.x, number_of_channels, number_of_trials);
    results(SUBJECT).wavelet_amplitude = NaN(number_of_trials,1);
    
    for TRIAL = 1:number_of_trials
        if ~isnan(start(TRIAL))
            data = EEG_RS(start(TRIAL):stop(TRIAL),:);
            data = detrend(data, 'linear');
            data = data - repmat(data(t == 0,:), size(data,1), 1);

            if ~any(abs(data(:)) > 100)
                epoch(:,:,TRIAL) = data;
                P = morlet_transform(nanmean(data(:,BEST),2), t, 7, fc, FWHM_tc, squared);
                wAMP = abs( squeeze( P(1,:,:) ) ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT
                results(SUBJECT).wavelet_amplitude(TRIAL) = wAMP(timepoint.i);
            else
                is_rejected(TRIAL) = true;
            end
        else
            is_missing(TRIAL) = true;
        end
    end
    
    results(SUBJECT).control = TYPE - 2;
    
    
    %% ----- save ERP
    
    if is_save_ERP
    
        close all
        h = figure('visible', 'off');

        for CC = 1:2
            ERP(:,:,CC,SUBJECT) = nanmean(epoch(:,:,control==CC),3);

            amp = abs( fft( ERP(:,:,CC,SUBJECT) ) )/n.x;
            amp(2:end-1,:) = amp(2:end-1,:)*2; % double amplitudes

            AMP(:,:,CC,SUBJECT) = amp;

            subplot(2,1,CC)
            imagesc(ERP(:,:,CC,SUBJECT)')
            colormap('gray')
        end

        saveas(h, [OUT 'ERP.' STR.SUBJECT '.png'])

        CONTROL(:,SESSION) = control;
        IS_MISSING(:,SESSION) = is_missing;
        IS_REJECTED(:,SESSION) = is_rejected;

        save([OUT 'ERP_AMP.mat'], 'ERP', 'ANP', 'CONTROL', 'IS_MISSING', 'IS_REJECTED') 
        
    end
    
end


%% get average task cue amplitude across players for each session

task_cue_single_trial = NaN(number_of_trials, number_of_sessions);
task_cue_mean = NaN(number_of_sessions,2);
control = NaN(number_of_trials, number_of_sessions);

subject_code = generate_subject_code;

for SESSION = 1:number_of_sessions
    
    tmp1 = NaN(number_of_trials,2);
    tmp2 = NaN(number_of_trials,2);
    
    for PLAYER = 1:number_of_players
        SUBJECT = subject_code(subject_code(:,2) == SESSION & subject_code(:,3) == PLAYER, 1);
        
        disp([results(SUBJECT).SUBJECT results(SUBJECT).SESSION results(SUBJECT).PLAYER])
        
        tmp1(:,PLAYER) = results(SUBJECT).wavelet_amplitude;
        tmp2(:,PLAYER) = results(SUBJECT).control;
    end
    
    if tmp2(:,1) ~= tmp2(:,2)
        error('misaligned!')
    else
        control(:,SESSION) = tmp2(:,1);
    end
    
    task_cue_single_trial(:,SESSION) = nanmean(tmp1,2);
    
    for CC = 1:2
        task_cue_mean(SESSION,CC) = nanmean(task_cue_single_trial(control(:,SESSION) == CC,SESSION));
    end
end
    
    
%%

h = figure();
errorbar_groups(mean(task_cue_mean), ws_bars(task_cue_mean), 'bar_colors', [0.9 0.9 0.9], 'FigID', h)
set(gca, 'xtick', 1:2, 'xticklabel', {'solo', 'joint'});
xlabel('Control')
ylabel('Wavelet Amplitude (uV)')
axis('square')
saveas(h, [OUT 'wavelet_amplitude.png'])

[h,p,ci,stats] = ttest(task_cue_mean(:,1), task_cue_mean(:,2))

save([OUT 'task_cue_single_trial.mat'], 'task_cue_single_trial', 'control')
