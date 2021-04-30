%% //////////// generic start

close all; clear; clc; restoredefaultpath

p = mfilename('fullpath');
[~, direct.output, ext] = fileparts(p);
direct.output = [ direct.output '\' ]; mkdir( direct.output );

addpath('..\external')

input('press enter') % //////////// generic start


basicSettings
options.loadfresh=1;


%% information

n.trials = 960;
dpp = (53.2/1920); % degrees/pixel
n.cursors = 3;

OUT = direct.output;


%% metadata
if options.loadfresh
    for SESSION = 1:N.sessions
        
        
        
        %% get data
        
        load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer');
        
        
        %% rand info
        n.cursors = 3;
        
        TRIGGERS = triggers(:, 1:n.trials);
        
        DTRIGGERS = [ ones(1,n.trials); diff(TRIGGERS) ] > 0;
        trigger_onset = TRIGGERS .* DTRIGGERS;
        
        str.cursor = {'P1' 'P2' 'Joint Action'};
        str.cond = {'Solo' 'Co-op'};
        
        %% plot trajectories
        
        for CURSOR = 1:n.cursors
            
            
            switch CURSOR
                case 1
                    COND = 1;
                case 2
                    COND = 1;
                case 3
                    COND = 2;
            end
            
            target = 0;
            for LOC = 1:2
                for POS = 1:4
                    target = target+1;
                    IDX = find( data(:,D.location) == LOC & data(:,D.position_combo) == POS & data(:,D.cond) == COND & data(:,D.correct(CURSOR) ) == 1  );
                    
                    allcursors{LOC,POS,CURSOR, SESSION} =  cursor.xy(:,:,IDX,CURSOR);
                    
                    IDX2 = find( data(:,D.location) == LOC & data(:,D.position_combo) == POS & data(:,D.cond) == COND & data(:,D.correct(CURSOR) ) == 0  );
                    
                    allcursors_error{LOC,POS,CURSOR, SESSION} =  cursor.xy(:,:,IDX2,CURSOR);
                    
                end
            end
        end
        
    end
end


%% plot trajectories

clear cursor

col.location{1} = {'r' [1 0.36 0] 'y' 'g'};
col.location{2} = {'c' 'b' [0.5 0.25 0.6]  'm'};
col.location{3} = {[0.5 0.25 0.6] 'm' 'r' [1 0.36 0] 'y' 'g' 'c' 'b' };

close all

clear IM

h = figure; hold on

for SESSION = 1:20
    for CURSOR = 1:2
        COND = 1;
        
        target = 0;
        for LOC = 1:2
            for POS = 1:4
                target = target+1;
                
                cursor.xy = allcursors{LOC,POS,CURSOR, SESSION};
                for TRIAL = 1:size(cursor.xy,3)
                    
                    plot( cursor.xy(1,:,TRIAL)*dpp, cursor.xy(2,:,TRIAL)*dpp, 'color', col.location{LOC}{POS} )
                end
            end
        end
        
        
    end
end

xlim( [-1 +1] .* 13 )
ylim( [-1 +1] .* 13 )

for LL = 1:n.positions
    pos = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp;
    rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', col.location{3}{LL});
end

title( 'Solo Trajectories' )

xlabel( 'x (°)' )
ylabel( 'y (°)' )

axis square

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [ OUT 'solo cursor Trajectories.png' ] )
saveas(h, [ OUT 'solo cursor Trajectories.eps' ], 'epsc' )
%% plot joint trajectories

h = figure; hold on

for SESSION = 1:20
    CURSOR = 3;
    COND = 2;
    
    target = 0;
    for LOC = 1:2
        for POS = 1:4
            target = target+1;
            
            cursor.xy = allcursors{LOC,POS,CURSOR, SESSION};
            for TRIAL = 1:size(cursor.xy,3)
                
                plot( cursor.xy(1,:,TRIAL)*dpp, cursor.xy(2,:,TRIAL)*dpp, 'color', col.location{LOC}{POS} )
            end
        end
    end
    
end

xlim( [-1 +1] .* 13 )
ylim( [-1 +1] .* 13 )

for LL = 1:n.positions
    pos = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp;
    rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', col.location{3}{LL});
end

title( 'Joint Trajectories' )

xlabel( 'x (°)' )
ylabel( 'y (°)' )

axis square

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [ OUT 'Joint cursor Trajectories.png' ] )
saveas(h, [ OUT 'Joint cursor Trajectories.eps' ], 'epsc' )

%% plot solo error trajectories
clear cursor

col.location{1} = {'r' [1 0.36 0] 'y' 'g'};
col.location{2} = {'c' 'b' [0.5 0.25 0.6]  'm'};
col.location{3} = {[0.5 0.25 0.6] 'm' 'r' [1 0.36 0] 'y' 'g' 'c' 'b' };

close all

clear IM

h = figure; hold on

for SESSION = 1:20
    for CURSOR = 1:2
        COND = 1;
        
        target = 0;
        for LOC = 1:2
            for POS = 1:4
                target = target+1;
                
                cursor.xy = allcursors_error{LOC,POS,CURSOR, SESSION};
                for TRIAL = 1:size(cursor.xy,3)
                    
                    plot( cursor.xy(1,:,TRIAL)*dpp, cursor.xy(2,:,TRIAL)*dpp, 'color', col.location{LOC}{POS} )
                end
            end
        end
        
        
    end
end

xlim( [-1 +1] .* 13 )
ylim( [-1 +1] .* 13 )

for LL = 1:n.positions
    pos = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp;
    rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', col.location{3}{LL});
end

title( 'Solo Trajectories' )

xlabel( 'x (°)' )
ylabel( 'y (°)' )

axis square

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [ OUT 'solo error cursor Trajectories.png' ] )

%% plot joint error trajectories

h = figure; hold on

for SESSION = 1:20
    CURSOR = 3;
    COND = 2;
    
    target = 0;
    for LOC = 1:2
        for POS = 1:4
            target = target+1;
            
            cursor.xy = allcursors_error{LOC,POS,CURSOR, SESSION};
            for TRIAL = 1:size(cursor.xy,3)
                
                plot( cursor.xy(1,:,TRIAL)*dpp, cursor.xy(2,:,TRIAL)*dpp, 'color', col.location{LOC}{POS} )
            end
        end
    end
    
end

xlim( [-1 +1] .* 13 )
ylim( [-1 +1] .* 13 )

for LL = 1:n.positions
    pos = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp;
    rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', col.location{3}{LL});
end

title( 'Joint error Trajectories' )

xlabel( 'x (°)' )
ylabel( 'y (°)' )

axis square

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [ OUT 'Joint error cursor Trajectories.png' ] )