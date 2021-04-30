function [Rplot] = plot_regression_fit(reality, OUT, YLIMIT, COLOR)

generate_global_variables
    
RESULT.R = NaN(3, number_of_trials/2, number_of_sessions);

for SESSION = 1:number_of_sessions
    load( [OUT generate_session_string(SESSION) '.' reality '.trajectories.mat'], 'R')
    RESULT.R(:,1:size(R,2),SESSION) = R;
end

% ----- order by best player

Rplot = squeeze(nanmean(RESULT.R,2));

[~, idxmax] = max(Rplot([1 2],:));
idxmax2 = [idxmax' abs(idxmax'-3) ones(number_of_sessions,1)*3];

for SESSION = 1:number_of_sessions
    Rplot(:,SESSION) = Rplot(idxmax2(SESSION,:),SESSION);
end

% ----- plot linear regression results.

h = figure('visible', 'on'); hold on

Mr = nanmean(Rplot,2);
Er = ws_bars(Rplot');
errorbar_groups(Mr',Er, 'bar_colors', COLOR, 'bar_names', {'Best Solo' 'Worst Solo' 'Joint'}, 'FigID', h)

xlabel('Control')
ylabel('Linear Regression Fit (r^2)')

title('Linear Regression Fit')
ylim(YLIMIT)

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [OUT 'fit.' reality '.png' ] )
saveas(h, [OUT 'fit.' reality '.eps' ], 'epsc' )

disp('***********************')
[H,P,CI,stats] = ttest(Rplot(3,:),  Rplot(2,:))
[H,P,CI,stats] = ttest(Rplot(3,:),  Rplot(1,:))
disp(mean(Rplot'))
disp(std(Rplot'))