close all; clear; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ext] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = '..\data_manager\CheckFiles2\';

addpath('..\external')
addpath('..\common')

is_figure_visible = 'off';
is_load_fresh = false;

generate_global_variables


%%

number_of_sessions = 20;
number_players = 2;

load( [IN 'fname.mat'] )
fname.behave( cellfun( @isempty, fname.behave ) ) = [];


%%

results.accuracyComparison = [];

results.synchrony_M = NaN(number_of_sessions,2);
results.synchrony_E = NaN(number_of_sessions,2);

results.RTfast = [];
results.RTslow = [];
results.MTslow = [];
results.leaving = [];
results.correct = [];
results.RT = [];
results.MT = [];
results.behavioral_coupling = NaN(number_of_trials, number_of_sessions);

% synchronyOffsetM: [20×2 double]
% synchronyOffsetE: [20×2 double]
% synchronyOffsetM2: [20×2×2 double]
% synchronyOffsetR: [20×2×2 double]
% synchronyOnsetM2: [20×2×2 double]
% synchronyOnsetR: [20×2×2 double]
% synchronyN: [20×2 double]
% lastFRAME: [20×2 double]

if is_load_fresh
    for SESSION = 1:number_of_sessions
        
        disp('****************************')
        disp(num2str(SESSION))
        STR.SESSION =  STR.session;    
        load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer');
    

        %% ---- accuracy comparison - signal averaging cooperation trials
        
        IDX = data(:,D.cond) == 1;
        data2use = data( IDX, D.correct );        
        results.accuracyComparison = [ results.accuracyComparison ; nanmean(data2use) ];
        
    
        %% ---- accuracy comparison - signal averaging cooperation trials - trajectory
        
        str.cursor = {'P1' 'P2' 'Joint Action'};
        str.cond = {'Solo' 'Co-op'};
        
        CURSOR = 3;
        COND = 1;
        
        target = 0;
        
        for LOC = 1:2
            for POS = 1:4
                IDX = find( data(:,D.location) == LOC & data(:,D.position_combo) == POS & data(:,D.cond) == COND  );
                results.averageCursor{LOC,POS,SESSION} =  cursor.xy(:,:,IDX,CURSOR);
            end
        end
        
        CURSOR = 3;
        COND = 2;
        
        target = 0;
        
        for LOC = 1:2
            for POS = 1:4
                IDX = find( data(:,D.location) == LOC & data(:,D.position_combo) == POS & data(:,D.cond) == COND  );
                results.jointCursor{LOC,POS,SESSION} =  cursor.xy(:,:,IDX,CURSOR);
            end
        end
        

        %% ----- accuracy
        
        tmp1 = [];
        tmp2 = [];
        tmp3 = [];
        tmp4 = [];
        tmp5 = [];
        
        for CC = 1:n.cond
            
            IDX = data(:,D.cond) == CC;
            
            switch CC
                case 1
                    p2use = 1:2;
                case 2
                    p2use = 3;
            end
            
            for EE = 1:5
                
                switch EE
                    case 1
                        tmp1 =  [ tmp1 mean( data(IDX, D.RT_fast(p2use) ) ) ];
                    case 2
                        tmp2 =  [ tmp2 mean( data(IDX, D.RT_slow(p2use) ) ) ];
                    case 3
                        tmp3 =  [ tmp3 mean( data(IDX, D.MT_slow(p2use) ) ) ];
                    case 4
                        tmp4 = [ tmp4 mean( data(IDX, D.leaving(p2use) ) ) ];
                    case 5
                        tmp5 = [ tmp5 mean( data(IDX, D.correct(p2use) ) ) ];
                end
                
            end
        end
        
        results.RTfast =  [ results.RTfast ; tmp1 ];
        results.RTslow =  [ results.RTslow ; tmp2 ];
        results.MTslow =  [ results.MTslow ; tmp3 ];
        results.leaving = [ results.leaving ; tmp4 ];
        results.correct = [ results.correct ; tmp5 ];
        
        
        %% ----- RT
        
        for CURSOR = 1:n.cursors
            for CC = 1:n.cond
                
                IDX = data(:,D.cond) == CC & data(:, D.correct(CURSOR) ) == 1;
                data2use = data(IDX, D.RT(CURSOR) );
                
                if any(data2use < 200)
                    error('should be incorrect!')
                end
                
                results.RT = [ results.RT nanmean(data2use) ];
            end
        end
        
        
        %% ----- MT
        
        for CURSOR = 1:3
            
            switch CURSOR
                case 1
                    CC = 1;
                case 2
                    CC = 1;
                case 3
                    CC = 2;
            end
            
            IDX = data(:,D.cond) == CC & data(:, D.correct(CURSOR) ) == 1;
            results.MT = [ results.MT nanmean( data(IDX, D.MT(CURSOR) ) ) ];
            
        end

        
        %% synchrony
        
        moveFRAME = data( :, D.move_cue_frame );
        
        firstFRAME = NaN(n.trials,n.cursors);
        lastFRAME = NaN(n.trials,n.cursors);
        
        %         figure;
        
        for TRIAL = 1:n.trials
            for CURSOR = 1:n.cursors
                
                THUMB = cursor.thumb(:,:,TRIAL,CURSOR)';
                
                ThumbX = THUMB(:,1);
                ThumbY = THUMB(:,2);
                
                DIST = sqrt( ThumbX.^2 + ThumbY.^2 );
                DIST( isnan( DIST ) ) = 0;
                DIST = abs( DIST ) <= cursor.sensitivity;
                DIST = ~DIST;
                
                if isempty( find(DIST,1,'first') )
                    tmp = NaN;
                else
                    tmp = find(DIST,1,'first');
                end
                
                firstFRAME(TRIAL,CURSOR) = tmp;
                
                if isempty( find(DIST,1,'last') )
                    tmp = NaN;
                else
                    tmp = find(DIST,1,'last');
                end
                
                lastFRAME(TRIAL,CURSOR) = tmp;
                
                %                 subplot(2,1,CURSOR); cla; hold on
                %                 plot(ThumbX,'r')
                %                 plot(ThumbY,'g')
                %                 plot(DIST,'b')
                %
                %                 line( [1 1].*moveFRAME(TRIAL), get(gca,'ylim'), 'color', 'k' )
                %                 line( [1 1].*lastFRAME(TRIAL,CURSOR), get(gca,'ylim'), 'color', 'k', 'linestyle', '--' )
                %                 line( [1 1].*firstFRAME(TRIAL,CURSOR), get(gca,'ylim'), 'color', 'k', 'linestyle', '-.' )
            end
            
            %             input('enter')
        end
        
        firstFRAME = firstFRAME - repmat( moveFRAME, 1, n.cursors); % not necessary
        firstFRAME = ( firstFRAME ./ mon.ref ) * 1000;
        
        lastFRAME = lastFRAME - repmat( moveFRAME, 1, n.cursors); % not necessary
        lastFRAME = ( lastFRAME ./ mon.ref ) * 1000;
        
        results.behavioral_coupling(:,SESSION) = abs(diff(lastFRAME,[],2));
        
        for CC = 1:n.cond
            
            switch CC
                case 1
                    IDX = sum( data(:,D.RT_fast(1:2)), 2 ) == 0 & sum( data(:,D.correct(1:2)), 2 ) == 2 & data(:,D.cond) == CC;
                case 2
                    IDX = sum( data(:,D.RT_fast(1:2)), 2 ) == 0 & data(:,D.correct(3)) == 1 & data(:,D.cond) == CC;
            end
            
            data2use = abs( diff( firstFRAME(IDX,:), [], 2 ) );
            
            results.synchrony_M(SESSION,CC) = nanmean( data2use );
            results.synchrony_E(SESSION,CC) = nanstd( data2use ) ./ sqrt( size(data2use,1) );
            
            data2use = abs( diff( lastFRAME(IDX,:), [], 2 ) );
            
            results.synchronyOffsetM(SESSION,CC) = nanmean( data2use );
            results.synchronyOffsetE(SESSION,CC) = nanstd( data2use ) ./ sqrt( size(data2use,1) );

            %% offset/onset
            
            for ACC = 0:1
                
                switch CC
                    case 1
                        IDX = sum( data(:,D.RT_fast(1:2)), 2 ) == 0 & sum( data(:,D.correct(1:2)) == ACC, 2 ) == 2 & data(:,D.cond) == CC;
                    case 2
                        IDX = sum( data(:,D.RT_fast(1:2)), 2 ) == 0 & data(:,D.correct(3)) == ACC & data(:,D.cond) == CC;
                end
                
                % ----- delta offset
                data2use = abs( diff( lastFRAME(IDX,:), [], 2 ) );
                results.synchronyOffsetM2(SESSION,CC,ACC+1) = nanmean( data2use );
                
                % ----- correlation offset
                data2use = lastFRAME(IDX,:);
                results.synchronyOffsetR(SESSION,CC,ACC+1) = corr( data2use(:,1), data2use(:,2), 'rows', 'complete' );
                
                % ----- delta onset
                data2use = abs( diff( firstFRAME(IDX,:), [], 2 ) );
                results.synchronyOnsetM2(SESSION,CC,ACC+1) = nanmean( data2use );
                
                % ----- correlation onset
                data2use = firstFRAME(IDX,:);
                results.synchronyOnsetR(SESSION,CC,ACC+1) = corr( data2use(:,1), data2use(:,2), 'rows', 'complete' );
                
            end

            %%
            
            results.synchronyN(SESSION,CC) = size(data2use,1);
            results.lastFRAME(SESSION,:) = nanmean( lastFRAME(IDX,:) );
            
        end
        
     
        
        %%
        
        save( [ OUT 'results.mat' ], 'results' )
        
    end
    
