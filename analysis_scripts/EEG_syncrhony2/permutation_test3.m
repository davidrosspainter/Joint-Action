% to be run after loading the data from synchrony_group - in place of old
% sliding window calculation correlation (this produces the same results
% but much faster ---- months to hours depending on number of cores/speed

clear; clc; close all; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );

addpath('..\common\')
addpath('..\external\topoplot_hack')

is_permute_fresh = true;
is_test_permute = false; % assess configuration...

is_figure_visible = 'on';

IN = {'synchrony_group\', 'generate_trial_correlation_matrix\'};

generate_global_variables
SRATE_EEG = 64;
synchrony_settings


%% ----- load correlation values and trial lables

disp('loading...')

tic
load([IN{1} 'group.EPOCH2.mat'], 'type2')
load([IN{2} 'r4.mat'], 'r4')
toc

synchrony_image_plot


%% ----- permute trial labels (epochs vectorized) 

if is_permute_fresh

    number_of_workers = 16;
    
    if is_test_permute
        number_of_permutations = number_of_workers;
    else
        number_of_permutations = 1000;
    end
    
    p = gcp('nocreate'); % If no pool, do not create new one.
    
    if isempty(p)
        parpool(number_of_workers)
    end
    
    % 64 Hz EEG, 16 cores (3.57 GHz) ----- 35 GB, ~ computation takes ~ 26
    % minutes - booyah!

    results1 = cell(number_of_permutations,1);
    results2 = NaN(nEpochs, 2, number_of_channels, number_of_permutations);

    disp('permuting trial labels... this could take many hours...')

    rng(0) % for reproducibility - set the seed state!
    
    % ------ permutation test

    loop_start = tic;
    
    parfor PERMUTATION = 1:number_of_permutations
        results1{PERMUTATION} = permutation_test_shuffler(PERMUTATION, type2, r4, nEpochs, number_of_channels, number_of_sessions);
    end

    loop_elapsed = toc(loop_start)
    
    % ----- results as multidimensional array
    
    for PERMUTATION = 1:number_of_permutations
        results2(:,:,:,PERMUTATION) = results1{PERMUTATION};
    end
    
    clear results1
    
    tic
    save([OUT 'results2.mat'], 'results2')
    toc

else
    
    tic
    load([OUT 'results2.mat'], 'results2')
    toc
    
end
    

%% ----- check synchrony image (obtained vs. permuted values)

for PERMUTATION = 1:3 % 2 and 3 should be shuffled
    
    % ------
    
    h = figure('visible', is_figure_visible);

    m = results2(:,:,:,PERMUTATION);
    m(:,3,:) = m(:,2,:) - m(:,1,:);
    m = permute(m,[1 3 2]);

    TIT = ['synchrony.image.permutation.' num2str(PERMUTATION)];

    for CC = 1:n.cond+1

        % ------

        subplot(3,1,CC)
        imagesc(win.t, [], m(:,channel_order2,CC)')
        
        if CC < n.cond+1
            data2use = m(:,:,1:2);
            limit = [ min(m(:)) max(m(:)) ];
        else
            data2use = m(:,:,3);
            limit = [-1 +1] .* max(abs(data2use(:)));
        end

        caxis(limit)
        colorbar
        colormap('jet')

        % -----

        title( STR.cond{CC} )

    end

    suptitle(TIT)
    saveas(h, [OUT TIT '.png'])

end

if is_test_permute
	return 
end

    
%% ----- calculate probability values

tic

m = results2;
m = permute(m,[1 3 2 4]);
obt = m(:,:,2,:) - m(:,:,1,:);
obt = obt(:);

% figure
% hist(obt,1000)

dm = m(:,:,2) - m(:,:,1);
pVal = NaN(size(dm));

for c = 1:size(dm,2)
    
    disp(c)
    
    parfor r = 1:size(dm,1)        
        pVal(r,c) = sum( abs( dm(r,c) ) > abs(obt) ) / numel(obt); % back to front, but corrected below
    end
    
end

save([OUT 'pVal.mat'], 'pVal')

toc % 5.25 minutes


%% ----- find largest effect

pVal2 = 1 - pVal;

TIT = 'largest.effect';

h = figure('visible', is_figure_visible);
imagesc(win.t,[],pVal2(:,channel_order2)')
colorbar
colormap(flipud('hot'))
caxis([0 .0001])

[v,i] = min(pVal2);
v2 = min(v);

i2 = find(v == v2);

tIDX = find(pVal2(:,i2) == v2);

line(win.t(tIDX)*[1 1], get(gca,'ylim'), 'color', 'r', 'linewidth', 2)
line(get(gca,'xlim'), find(channel_order2==i2)*[1 1], 'color', 'r', 'linewidth', 2)

suptitle(TIT)
saveas(h, [OUT TIT '.png'])


%% topo

map_limits = [-1 +1] .* max(abs(dm(:)));

h = figure('visible', is_figure_visible); cla
topoplot(dm(tIDX,:), chanlocs, 'maplimits', map_limits)
title(win.t(tIDX))
saveas(h, [OUT num2str(win.t(tIDX)) '.png'])

