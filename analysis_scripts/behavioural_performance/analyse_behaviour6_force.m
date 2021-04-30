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

number_of_sessions = 20;
number_players = 2;


%%

results.synchrony_M = NaN(number_of_sessions, 2);
results.synchrony_E = NaN(number_of_sessions, 2);
results.accuracyComparison = [];

FORCE = [];
RT = [];
RTSD = [];

if is_load_fresh
    for SESSION = 1:number_of_sessions
              
        disp('****************************')
        disp(num2str(SESSION))
        STR.SESSION = sess_string_gen(SESSION);
        load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer');
        
        
        %% ----- accuracy comparison - signal averaging cooperation trials
        
        IDX = data(:,D.cond) == 1;
        data2use = data(IDX, D.correct);
        results.accuracyComparison = [results.accuracyComparison; nanmean(data2use)];
        
        
        %% ----- calculate force
        
        force = NaN( f.trial_max, n.cursors, n.trials);
        
        for CURSOR = 1:n.cursors
            for TRIAL = 1:n.trials
                
                disp( [ CURSOR TRIAL ] )
                
                for FRAME = 1:f.trial_max
                    
                    ThumbX = cursor.thumb(1, FRAME, TRIAL, CURSOR);
                    ThumbY = cursor.thumb(2, FRAME, TRIAL, CURSOR);
                    DIST = sqrt( ThumbX.^2 + ThumbY.^2 );
                    
                    if DIST > 1; DIST = 1; end
                    force(FRAME,CURSOR,TRIAL) = DIST;
                end
            end
        end
        
        
        %% correlation of forces between the two players
        
        force_corr = [];

        for TRIAL = 1:n.trials
            [r,p] = corr( force(:,1,TRIAL), force(:,2,TRIAL), 'rows', 'pairwise' );
            force_corr(TRIAL,:) = r;
        end
        
        for CC = 1:2
            force_corrM(SESSION, CC) = nanmean( force_corr( data(:,D.cond) == CC ) );
            force_corrE(SESSION, CC) = nanstd( force_corr( data(:,D.cond) == CC ) );
        end
        
        for CORRECT = 0:1
            force_corrM2(SESSION, CORRECT+1) = nanmean( force_corr( data(:,D.cond) == 2 & data(:,D.correct(3)) == CORRECT ) );
            force_corrE2(SESSION, CORRECT+1) = nanstd( force_corr( data(:,D.cond) == 2 & data(:,D.correct(3)) == CORRECT ) );
        end
        
        whodunit = data(:,D.correct(1)) == 1 & data(:,D.correct(2)) == 1;
        
        for CORRECT = 0:1
            force_corrM2S(SESSION, CORRECT+1) = nanmean( force_corr( data(:,D.cond) == 1 & whodunit == CORRECT ) );
            force_corrE2S(SESSION, CORRECT+1) = nanstd( force_corr( data(:,D.cond) == 1 & whodunit == CORRECT ) );
        end

        
        %% align to RT
        
        FORCEX(:,:,:,SESSION) = force;

        for CURSOR = 1:2
            for CC = 1:2
                FORCE(:,CC,CURSOR,SESSION) = nanmean( force(:,CURSOR,data(:,D.cond) == CC), 3);
            end
        end
        
        RT = cat(1, RT, nanmean( data(:,D.RT(1:2)) )' );
        RTSD = cat(1, RTSD, nanstd( data(:,D.RT(1:2)) )' );
        
    end
end


%%

[ nanmean(RT) nanmean(RTSD) ]
[~,p,~,stats] = ttest( force_corrM(:,1), force_corrM(:,2) )

close all
h = figure('visible', is_figure_visible);
errorbar( mean( force_corrM ), ws_bars( force_corrM ) )
set(gca,'xtick',1:2,'xticklabel',{'Solo' 'Joint'})
xlabel('Control')
ylabel('Correlation (r)')

title( 'Thumbstick Force Correlation Between Players' )
saveas(h, [ OUT 'Thumbstick Force Correlation Between Players.png' ] )


%% bar graph

h = figure('visible', is_figure_visible);
errorbar_groups( mean(force_corrM), ws_bars(force_corrM), 'bar_colors', [0.9 0.9 0.9], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)
xlabel('Control')
ylabel('Correlation (r)')
ylim([0 1])

tit = 'BAR Thumbstick Force Correlation Between Players';
title(tit);

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [OUT tit '.png'])
saveas(h, [OUT tit '.eps'], 'epsc')


%%

h = figure('visible', is_figure_visible);
errorbar( mean( force_corrM2 ), ws_bars( force_corrM2 ) )
set(gca,'xtick',1:2,'xticklabel',{'Incorrect' 'Correct'})
xlabel('Control')
ylabel('Correlation (r)')

title( 'Thumbstick Force Correlation Between Players - Joint Trials' )
saveas(h, [ OUT 'Thumbstick Force Correlation Between Players - Joint Trials.png' ] )

[~,p,~,stats] = ttest( force_corrM2(:,1), force_corrM2(:,2) );


%% correct split bargraph:

M =  [mean( force_corrM2S ); mean( force_corrM2 )  ]
E =  [ws_bars( force_corrM2S );  ws_bars( force_corrM2 )]

h = figure('visible', is_figure_visible);
errorbar_groups(M', E', 'bar_colors', [0.9 0.9 0.9; 1 1 1], 'bar_names', {'Solo' 'Joint'}, 'FigID', h);

xlabel('Control')
ylabel('Correlation (r)')
ylim([0 1])

tit = 'BAR Thumbstick Force Correlation By Error';
title(tit);

legend({'Error' 'Correct'})
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [ OUT tit '.png'])
saveas(h, [ OUT tit '.eps'], 'epsc')