else
    
    load([OUT 'results.mat'], 'results')
    behavioral_coupling = results.behavioral_coupling;
    save([OUT 'behavioral_coupling.mat'], 'behavioral_coupling', '-v6')
    
    
end


%% stimulus

n.locations = 8; n.positions = n.locations;

array.t = linspace( 0, 2*pi - 2*pi/n.locations, n.locations ) + 2*pi/n.locations/2;
array.t_deg = rad2deg(array.t);

array.r = ones(1,n.locations)*300*(100/83)*(100/99)*(8/10);

[array.x, array.y] = pol2cart(array.t, array.r);

sizes.target = 50*20/13;


%% ------ make flower

dpp = (53.2/1920); % degrees/pixel

col.location{1} = {'r' [1 0.36 0] 'y' 'g'};
col.location{2} = {'c' 'b' [0.5 0.25 0.6]  'm'};
col.location{3} = {[0.5 0.25 0.6] 'm' 'r' [1 0.36 0] 'y' 'g' 'c' 'b' };

h = figure; hold on

for SESSION = 1:20
    for LOC = 1:2
        for POS = 1:4
            
            cursor.xy = results.averageCursor{LOC,POS,SESSION};

            for TRIAL = 1:size(cursor.xy,3)
                plot( cursor.xy(1,:,TRIAL)*dpp, cursor.xy(2,:,TRIAL)*dpp, 'color', col.location{LOC}{POS} )
            end
        end
    end  
    
