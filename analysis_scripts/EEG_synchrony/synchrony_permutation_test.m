% to be run after loading the data from synchronyGroup - in place of old
% sliding window calculation correlation (this produces the same results
% but much faster ---- months -> < 1 hour.

clear; clc; close all; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );

addpath('..\common\')
addpath('..\external\topoplot_hack')

is_load_fresh = false;
is_permute_fresh = true;

is_figure_visible = 'on';

IN = 'synchronyGroup\';

number_of_workers = 8;

generate_global_variables
SRATE_EEG = 64;
synchrony_settings


%% get epoch correlation values (channels vectorized)

CHANGE_THIS = win.length + 1; % win.length should == win.length

if is_load_fresh

    tic
    load([IN 'group.EPOCH2.mat'], 'EPOCH2', 'type2')
    toc
    
    r3 = NaN(number_of_trials, number_of_sessions, nEpochs, number_of_channels);

    tic
    
    parfor ELECTRODE = 1:number_of_channels % parfor

        tic
        
        EPOCH = EPOCH2(:,ELECTRODE,:,:,:);

        r2 = NaN(number_of_trials, number_of_sessions, nEpochs );

        for EE = 1:nEpochs

            a = squeeze(EPOCH(win.start(EE):win.stop(EE),:,:,1,:));
            b = squeeze(EPOCH(win.start(EE):win.stop(EE),:,:,2,:));

            idx = repmat( range(a) > EEG_ARTIFACT_THREHOLD_RANGE | range(b) > EEG_ARTIFACT_THREHOLD_RANGE, CHANGE_THIS, 1, 1); % remove outliers

            a(idx) = NaN;
            b(idx) = NaN;

            a = permute(a,[2 3 1]);
            b = permute(b,[2 3 1]);

            az = bsxfun(@minus, a, mean(a,3));
            bz = bsxfun(@minus, b, mean(b,3));

            % Standard Pearson correlation coefficient formula

            a2 = az .^ 2;
            b2 = bz .^ 2;
            ab = az .* bz;
            r = sum(ab, 3) ./ sqrt(sum(a2, 3) .* sum(b2, 3));

            r2(:,:,EE) = r;

        end

        r3(:,:,:,ELECTRODE) = r2;

        toc
        
    end

    toc
    
    r4 = single(r3);
    
    tic
    save([OUT 'r4.mat'], 'r4')
    toc
    
    
    % clean up, free some memory
    clear EPOCH EPOCH2 r3 r2 epoch2use

else
    
	tic
    
    disp(['loading... ' IN 'group.EPOCH2.mat'])
    load([IN 'group.EPOCH2.mat'], 'type2')
    load([OUT 'r4.mat'], 'r4')
    
    toc
    
end


%% ----- permute trial labels (epochs vectorized) 

if is_permute_fresh

    % 256 Hz EEG, 6 cores ---- 14 GB of memory used, ~ computation takes ~1.5 hours

    number_of_permutations = 1000;
    M = NaN(nEpochs, 2, number_of_channels, number_of_permutations);

    tic

    disp('permuting trial labels... this could take many hours...')

    parfor PERM = 1:number_of_permutations

        tic

        if PERM == 1 % obtained results
            type_to_use = type2;
        else % permuted results
            type_to_use = type2( randperm(size(type2,1)),: );
        end

        m = NaN(nEpochs,2,number_of_channels);

        for e2use = 1:number_of_channels

            res = NaN(nEpochs,2,number_of_sessions);

            for SESSION = 1:number_of_sessions
                data2use = squeeze( r4(:,SESSION,:,e2use) );
                res(:,:,SESSION) = grpstats( data2use, type_to_use(:,SESSION), {'mean'} )';
            end

            m(:,:,e2use) = nanmean(res,3);

        end

        M(:,:,:,PERM) = m;

        toc

    end

    toc

    tic
    save('M.mat', 'M')
    toc

else
    
    tic
    load('M.mat', 'M')
    toc
    
end
    
    
%% ----- calculate probability values

m = M;

m = permute(m,[1 3 2 4]);
obt = m(:,:,2,:) - m(:,:,1,:);
obt = obt(:);

% figure
% hist(obt,1000)

pVal = NaN(size(dm));

for c = 1:size(dm,2)
    
    disp(c)
    
    parfor r = 1:size(dm,1)        
        pVal(r,c) = sum( abs( dm(r,c) ) > abs(obt) ) / numel(obt); % back to front, but corrected below
    end
end

save('pVal', 'pVal')


%% TIT = 'synchrony.image';

h = figure('visible', is_figure_visible);

m = M(:,:,:,1);
m = permute(m,[1 3 2]);

TIT = 'synchrony.image';

limit = [ min(m(:)) max(m(:)) ];

for CC = 1:n.cond+1
    
    % ------
   
    subplot(3,1,CC)
    
    if CC < 3
        imagesc( win.t, [], m(:,channel_order2,CC)' )
        caxis(limit)
    else
        dm = m(:,:,2) - m(:,:,1);
        imagesc( win.t, [], dm(:,channel_order2)' )
        caxis( [-1 +1] .* max(abs(dm(:))) )
    end
    
    colorbar
    colormap('jet')

    % -----
    
    title( STR.cond{CC} )

end

[v,e2use] = max( max(dm) );
idx = find( dm(:,e2use) == v );

suptitle(TIT)


%% ----- find largest effect

pVal2 = 1 - pVal;

h = figure('visible', is_figure_visible);
imagesc(win.t,[],pVal2(:,order2)')
colorbar
colormap(flipud('hot'))
caxis([0 .0001])

[v,i]=min(pVal2);
v2 = min(v);

i2 = find(v == v2);

tIDX = find(pVal2(:,i2) == v2);

line(win.t(tIDX)*[1 1], get(gca,'ylim'), 'color', 'r', 'linewidth', 2)
line(get(gca,'xlim'), find(order2==i2)*[1 1], 'color', 'r', 'linewidth', 2)


%% topo

map_limits = [-1 +1] .* max(abs(dm(:)));
tIDX2 = 405;

h = figure('visible', is_figure_visible); cla
topoplot(dm(tIDX2,:), chanlocs, 'maplimits', map_limits)
title(win.t(tIDX2))