[~,p,~,stats] = ttest( force_corrM2(:,1), force_corrM2(:,2) )
[~,p,~,stats] = ttest( force_corrM2S(:,1), force_corrM2S(:,2) )

[~,p,~,stats] = ttest( force_corrM2S(:,2)- force_corrM2S(:,1), force_corrM2(:,2)- force_corrM2(:,1) )


%% Difference plot

DIFF =  force_corrM2(:,2)- force_corrM2(:,1);
DIFFS =  force_corrM2S(:,2)- force_corrM2S(:,1);

M =  [mean(DIFFS); mean(DIFF)  ]';
E =  [ws_bars( DIFFS );  ws_bars( DIFF)]';

errorbar_groups(M, E, 'bar_colors', [0.9 0.9 0.9], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)

xlabel('Control')
ylabel('Correct - Error Correlation (r)')
ylim([0 0.3])

tit = 'BAR Correlation Difference Between Conditions';
title(tit);

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [ OUT tit '.png'])
saveas(h, [ OUT tit '.eps'], 'epsc')


%% export to SPSS

str.spss  = [	'solo_overall\t' ...
                'joint_overall\t' ...
                'error_solo\t' ...
                'correct_solo\t' ...
                'error_joint\t' ...
                'correct_joint\t' ...
                'delta_solo\t' ...
                'delta_joint\t' ];

spss.out = [ force_corrM2 force_corrM2S force_corrM2 DIFFS DIFF];

out_name = [OUT 'displacement.txt' ];

delete( out_name )
fid = fopen(out_name,'a+');

fprintf(fid, str.spss);
fprintf(fid, '\n');
dlmwrite(out_name, spss.out, '-append', 'delimiter', '\t');
fclose(fid);


%%

h = figure('visible', is_figure_visible);

keep = 1:20;
keep = keep(~ismember(keep,5));

col = {'r' 'b'};

for PP = 1:2
    
    subplot(1,2,PP)

    switch PP
        case 1
            data2use = force_corrM;
        case 2
            data2use = force_corrM(keep,:);
    end
    
    scatter( data2use(:,1), data2use (:,2), col{PP} )
    [r,p] = corr( data2use(:,1), data2use(:,2) )
    
    lsline
    
    xlabel('Solo Correlation (r)')
    ylabel('Joint Correlation (r)')
    
    title( [ 'r = ' num2str(r) ', p = ' num2str(p) ] )
    
end

suptitle( 'Synchrony Proclivity')
saveas(h, [OUT 'Synchrony Proclivity.png' ] )


%%

force2 = [];
FORCEX2 = [];

for SESSION = 1:20
    for CURSOR = 1:2
        force2 = cat(3, force2, FORCE(:,:,CURSOR,SESSION) );
        FORCEX2 = cat(3, FORCEX2, squeeze( FORCEX(:,CURSOR,:,SESSION) ) );
    end
end


%%

t = (1:f.trial_max)./120*1000;

FORCEX2M = mean( mean(FORCEX2,2), 3);
h = figure('visible', is_figure_visible);
plot(t,FORCEX2M)
title('Force')
saveas(h, [OUT 'force.png'])