end

for LL = 1:n.positions; pos = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp; rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', 'k'); end
TIT = 'Averaging Trajectories'; title( TIT ); xlabel( 'x (°)' ); ylabel( 'y (°)' ); axis square; set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial'); xlim( [-1 +1] .* 13 ); ylim( [-1 +1] .* 13 )
saveas(h, [ OUT TIT '.png' ] )


%% endpoint dots averaging

h = figure; hold on

endPoint = [];
colors = [];

col.location2{1} = [1 0 0; 1 0.36 0; 1 1 0; 0 1 0];
col.location2{2} = [0 1 1; 0 0 1 ; 0.5 0.25 0.6 ; 1 0 1];

for SESSION = 1:20

    target = 0;
    for LOC = 1:2
        for POS = 1:4
            target = target+1;

            cursor.xy = results.averageCursor{LOC,POS,SESSION};
           

            for TRIAL = 1:size(cursor.xy,3)
                
                %disp('*')
                
                data2use = cursor.xy( :, find( ~isnan( cursor.xy(1,:,TRIAL) ), 1, 'last' ), TRIAL );
                endPoint = [endPoint ; data2use' ];
                colors = [colors ; col.location2{LOC}(POS,:) ];
                
                %scatter(data2use(1),data2use(2), 5, col.location{LOC}{POS} )
            
            end
        end
    end
        
end


endPoint = endPoint*dpp;

scatter(endPoint(:,1), endPoint(:,2), 5, colors, 'f' )
for LL = 1:n.positions; pos = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp; rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', 'k'); end
TIT = 'Averaging Endpoints'; title( TIT ); xlabel( 'x (°)' ); ylabel( 'y (°)' ); axis square; set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial'); xlim( [-1 +1] .* 13 ); ylim( [-1 +1] .* 13 )
saveas(h, [ OUT TIT '.png' ] )
saveas(h, [ OUT TIT '.eps' ], 'epsc' )


%% endpoint dots joint

h = figure; hold on

endPoint = [];
colors = [];

col.location2{1} = [1 0 0; 1 0.36 0; 1 1 0; 0 1 0];
col.location2{2} = [0 1 1; 0 0 1 ; 0.5 0.25 0.6 ; 1 0 1];

for SESSION = 1:20

    for LOC = 1:2
        for POS = 1:4
            
            cursor.xy = results.jointCursor{LOC,POS,SESSION};
           
            for TRIAL = 1:size(cursor.xy,3)
                data2use = cursor.xy( :, find( ~isnan( cursor.xy(1,:,TRIAL) ), 1, 'last' ), TRIAL );
                endPoint = [endPoint ; data2use' ];
                colors = [colors ; col.location2{LOC}(POS,:) ];
            end
            
        end
    end
        
end

endPoint = endPoint*dpp;

scatter(endPoint(:,1), endPoint(:,2), 5, colors, 'f' )
for LL = 1:n.positions; pos = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp; rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', 'k'); end
TIT = 'Joint Endpoints'; title( TIT ); xlabel( 'x (°)' ); ylabel( 'y (°)' ); axis square; set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial'); xlim( [-1 +1] .* 13 ); ylim( [-1 +1] .* 13 )
saveas(h, [ OUT TIT '.png' ] )




%% ------ accuracy comparison - signal averaging

data2use = [ mean( results.accuracyComparison(:,1:2), 2) results.accuracyComparison(:,3) ]*100;

[h,p,ci,stats] = ttest(data2use(:,1),data2use(:,2))

mean( data2use )
std( data2use )

close all

TIT = 'accuracy.comparison';

h = figure;
errorbar_groups( nanmean( data2use ), ws_bars( data2use ), 'bar_colors', [0.9 0.9 0.9], 'FigID', h )
set(gca,'tickdir','out','xticklabel', {'Individual Cursor' 'Mean Cursor'} )
xlabel('Control')
ylabel('Proportion Correct')

text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )

line( get(gca,'xlim'), [1/8 1/8]*100 )
%ylim( [0 85] )

suptitle(TIT)
saveas(h, [ OUT TIT '.png' ] )
saveas(h, [ OUT TIT '.eps' ], 'eps' )

[h,p,ci,stats] = ttest( data2use(:,2), .125 )



out_name = [OUT 'averaging.txt' ]; delete( out_name ); fid = fopen(out_name,'a+');
fprintf(fid, [ 'solo\t' 'averaging\t' ]); fprintf(fid, '\n');
dlmwrite(out_name, data2use, '-append', 'delimiter', '\t'); fclose(fid);


%% ----- accuracy breakdown

n.cond = 2;

for CC = 1:n.cond
    
    switch CC
        case 1
            p2use = 1:2;
        case 2
            p2use = 3;
    end
    
    for EE = 1:5
        switch EE
            case 1
                data2use = results.correct(:,p2use);
            case 2
                data2use = results.RTfast(:,p2use);
            case 3
                data2use = results.RTslow(:,p2use);
            case 4
                data2use = results.MTslow(:,p2use);
            case 5
                data2use = results.leaving(:,p2use);
        end
        
        data2use2(EE,CC) = mean( mean( data2use, 2 ) );
        
    end
end

close all

TIT = 'trial.classification';

h = figure;
bar( data2use2', 'stacked' )
legend( {'correct' 'RT fast' 'RT slow' 'MT slow' 'Missed Target'}, 'location', 'best' )
colormap( 'hot' )
set(gca,'xticklabel', {'Individual' 'Joint'}, 'tickdir', 'out' )
xlabel('Control')
ylabel('Proportion of Trials')

saveas(h, [ OUT TIT '.png' ] )


%% synchrony

[~,p,ci,stats] = ttest( results.synchrony_M(:,1), results.synchrony_M(:,2) )

close all

h = figure; hold on
errorbar_groups(  nanmean( results.synchrony_M ), ws_bars( results.synchrony_M ) , 'bar_colors', [0.9 0.9 0.9],'bar_names', {'Solo' 'Joint'}, 'FigID', h)
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

ylabel('Absolute RT Difference (ms)')
xlabel('Control')
title('Synchrony')
%ylim([90 105])

text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )

saveas(h, [ OUT 'Synchrony.png' ] )
saveas(h, [ OUT 'Synchrony.eps' ], 'epsc')

% synchrony offset

[~,p,ci,stats] = ttest( results.synchronyOffsetM(:,1), results.synchronyOffsetM(:,2) )

h = figure; hold on
errorbar_groups(  nanmean( results.synchronyOffsetM ), ws_bars( results.synchronyOffsetM ) , 'bar_colors', [0.9 0.9 0.9],'bar_names', {'Solo' 'Joint'}, 'FigID', h)
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

ylabel('Absolute RT Difference (ms)')
xlabel('Control')
title('Synchrony.offset')

text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )

