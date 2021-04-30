close all; clear; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ext] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = '..\data_manager\CheckFiles2\';

addpath('..\external')
addpath('..\common')

is_figure_visible = 'off';
is_load_fresh = false;


%%

number_of_sessions = 20;
number_players = 2;

load( [IN 'fname.mat'] )
fname.behave( cellfun( @isempty, fname.behave ) ) = [];
direct.data = fname.direct_behav;


%%

results.synchrony_M = NaN(number_of_sessions, number_players);
results.synchrony_E = NaN(number_of_sessions, number_players);

results.accuracy_res = NaN(number_of_sessions,3);
results.accuracy_res2 = NaN(number_of_sessions, number_players);

results.RT_resM = [];

results.MT_resM = NaN(number_of_sessions,3);
results.MT_resM2 = NaN(number_of_sessions, number_players);

results.RT_resM_David = [];

tic

if is_load_fresh
    
    for SESSION = 1:number_of_sessions
        
        
        disp('****************************')
        disp(num2str(SESSION))
        STR.SESSION =  sess_string_gen(SESSION);        
        load( [direct.data fname.behave{SESSION} ], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer');
        
        
        %% overall accuracy
        
        res = [];
        
        for COND = 1:2
            
            IDX = data(:,D.cond) == COND;
            
            switch COND
                case 1
                    p2use = 1:2;
                case 2
                    p2use = 3;
            end
            
            data2use = data(IDX, D.correct(p2use) );
            
            res = [ res mean( data2use ) ];
            
        end
        
        res2 = [ mean(res(1:2)) res(3) ];

        h = figure('visible', is_figure_visible);
        
        ax(1) = subplot(1,2,1);
        bar(res,'facecolor', [.5 .5 .5])
        ylabel( 'Proportion Correct' )
        set(gca, 'xticklabel', {'P1' 'P2' 'Joint'} )
        xlabel( 'Condition' )

        ax(2) = subplot(1,2,2);

        bar(res2, 'facecolor', [.5 .5 .5]);
        ylabel( 'Proportion Correct' )
        set(gca, 'xticklabel', {'Solo' 'Joint'} )
        xlabel( 'Control' )
        
        linkaxes(ax,'y')
        set(gca,'ylim',[0 1])
        
        suptitle([STR.SESSION '.accuracy.png'])
        saveas(h, [ OUT STR.SESSION '.accuracy.png' ] )

        results.accuracy_res(SESSION,:) = res;
        results.accuracy_res2(SESSION,:) = res2;
        
        
        %% RT ----- old version
        
        clear ax
        
        resM = [];
        resE = [];
        
        for COND = 1:2
            for CURSOR = 1:2
                
                switch COND
                    case 1
                        p2use = CURSOR;
                    case 2
                        p2use = 3;
                end
                
                IDX = data(:,D.cond) == COND & data(:, D.correct(p2use) ) == 1;
                
                data2use = data(IDX, D.RT(CURSOR) );
                
                data2use( data2use < 200 ) = [];
                
                M = mean( data2use );
                E = std( data2use ) ./ length(data2use);
                
                resM(CURSOR,COND) = M;
                resE(CURSOR,COND) = E;
                
            end
        end
        
        results.RT_resM_David = [ results.RT_resM_David; resM(1,:); resM(2,:) ];
            
        clear ax
        
        resM = [];
        resE = [];
        
        for COND = 1:2
            for CURSOR = 1:3
                switch COND
                    case 1
                        IDX = data(:,D.cond) == COND & data(:, D.correct(CURSOR) ) == 1;
                    case 2
                        IDX = data(:,D.cond) == COND & data(:, D.correct(3) ) == 1;
                end
                
                data2use = data(IDX, D.RT(CURSOR) );
                
                data2use( data2use < 200 ) = [];
                
                M = mean( data2use );
                E = std( data2use ) ./ length(data2use);
                
                resM(CURSOR,COND) = M;
                resE(CURSOR,COND) = E;
                
            end
        end
        
        results.RT_resM(SESSION,:) = [ mean(resM(1:2,1)) mean(resM(1:2,2)) ];
        results.RT_resM2(SESSION,:) = [ min(resM(1:2,1)) max(resM(1:2,1)) min(resM(1:2,2)) max(resM(1:2,2)) resM(3,2) ];
        
        
        %% MT
        
        resM = [];
        resE = [];
        
        for CURSOR = 1:3
            
            switch CURSOR
                case 1
                    COND = 1;
                case 2
                    COND = 1;
                case 3
                    COND = 2;
            end
            
            IDX = data(:,D.cond) == COND & data(:, D.correct(CURSOR) ) == 1;
            
            data2use = data(IDX, D.MT(CURSOR) );
            
            M = mean( data2use );
            E = std( data2use ) ./ length(data2use);
            
            resM(1,CURSOR) = M;
            resE(1,CURSOR) = E;
            
        end
        
        resM2 = [ mean(resM(1:2)) resM(3) ];
        resE2 = [ mean(resE(1:2)) resE(3) ];
        
        
        results.MT_resM(SESSION,:) = resM;
        results.MT_resM2(SESSION,:) = resM2;
        
        
        %% synchrony
        
        RTD = [];
        
        for COND = 1:2
            switch COND
                case 1
                    IDX = sum( data(:,D.RT_fast(1:2)), 2 ) == 0 & sum( data(:,D.correct(1:2)), 2 ) == 2 & data(:,D.cond) == COND;
                case 2
                    IDX = sum( data(:,D.RT_fast(1:2)), 2 ) == 0 & data(:,D.correct(3)) == 1 & data(:,D.cond) == COND;
            end
            
            data2use = data(IDX,:);
            
            for TRIAL = 1:size(data2use,1)
                RTD{COND}(TRIAL,1) = abs( diff( data2use(TRIAL,D.RT([1 2])) ) );
            end
            
            MM = mean( RTD{COND} );
            EE = std( RTD{COND} )./sqrt( length( RTD{COND} ) );
            
            results.synchrony_M(SESSION,COND) = MM;
            results.synchrony_E(SESSION,COND) = EE;
        end
    end
    
    save( [ OUT 'results.mat' ], 'results' )   
    
else
    
    load( [ OUT 'results.mat' ], 'results' )
    
end


%% accuracy

h = figure('visible', is_figure_visible);
clear ax
ax(1) = subplot(1,2,1);
errorbar_groups(nanmean( results.accuracy_res2 ), ws_bars( results.accuracy_res2 ), 'bar_colors', [0.9 0.9 0.9], 'FigID', h, 'AxID', ax(1))

set(gca,'xtick',1:2,'xticklabel', {'Mean Solo' 'Joint'})
xlabel('Control')
ylabel('Proportion Correction')

ylim([.6 .85])
% [h,p,ci,stats] = ttest( results.accuracy_res2(:,1), results.accuracy_res2(:,2) );

% subplot(1,2,2)
% bar( (results.accuracy_res2(:,2) - results.accuracy_res2(:,1) ))

for SESSION = 1:number_of_sessions
    results.accuracy_res(SESSION,1:2) = sort( results.accuracy_res(SESSION,1:2) );
end

ax(2) = subplot(1,2,2);

errorbar_groups( nanmean( results.accuracy_res ), ws_bars( results.accuracy_res ) , 'bar_colors', [0.9 0.9 0.9], 'FigID', h, 'AxID', ax(2))
ylim([.6 .85])

set(gca,'xtick',1:3,'xticklabel', {'Low' 'High' 'Joint'})
xlabel('Control')
ylabel('Proportion Correction')

suptitle( 'Accuracy' )
%linkaxes(ax,'y')
saveas(h, [ OUT 'Accuracy.png' ] )

[~,p,~,~] = ttest( results.accuracy_res(:,1), results.accuracy_res(:,3)  )
[~,p,~,~] = ttest( results.accuracy_res(:,2), results.accuracy_res(:,3)  )
[~,p,~,~] = ttest( results.accuracy_res2(:,1), results.accuracy_res2(:,2) )


%% accuracy summary

h = figure('visible', is_figure_visible);

errorbar_groups(nanmean( results.accuracy_res2 ), ws_bars( results.accuracy_res2 ), 'bar_colors', [0.9 0.9 0.9], 'bar_names',{'Mean Solo' 'Joint'}, 'FigID', h)

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

xlabel('Control')
ylabel('Proportion Correction')

ylim([.6 .85])

title('Accuracy Summary')

saveas(h, [OUT 'Accuracy Summary.eps'], 'epsc')


%% accuracy split

h = figure('visible', is_figure_visible);

errorbar_groups( nanmean( results.accuracy_res ), ws_bars( results.accuracy_res ) , 'bar_colors', [0.9 0.9 0.9],'bar_names',  {'Low Accuracy Solo' 'High Accuracy Solo' 'Joint'},'FigID', h)
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

ylim([.6 .85])

xlabel('Control')
ylabel('Proportion Correction')

title( 'Accuracy' )

saveas(h, [ OUT 'Accuracy.eps' ], 'epsc' )


%% RT

h = figure('visible', is_figure_visible);

errorbar( mean( results.RT_resM ), ws_bars( results.RT_resM ) )
Y = get(gca,'ylim');
errorbar_groups(  mean( results.RT_resM ), ws_bars( results.RT_resM ) , 'bar_colors', [0.9 0.9 0.9], 'bar_names', {'Solo' 'Joint'}, 'FigID', h)
ylim([400 500])
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

xlabel( 'Control' )
ylabel( 'RT (ms)' )
title( 'RT Summary' )

saveas(h, [ OUT 'RT.png' ] )
saveas(h, [ OUT 'RT.eps' ], 'epsc' )

[h,p,ci,stats] = ttest( results.RT_resM(:,1), results.RT_resM(:,2) )
[h,p,ci,stats] = ttest( results.RT_resM_David(:,1), results.RT_resM_David(:,2) )


%% RT split

M =  mean( results.RT_resM2(:,1:4) );
E = ws_bars( results.RT_resM2(:,1:4) )

M = [M(1:2) ; M(3:4)];
E = [E(1:2) ; E(3:4)];

h = figure('visible', is_figure_visible);

errorbar_groups( M, E , 'bar_colors', [0.9 0.9 0.9; 1 1 1], 'bar_names', {'faster' 'slower'}, 'FigID', h)
ylim([400 500])
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

legend({'Solo' 'Joint' })
xlabel( 'Participant' )
ylabel( 'RT (ms)' )
title( 'RT' )

[~,p,~,~] = ttest( results.RT_resM2(:,1), results.RT_resM2(:,2) )
[~,p,~,~] = ttest( results.RT_resM2(:,3), results.RT_resM2(:,4) )

[~,p,~,~] = ttest( results.RT_resM2(:,1), results.RT_resM2(:,3) )
[~,p,~,~] = ttest( results.RT_resM2(:,2), results.RT_resM2(:,4) )

saveas(h, [ OUT 'RT split.png' ] );
saveas(h, [ OUT 'RT split.eps' ], 'epsc' );


%% MT

close all; clear h
h = figure('visible', is_figure_visible);

ax(1) = subplot(1,2,1);
errorbar_groups(   nanmean( results.MT_resM2 ), ws_bars( results.MT_resM2)  , 'bar_colors', [0.9 0.9 0.9], 'FigID', h, 'AxID', ax(1))
% errorbar(  nanmean( results.MT_resM2 ), ws_bars( results.MT_resM2) )
set(gca,'xtick',1:2,'xticklabel', {'Solo' 'Mean Joint'})
xlabel('Control')
ylabel('MT (ms)')
ylim([550 800])
% [h,p,ci,stats] = ttest( results.accuracy_res2(:,1), results.accuracy_res2(:,2) );

% subplot(1,2,2)
% bar( (results.accuracy_res2(:,2) - results.accuracy_res2(:,1) ))

for SESSION = 1:number_of_sessions
    results.MT_resM(SESSION,1:2) = sort( results.MT_resM(SESSION,1:2) );
end

ax(2) = subplot(1,2,2);

errorbar_groups(  nanmean( results.MT_resM ), ws_bars( results.MT_resM )  , 'bar_colors', [0.9 0.9 0.9], 'FigID', h, 'AxID', ax(2))
% errorbar(  nanmean( results.MT_resM ), ws_bars( results.MT_resM ) )
ylim([550 800])
set(gca,'xtick',1:3,'xticklabel', {'Fast' 'Slow' 'Joint'})
xlabel('Control')
ylabel('Proportion Correction')

suptitle( 'MT (ms)' )
% linkaxes(ax,'y')

saveas(h, [ OUT 'MT.png' ] )

[h,p,ci,stats] = ttest( results.MT_resM2(:,1), results.MT_resM2(:,2) )
[h,p,ci,stats] = ttest( results.MT_resM(:,1), results.MT_resM(:,3) )
[h,p,ci,stats] = ttest( results.MT_resM(:,2), results.MT_resM(:,3) )


%% MT summary

close all; clear h
h = figure('visible', is_figure_visible);

errorbar_groups(   nanmean( results.MT_resM2 ), ws_bars( results.MT_resM2)  , 'bar_colors', [0.9 0.9 0.9],'bar_names', {'Solo' 'Mean Joint'}, 'FigID', h)
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

xlabel('Control')
ylabel('MT (ms)')
ylim([550 800])

title('MT summary')
saveas(h, [ OUT 'MT summary.eps' ], 'epsc')


%% MT split

for SESSION = 1:number_of_sessions
    results.MT_resM(SESSION,1:2) = sort( results.MT_resM(SESSION,1:2) );
end

errorbar_groups(  nanmean( results.MT_resM ), ws_bars( results.MT_resM )  , 'bar_colors', [0.9 0.9 0.9], 'bar_names', {'Fast' 'Slow' 'Joint'}, 'FigID', h)
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')


ylim([550 800])
xlabel('Control')
ylabel('MT (ms)')

title( 'MT' )

saveas(h, [ OUT 'MT.eps' ], 'epsc')


%% synchrony

close all

h = figure('visible', is_figure_visible);
errorbar_groups(  nanmean( results.synchrony_M ), ws_bars( results.synchrony_M ) , 'bar_colors', [0.9 0.9 0.9],'bar_names', {'Solo' 'Joint'}, 'FigID', h)
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

ylabel('Absolute RT Difference (ms)')
xlabel('Control')
title('Synchrony')
ylim([90 105])

saveas(h, [ OUT 'Synchrony.png' ] )
saveas(h, [ OUT 'Synchrony.eps' ], 'epsc')

[h,p,ci,stats] = ttest( results.synchrony_M(:,1), results.synchrony_M(:,2) )


%% combine data
str.spss = ['Accuracy_Solo\t' 'Accuracy_Joint\t' ...
    'AccuracySplit_Solo_Inaccurate\t' 'AccuracySplit_Solo_Accurate\t' 'AccuracySplit_Joint\t'...
    'RT_Solo\t' 'RT_Joint\t'...
    'RTSplit_Solo_Fast\t' 'RTSplit_Solo_Slow\t' 'RTSplit_Joint_Fast\t' 'RTSplit_Joint_Slow\t'...
    'MT_Solo\t' 'MT_Joint\t'...
    'MTSplit_Solo_fast\t' 'MTSplit_Solo_slow\t' 'MTSplit_Joint\t'...
    'RT_diff_Solo\t' 'RT_diff_Joint\t'    ];
spss.out = [results.accuracy_res2 results.accuracy_res results.RT_resM results.RT_resM2(:,1:4) results.MT_resM2 results.MT_resM results.synchrony_M];


%% export to SPSS

out_name = [OUT 'JointAction_behviour.txt' ];

delete( out_name )
fid = fopen(out_name,'a+');

fprintf(fid, str.spss);
fprintf(fid, '\n');
dlmwrite(out_name, spss.out, '-append', 'delimiter', '\t');
fclose(fid);
