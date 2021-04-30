function get_linear_regression_fit(reality, OUT)
    
    generate_global_variables
    dpp = (53.2/1920); % degrees/pixel

    
    for SESSION = 1:number_of_sessions
          
        disp('****************************')
        disp(num2str(SESSION))
        
        load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D', 'mon', 'n', 'cursor');
        

        %% get trajectories

        MT_max = 1.5;
        
        n.cursors = 3;
        
        n.pointsmax = mon.ref*MT_max;
        n.targ = 8;
        n.trialsmaxloc = n.trials/n.targ;
        
        traject.x = nan(n.pointsmax,n.trialsmaxloc, n.targ, n.cursors);
        traject.y = nan(n.pointsmax,n.trialsmaxloc, n.targ, n.cursors);
        
        for CURSOR = 1:n.cursors
            
            switch reality
                case 'veridical'
                    switch CURSOR
                        case 1; COND = 1;
                        case 2; COND = 1;
                        case 3; COND = 2;
                    end                    
                case 'hypothetical'
                    switch CURSOR
                        case 1; COND = 2;
                        case 2; COND = 2;
                        case 3; COND = 1;
                    end
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
                            %disp('trial skipped')
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
            
            tcount = 0;
            
            for target = 1:n.targ;
                for TRIAL = 1:size(TRAJECT.x{target,CURSOR},2);
                    tcount = tcount+1;
                    
                    % define the x- and y-data for the original line we would like to rotate
                    x = TRAJECT.x{target,CURSOR}(:,TRIAL)';
                    y = TRAJECT.y{target,CURSOR}(:,TRIAL)';
                    
                    % create a matrix of these points, which will be useful in future calculations
                    v = [x;y];
                    
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
                    
                end
            end
            
        end
        
        
        %% Regression
        clear R
        
        for CURSOR = 1:n.cursors
            
            data2use.x = (TRAJECT2.x{CURSOR})*dpp;
            data2use.y = (TRAJECT2.y{CURSOR})*dpp;
            
            for TRIAL = 1:size(data2use.x,2)
                x = data2use.x(:,TRIAL);
                y = data2use.y(:,TRIAL);
                LM = fitlm(x, y, 'linear', 'Intercept',false);
                R(CURSOR,TRIAL) = LM.Rsquared.Ordinary;
            end
            
        end
        
        
        %% data for saving
        save( [OUT generate_session_string(SESSION) '.' reality '.trajectories.mat'], 'R')
        
    end