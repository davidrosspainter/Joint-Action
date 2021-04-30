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


%% endpoint accuracy...

is_load_fresh = true;
is_debug_endpoint = false;

dpp = (53.2/1920); % degrees/pixel
col = {'r', 'g', 'b'};

LOC_CODE = [3 7 % - uppermost left, lowermost right
    4 8 % - upper left, lower right
    5 1 % - lower left, upper right
    6 2]; % lowermost left, uppermost right

if is_debug_endpoint
    figure;
end

results = struct('control', cell(number_of_sessions,1), ...
    'target_position', cell(number_of_sessions,1), ...
    'endpoint', cell(number_of_sessions,1), ...
    'endpoint_displacement', cell(number_of_sessions,1));

if is_load_fresh
    for SESSION = 1:number_of_sessions
        
        disp('****************************')
        disp(num2str(SESSION))
        STR.SESSION =  STR.session;
        load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer');
        
        results(SESSION).control = data(:,D.cond);
        results(SESSION).target_position = NaN(number_of_trials,1);
        results(SESSION).trajectory = NaN(2, 1008, number_of_trials, n.cursors+1);
        results(SESSION).endpoint = NaN(2, number_of_trials, n.cursors+1);
        results(SESSION).endpoint_displacement = NaN(number_of_trials, n.cursors+1);
        
        for TRIAL = 1:number_of_trials
            
            if is_debug_endpoint
                
                %% all targets...
                
                clf; hold on
                
                for LL = 1:n.positions
                    position = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp;
                    rectangle('Position',position,'Curvature',[1 1], 'edgecolor', 'k');
                end
                
                xlim( [-1 +1] .* 13 )
                ylim( [-1 +1] .* 13 )
                axis equal
                
            end
            
            %% current target positions
            
            results(SESSION).target_position(TRIAL) = LOC_CODE(data(TRIAL,D.position_combo),data(TRIAL,D.location));
            
            target.x = array.x(results(SESSION).target_position(TRIAL))*dpp;
            target.y = array.y(results(SESSION).target_position(TRIAL))*dpp;
            
            if is_debug_endpoint
                scatter(target.x, target.y, 25, 'k', 'f')
            end
            
            
            %% cursor trajectories
            
            for CURSOR = 1:n.cursors+1
                
                IDX = find(~isnan(cursor.xy(1,:,TRIAL,CURSOR)), 1, 'last');
                X = cursor.xy(1,:,TRIAL,CURSOR)*dpp;
                Y = cursor.xy(2,:,TRIAL,CURSOR)*dpp;
                
                results(SESSION).trajectory(:,:,TRIAL,CURSOR) = [X; Y];
                results(SESSION).endpoint(:,TRIAL,CURSOR) = [X(IDX) Y(IDX)];
                results(SESSION).endpoint_displacement(TRIAL,CURSOR) = sqrt((target.x-X(IDX))^2 + (target.y-Y(IDX))^2);
                
                if is_debug_endpoint
                    plot(X, Y, col{CURSOR}) % plot trajectory
                    scatter(X(IDX), Y(IDX), 25, col{CURSOR}, 'f')  % plot endpoint
                    text(X(IDX)+.1, Y(IDX)+.1, num2str(results(SESSION).endpoint_displacement(TRIAL,CURSOR)))
                end
            end
            
            if is_debug_endpoint
                input('press enter')
            end
            
        end
        
        if SESSION == 20
            results(SESSION).endpoint(:,705:end,CURSOR) = NaN; %% controller disconnected!
            results(SESSION).endpoint_displacement(705:end,CURSOR) = NaN; %% controller disconnected!
        end

        
    end
end

% save results for R
save([OUT 'results.mat'], 'results', '-v6')


%% plot all endpoints

is_plot = true;

