function curvature_function(SESSION)
    
    start = tic;
    
    OUT = 'curvature_runner\';
    
    generate_global_variables
    
    IN = '..\data_manager\CheckFiles2\';
    load( [IN 'fname.mat'] )
    fname.behave( cellfun( @isempty, fname.behave ) ) = [];
    
    load([fname.direct_behav fname.behave{SESSION}], 'data', 'D', 'observer', 'cursor', 'n', 'array', 'sizes');
    
    %         if SESSION == 20
    %             % find(~isnan(data(:,D.RT(1))),1,'last')
    %             keep = 1:960 <= 704;
    %         else
    %             keep = 1:960 <= 960;
    %         end
    
    %%
    
    
    %         close 'all'
    %         h = figure(1);
    %         h = figure(2);
    
    %%
    
    dpp = (53.2/1920); % degrees/pixel
    
    curvature_results = NaN(number_of_trials, 3);
    
    for TRIAL = 1:number_of_trials
        for CURSOR = 1:3
            
            xy = cursor.xy(:,:,TRIAL,CURSOR)'*dpp;
            xy(any(isnan(xy),2),:) = [];
            
            addpath 'D:\JOINT.ACTION\JointActionRevision\analysis\final_revision'
            
            [~, ~, K2] = curvature(xy);
            %curvature_results(TRIAL,CURSOR) = nansum(sqrt(sum(K2.^2, 2)));
            curvature_results(TRIAL,CURSOR) = nanmean(sqrt(sum(K2.^2, 2))); % mean of curvature rather than the sum
            
%                             figure(1)
%                             clf
%                             hold on
%             
%                             plot(xy(:,1), xy(:,2)); grid on; axis equal
%                             xlabel('x')
%                             ylabel('y')
%                             title([num2str(TRIAL) ', ' num2str(CURSOR) ])
%                             quiver(xy(:,1), xy(:,2), K2(:,1), K2(:,2));
%             
%                             for LL = 1:n.positions; pos = [array.x(LL)-sizes.target/2 array.y(LL)-sizes.target/2 sizes.target sizes.target] .* dpp; rectangle('Position',pos,'Curvature',[1 1], 'edgecolor', 'k'); end
%                             xlabel( 'x (°)' ); ylabel( 'y (°)' ); axis square; set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial'); xlim( [-1 +1] .* 13 ); ylim( [-1 +1] .* 13 )
%                             TIT = 'Joint Endpoints'; title( TIT );
%             
%                             figure(2)
%                             clf
%                             quiver(K2(:,1), K2(:,2))
%             
%                             input('press enter')
            
        end
    end
    
    control = data(:,D.cond);
    save([OUT STR.session{SESSION} '.curvature_results.mat'], 'curvature_results', 'control')
    
    toc(start)
    