saveas(h, [ OUT 'Synchrony.offset.png' ] )
saveas(h, [ OUT 'Synchrony.offset.eps' ], 'epsc')


%%

TIT = 'MT.offset';

close all
h = figure;

for CC = 1:n.cond
    
    data2use = squeeze( results.synchronyOffsetM2(:,CC,:) );
    
    ax(CC) = subplot(1,2,CC);
    
    errorbar_groups(  nanmean( data2use ), ws_bars( data2use ), 'bar_colors', [0.9 0.9 0.9], 'bar_names', {'Error' 'Correct'}, 'FigID', h, 'AxID', ax(CC) )
    set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')
    xlabel('Accuracy')
    ylabel(' \DeltaMT (ms)' )
    
    %title(str.cond{CC})
    ylim([0 700] )
    
    [~,p,~,stats] = ttest( data2use(:,1), data2use(:,2) );
    text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )
    
end

suptitle(TIT)
saveas(h, [ OUT TIT '.png' ] )


%%

TIT = 'MT.offset.correlation';

close all
h = figure;

for CC = 1:n.cond
    
    data2use = squeeze( results.synchronyOffsetR(:,CC,:) );
    
    ax(CC) = subplot(1,2,CC);
    
    errorbar_groups(  nanmean( data2use ), ws_bars( data2use ), 'bar_colors', [0.9 0.9 0.9], 'bar_names', {'Error' 'Correct'}, 'FigID', h, 'AxID', ax(CC) )
    set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')
    xlabel('Accuracy')
    ylabel(' \DeltaMT (ms)' )
    
    %title(str.cond{CC})
    ylim([0 .7] )
    
    [~,p,~,stats] = ttest( data2use(:,1), data2use(:,2) );
    text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )
    
