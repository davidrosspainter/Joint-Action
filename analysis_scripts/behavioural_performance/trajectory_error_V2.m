close all; clear; restoredefaultpath

addpath('..\external')
addpath('..\common')
addpath(genpath('D:\JointActionRevision\analysis\external\kakearney-boundedline-pkg-50f7e4b'))

number_of_sessions = 20;
number_players = 2;

IN = '..\data_manager\CheckFiles2\';
load( [IN 'fname.mat'] )

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

is_figure_visible = 'off';
is_load_fresh = false;

n.trials = 960;
dpp = (53.2/1920); % degrees/pixel
n.cursors = 3;


if is_load_fresh
    for SESSION = 1:number_of_sessions
        
        close all
        
        disp('****************************')
        disp(num2str(SESSION))
        STR.SESSION = sess_string_gen(SESSION);
        load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer');
        
        
        %% rand info
        
        n.cursors = 3;
        TRIGGERS = triggers(:, 1:n.trials);
        
        DTRIGGERS = [ ones(1,n.trials); diff(TRIGGERS) ] > 0;
        trigger_onset = TRIGGERS.*DTRIGGERS;
        
        str.cursor = {'P1' 'P2' 'Joint Action'};
        str.cond = {'Solo' 'Co-op'};
        
        
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
        
        
        TIT = [STR.SESSION  '.accuracy.png'];
        
        h = figure('visible', is_figure_visible);
        
        bar(res)
        ylabel('Proportion Correct' )
        set(gca, 'xticklabel', {'P1' 'P2' 'Joint'} )
        xlabel( 'Condition' )
        title(TIT)
        colormap([0.9 0.9 0.9])
        ylim([min(res)-0.1 max(res) + 0.1])
        
        saveas(h, [OUT TIT])
        
        
        %% plot trajectories
        
        col.location{1} = {'r' [1 0.36 0] 'y' 'g'};
        col.location{2} = {'c' 'b' [0.5 0.25 0.6]  'm'};
        col.location{3} = {[0.5 0.25 0.6] 'm' 'r' [1 0.36 0] 'y' 'g' 'c' 'b' };
        
        clear IM
        
        for CURSOR = 1:n.cursors
            
            h = figure('visible', is_figure_visible); hold on
            TIT = [STR.SESSION '.' str.cursor{CURSOR} '.trajectories.png'];
            
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
                    
                    for TRIAL = 1:length(IDX)
                        plot( cursor.xy(1,:,IDX(TRIAL),CURSOR)*dpp, cursor.xy(2,:,IDX(TRIAL),CURSOR)*dpp, 'color', col.location{LOC}{POS} )
                    end
                end
            end
            
            xlim( [-1 +1] .* 10 )
            ylim( [-1 +1] .* 10 )
            
            for LL = 1:n.positions
                pos = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp;
                rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', col.location{3}{LL});
            end
            
            title( str.cursor{CURSOR} )
            
            xlabel( 'x (°)' )
            ylabel( 'y (°)' )
            
            axis square
            
            title(TIT)
            saveas(h, [OUT TIT])
            IM{1,CURSOR} = imread( [OUT TIT]);
            
        end
        
        imwrite(cell2mat(IM), [OUT STR.SESSION '.trajectories.png'])
        
        
        %% get trajectories
        
        MT_max = 1.5;
        n.pointsmax = mon.ref*MT_max;
        n.targ = 8;
        n.trialsmaxloc = n.trials/n.targ;
        
        traject.x = nan(n.pointsmax,n.trialsmaxloc, n.targ, n.cursors);
        traject.y = nan(n.pointsmax,n.trialsmaxloc, n.targ, n.cursors);
        
        for CURSOR = 1:n.cursors
            switch CURSOR
                case 1; COND = 1;
                case 2; COND = 1;
                case 3; COND = 2;
            end
            
            target = 0;
            
            for LOC = 1:2
                for POS = 1:4
                    target = target+1;
                    IDX = find( data(:,D.location) == LOC & data(:,D.position_combo) == POS & data(:,D.cond) == COND & data(:,D.correct(CURSOR) ) == 1  );
                    
                    for TRIAL = 1:length(IDX)
                        RF = data(IDX(TRIAL),D.react_frame(CURSOR));
                        IF = data(IDX(TRIAL),D.inside_frame(CURSOR));
                        MT = IF-RF+1;
                        if MT>n.pointsmax; continue; end
                        
                        traject.x(1:MT,TRIAL, target, CURSOR) = cursor.xy(1,RF:IF,IDX(TRIAL),CURSOR);
                        traject.y(1:MT,TRIAL, target, CURSOR) = cursor.xy(2,RF:IF,IDX(TRIAL),CURSOR);
                    end
                end
            end
        end
        
        
        %% interpolate trajectories
        
        clear TRAJECT  
        str.dim = {'x', 'y'};
        
        for dim = 1:2
            for CURSOR = 1:n.cursors
                for target = 1:n.targ
                    tcount = 0;
                    for TRIAL = 1:n.trialsmaxloc
                        
                        X = (traject.(str.dim{dim})(:,TRIAL, target, CURSOR));
                        
                        Nx = find(isnan(X));
                        
                        if ~any(Nx)
                            tcount = tcount+1;
                            TRAJECT.(str.dim{dim}){target,CURSOR}(:,tcount) = X;
                            continue;
                        end
                        if Nx(1) == 1
                            disp('trial skipped')
                            continue;
                        end
                        tcount = tcount+1;
                        
                        Nx = Nx(1)-1; % find end of sequence
                        
                        frames = linspace(1,Nx,n.pointsmax);
                        
                        for FF = 1:n.pointsmax
                            
                            if rem(frames(FF),1) ==0
                                TRAJECT.(str.dim{dim}){target,CURSOR}(FF,tcount) = X(frames(FF));
                            else
                                
                                % frames(FF) 1.6605
                                
                                start = floor( frames(FF) ); % 1
                                stop = ceil( frames(FF) ); % 2
                                
                                weight2 = frames(FF) - start; % 0.6605
                                weight1 = 1 - weight2; % 0.3395
                                
                                TRAJECT.(str.dim{dim}){target,CURSOR}(FF,tcount) = X(start) * weight1 + X(stop) * weight2;
                                
                            end
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
        
        for CURSOR = 1:n.cursors
            
            h = figure('visible', is_figure_visible); hold on;
            
            TIT = [STR.SESSION  '.' str.cursor{CURSOR} '.rotated.trajectories.png'];
            
            tcount = 0;
            
            for target = 1:n.targ;
                for TRIAL = 1:size(TRAJECT.x{target,CURSOR},2);
                    tcount = tcount+1;
                    
                    % define the x- and y-data for the original line we would like to rotate
                    x = TRAJECT.x{target,CURSOR}(:,TRIAL)';
                    y = TRAJECT.y{target,CURSOR}(:,TRIAL)';
                    
                    % create a matrix of these points, which will be useful in future calculations
                    v = [x; y];
                    
                    % choose a point which will be the center of rotation
                    x_center = 0;
                    y_center = 0;
                    
                    % create a matrix which will be used later in calculations
                    center = repmat([x_center; y_center], 1, length(x));
                    
                    % define a counter-clockwise rotation matrix
                    theta = deg2rad(angrot(target));
                    R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
                    
                    % do the rotation...
                    % shift points in the plane so that the center of rotation is at the origin
                    % apply the rotation about the origin
                    % shift again so the origin goes back to the desired center of rotation
                    vo = R*(v - center) + center;
                    
                    % pick out the vectors of rotated x- and y-data
                    x_rotated = vo(1,:);
                    y_rotated = vo(2,:);
                    
                    TRAJECT2.x{CURSOR}(:,tcount) = x_rotated;
                    TRAJECT2.y{CURSOR}(:,tcount) = y_rotated;
                    % make a plot
                    
                    plot(x, y, 'k-', x_rotated, y_rotated, 'r-', x_center, y_center, 'bo');

                    
                end
            end
            
            
            xlim([-400 400])
            ylim([-400 400])
            title(str.cursor{CURSOR})
            suptitle(TIT)
            saveas(h, [OUT TIT]);
            
        end
        
        
        %% get error on trajectories
        
        clear data2use M E
        
        h = figure('visible', is_figure_visible); hold on;
        TIT = [STR.SESSION '.meanTrajectories.png' ];
        
        col.cursor = {'r', 'g', 'b'};
        
        for CURSOR = 1:n.cursors
            data2use.x = TRAJECT2.x{CURSOR};
            data2use.y = TRAJECT2.y{CURSOR};
            
            M.x(:,CURSOR) = mean(data2use.x,2)*dpp;
            M.y(:,CURSOR) = mean(data2use.y,2)*dpp;
            
            E.x(:,CURSOR) = std(data2use.x')/sqrt(size(data2use.x,2))*dpp;
            E.y(:,CURSOR) = std(data2use.y')/sqrt(size(data2use.y,2))*dpp;
        end
        
        boundedline(M.x(:,1), M.y(:,1), E.y(:,1), 'alpha', col.cursor{1},M.x(:,2), M.y(:,2), E.y(:,2), 'alpha', col.cursor{2}, M.x(:,3), M.y(:,3), E.y(:,3), 'alpha', col.cursor{3})
        
        xp = sqrt((array.x(1))^2+(array.y(1))^2)*dpp-(dpp*sizes.target/2);
        rectangle('Position',[xp -dpp*sizes.target/2 dpp*sizes.target dpp*sizes.target],'Curvature',[1 1], 'edgecolor', 'k');
        
        ylim([-max(abs(M.y(:)))-0.04 max(abs(M.y(:)))+0.04])
        xlim([0 8])
        
        line(get(gca, 'xlim'), [0 0], 'color', 'k', 'LineStyle', '--')
        ylabel('° of visual angle')
        xlabel('° of visual angle')
        
        axis square
        legend(str.cursor)
        title(TIT);
        saveas(h, [ OUT TIT ] )
        
        
        %% summarise X
        
        clear IM
        
        h = figure('visible', is_figure_visible); hold on;
        TIT = [STR.SESSION '.trajectory.error.x.png'];
        
        Eplot = E.x;
        t = 1/n.pointsmax:1/n.pointsmax:1;
        boundedline(t, zeros(1, n.pointsmax), Eplot(:,1), 'alpha', 'r', t, zeros(1, n.pointsmax), Eplot(:,2),'alpha',  'g', t, zeros(1, n.pointsmax), Eplot(:,3),'alpha', 'b')
        plot(t,Eplot(:,1),'r')
        plot(t,Eplot(:,2),'g')
        plot(t,Eplot(:,3),'b')
        
        legend(str.cursor)
        ylim([0 max(Eplot(:))+0.01])
        xlabel('proportion of movment')
        ylabel('Standard Error (° of visual angle)')
        title(TIT)
        saveas(h, [ OUT TIT ] )
        IM{1} = imread( [ OUT TIT ] );
        
        % ---- summarise Y
        
        h = figure('visible', is_figure_visible); hold on;
        TIT = [STR.SESSION '.trajectory.error.y.png'];
        
        Eplot = E.y;
        t = 1/n.pointsmax:1/n.pointsmax:1;
        boundedline(t, zeros(1, n.pointsmax), Eplot(:,1), 'alpha', 'r', t, zeros(1, n.pointsmax), Eplot(:,2),'alpha',  'g', t, zeros(1, n.pointsmax), Eplot(:,3),'alpha', 'b')
        plot(t,Eplot(:,1),'r')
        plot(t,Eplot(:,2),'g')
        plot(t,Eplot(:,3),'b')
        
        legend(str.cursor)
        ylim([0 max(Eplot(:))+0.01])
        xlabel('proportion of movment')
        ylabel('Standard Error (° of visual angle)')
        title(TIT)
        saveas(h, [ OUT TIT ] )
        IM{2} = imread( [ OUT TIT ] );
        
        imwrite( cell2mat(IM), [OUT STR.SESSION '.trajectory.error.png'])
        
        
        %% get absolute trajectories
        
        clear data2use M2 E2
        h = figure('visible', is_figure_visible); hold on;
        TIT = [STR.SESSION '.meanAbsoluteTrajectories.png'];
        
        col.cursor = {'r' 'g' 'b'};
        
        for CURSOR = 1:n.cursors
            data2use.x = abs(TRAJECT2.x{CURSOR});
            data2use.y = abs(TRAJECT2.y{CURSOR});
            
            M2.x(:,CURSOR) = mean(data2use.x,2)*dpp;
            M2.y(:,CURSOR) = mean(data2use.y,2)*dpp;
            
            E2.x(:,CURSOR) = std(data2use.x')/sqrt(size(data2use.x,2))*dpp;
            E2.y(:,CURSOR) = std(data2use.y')/sqrt(size(data2use.y,2))*dpp;
        end
        
        boundedline(M2.x(:,1), M2.y(:,1), E2.y(:,1), 'alpha', col.cursor{1},M2.x(:,2), M2.y(:,2), E2.y(:,2), 'alpha', col.cursor{2}, M2.x(:,3), M2.y(:,3), E2.y(:,3), 'alpha', col.cursor{3})
        
        xp = sqrt((array.x(1))^2+(array.y(1))^2)*dpp-(dpp*sizes.target/2);
        rectangle('Position',[xp -dpp*sizes.target/2 dpp*sizes.target dpp*sizes.target],'Curvature',[1 1], 'edgecolor', 'k');
        
        ylim([0 max(M2.y(:))+0.02])
        xlim([0 8])
        
        % line(get(gca, 'xlim'), [0 0], 'color', 'k', 'LineStyle', '--')
        ylabel('° of visual angle')
        xlabel('° of visual angle')
        
        axis square
        legend(str.cursor)
        title(TIT);
        saveas(h, [OUT TIT] )

        
        %% Regression
        clear R
        
        h = figure('visible', is_figure_visible); hold on;
        TIT = [STR.SESSION '.linearRegressions.png'];
        
        for CURSOR = 1:n.cursors
            data2use.x = (TRAJECT2.x{CURSOR})*dpp;
            data2use.y = (TRAJECT2.y{CURSOR})*dpp;
            
            subplot(1,3,CURSOR); hold on;
            for TRIAL = 1:size(data2use.x,2)
                x = data2use.x(:,TRIAL);
                y = data2use.y(:,TRIAL);
                LM = fitlm(x, y, 'linear', 'Intercept', false);
                
                R(CURSOR, TRIAL) = LM.Rsquared.Ordinary;
                m = LM.Coefficients{1,1};
                
                plot(x, m*x)
            end
            
            title([str.cursor{CURSOR} ' avg r^2= ' num2str(mean(R(CURSOR,:)))])
            ylim([-2 2])
            xlim([0 10])
            ylabel('° of visual angle')
            xlabel('° of visual angle')
            
        end
        
        suptitle(TIT);
        saveas(h, [OUT TIT])
        
        h = figure('visible', is_figure_visible); hold on;
        TIT = [STR.SESSION '.regressionFit.png'];
        Mr = mean(R,2)';
        Er = std(R')/sqrt(length(R));
        errorbar(Mr,Er)
        set(gca, 'xtick', 1:3, 'xticklabel', str.cursor)
        xlabel('cursor')
        ylabel('r^2 in linear regression')
        
        title(TIT)
        saveas(h,[OUT TIT ])
        
        
        %% data for saving
        save( [OUT STR.SESSION '.trajectories.mat'], 'TRAJECT2', 'R', 'E')
        
    end
    
    close all
    
end


%% load saved data

generate_global_variables

n.trialmax = n.trials/2;
n.sessions = 17;

RESULT.trajectx = NaN(216,n.trialmax,3,n.sessions);
RESULT.trajecty = NaN(216,n.trialmax,3,n.sessions);
RESULT.R = NaN(3,n.trialmax, n.sessions);

for SESSION = 1:number_of_sessions
    
    load( [OUT 'S' STR.session{SESSION} '.trajectories.mat'], 'TRAJECT2', 'R', 'E')
    
    for CURS = 1:3
        RESULT.trajectx(:,1:size(TRAJECT2.x{CURS},2),CURS,SESSION)=TRAJECT2.x{CURS}; %(points,trajectories,cursors,sessions)
        RESULT.trajecty(:,1:size(TRAJECT2.x{CURS},2),CURS,SESSION)=TRAJECT2.y{CURS};
    end
    
    RESULT.Ex(:,:,SESSION) = E.x;
    RESULT.Ey(:,:,SESSION) = E.y;
    RESULT.R(:,1:size(R,2),SESSION) = R;
    
end


%% grand mean trajectories

h = figure('visible', is_figure_visible); hold on

for CURSOR = 1:2
    for SESSION = 1:number_of_sessions
        traj.x = RESULT.trajectx(:,:,CURSOR,SESSION);
        traj.y = RESULT.trajecty(:,:,CURSOR,SESSION);
        
        %         col = rand( size(traj.x,2), 3);
        
        for T = 1:n.trialmax
            plot(traj.x(:,T),traj.y(:,T), 'color', [rand rand rand] );
        end
        
    end
end

plot(0, 0, 'ro'); % starting postion
ylim([-190 190])
xlim([-200 500])
title('All Solo Trajectories')
saveas(h, [OUT 'all_solo_trajectories.png'])

h = figure('visible', is_figure_visible); hold on

for CURSOR = 3
    for SESSION = 1:number_of_sessions
        traj.x = RESULT.trajectx(:,:,CURSOR,SESSION);
        traj.y = RESULT.trajecty(:,:,CURSOR,SESSION);
        for T = 1:n.trialmax
            plot(traj.x(:,T),traj.y(:,T), 'color', [rand rand rand] );
        end
        
    end
end

ylim([-190 190])
xlim([-200 500])
title('All Joint Trajectories')
saveas(h, [OUT 'all_joint_trajectories.png'])


%% get error on trajectories

clear M E traj
% close all

for CURSOR = 1:n.cursors
    traj.x(:,:,CURSOR) = squeeze(nanmean(abs(RESULT.trajectx(:,:,CURSOR,:)),2));
    traj.y(:,:,CURSOR) = squeeze(nanmean(abs(RESULT.trajecty(:,:,CURSOR,:)),2));
end

maxpeak = [nanmax(abs(traj.y(:,:,1)),[],1)' nanmax(abs(traj.y(:,:,2)),[],1)'];
[~, idxmax]=max(maxpeak');
idxmax2 = [idxmax' abs(idxmax'-3) ones(number_of_sessions,1)*3];

% -- reshuffle traj.x so that accurate and inaccurate participants are
% clumped together

for SESSION = 1:number_of_sessions
    traj.x(:,SESSION,:) = traj.x(:,SESSION,idxmax2(SESSION,:));
    traj.y(:,SESSION,:) = traj.y(:,SESSION,idxmax2(SESSION,:));
end

for CURSOR = 1:n.cursors
    M.x(:,CURSOR) = squeeze(nanmean(traj.x(:,:,CURSOR) ,2)*dpp);
    M.y(:,CURSOR) = squeeze(nanmean(traj.y(:,:,CURSOR) ,2)*dpp);
    
    E.x(:,CURSOR) = ws_bars(traj.x(:,:,CURSOR)')*dpp;
    E.y(:,CURSOR) = ws_bars(traj.y(:,:,CURSOR)')*dpp;
    
end


%% plot mean trajectories

addpath 'D:\JOINT.ACTION\JointActionRevision\analysis\external\kakearney-boundedline-pkg-50f7e4b\boundedline'
addpath 'D:\JOINT.ACTION\JointActionRevision\analysis\external\kakearney-boundedline-pkg-50f7e4b\Inpaint_nans'

load( [fname.direct_behav fname.behave{1} ], 'array', 'sizes', 'mon');

col.cursor = {'r' 'g' 'b'};

h = figure('visible', is_figure_visible); hold on

boundedline(M.x(:,1), M.y(:,1), E.y(:,1), 'alpha', col.cursor{1},M.x(:,2), M.y(:,2), E.y(:,2), 'alpha', col.cursor{2}, M.x(:,3), M.y(:,3), E.y(:,3), 'alpha', col.cursor{3})

xp = sqrt((array.x(1))^2+(array.y(1))^2)*dpp-(dpp*sizes.target/2);
rectangle('Position',[xp -dpp*sizes.target/2 dpp*sizes.target dpp*sizes.target],'Curvature',[1 1], 'edgecolor', 'k');

ylim([-max(abs(M.y(:)))-0.04 max(abs(M.y(:)))+0.04])
xlim([0 8])
ylim([0 0.7])

line(get(gca, 'xlim'), [0 0], 'color', 'k', 'LineStyle', '--')
ylabel('° of visual angle')
xlabel('° of visual angle')

% axis square
legend({'Far Participant' 'Close Participant' 'Joint Action'})
title('Mean Trajectories');

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [OUT 'Mean Trajectories.png' ] )
saveas(h, [OUT 'Mean Trajectories.eps' ], 'epsc' )


%% summarise X Error

MT_max = 1.5;
n.pointsmax = mon.ref*MT_max;
n.targ = 8;
n.trialsmaxloc = n.trials/n.targ;

close all
clear IM
h = figure('visible', is_figure_visible); hold on

for SESSION = 1:number_of_sessions
    RESULT.Exarranged(:,:,SESSION)=RESULT.Ex(:,idxmax2(SESSION,:),SESSION);
end

Eplot = nanmean(RESULT.Exarranged,3);

for CUR = 1:3
    EEplot(:,CUR) = ws_bars(squeeze(RESULT.Exarranged(:,CUR,:))');
end

t = 1/n.pointsmax:1/n.pointsmax:1;
boundedline(t, Eplot(:,1), EEplot(:,1), 'alpha', 'r', t, Eplot(:,2), EEplot(:,2),'alpha',  'g', t, Eplot(:,3), EEplot(:,3),'alpha', 'b')

legend({'Far Participant' 'Close Participant' 'Joint Action'})
ylim([0 max(Eplot(:))+0.01])
xlabel('proportion of movment')
ylabel('Standard Error (° of visual angle)')
title('Horizontal Trajectory Error')
saveas(h, [ OUT 'X Trajectory error.png' ] )


%% ---- summarise Y Error

clear IM
h = figure('visible', is_figure_visible); hold on

for SESSION = 1:number_of_sessions
    RESULT.Eyarranged(:,:,SESSION)=RESULT.Ey(:,idxmax2(SESSION,:),SESSION);
end

Eplot = nanmean(RESULT.Eyarranged,3);

for CUR = 1:3
    EEplot(:,CUR) = ws_bars(squeeze(RESULT.Eyarranged(:,CUR,:))');
end

t = 1/n.pointsmax:1/n.pointsmax:1;
boundedline(t, Eplot(:,1), EEplot(:,1), 'alpha', 'r', t, Eplot(:,2), EEplot(:,2),'alpha',  'g', t, Eplot(:,3), EEplot(:,3),'alpha', 'b')

legend({'Far Participant' 'Close Participant' 'Joint Action'})
ylim([0 max(Eplot(:))+0.01])
xlabel('proportion of movment')
ylabel('Standard Error (° of visual angle)')
title('Vertical Trajectory Error')
saveas(h, [ OUT 'Y Trajectory error.png' ] )


%% linear regression results.

h = figure('visible', is_figure_visible); hold on
Rplot = squeeze(nanmean(RESULT.R,2));

fit_results = Rplot';

save([OUT 'fit_results.mat'], 'fit_results', '-v6')



[~, idxmax] = max(Rplot([1 2],:));
idxmax2 = [idxmax' abs(idxmax'-3) ones(number_of_sessions,1)*3];

for SESSION = 1:number_of_sessions
    Rplot(:,SESSION) = Rplot(idxmax2(SESSION,:),SESSION);
end

Mr = nanmean(Rplot,2);
Er = ws_bars(Rplot');
errorbar_groups(Mr',Er, 'bar_colors', [0.9 0.9 0.9], 'bar_names', {'straight solo' 'curved solo' 'joint'}, 'FigID', h)

xlabel('cursor')
ylabel('r^2 in linear regression')

title('fit of linear regression')
ylim([0.55 0.75])

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [OUT 'regression fit.png' ] )
saveas(h, [OUT 'regression fit.eps' ], 'epsc' )

disp('***********************')
[H,P,CI,stats] = ttest(Rplot(3,:),  Rplot(2,:))
[H,P,CI,stats] = ttest(Rplot(3,:),  Rplot(1,:))
disp(mean(Rplot'))
disp(std(Rplot'))


%%

str.spss = ['Trajectory_Rsquared_Solo_goodfit\t' 'Trajectory_Rsquared_Solo_poorfit\t'  'Trajectory_Rsquared_Joint\t'   ];
spss.out = Rplot';


%% export to SPSS

out_name = [OUT 'JointAction_Trajectories.txt' ];

delete( out_name )
fid = fopen(out_name,'a+');

fprintf(fid, str.spss);
fprintf(fid, '\n');
dlmwrite(out_name, spss.out, '-append', 'delimiter', '\t');
fclose(fid);
