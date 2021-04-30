clear; clc; close all; restoredefaultpath

addpath('..\common\')
addpath('..\external\')
addpath(genpath('..\external\kakearney-boundedline-pkg-50f7e4b'))

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = 'import_eyetracker_matlab2\';
load '..\data_manager\CheckFiles2\fname.mat'

number_of_sessions = 20;
number_of_players = 2;

str.side = {'left', 'right'};
str.player = {'P1', 'P2'};

is_load_fresh = true;
is_figure_visible = 'off';

sessions_to_use = [6 7 8 9 10 11 12 13 14 15 16 17 18 19 21 22 23]; % exclude 2 3 5


%% triggers

TRIG.fix = [1 2]; % Hz combo 1, 2
TRIG.task_cue = [3 4]; % solo, co-op
TRIG.move_cue = [5 6]; % left/right
TRIG.feedback = 7; % feedback onset


%% settings

fs = 120;

COND = TRIG.move_cue;

str.COND = {'solo' 'coop'};
STR.SIDE = {'left' 'right'};
mon.res = [1920 1080];

n.trials = 960;
dpp = (53.2/1920); % degrees/pixel


%% RUN!

if is_load_fresh
    
    ses_count = 0;
    
    for SES = sessions_to_use
        
        
        disp('****************************')
        disp(SES)
        
        close all;
        clear IM
        
        ses_count = ses_count+1;

           
        %% get behavioural data

        SES_string = ['S' num2str(SES) ' test*'];
        idx = strfndw(fname.behave, SES_string);
        
        leader = ['S' num2str(SES)];
        
        disp(fname.behave{idx})

        load( [fname.direct_behav fname.behave{idx} ], 'data', 'D', 'n', 'array', 'sizes', 'str', 'cursor');
 
        cond_test.behave = data(:,D.cond)+2;
        
        for PLAYER = 1:number_of_players
            
            
            %% get eye data    
            
            fname.EYE = [leader '.' str.player{PLAYER} '.eyeData.mat'];
            load( [ IN fname.EYE ], 'samples', 'type', 'latency' )
            
            cond_test.eye = type;
            cond_test.eye = cond_test.eye(ismember(cond_test.eye,TRIG.task_cue));
            
            aligned = all(cond_test.behave == cond_test.eye);
            
            if ~aligned
                error('~aligned')
            end
            
            fname.save = [leader '_' STR.SIDE{PLAYER}];
            fname.tit = [ leader ' ' STR.SIDE{PLAYER}];
            

            %% get eye positions
            idx.x = [6 8];
            idx.y = [7 9];
            
            samples(samples == 0) = NaN;
            GAZE = [ nanmean(samples(:,idx.x),2) nanmean(samples(:,idx.y),2)];
            time = samples(:,1);
            
            %% Recentre data based on Pre-move cue period
            
            lim.s = [-0.5 0];
            lim.S = lim.s*1000000;
            f.trial = (lim.s(2) - lim.s(1))*fs;
            
            IDX = find(ismember(type, TRIG.task_cue));
            
            start_time = latency(IDX+1)+lim.S(1);
            stop_time = latency(IDX+1)+lim.S(2);
            
            gaze.x = nan(f.trial, length(start_time));
            gaze.y = nan(f.trial, length(start_time));
            
            for O = 1:length(start_time)
                idx.trial = find(time >= start_time(O) & time < stop_time(O));
                gaze.x(1:length(idx.trial),O) = GAZE(idx.trial, 1);
                gaze.y(1:length(idx.trial),O) = GAZE(idx.trial, 2);
            end
            
            if size(gaze.x,1)>f.trial
                gaze.x = gaze.x(1:f.trial,:);
                gaze.y = gaze.y(1:f.trial,:);
            end
            
            %% recentre
            
            GAZEIM = round([gaze.y(:) gaze.x(:)]);
            vXEdge = 1:2:mon.res(1);
            vYEdge = 1:2:mon.res(2);
            gazehist = hist2d( GAZEIM, vYEdge, vXEdge );
            
            [~, Center.x] = max(max(gazehist, [], 1), [], 2);
            [~, Center.y] = max(max(gazehist, [], 2), [], 1);
            
            GAZE(:,1) = GAZE(:,1) - Center.x + mon.res(1)/4 - mon.res(1)/2;
            
            GAZE(:,2) = GAZE(:,2) - Center.y + mon.res(2)/4 - mon.res(2)/2;
            
            
            
            %% Get post-move cue period
            
            COND = TRIG.move_cue;
            
            IDX = find(ismember(type, TRIG.task_cue));
            
            lim.s = [0 2.5];
            lim.S = lim.s*1000000;
            
            f.trial = (lim.s(2) - lim.s(1))*fs;
            time = samples(:,1);
            
            %% get gaze data for post-movecue period
            
            start_time = latency(IDX+1)+lim.S(1);
            stop_time = latency(IDX+1)+lim.S(2);
            
            gaze.x = nan(f.trial, length(start_time));
            gaze.y = nan(f.trial, length(start_time));
            
            for O = 1:length(start_time)
                idx.trial = find(time >= start_time(O) & time < stop_time(O));
                
                gaze.x(1:length(idx.trial),O) = GAZE(idx.trial, 1);
                gaze.y(1:length(idx.trial),O) = GAZE(idx.trial, 2);
            end
            
            %% plot trajectories
            % -- prepare data in dva
            
            Gaze.y = -gaze.y.*dpp;
            Gaze.x = gaze.x.*dpp;
            Array.x = array.x.*dpp;
            Array.y = array.y.*dpp;
            Sizes.target = sizes.target*dpp;
            bounds.x = [min(Array.x)-5 max(Array.x)+5];
            bounds.y = [min(Array.y)-5 max(Array.y)+5];
            
            % -- things for plotting
            col.location{1} = {'r' [1 0.36 0] 'y' 'g'};
            col.location{2} = {'c' 'b' [0.5 0.25 0.6]  'm'};
            col.location{3} = {[0.5 0.25 0.6] 'm' 'r' [1 0.36 0] 'y' 'g' 'c' 'b' };
            
            ArrayPos = [
                3 7
                4 8
                5 1
                6 2];
            
            % -- preallocate
            MT_max = 2.5;
            n.pointsmax = fs*MT_max;
            n.targ = 8;
            n.trialsmaxloc = n.trials/n.targ;
            stretch = 370;
            
            traject.x = nan(stretch,n.trialsmaxloc, n.targ, n.cond);
            traject.y = nan(stretch,n.trialsmaxloc, n.targ, n.cond);
            
            trajectC.x = nan(stretch,n.trialsmaxloc, n.targ, n.cond);
            trajectC.y = nan(stretch,n.trialsmaxloc, n.targ, n.cond);
            
            % -- run!
            
            for COND = 1:2;
                switch COND
                    case 1
                        CURSOR = PLAYER;
                    case 2
                        CURSOR = 3;
                end
                
                h = figure('visible','off'); hold on
                
                xlim( [-500 +500].*dpp )
                ylim( [-500 +500].*dpp )
                
                target = 0;
                for LOC = 1:2
                    for POS = 1:4
                        target = target+1;
                        IDX = find( data(:,D.location) == LOC & data(:,D.position_combo) == POS  & data(:,D.correct(CURSOR)) == 1 & data(:,D.cond) == COND   );
                        
                        % --- draw target circle
                        LL = ArrayPos(POS,LOC);
                        
                        Xpos = (Array.x(LL)-Sizes.target/2);
                        Ypos = (Array.y(LL)-Sizes.target/2);
                        pos = [Xpos Ypos Sizes.target Sizes.target];
                        rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', col.location{3}{LL}, 'LineWidth',3);
                        
                        for TRIAL = 1:length(IDX)
                            
                            % -- get movement end
                            moveframes = data(IDX(TRIAL),D.inside_frame(CURSOR))-data(IDX(TRIAL),D.move_cue_frame);
                            moveframes = round((moveframes/144)*120);
                            
                            % -- get eyedata in this period
                            GAZEX = Gaze.x(1:moveframes,IDX(TRIAL));
                            GAZEY = Gaze.y(1:moveframes,IDX(TRIAL));
                            
                            % -- get cursor data in this period
                            MF = data(IDX(TRIAL),D.move_cue_frame);
                            IF = data(IDX(TRIAL),D.inside_frame(CURSOR));
                            MT = IF-MF +1;
                            
                            CURSX = cursor.xy(1,MF:IF,IDX(TRIAL),CURSOR);
                            CURSY = cursor.xy(2,MF:IF,IDX(TRIAL),CURSOR);
                            
                            % -- conditions for exclusion
                            conditions = [
                                GAZEX(1) > -1.5 & GAZEX(1) < +1.5
                                GAZEY(1) > -1.5 & GAZEY(1) < +1.5
                                GAZEX(end) > Array.x(LL)-1.5 & GAZEX(end) < Array.x(LL)+1.5
                                GAZEY(end) > Array.y(LL)-1.5 & GAZEY(end) < Array.y(LL)+1.5
                                ~any(GAZEX<bounds.x(1)) &  ~any(GAZEX>bounds.x(2))
                                ~any(GAZEY<bounds.y(1)) &  ~any(GAZEY>bounds.y(2))
                                moveframes < n.pointsmax
                                ];
                            
                            
                            if ~all(conditions);
                                continue % don't plot crazy trials
                            end
                            
                            
                            %% stretch eyedata
                            clear GAZEX2 GAZEY2
                            
                            frames = linspace(1,length(GAZEX),stretch);
                            
                            for FF = 1:stretch
                                
                                if rem(frames(FF),1) ==0
                                    GAZEX2(FF) =  GAZEX(frames(FF));
                                    GAZEY2(FF) =  GAZEY(frames(FF));
                                    
                                else
                                    
                                    start = floor( frames(FF) ); % 1
                                    stop = ceil( frames(FF) ); % 2
                                    
                                    weight2 = frames(FF) - start; % 0.6605
                                    weight1 = 1 - weight2; % 0.3395
                                    
                                    GAZEX2(FF) = GAZEX(start) * weight1 +GAZEX(stop) * weight2;
                                    GAZEY2(FF) = GAZEY(start) * weight1 +GAZEY(stop) * weight2;
                                end
                            end
                            
                            %% stretch cursor data
                            clear CURSX2 CURSY2
                            frames = linspace(1,length(CURSX),stretch);
                            
                            for FF = 1:stretch
                                
                                if rem(frames(FF),1) ==0
                                    CURSX2(FF) =  CURSX(frames(FF));
                                    CURSY2(FF) =  CURSY(frames(FF));
                                    
                                else
                                    
                                    start = floor( frames(FF) ); % 1
                                    stop = ceil( frames(FF) ); % 2
                                    
                                    weight2 = frames(FF) - start; % 0.6605
                                    weight1 = 1 - weight2; % 0.3395
                                    
                                    CURSX2(FF) =  CURSX(start) * weight1 +CURSX(stop) * weight2;
                                    CURSY2(FF) =  CURSY(start) * weight1 +CURSY(stop) * weight2;
                                end
                            end
                            
                            
                            %% -- plot trajectory
                            plot(GAZEX2,  GAZEY2, 'color', col.location{LOC}{POS} )
                            
                            % -- store trajectories
                            traject.x(:,TRIAL, target, COND) = GAZEX2;
                            traject.y(:,TRIAL, target, COND) = GAZEY2;
                            
                            trajectC.x(:,TRIAL, target, COND) = CURSX2*dpp;
                            trajectC.y(:,TRIAL, target, COND) = CURSY2*dpp;
                            
                        end
                    end
                end
                
                axis square
                
                xlabel( 'x (px)' )
                ylabel( 'y (px)' )
                
                title( [ str.player{PLAYER} ' ' str.cond{COND} ' Trajectories ' ] )
                saveas(h, [ OUT leader '.'  str.player{PLAYER} ' ' str.cond{COND}  ' Trajectories.png' ] )
                IM{PLAYER,COND} = imread( [ OUT leader '.' str.player{PLAYER} ' ' str.cond{COND} ' Trajectories.png' ] );
                
            end
            
            %% get rid of excess trials
            clear TRAJECT
            
            TRAJECT.x = cell(8,2);
            TRAJECT.y = cell(8,2);
            
            TRAJECTC.x = cell(8,2);
            TRAJECTC.y = cell(8,2);
            
            str.dim = {'x' 'y'};
            for dim = 1:2
                for COND = 1:2
                    for target = 1:n.targ
                        tcount = 0;
                        for TRIAL = 1:n.trialsmaxloc
                            
                            X = (traject.(str.dim{dim})(:,TRIAL, target, COND));
                            XCurs = (trajectC.(str.dim{dim})(:,TRIAL, target, COND));
                            
                            Nx = find(isnan(X));
                            
                            if ~any(Nx)
                                tcount = tcount+1;
                                TRAJECT.(str.dim{dim}){target,COND}(:,tcount) = X;
                                TRAJECTC.(str.dim{dim}){target,COND}(:,tcount) = XCurs;
                                continue;
                            end
                            if Nx(1) == 1
                                
                                %disp('trial skipped')
                                continue;
                            end
                            
                        end
                    end
                end
            end
            
            %% Rotate
            
            %        1  8
            %      2      7
            %      3      6
            %        4  5
            
            %   6    5     4     3     2     1     8    7
            % [22.5 67.5 112.5 157.5 202.5 247.5 292.5 337.5 ];
            
            angrot = [247.5 202.5 157.5 112.5 67.5 22.5 337.5 292.5 ];
            TRAJECT2.x = cell(1,2);
            TRAJECT2.y = cell(1,2);
            TRAJECTC2.x = cell(1,2);
            TRAJECTC2.y = cell(1,2);
            for COND = 1:2
                h = figure('visible','off');
                hold on;
                tcount = 0;
                for target = 1:n.targ;
                    for TRIAL = 1:size(TRAJECT.x{target,COND},2);
                        tcount = tcount+1;
                        
                        % define the x- and y-data for the original line we would like to rotate
                        x = TRAJECT.x{target,COND}(:,TRIAL)';
                        y = TRAJECT.y{target,COND}(:,TRIAL)';
                        
                        xc = TRAJECTC.x{target,COND}(:,TRIAL)';
                        yc = TRAJECTC.y{target,COND}(:,TRIAL)';
                        
                        % create a matrix of these points, which will be useful in future calculations
                        v = [x;y];
                        vc = [xc;yc];
                        
                        % choose a point which will be the center of rotation
                        x_center = 0;
                        y_center = 0;
                        center = repmat([x_center; y_center], 1, length(x));
                        
                        % define a counter-clockwise rotation matrix
                        theta = deg2rad(angrot(target));
                        R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
                        
                        % do the rotation...
                        vo = R*(v - center) + center;
                        voc = R*(vc - center) + center;
                        
                        % pick out the vectors of rotated x- and y-data
                        x_rotated = vo(1,:);
                        y_rotated = vo(2,:);
                        
                        
                        TRAJECT2.x{COND}(:,tcount) = x_rotated;
                        TRAJECT2.y{COND}(:,tcount) = y_rotated;
                        
                        TRAJECTC2.x{COND}(:,tcount) = voc(1,:);
                        TRAJECTC2.y{COND}(:,tcount) = voc(2,:);
                        
                        % make a plot
                        plot(x, y, 'k-', x_rotated, y_rotated, 'r-', x_center, y_center, 'bo');
                        
                    end
                end
                
                xlim( [-500 +500].*dpp )
                ylim( [-500 +500].*dpp )
                
                title([str.player{PLAYER} ' ' str.cond{COND}])
                saveas(h, [ OUT leader '.' str.player{PLAYER} ' ' str.cond{COND} ' rotated trajectories.png' ] )
                IM{PLAYER+2,COND} = imread( [ OUT leader '.'  str.player{PLAYER} ' ' str.cond{COND} ' rotated trajectories.png' ]  );
            end
            
            %% mean trajectories
            clear data2use M E
            close all
            h = figure('visible','off');
            hold on;
            
            col.cursor = {'r' 'b' };
            
            targetpos = sqrt((array.x(1))^2+(array.y(1))^2)*dpp-(dpp*sizes.target/2);
            
            for COND = 1:2
                % -- cursor
                data2use.x = TRAJECTC2.x{COND};
                data2use.y = TRAJECTC2.y{COND};
                
                M.xc(:,COND) = mean(data2use.x,2);
                M.yc(:,COND) = mean(data2use.y,2);
                
                if size(data2use.x,2) <2
                    E.xc(:,COND) = zeros(370,1);
                    E.yc(:,COND) = zeros(370,1);
                else
                    E.xc(:,COND) = std(data2use.x')/sqrt(size(data2use.x,2));
                    E.yc(:,COND) = std(data2use.y')/sqrt(size(data2use.y,2));
                end
                % -- eyes
                data2use.x = TRAJECT2.x{COND };
                data2use.y = TRAJECT2.y{COND };
                
                M.xe(:,COND) = mean(data2use.x,2);
                M.ye(:,COND) = mean(data2use.y,2);
                
                if size(data2use.x,2) <2
                    E.xe(:,COND) = zeros(370,1);
                    E.ye(:,COND) = zeros(370,1);
                else
                    E.xe(:,COND) = std(data2use.x')/sqrt(size(data2use.x,2));
                    E.ye(:,COND) = std(data2use.y')/sqrt(size(data2use.y,2));
                end
            end
            
            for COND = 1:2
                subplot(1,2,COND)
                
                boundedline(M.xc(:,COND), M.yc(:,COND), E.yc(:,COND), 'alpha', col.cursor{1},M.xe(:,COND), M.ye(:,COND), E.ye(:,COND), 'alpha', col.cursor{2})
                
                rectangle('Position',[targetpos -dpp*sizes.target/2 dpp*sizes.target dpp*sizes.target],'Curvature',[1 1], 'edgecolor', 'k');
                
                Ms = [M.yc(:);M.ye(:)];
                ylim([-max(abs(Ms(:)))-0.1 max(abs(Ms(:)))+0.1])
                xlim([0 8])
                
                line(get(gca, 'xlim'), [0 0], 'color', 'k', 'LineStyle', '--')
                ylabel('° of visual angle')
                xlabel('° of visual angle')
                
                axis square
                legend({'Cursor' 'Eye position'})
                title(str.cond{COND});
                
            end
            
            suptitle([ str.player{PLAYER} ' Cursor and eye positions'])
            
            saveas(h, [ OUT leader ' ' str.player{PLAYER} ' ' str.cond{COND} ' Mean Trajectories.png' ] )
            IM2{PLAYER,1} = imread( [ OUT leader ' ' str.player{PLAYER} ' ' str.cond{COND} ' Mean Trajectories.png' ] );
            
            result.Mtrajectories = M;
            
            %% Distance
            
            clear data2use M E
            close all
            h = figure('visible','off');
            hold on;
            
            col.cursor = {'r' 'b' };
            
            targetpos = sqrt((array.x(1))^2+(array.y(1))^2)*dpp-(dpp*sizes.target/2);
            
            for COND = 1:2
                % -- cursor
                data2use = sqrt((targetpos - TRAJECTC2.x{COND } ).^2+ (0 - TRAJECTC2.y{COND } ).^2);
                
                M.c(:,COND) = mean(data2use,2);
                
                if size(data2use,2) <2
                    E.c(:,COND) = zeros(370,1);
                else
                    E.c(:,COND) = std(data2use')/sqrt(size(data2use,2));
                end
                
                % -- eyes
                data2use = sqrt((targetpos - TRAJECT2.x{COND } ).^2+ (0 - TRAJECT2.y{COND } ).^2);
                
                M.e(:,COND) = mean(data2use,2);
                
                if size(data2use,2) <2
                    E.e(:,COND) = zeros(370,1);
                else
                    E.e(:,COND) = std(data2use')/sqrt(size(data2use,2));
                end
            end
            
            for COND = 1:2
                subplot(1,2,COND)
                
                boundedline((1:370)/370, M.c(:,COND), E.c(:,COND), 'alpha', col.cursor{1},(1:370)/370, M.e(:,COND), E.e(:,COND), 'alpha', col.cursor{2})
                
                
                ylim([0 8])
                xlim([0 1])
                
                ylabel('Distance from target (°)')
                xlabel('Proportion of trial')
                
                axis square
                legend({'Cursor' 'Eye position'})
                title(str.cond{COND});
                
            end
            
            suptitle([ str.player{PLAYER} ' Cursor and eye Distance from target'])
            
            saveas(h, [ OUT leader ' ' str.player{PLAYER} ' ' str.cond{COND} ' Mean Distance.png' ] )
            IM2{PLAYER+2,1} = imread( [ OUT leader ' ' str.player{PLAYER} ' ' str.cond{COND} ' Mean Distance.png' ] );
            
            result.MDistance = M;
            
            %% save
            
            save([OUT leader '.' str.player{PLAYER} 'result.mat'], 'result')
            
        end
        imwrite( cell2mat(IM), [ OUT leader '_Trajectories.png' ] )
        imwrite( cell2mat(IM2), [ OUT leader '_MeanTrajectories.png' ] )
    end
    
end


%% group together

sessions2use = [6 9 10 11 12 13 14 15 16 17 18 19 21 22 23]; % exclude 2 3 5

Pcount = 0;
for SES = sessions2use
    for PLAYER = 1:2
        Pcount = Pcount+1;
  
        
        load([OUT 'S' num2str(SES) '.' str.player{PLAYER} 'result.mat'], 'result')
        
        % -- trajectories
        RESULT.Traj.xc(:,:, Pcount ) = result.Mtrajectories.xc;
        RESULT.Traj.yc(:,:, Pcount ) = result.Mtrajectories.yc;
        RESULT.Traj.xe(:,:, Pcount ) = result.Mtrajectories.xe;
        RESULT.Traj.ye(:,:, Pcount ) = result.Mtrajectories.ye;
        
        % -- distance
        
        RESULT.Dist.c(:,:, Pcount ) = result.MDistance.c;
        RESULT.Dist.e(:,:, Pcount ) = result.MDistance.e;
    end
end


%% Distance

clear data2use M E
close all
h = figure('visible','off');
hold on;

col.cursor = {'r' 'b' 'm' 'c'};

% -- cursor
data2use.c = RESULT.Dist.c;
data2use.e = RESULT.Dist.e;

M.c = mean(data2use.c,3);
M.e = mean(data2use.e,3);

for COND = 1:2
    E.c(:,COND) =  ws_bars(squeeze(data2use.c(:,COND,:))');
    E.e(:,COND) =  ws_bars(squeeze(data2use.e(:,COND,:))');
end

for COND = 1:2
    subplot(1,2,COND)
    
    boundedline((1:370)/370, M.c(:,COND), E.c(:,COND), 'alpha', col.cursor{1},(1:370)/370, M.e(:,COND), E.e(:,COND), 'alpha', col.cursor{2})
    
    ylim([0 8])
    xlim([0 1])
    
    ylabel('Distance from target centre (°)')
    xlabel('Proportion of Movement')
    
    axis square
    legend({'Cursor' 'Eye position'})
    title([str.cond{COND} ' trials']);
    
end

suptitle( 'Distance from target centre over movement duration')
saveas(h, [ OUT 'GRANDMEAN Distance.png' ] )


%% Distance alltogether

clear data2use M E
close all
h = figure('visible','off');

col.cursor = {'r' 'b' 'm' 'c'};

% -- cursor
data2use.c = RESULT.Dist.c;
data2use.e = RESULT.Dist.e;

M.c = mean(data2use.c,3);
M.e = mean(data2use.e,3);

for COND = 1:2
    E.c(:,COND) =  ws_bars(squeeze(data2use.c(:,COND,:))');
    E.e(:,COND) =  ws_bars(squeeze(data2use.e(:,COND,:))');
end

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

boundedline((1:370)/370, M.c(:,1), E.c(:,1), 'alpha', col.cursor{1},(1:370)/370, M.c(:,2), E.c(:,2), 'alpha', col.cursor{3},...
    (1:370)/370, M.e(:,1), E.e(:,1), 'alpha', col.cursor{2},(1:370)/370, M.e(:,2), E.e(:,2), 'alpha', col.cursor{4})


ylim([0 8])
xlim([0 1])

ylabel('Distance from target centre (°)')
xlabel('Proportion of Movement')

% axis square
legend({'Cursor - solo' 'Cursor - joint action' 'Eye position - solo'  'Eye position - joint action'})


suptitle( 'Distance from target centre over movement duration')


saveas(h, [ OUT 'GRANDMEAN Distance alltogether.png' ] )
saveas(h, [ OUT 'GRANDMEAN Distance alltogether.eps' ], 'epsc' )


%% grand mean trajectories

clear data2use M E
close all
h = figure('visible','off');
hold on;

col.cursor = {'r' 'b' };

targetpos = 7.0273;

M.xc = mean(RESULT.Traj.xc,3);
M.yc = mean(RESULT.Traj.yc,3);
M.xe = mean(RESULT.Traj.xe,3);
M.ye = mean(RESULT.Traj.ye,3);

for COND = 1:2
    E.xc(:,COND) =  ws_bars(squeeze(RESULT.Traj.xc(:,COND,:))');
    E.yc(:,COND) =  ws_bars(squeeze(RESULT.Traj.yc(:,COND,:))');
    E.xe(:,COND) =  ws_bars(squeeze(RESULT.Traj.xe(:,COND,:))');
    E.ye(:,COND) =  ws_bars(squeeze(RESULT.Traj.ye(:,COND,:))');
end


for COND = 1:2
    
    subplot(1,2,COND)
    boundedline(M.xc(:,COND), M.yc(:,COND), E.yc(:,COND), 'alpha', col.cursor{1},M.xe(:,COND), M.ye(:,COND), E.ye(:,COND), 'alpha', col.cursor{2})
    
    rectangle('Position',[targetpos -dpp*sizes.target/2 dpp*sizes.target dpp*sizes.target],'Curvature',[1 1], 'edgecolor', 'k');
    
    Ms = [M.yc(:);M.ye(:)];
    ylim([-max(abs(Ms(:)))-0.05 max(abs(Ms(:)))+0.05])
    xlim([0 8])
    
    line(get(gca, 'xlim'), [0 0], 'color', 'k', 'LineStyle', '--')
    ylabel('° of visual angle')
    xlabel('° of visual angle')
    
    axis square
    legend({'Cursor' 'Eye position'})
    title(str.cond{COND});
    
end

suptitle([ 'Cursor and Eye Trajectories'])
saveas(h, [ OUT 'GRANDMEAN Trajectories.png' ] )