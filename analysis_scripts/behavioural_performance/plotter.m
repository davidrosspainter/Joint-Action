function dataToUse = plotter(dataToUse, LIMIT, TIT, YLABEL, OUT, COLOR, sort_string)

dataToUse2 = [mean(dataToUse(:,1:2), 2) dataToUse(:,3)];

for SESSION = 1:size(dataToUse, 1) % mean of solo
    dataToUse(SESSION,1:2) = sort(dataToUse(SESSION,1:2), sort_string);
end

% [~,p,~,~] = ttest(dataToUse(:,1), dataToUse(:,3))
% [~,p,~,~] = ttest(dataToUse(:,2), dataToUse(:,3))
% [~,p,~,~] = ttest(dataToUse2(:,1), dataToUse2(:,2))

% ----- figure

h = figure('visible', 'on');

ax(1) = subplot(1,2,1); hold on
errorbar_groups(nanmean(dataToUse2), ws_bars(dataToUse2), 'bar_colors', COLOR, 'FigID', h, 'AxID', ax(1));

set(gca, 'xtick', 1:2, 'xticklabel', {'Mean Solo' 'Joint'}, 'tickdir', 'out')
xlabel('Control')
ylabel(YLABEL)
ylim(LIMIT)

ax(2) = subplot(1,2,2); hold on
errorbar_groups(nanmean(dataToUse), ws_bars(dataToUse), 'bar_colors', COLOR, 'FigID', h, 'AxID', ax(2));

set(gca, 'xtick', 1:3, 'xticklabel', {'Best' 'Worst' 'Joint'}, 'tickdir', 'out')
xlabel('Control')
ylabel(YLABEL)
ylim(LIMIT)

suptitle(TIT)
saveas(h, [OUT TIT '.png' ])
saveas(h, [OUT TIT '.eps' ])