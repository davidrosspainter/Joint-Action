clear; clc; close all; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );

addpath '..\external\Colormaps\pmkmp\'
addpath '..\external\Colormaps\'
addpath '..\external\topoplot_hack\'
addpath '..\external\'

addpath '..\common\'

generate_global_variables

SRATE_EEG = 64;
synchrony_settings

IN = 'permutation_test3\';

load([IN 'M.mat'])
load([IN 'pVal.mat'])


%% TIT = 'synchrony.image';

close all
h = figure; 

clf

STR.cond{3} = 'Joint Minus Solo';

m = M(:,:,:,1);
m = permute(m,[1 3 2]);

TIT = 'synchrony.image';

limit = [ -1 +1 ] * max(abs(m(:)));

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
    
    caxis()
    
    hcb = colorbar;
    colorTitleHandle = get(hcb,'Title');
    set(colorTitleHandle ,'String','r');
    
    set(gca,'ytick',[15 30 46],'yticklabel',{'Anterior' 'Central' 'Posterior'})

    
    xlabel('Time (s)')
    ylabel('Electrode')

    % -----
    
    title( STR.cond{CC} )
    
    set(gca,'tickdir','out')
    
    xlim([-2.5 +3])
    set(gca,'xtick',-2.5:.5:3)

end

[v,e2use] = max( max(dm) );
idx = find( dm(:,e2use) == v );

suptitle(TIT)

%     'IsoL'      Lab-based isoluminant rainbow with constant 
%     'IsoAZ'      Lightness-Chroma-Hue based isoluminant rainbow 
%     'IsoAZ180'   Lightness-Chroma-Hue based isoluminant rainbow g
%     'LinearL'	  Lab-based linear lightness rainbow. 
%     'LinLhot'	  Linear lightness modification of Matlab's hot 
%     'CubicYF'	   Lab-based rainbow scheme with cubic-law 
%     'CubicL'	   Lab-based rainbow scheme with cubic-law lightness
%     'Swtth'      Lab-based rainbow scheme with sawtooth-shaped 
%     'Edge'       Diverging Black-blue-cyan-white-yellow-red-black


map = pmkmp(256,'Edge');
colormap(map)

maximize

saveas(h, [OUT 'sychrony.png'])
saveas(h, [OUT 'sychrony.eps'], 'epsc')
saveas(h, [OUT 'sychrony.tif'], 'tiffn')


%% ----- find largest effect

pVal2 = 1-pVal;

h = figure;
imagesc(win.t,[],pVal2(:,channel_order2)')
colorbar
colormap(flipud('hot'))
caxis([0 (1e-4)/2])

[v,i]=min(pVal2);
v2 = min(v);

i2 = find(v==v2);

tIDX = find( pVal2(:,i2) == v2 );

line( win.t(tIDX)*[1 1], get(gca,'ylim'), 'color', 'r', 'linewidth', .1 )
line( get(gca,'xlim'), find(channel_order2==i2)*[1 1], 'color', 'r', 'linewidth', .1 )

%     'IsoL'      Lab-based isoluminant rainbow with constant 
%     'IsoAZ'      Lightness-Chroma-Hue based isoluminant rainbow 
%     'IsoAZ180'   Lightness-Chroma-Hue based isoluminant rainbow g
%     'LinearL'	  Lab-based linear lightness rainbow. 
%     'LinLhot'	  Linear lightness modification of Matlab's hot 
%     'CubicYF'	   Lab-based rainbow scheme with cubic-law 
%     'CubicL'	   Lab-based rainbow scheme with cubic-law lightness
%     'Swtth'      Lab-based rainbow scheme with sawtooth-shaped 
%     'Edge'       Diverging Black-blue-cyan-white-yellow-red-black

set(gca,'tickdir','out')
map = pmkmp(128,'Swtth');

xlim([-2.5 +3])
set(gca,'xtick',-2.5:.5:3)

colormap(gray(1024))

caxis()

saveas(h, [OUT 'pval.png'])
saveas(h, [OUT 'pval.eps'], 'epsc')


%%

h = figure;
plot(  win.t, pVal2(:,i2) <= (1e-4)/2 )
xlim([-2.5 +3])

saveas(h, [OUT 'sigCz.eps'])
saveas(h, [OUT 'sigCz.png'])

win.t( find( pVal2(:,i2) <= (1e-4)/2, 1, 'first' ) )
win.t( find( pVal2(:,i2) <= (1e-4)/2, 1, 'last' ) )


%% topo

cmaps

h = figure;

cla

mapLimits = [-1 +1] .* max(abs(dm(:)));

cla

topoplot( dm(tIDX,:), chanlocs, 'maplimits', mapLimits, 'electrodes', 'on', 'shading', 'interp', 'conv', 'on')
%title(win.t(tIDX2))

colorbar
caxis

colormap(kindlmann)
maximize

saveas(h, [OUT 'topo.png'])
saveas(h, [OUT 'topo.eps'], 'epsc')


%%

h = figure;

pos = cat(2, [-1 -.5 0 2.5], [-1 -.5] -1.424, [-1 -.5] -1.424-.576, 0.4524, 0.6628+0.4524);

cla
hold on

imagesc( win.t, [], zeros(61,550) )
set(gca,'tickdir','out')

for LL = 1:length(pos)
    line( pos(LL)*[1 +1], get(gca,'ylim'),'color','k')
end

xlim([-2.5 +3])

saveas(h, [OUT 'timeLine.eps'])
saveas(h, [OUT 'timeLine.png'])


%% TimeCourseCz

e2use = find( ismember(lab,'Cz') );

pVal2 = 1-pVal;

startIDX = find( pVal2(:,e2use) <= (1e-4)/2, 1, 'first' );
stopIDX = find( pVal2(:,e2use) <= (1e-4)/2, 1, 'last' );

start = win.t( startIDX );
stop = win.t( stopIDX );

obt = M(:,:,e2use,1);
obt(:,3) = obt(:,2) - obt(:,1);

prior = M(:,:,e2use,:);
prior = prior(:,2,:,:) - prior(:,1,:,:);
prior = prior(:);

alpha = 1e-4;
alpha = alpha*100;

cutoff = prctile( prior, [alpha/2 100-alpha/2] );

startY = obt(startIDX,3);
stopY = obt(stopIDX,3);

[v,i] = max(obt(:,3))
win.t(i)
obt(i,3)

h = figure;

ax(1) = subplot(5,1,[1 2 3 4]);
cla; hold on

plot(win.t,obt)

line( get(gca,'xlim'), [0 0], 'color', 'k' )
line( get(gca,'xlim'), [startY startY], 'color', 'k' )
line( get(gca,'xlim'), [stopY stopY], 'color', 'k' )


xlim([-2.5 +3])
YLIM = get(gca,'ylim');

set(gca,'tickdir','out')

legend({'Individual' 'Joint' 'Joint-Individual'}, 'location','best')

line( [start start], get(gca,'ylim'), 'color', 'r')
line( [stop stop], get(gca,'ylim'), 'color', 'r')

ax(2) = subplot(5,1,5);
plot( win.t, 1-pVal(:,e2use) <= (1e-4)/2 )

xlim([-2.5 +3])

set(gca,'tickdir','out')

line( [start start], get(gca,'ylim'), 'color', 'r')
line( [stop stop], get(gca,'ylim'), 'color', 'r')

linkaxes(ax,'x')

saveas(h, [OUT 'TimeCourseCz.eps'], 'epsc')
saveas(h, [OUT 'TimeCourseCz.png'], 'png')