end

suptitle(TIT)
saveas(h, [ OUT TIT '.png' ] )


%% MT offset correlation 2

data2use = [];

for CC = 1:n.cond
    data2use = [data2use squeeze( results.synchronyOffsetR(:,CC,:) ) ];
end

M = mean(data2use);
E = ws_bars(data2use);

M = [ M(1:2) ; M(3:4) ];
E = [ E(1:2) ; E(3:4) ];

h = figure;
[hBar, hErrorbar] = barwitherr(E,M);
xlim( [.375 2.625] )
set(gca,'tickdir','out')
ylabel('Correlation (\Deltar)' )
xlabel('Control')
set(gca,'xticklabels', {'Solo' 'Joint' })
legend({'Error' 'Correct'},'location','northeast')

saveas(h, [ OUT 'MT.offset.correlation2.eps' ] , 'epsc' )
saveas(h, [ OUT 'MT.offset.correlation2.png' ] , 'png' )


out_name = [OUT 'offset.txt' ]; delete( out_name ); fid = fopen(out_name,'a+');
fprintf(fid, [ 'solo.error\t' 'solo.correct\t' 'joint.error\t' 'joint.correct\t' ]); fprintf(fid, '\n');
dlmwrite(out_name, data2use, '-append', 'delimiter', '\t'); fclose(fid);