if is_plot
    
    % set up plot
    
    number_of_control = 2;
    number_of_visibility = 2;
    
    str_control = {'HP Solo', 'LP Solo', 'Joint'};
    str_visibility = {'Visible', 'Invisible'};
    
    close all
    clear h
    
    for FIGURE = 1:2
        
        figure(FIGURE); hold on
        %[ha, pos] = tight_subplot(2, 3, 0, 0, 0)
        
        col_location = [0.5 0.25 0.6
            1 0 1
            1 0 0
            1 0.36 0
            1 1 0
            0 1 0
            0 1 1
            0 0 1];
        
        for VISIBILITY = 1:number_of_visibility
            for CONTROL = 1:number_of_control+1 % hp solo, lp solo, joint
                subplot(2,3,(VISIBILITY-1)*3+CONTROL)
                axis equal
                hold on
                xlim([-1 +1] .* 13)
                ylim([-1 +1] .* 13)
                title([str_control{CONTROL} ': ' str_visibility{VISIBILITY}]);
            end
        end
        
    end
    
    
    ED = NaN(number_of_sessions, number_of_control+1, number_of_visibility);
    
    for SESSION = 1:number_of_sessions
        
        load(['curvature_runner\' STR.SESSION{SESSION} '.curvature_results.mat'], 'curvature_results', 'control')
        
        if SESSION == 20
            curvature_results(705:end,:) = NaN; %% controller disconnected!
        end
        
        for CONTROL = 1:number_of_control % solo/joint
            for VISIBILITY = 1:2
                
                if CONTROL == 1
                    if VISIBILITY == 1
                        COND = 1;
                        subplot_mod = 0;
                    else
                        COND = 2;
                        subplot_mod = 3;
                    end
                    
                    % ----- figure 1
                    
                    endpoint = results(SESSION).endpoint(:, results(SESSION).control == COND, 1:2);
                    endpoint_displacement = results(SESSION).endpoint_displacement(results(SESSION).control == COND, 1:2);
                    
                    % sort by best performer on endpoint displacement
                    
                    for TRIAL = 1:number_of_trials/2
                        [v, i] = sort(endpoint_displacement(TRIAL,:), 'ascend');
                        endpoint_displacement(TRIAL,:) = endpoint_displacement(TRIAL,i);
                        endpoint(:,TRIAL,:) = endpoint(:,TRIAL,i);
                    end
                    
                    ED(SESSION,1:2,VISIBILITY) = nanmean(endpoint_displacement);
                    
                    figure(1)
                    
                    for PLAYER = 1:number_of_players
                        subplot(2,3,PLAYER+subplot_mod)
                        scatter(endpoint(1,:,PLAYER), endpoint(2,:,PLAYER), 5, col_location(results(SESSION).target_position(results(SESSION).control == COND),:), 'f')
                    end
                    
                    
                    % ----- figure 2
                    
                    trajectory = results(SESSION).trajectory(:,:,results(SESSION).control == COND, 1:2);
                    target_positions = results(SESSION).target_position(results(SESSION).control == COND);
                    
                    curvature_to_use = curvature_results(results(SESSION).control == COND, 1:2);
                    
                    % sort by best performer on trajectory curvature
                    
                    for TRIAL = 1:number_of_trials/2
                        [v, i] = sort(curvature_to_use(TRIAL,:), 'ascend');
                        trajectory(:,:,TRIAL,:) = trajectory(:,:,TRIAL,i);
                    end
                    
                    figure(2)
                    
                    for PLAYER = 1:number_of_players
                        subplot(2,3,PLAYER+subplot_mod)
                        for TT = 1:8
                            plot(squeeze(trajectory(1,:,target_positions == TT,PLAYER)), squeeze(trajectory(2,:,target_positions == TT,PLAYER)), 'color', col_location(TT,:))
                        end
                    end
                    
                end
                
                if CONTROL == 2
                    if VISIBILITY == 1
                        COND = 2;
                        subplot_mod = 0;
                    else
                        COND = 1;
                        subplot_mod = 3;
                    end
                    
                    % ----- figure 1
                    
                    endpoint = results(SESSION).endpoint(:, results(SESSION).control == COND, 3);
                    endpoint_displacement = results(SESSION).endpoint_displacement(results(SESSION).control == COND, 3);
                    ED(SESSION,3,VISIBILITY) = nanmean(endpoint_displacement);
                    
                    figure(1)
                    subplot(2,3,3+subplot_mod)
                    scatter(endpoint(1,:), endpoint(2,:), 5, col_location(results(SESSION).target_position(results(SESSION).control == COND),:), 'f')
                    
                    % ----- figure 2
                    
                    trajectory = results(SESSION).trajectory(:,:,results(SESSION).control == COND, 3);
                    target_positions = results(SESSION).target_position(results(SESSION).control == COND);
                    
                    figure(2)
                    subplot(2,3,3+subplot_mod)
                    
                    for TT = 1:8
                        plot(squeeze(trajectory(1,:,target_positions == TT)), squeeze(trajectory(2,:,target_positions == TT)), 'color', col_location(TT,:))
                    end
                    
                end
            end
        end
    end
    
    
    str_figure = {'endpoints.png', 'trajectories.png'};
    
    % draw targets
    
    for FIGURE = 1:2
        
        h = figure(FIGURE);
        
        for VISIBILITY = 1:number_of_visibility
            for CONTROL = 1:number_of_control+1 % hp solo, lp solo, joint
                subplot(2,3,(VISIBILITY-1)*3+CONTROL)
                for LL = 1:n.positions
                    position = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp;
                    rectangle('Position',position,'Curvature',[1 1], 'edgecolor', 'k');
                end
                
                xlabel('{\it x} (°)')
                ylabel('{\it y} (°)')
            end
        end
        
        saveas(h, [OUT str_figure{FIGURE}])
        
    end
    
    
    %% endpoint accuracy bars
    
    M = squeeze(mean(ED));
    E = [ws_bars(ED(:,:,1)); ws_bars(ED(:,:,2))]';
    
    close all
    h = figure;
    errorbar(M,E)
    set(gca, 'xtick', 1:3, 'xticklabel', str_control)
    legend(str_visibility)
    xlabel('Control')
    ylabel('Mean Endpoint Displacement (°)')
    saveas(h, [OUT 'mean_endpoint_displacement.png'])
    
    
    %% save for R!
    
    visible = ED(:,:,1);
    invisible = ED(:,:,2);
    
    save([OUT 'endpoint_accuracy.mat'], 'visible', 'invisible', '-v6')
    
end

