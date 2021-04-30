function plotter(dataToUse, OUT, TIT)
    
% dataToUse N*2

N = size(dataToUse, 1);


hf = figure; cla; hold on

M = mean(dataToUse);
E = ws_bars(dataToUse);

barwitherr(E, M, 'facecolor', [.75 .75 .75], 'barwidth', .5); hold on

rng(0)

for CC = 1:2
    scatter( CC*ones(N,1)+(rand(N,1)*2-1)*.1, sort(dataToUse(:,CC)), [], 'k')
end

set(gca,'box','off')
set(gca,'tickdir','out', 'fontsize', 8)
set(gca, 'xtick', 1:2, 'xticklabel', {'Solo', 'Joint'}, 'fontsize', 10)
xlabel('Control', 'fontsize', 12)
ylabel({'Correlation Between Inter-Cursor Distance &' 'Inter-Brain Neural Correlations ({\itr})'}, 'fontsize', 12)


[h, p, ci, stats] = ttest(dataToUse(:,1), dataToUse(:,2))

text(1.5, -.08,['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

[h, p, ci, stats] = ttest( dataToUse(:,1), 0)

text(1.25, -.04,['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

[h, p, ci, stats] = ttest( dataToUse(:,2), 0)
text(2.25, -.07,['{\itp} = ' num2str(p)], 'verticalalignment', 'middle', 'horizontalalignment', 'center')

line([1 2],[-.09 -.09], 'color', 'k')

TIT = 'Effect of Visual Input';
suptitle(TIT)
saveas(hf, [OUT TIT '.png'])