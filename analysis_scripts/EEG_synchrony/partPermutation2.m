clear; clc; close all; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );

IN = {'synchrony_permutation_test\' 'synchrony\'};

addpath('..\common\')
addpath('..\external')

generate_global_variables
SRATE_EEG = 64;
synchrony_settings


%% get type

type2 = NaN( number_of_trials, number_of_players, number_of_sessions, 'single' );
ACC = NaN( number_of_trials, number_of_sessions );

for SUBJECT = 1:number_of_subjects
    
    disp(SUBJECT)
    
    [SESSION, PLAYER, STR] = generate_subject_string(SUBJECT, subject_code);
    load([IN{2} STR.SUBJECT '.epoch.' num2str(SRATE_EEG) '.mat'], 'TYPE' );
    
    type2(:,PLAYER,SESSION) = TYPE;
    
    
	%% get accuracy
    
    load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D' );
    
    acc = NaN(number_of_trials,1);
    
    for COND = 1:2
        
        IDX = data(:,D.cond) == COND;
        
        switch COND
            case 1
                p2use = 1:2;
            case 2
                p2use = 3;
        end
        
        tmp = data(IDX, D.correct(p2use) );
        
        if COND == 1
            tmp = all(tmp,2); % do mean instead?
        end
        
        acc(IDX) = tmp;
        
    end
    
     ACC(:,SESSION) = acc;
     
     
end


return

%% load single trial correlations

tic
load([IN{1} 'r4.mat'], 'r4')
toc


%% get neural coupling

e2use = find( ismember(lab,'Cz') );

type2use = type2;

res = NaN(nEpochs,2,number_of_sessions);
res2 = NaN(nEpochs,4,number_of_sessions);

for SESSION = 1:number_of_sessions

    data2use = squeeze( r4(:,SESSION,:,e2use) );
    
    res(:,:,SESSION) = grpstats( data2use,  type2(:,1,SESSION), {'mean'} )';
    res2(:,:,SESSION) = grpstats( data2use, [ type2(:,1,SESSION) ACC(:,SESSION) ], {'mean'} )';
    
end

m = nanmean(res,3);
m2 = nanmean(res2,3);


%%

close all

figure
plot(win.t,m)
ylim([-.02 +.1])
xlim([-2.5 +3])

figure
plot(win.t,m2)
ylim([-.02 +.1])
xlim([-2.5 +3])
legend({ 'S incorrect' 'S correct', 'J incorrect' 'J correct'} )


%%

[v,i] = max(m(:,2)-m(:,1));
data2use = squeeze( res2(i,:,:) )';

M = mean(data2use);
E = ws_bars(data2use);

M = [ M(1:2) ; M(3:4) ];
E = [ E(1:2) ; E(3:4) ];

close all

h = figure;
[hBar, hErrorbar] = barwitherr(E,M);
xlim( [.375 2.625] )
set(gca,'tickdir','out')
ylabel('Correlation (\Deltar)' )
xlabel('Control')
set(gca,'xticklabels', {'Solo' 'Joint' })
legend({'Error' 'Correct'},'location','northeast')

saveas(h, [ OUT 'bars.publish.eps' ] , 'epsc' )


%% SPSS

STR.cond3 = {'soloE', 'soloC', 'jointE', 'jointC'};

STR.spss = [];

for CC = 1:4
    
    STR.spss = [ STR.spss STR.cond3{CC} '\t' ] ;
end


out_name = [OUT 'accuracy.Cz.txt' ];

delete( out_name )
fid = fopen(out_name,'a+');

fprintf(fid, STR.spss);
fprintf(fid, '\n');
dlmwrite(out_name, data2use, '-append', 'delimiter', '\t');
fclose(fid);


%% coupling on each trial ...

clc

results = [];

results.control = squeeze(type2(:,1,:));
results.coupling = r4(:, :, i, e2use);
results.accuracy = ACC;

results.r = NaN(number_of_sessions, 2);
results.p = NaN(number_of_sessions, 2);

neural_coupling = NaN(number_of_sessions, 2);

for SESSION = 1:number_of_sessions

    for CC = 3:4
    
        index = find(results.control(:,SESSION) == CC);

        accuracy = results.accuracy(index, SESSION);
        coupling = results.coupling(index, SESSION);

        neural_coupling(SESSION,CC-2) = nanmean(coupling);
        
        nan_index = find(isnan(accuracy) | isnan(coupling));

        accuracy(nan_index) = [];
        coupling(nan_index) = [];

        [r, p] = corr(accuracy, coupling);
        
        results.r(SESSION,CC-2) = r;
        results.p(SESSION,CC-2) = p;
        
    end
        
end

[h, p, ci, stats] = ttest(results.r, 0)
[r, p, ci, stats] = ttest(results.r(:,1), results.r(:,2))

M = mean(results.r)
E = ws_bars(results.r)


close all
h = figure;

errorbar_groups(M, E, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)

xlabel('Control')
%ylabel('Explained Variance ({\it r}^2)')

%title('fit of linear regression')
%ylim([0.55 0.75])

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

% [hBar, hErrorbar] = barwitherr(E, M);
% hBar.FaceColor = [.75, .75, .75];
% xlim( [.375 2.625] )
% set(gca,'tickdir','out')
ylabel('Accuracy/Neural Coupling Correlation ({\itr})' )
% xlabel('Control')
% set(gca,'xticklabels', {'Solo' 'Joint' })
saveas(h, [OUT 'trial-level correlations.png'])


%saveas(h, [ OUT 'bars.publish.eps' ] , 'epsc' )

accuracy_neural = results.r;
[h,p,ci,stats] = ttest(accuracy_neural(:,1),accuracy_neural(:,2))


save([OUT 'results.mat'], 'results')


%%

results2 = load('..\behavioural_performance\accuracy3\results.mat');
results2 = results2.results;

results2.r = NaN(number_of_sessions, 2);
results2.p = NaN(number_of_sessions, 2);

behavioural_coupling = NaN(number_of_sessions, 2);

for SESSION = 1:number_of_sessions

    for CC = 3:4
    
        index = find(results.control(:,SESSION) == CC);

        accuracy = results2.behavioral_coupling(index, SESSION);
        coupling = results.coupling(index, SESSION);

        behavioural_coupling(SESSION,CC-2) = nanmean(accuracy);
        
        nan_index = find(isnan(accuracy) | isnan(coupling));

        accuracy(nan_index) = [];
        coupling(nan_index) = [];

        [r, p] = corr(accuracy, coupling);
        
        results2.r(SESSION,CC-2) = r;
        results2.p(SESSION,CC-2) = p;
        
    end
        
end


%

disp('*************************************')

[h, p, ci, stats] = ttest(results2.r, 0)
[r, p, ci, stats] = ttest(results2.r(:,1), results2.r(:,2))

M = mean(results2.r)
E = ws_bars(results2.r)

close all
h = figure;

errorbar_groups(M, E, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)

xlabel('Control')
%ylabel('Explained Variance ({\it r}^2)')

%title('fit of linear regression')
%ylim([0.55 0.75])

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

% [hBar, hErrorbar] = barwitherr(E, M);
% hBar.FaceColor = [.75, .75, .75];
% xlim( [.375 2.625] )
% set(gca,'tickdir','out')
ylabel('Behavioural/Neural Coupling Correlation ({\itr})' )
% xlabel('Control')
% set(gca,'xticklabels', {'Solo' 'Joint' })

saveas(h, [OUT 'trial-level correlations 2.png'])


behavioural_neural = results2.r;
[h,p,ci,stats] = ttest(behavioural_neural(:,1),behavioural_neural(:,2))


%%


results2 = load('..\behavioural_performance\accuracy3\results.mat');
results2 = results2.results;

results2.r = NaN(number_of_sessions, 2);
results2.p = NaN(number_of_sessions, 2);

behavioural_coupling = NaN(number_of_sessions, 2);

for SESSION = 1:number_of_sessions

    for CC = 3:4
    
        index = find(results.control(:,SESSION) == CC);

        accuracy = results2.behavioral_coupling(index, SESSION);
        coupling = ACC(index,SESSION);

        %behavioural_coupling(SESSION,CC-2) = nanmean(accuracy);
        
        nan_index = find(isnan(accuracy) | isnan(coupling));

        accuracy(nan_index) = [];
        coupling(nan_index) = [];

        [r, p] = corr(accuracy, coupling);
        
        results2.r(SESSION,CC-2) = r;
        results2.p(SESSION,CC-2) = p;
        
    end
        
end


%

disp('*************************************')

[h, p, ci, stats] = ttest(results2.r, 0)
[r, p, ci, stats] = ttest(results2.r(:,1), results2.r(:,2))

M = mean(results2.r)
E = ws_bars(results2.r)

close all
h = figure;

errorbar_groups(M, E, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)

xlabel('Control')
%ylabel('Explained Variance ({\it r}^2)')

%title('fit of linear regression')
%ylim([0.55 0.75])

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

% [hBar, hErrorbar] = barwitherr(E, M);
% hBar.FaceColor = [.75, .75, .75];
% xlim( [.375 2.625] )
% set(gca,'tickdir','out')
ylabel('Accuracy/Behavioural Coupling Correlation ({\itr})' )
% xlabel('Control')
% set(gca,'xticklabels', {'Solo' 'Joint' })

saveas(h, [OUT 'trial-level correlations 2a.png'])


%%

load('D:\JOINT.ACTION\JointActionRevision\analysis\behavioural_performance\curvature_runner\curvature_single_trial.mat')

results2 = load('..\behavioural_performance\accuracy3\results.mat');
results2 = results2.results;

results2.r = NaN(number_of_sessions, 2);
results2.p = NaN(number_of_sessions, 2);

behavioural_coupling = NaN(number_of_sessions, 2);

for SESSION = 1:number_of_sessions

    for CC = 3:4
    
        index = find(results.control(:,SESSION) == CC);

        accuracy = results2.behavioral_coupling(index, SESSION);
%         coupling = results.coupling(index, SESSION);
        coupling = curvature_single_trial(index,SESSION);

        behavioural_coupling(SESSION,CC-2) = nanmean(accuracy);
        
        nan_index = find(isnan(accuracy) | isnan(coupling));

        accuracy(nan_index) = [];
        coupling(nan_index) = [];

        [r, p] = corr(accuracy, coupling);
        
        results2.r(SESSION,CC-2) = r;
        results2.p(SESSION,CC-2) = p;
        
    end
        
end


%

disp('*************************************')

[h, p, ci, stats] = ttest(results2.r, 0)
[r, p, ci, stats] = ttest(results2.r(:,1), results2.r(:,2))

M = mean(results2.r)
E = ws_bars(results2.r)

close all
h = figure;

errorbar_groups(M, E, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)

xlabel('Control')
%ylabel('Explained Variance ({\it r}^2)')

%title('fit of linear regression')
%ylim([0.55 0.75])

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

% [hBar, hErrorbar] = barwitherr(E, M);
% hBar.FaceColor = [.75, .75, .75];
% xlim( [.375 2.625] )
% set(gca,'tickdir','out')
ylabel('Behavioural Coupling/Curvature Correlation ({\itr})' )
% xlabel('Control')
% set(gca,'xticklabels', {'Solo' 'Joint' })

saveas(h, [OUT 'trial-level correlations 3.png'])



%%


load('D:\JOINT.ACTION\JointActionRevision\analysis\behavioural_performance\curvature_runner\curvature_single_trial.mat')

results2 = load('..\behavioural_performance\accuracy3\results.mat');
results2 = results2.results;

results2.r = NaN(number_of_sessions, 2);
results2.p = NaN(number_of_sessions, 2);

behavioural_coupling = NaN(number_of_sessions, 2);

for SESSION = 1:number_of_sessions

    for CC = 3:4
    
        index = find(results.control(:,SESSION) == CC);

        %accuracy = results2.behavioral_coupling(index, SESSION);
        accuracy = results.coupling(index, SESSION);
        coupling = curvature_single_trial(index,SESSION);

        behavioural_coupling(SESSION,CC-2) = nanmean(accuracy);
        
        nan_index = find(isnan(accuracy) | isnan(coupling));

        accuracy(nan_index) = [];
        coupling(nan_index) = [];

        [r, p] = corr(accuracy, coupling);
        
        results2.r(SESSION,CC-2) = r;
        results2.p(SESSION,CC-2) = p;
        
    end
        
end


%

disp('*************************************')

[h, p, ci, stats] = ttest(results2.r, 0)
[r, p, ci, stats] = ttest(results2.r(:,1), results2.r(:,2))

M = mean(results2.r)
E = ws_bars(results2.r)

close all
h = figure;

errorbar_groups(M, E, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)

xlabel('Control')
%ylabel('Explained Variance ({\it r}^2)')

%title('fit of linear regression')
%ylim([0.55 0.75])

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

% [hBar, hErrorbar] = barwitherr(E, M);
% hBar.FaceColor = [.75, .75, .75];
% xlim( [.375 2.625] )
% set(gca,'tickdir','out')
ylabel('Neural Coupling/Curvature Correlation ({\itr})' )
% xlabel('Control')
% set(gca,'xticklabels', {'Solo' 'Joint' })

saveas(h, [OUT 'trial-level correlations 4.png'])




%% ----- Accuracy/Curvature Correlation


load('D:\JOINT.ACTION\JointActionRevision\analysis\behavioural_performance\curvature_runner\curvature_single_trial.mat')

results2 = load('..\behavioural_performance\accuracy3\results.mat');
results2 = results2.results;

results2.r = NaN(number_of_sessions, 2);
results2.p = NaN(number_of_sessions, 2);

behavioural_coupling = NaN(number_of_sessions, 2);

for SESSION = 1:number_of_sessions

    for CC = 3:4
    
        index = find(results.control(:,SESSION) == CC);

        accuracy = ACC(index, SESSION);
        %accuracy = results.coupling(index, SESSION);
        coupling = curvature_single_trial(index,SESSION);

        behavioural_coupling(SESSION,CC-2) = nanmean(accuracy);
        
        nan_index = find(isnan(accuracy) | isnan(coupling));

        accuracy(nan_index) = [];
        coupling(nan_index) = [];

        [r, p] = corr(accuracy, coupling);
        
        results2.r(SESSION,CC-2) = r;
        results2.p(SESSION,CC-2) = p;
        
    end
        
end


%

disp('*************************************')

[h, p, ci, stats] = ttest(results2.r, 0)
[r, p, ci, stats] = ttest(results2.r(:,1), results2.r(:,2))

M = mean(results2.r)
E = ws_bars(results2.r)

close all
h = figure;

errorbar_groups(M, E, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)

xlabel('Control')
%ylabel('Explained Variance ({\it r}^2)')

%title('fit of linear regression')
%ylim([0.55 0.75])

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

% [hBar, hErrorbar] = barwitherr(E, M);
% hBar.FaceColor = [.75, .75, .75];
% xlim( [.375 2.625] )
% set(gca,'tickdir','out')
ylabel('Accuracy/Curvature Correlation ({\itr})' )
% xlabel('Control')
% set(gca,'xticklabels', {'Solo' 'Joint' })

saveas(h, [OUT 'trial-level correlations 5.png'])





%%





save([OUT 'single_trial_correlations_accuracy_behavioral_neural.mat'], 'accuracy_neural', 'behavioural_neural', '-v6')
save([OUT 'coupling.mat'], 'behavioural_coupling', 'neural_coupling', '-v6')
