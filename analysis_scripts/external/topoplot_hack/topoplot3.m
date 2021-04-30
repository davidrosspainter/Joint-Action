close all
clear
clc

%%

str.group = {'MD' 'CBS'};


%% data

results1 = load('res1.mat');
results2 = load('res2.mat');
      
res = cell2mat( [ results1.res; results2.res ]' ); 
res = res(1:24, 3:3:end)';


%% plot settings

BACKCOLOR = [1 1 1];  % EEGLAB standard
GRID_SCALE = 200;
SHADING = 'interp';


%% x, y positions

rad = [4*ones(8,1); 8*ones(8,1); 12*ones(8,1)];
theta = repmat( [0*pi 1/4*pi 2/4*pi  3/4*pi  4/4*pi  5/4*pi  6/4*pi  7/4*pi]', 3, 1);
[x,y] = pol2cart(theta, rad);


%% plot

for GG = 1:2

    h = figure; hold on
    
    switch GG
        case 1
            data2use = res(1:8,:); 
        case 2
            data2use = res(9:16,:); 
    end
    
    data2use = mean(data2use)*100;
    limit = [ 0.5837 1]*100;

    %% interpolate & plot

    xi = linspace(min(x)*1.1, max(x)*1.1, GRID_SCALE);
    yi = linspace(min(y)*1.1, max(y)*1.1, GRID_SCALE);
    
    [Xi,Yi,Zi] = griddata(y, x, data2use, yi', xi, 'v4'); % interpolate
    
    [T,R] = cart2pol(Xi, Yi);
    Zi( R > max(rad)*1.1 ) = 0;

    surface(Xi, Yi, zeros(size(Zi)), Zi, 'EdgeColor', 'none', 'FaceColor', SHADING);
    axis equal
    colormap('gray')
    hc = colorbar;
    
    set(hc,'tickdir', 'out')
    set(get(hc,'title'),'string','Accuracy (%)');
    
    caxis( limit )
    
    set(gca,'xlim',[-1 +1].*max(rad)*1.1, 'ylim',[-1 +1].*max(rad)*1.1, 'tickdir', 'out', 'xtick', -12:4:12, 'ytick', -12:4:12 )
    
    scatter(x, y, 25, [0 0 0], 'f' )
    xlabel( 'Eccentricity' )
    ylabel( 'Eccentricity' )
    
    title( str.group{GG} )
    
    saveas(h, [ str.group{GG} '.tiff' ], 'tiffn' )
    
    
    h = figure; hold on
    
    scatter(x, y, 25, [0 0 0], 'f' )
	set(gca,'xlim',[-1 +1].*max(rad)*1.1, 'ylim',[-1 +1].*max(rad)*1.1, 'tickdir', 'out', 'xtick', -12:4:12, 'ytick', -12:4:12 )
    
    
    xlabel( 'Eccentricity' )
    ylabel( 'Eccentricity' )
    hc = colorbar;
	caxis( limit )
    set(hc,'tickdir', 'out')
    title( str.group{GG} )
    colormap('gray')
    
    saveas(h, [ str.group{GG} '.eps' ], 'eps' )
    
end