offset_correlation = data2use;

save([OUT 'offset_correlation.mat'], 'offset_correlation', '-v6')


%%

TIT = 'RT.onset';

close all
h = figure;

for CC = 1:n.cond
    
    data2use = squeeze( results.synchronyOnsetM2(:,CC,:) );
    
    ax(CC) = subplot(1,2,CC);
    
    errorbar_groups(  nanmean( data2use ), ws_bars( data2use ), 'bar_colors', [0.9 0.9 0.9], 'bar_names', {'Error' 'Correct'}, 'FigID', h, 'AxID', ax(CC) )
    set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')
    xlabel('Accuracy')
    ylabel(' \DeltaMT (ms)' )
    
    %title(str.cond{CC})
    ylim([0 700] )
    
    [~,p,~,stats] = ttest( data2use(:,1), data2use(:,2) );
    text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )
    
end

suptitle(TIT)
saveas(h, [ OUT TIT '.png' ] )

TIT = 'RT.onset.correlation';

h = figure;

for CC = 1:n.cond
    
    data2use = squeeze( results.synchronyOnsetR(:,CC,:) );
    
    ax(CC) = subplot(1,2,CC);
    
    errorbar_groups(  nanmean( data2use ), ws_bars( data2use ), 'bar_colors', [0.9 0.9 0.9], 'bar_names', {'Error' 'Correct'}, 'FigID', h, 'AxID', ax(CC) )
    set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')
    xlabel('Accuracy')
    ylabel(' \DeltaMT (ms)' )
    
    %title(str.cond{CC})
    ylim([-.1 .15] )
    
    [~,p,~,stats] = ttest( data2use(:,1), data2use(:,2) );
    text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )
    
end

suptitle(TIT)
saveas(h, [ OUT TIT '.png' ] )


%% onset correlation 2

data2use = [];

for CC = 1:n.cond
    data2use = [data2use squeeze( results.synchronyOnsetR(:,CC,:) ) ];
end

M = mean(data2use);
E = ws_bars(data2use);

M = [ M(1:2) ; M(3:4) ];
E = [ E(1:2) ; E(3:4) ];

h = figure;
[hBar, hErrorbar] = barwitherr(E,M);
xlim( [.375 2.625] )
set(gca,'tickdir','out')
ylabel('Correlation (\Deltar)' )
xlabel('Control')
set(gca,'xticklabels', {'Solo' 'Joint' })
legend({'Error' 'Correct'},'location','northeast')

saveas(h, [ OUT 'onset.correlation2.eps' ] , 'epsc' )
saveas(h, [ OUT 'onset.correlation2.png' ] , 'png' )


out_name = [OUT 'onset.txt' ]; delete( out_name ); fid = fopen(out_name,'a+');
fprintf(fid, [ 'solo.error\t' 'solo.correct\t' 'joint.error\t' 'joint.correct\t' ]); fprintf(fid, '\n');
dlmwrite(out_name, data2use, '-append', 'delimiter', '\t'); fclose(fid);




%%

close all
bar( results.synchronyOffsetM )


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

%% anticipations

anticipations = results.RTfast*100;
soloA = [anticipations(:,1); anticipations(:,2)];
jointA = [[anticipations(:,1); anticipations(:,3)]];

[mean(soloA) std(soloA)]
[mean(jointA) std(jointA)]

[h,p,ci,stats] = ttest(soloA, jointA)

% [h,p,ci,stats] = ttest(soloA)
% [h,p,ci,stats] = ttest(jointA)



