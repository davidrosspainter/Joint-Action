close all
clear
clc

basicSettings
taskCueSettings




direct.output = 'taskCueGroup\'; if ~exist( direct.output, 'dir' ); mkdir( direct.output ); end


%% group effects

missing = NaN(Nsub,n.cond);
rejected = NaN(Nsub,n.cond);

ERPG = NaN( n.x, N.channels, n.cond, Nsub );
AMPG = NaN( n.x, N.channels, n.cond, Nsub );

for SUB = 1:Nsub
    
    [SESSION,PLAYER,STR] = subStringGen( SUB, subCode );
    load( [ 'taskCue\ERP.AMP.' STR.SUB '.mat' ] )
    
    missing(SUB,:) = num.missing;
    rejected(SUB,:) = num.rejected;
    
    ERPG(:,:,:,SUB) = ERP;
    AMPG(:,:,:,SUB) = AMP;
    
end


%%

ERPGM = mean( mean(ERPG,3), 4);

TIT = 'grand.ERP';

close all
h = figure;

subplot(2,1,1)
imagesc(t, [], ERPGM(:,order2)' )
colorbar
colormap('jet')

subplot(2,1,2)
plot( t, ERPGM(:,ismember(lab,'PO8')) )

colorbar
title(TIT)

saveas(h, [direct.output TIT '.png' ] )



%% generate grand

n.best = 3;

AMPM = nanmean( mean(AMPG,3), 4);

head = AMPM( idxHz, : );
[~,i] = sort(head(chan2use), 'descend');
BEST = i(1:n.best); BEST = chan2use(BEST);

save( [ direct.output 'BEST.mat' ], 'BEST' )


%

spectrumG = mean( mean( mean( AMPG(:,BEST,:,:), 2), 3), 4);
erpG =      squeeze( mean( mean( ERPG(:,BEST,:,:), 2), 4) );

wAMPG = NaN(n.x,length(f.wavelet),n.cond,Nsub);

for SUB = 1:Nsub
    for CC = 1:n.cond
        
        erp = nanmean( ERPG(:,BEST,CC, SUB ), 2);

        P = morlet_transform(erp, t, f.wavelet, fc, FWHM_tc, squared);
        E = 1;
        wAMPG(:,:,CC,SUB) = abs( squeeze( P(E,:,:) ) ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT
    end
end

wAMPGM = nanmean( nanmean( wAMPG, 3 ), 4);

% ----- plot grand

close all

TIT = 'taskCueSettings';

h = figure;

% ----- topoplot

subplot(3, 3, 1)

topoplot( head, chanlocs, 'maplimits', [min(head) max(head)], 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp' );
%topoplot( head, chanlocs, 'maplimits', [min(head) max(head)], 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp', 'emarker2', {BEST '.' 'b' 20} );
hc = colorbar;
set(get(hc,'title'),'string','\muV');
set(gca,'tickdir','out')
% ----- spectra

subplot(3, 3, 2)

plot(f.fft, spectrumG)
xlim( [realHz-2 realHz+2] )
xlim([2 21] )

line([Hz Hz], get(gca,'ylim'), 'color', 'r')

xlabel( 'Frequency (Hz)' )
ylabel( 'FFT Amp. (\muV)' )
set(gca,'tickdir','out')
% ---- FFT

subplot(3,3,3)

data2use = squeeze( mean( AMPG(idxHz,BEST,:,:), 2) )';


%data2use = squeeze( mean( sum( AMPG( ismember(f.fft,[7 14]),BEST,:,:) ), 2) )';


[hBar, hErrorbar] = barwitherr( ws_bars(data2use), mean(data2use) );
xlim( [.375 2.625] )

hBar.BarWidth = .75;
hBar.FaceColor = [.5 .5 .5];
set(gca,'tickdir','out','xticklabel',STR.cond(1:2))
ylabel('FFT Amp.')
xlabel('Control')
set(gca,'tickdir','out')
[~,p,ci,stats] = ttest( data2use(:,1), data2use(:,2) );

text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )

% ----- erps

subplot(3, 3, [4 5 6])

plot(t, mean(erpG,2))
%xlim( [lim.s(1) lim.s(2)] )
xlabel( 'Time (s)' )
ylabel( 'EEG Amp. (\muV)' )
colorbar
set(gca,'tickdir','out')

ylim([-2 6])

% ----- wavelet

subplot(3, 3, [7 8 9])

imagesc(t, f.wavelet, wAMPGM' );

xlabel( 'Time (s)' )
ylabel( 'Frequency (Hz)' )
hc = colorbar;
set(get(hc,'title'),'string','\muV');
set(gca,'tickdir','out')

colormap(jet)
suptitle( TIT )
cm = colormap('hot');
colormap(flipud(cm))

% cm = colormap(redblue);
% colormap(cm)
% 
% addpath('pmkmp')
% 
% map = pmkmp(128,'Edge');
% colormap(map)

saveas(h, [ direct.output TIT '.png' ] )
saveas(h, [ direct.output TIT '.eps' ], 'epsc' )


%% fft

h = figure;
plot(f.fft, spectrumG)
xlim( [realHz-5 realHz+5] )
%xlim([2 22] )

line([Hz Hz], get(gca,'ylim'), 'color', 'r')

xlabel( 'Frequency (Hz)' )
ylabel( 'FFT Amp. (\muV)' )
set(gca,'tickdir','out')

saveas(h, [ direct.output 'fft.publish.eps' ], 'epsc' )


%% headmaps


AMGH = mean( squeeze( AMPG(idxHz,:,:,:) ), 3);

STR.cond{4} = 'mean';

close all

for CC = 4
    
    h = figure;

    if CC < 3
        topoplot( AMGH(:,CC), chanlocs, 'maplimits', [min(AMGH(:,CC)) max(AMGH(:,CC))], 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp' );
        caxis( [ 0.2320 2.3904 ] )
        colormap(flipud(hot))
    elseif CC == 3
        topoplot( AMGH(:,2) - AMGH(:,1), chanlocs, 'maplimits', [-1 +1].*max(abs(AMGH(:,2) - AMGH(:,1))), 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp' );
        colormap(kindlmann)
    else
        head = mean(AMGH(:,[1 2]),2);
        topoplot( head, chanlocs, 'maplimits', [min(head) max(head)], 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp' );
        
        colormap(flipud(hot))
    end
    
    
    colorbar
    %colormap(kindlmann)
    
    title( [ STR.cond{CC} '.newTopos.png' ] )
    
    saveas(h, [ direct.output STR.cond{CC} '.newTopos.png' ] )
    
end


%% wavelet

cmaps

for CC = 3:4
    %subplot(3,1,CC); cla

    h = figure;
    
    if CC < 3
        
        head = mean(wAMPG(:,:,CC,:),4)';
        imagesc(t, f.wavelet, head)
     
        caxis( [ min(head) max(head) ]  )
        colormap(flipud(hot(1024)))
        colorbar
        axis()
        
    elseif CC == 3
        

        head = mean(wAMPG(:,:,2,:),4)'-mean(wAMPG(:,:,1,:),4)';
        imagesc(t, f.wavelet, head)
        caxis([-1 +1].*max(abs(head(:))))
        
        colormap(kindlmann)
        %colormap(parula)
        colorbar
        
    else
        
        
        head = mean( mean(wAMPG(:,:,[1 2],:),3), 4)';

        imagesc(t, f.wavelet, head)
        caxis( [0 1.8]  )
        
       
        colormap(flipud(hot(1024)))
        
        
    end
    
    
    caxis
    
    xlabel( 'Time (s)' )
    ylabel( 'Frequency (Hz)' )
    hc = colorbar;
    set(get(hc,'title'),'string','\muV');
    set(gca,'tickdir','out')
    
     saveas(h, [ direct.output STR.cond{CC} '.newWaves.png' ] )
    
end


%% colorbars

h = figure;
colorbar;
colormap(flipud(hot(1024)))
saveas(h,[direct.output 'hot.eps'],'epsc')


h = figure;
colorbar;
colormap(kindlmann)
saveas(h,[direct.output 'kindlmann.eps'],'epsc')


%% max difference


head = mean(wAMPG(:,:,2,:),4)'-mean(wAMPG(:,:,1,:),4)';
head = head(f.wavelet == 7,:);

close all
plot(head)

[v,i] = max(head);


data2use = squeeze( wAMPG(i,f.wavelet == 7,:,:) )';

h = figure;
[hBar, hErrorbar] = barwitherr( ws_bars(data2use), mean(data2use) );
xlim( [.375 2.625] )

hBar.BarWidth = .75;
hBar.FaceColor = [.5 .5 .5];
set(gca,'tickdir','out','xticklabel',STR.cond(1:2))
ylabel('FFT Amp.')
xlabel('Control')
set(gca,'tickdir','out')
[~,p,ci,stats] = ttest( data2use(:,1), data2use(:,2) );

text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )

saveas(h, [ direct.output 'bars.publish.eps' ] )



%% max difference head plot

for SUB = 1:Nsub
    for CC = 1:n.cond
        
        erp = ERPG(:,:,CC, SUB )';

        P = morlet_transform(erp, t, 7, fc, FWHM_tc, squared)';
        E = 1;
        
        wHead(:,:, CC, SUB) = abs(P)*2;

    end
end

data2use = squeeze( mean( wHead(i,:,:,:), 4) );


%%

for CC = 3:4
    
    h = figure;

    
    if CC == 3
        head = data2use(:,2) - data2use(:,1);
        mean(head(BEST))
        
        topoplot( head, chanlocs, 'maplimits', [-1 +1].*max(abs(head)), 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp' );
        colormap(kindlmann)
    else
        head = mean( data2use, 2);
        
        topoplot( head, chanlocs, 'maplimits', [0 max(head)], 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp' );
        colormap(flipud(hot(1024)))
        
        mean(head(BEST))
    end

    caxis()
    
    colorbar

    saveas(h,  [direct.output 'waveTopo.publish.' STR.cond{CC} ' .png' ] )

end





%%


% ----- spectra

h = figure;
plot(f.fft, spectrumG)
%xlim( [realHz-2 realHz+2] )
xlim([2 20] )

%line([Hz Hz], get(gca,'ylim'), 'color', 'r')

xlabel( 'Frequency (Hz)' )
ylabel( 'FFT Amp. (\muV)' )
set(gca,'tickdir','out')

saveas(h,[ direct.output  'fft.eps' ], 'epsc' )


%%
h = figure;

% ----- topoplot


topoplot( head, chanlocs, 'maplimits', [min(head) max(head)], 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp' );
%topoplot( head, chanlocs, 'maplimits', [min(head) max(head)], 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp', 'emarker2', {BEST '.' 'b' 20} );
hc = colorbar;
set(get(hc,'title'),'string','\muV');
set(gca,'tickdir','out')
cm = colormap(redblue);
colormap(cm)

saveas(h, [ direct.output  'topo.eps' ], 'epsc' )
saveas(h, [ direct.output  'topo.png' ], 'png' )

%% ----


TIT = 'taskCueWavelet';


h = figure;
limit = nanmean( wAMPG, 4); limit = [ min(limit(:)) max(limit(:)) ];

for CC = 1:3

    subplot(3, 1, CC)

    if CC < 3
        imagesc(t, f.wavelet, nanmean( wAMPG(:,:,CC,:), 4)' );
        caxis( limit )
    else
        data2use = nanmean( wAMPG(:,:,2,:), 4) - nanmean( wAMPG(:,:,1,:), 4);
        imagesc(t, f.wavelet, data2use' );
        caxis( [-1 +1] .* max( abs( data2use(:) ) ) );
    end
    
	title( STR.cond{CC} )
    
    xlabel( 'Time (s)' )
    ylabel( 'Frequency (Hz)' )
    hc = colorbar;
    set(get(hc,'title'),'string','\muV');
    
    colormap(jet)

end

colormap(redblue)

saveas(h, [ direct.output TIT '.png' ] )
saveas(h, [ direct.output TIT '.eps' ], 'epsc' )

%% t-test against 0

wAMPGd = squeeze( wAMPG(:,:,2,:) - wAMPG(:,:,1,:) );

TIT = 'wavelet.ttest.results';

clear P
for FF = 1:size(wAMPGd,2)
    [~,P(FF,:),~,~] = ttest( squeeze( wAMPGd(:,FF,:) )', zeros(size(wAMPGd,1),size(wAMPGd,3))');
end

h = figure;
subplot(3,1,3)

imagesc(P)
colorbar
colormap( flipud( colormap(hot) ) )
caxis([0 .05])

title( STR.cond{3} )

suptitle(TIT)
saveas(h, [ direct.output TIT '.png' ] )


%% t-test at maximum point

load( 'taskcuePerm\i.mat', 'i' )

data2use = squeeze( wAMPG(i,f.wavelet==Hz,:,:) )';

TIT = 'peaktTest';

h = figure;
[hBar, hErrorbar] = barwitherr( ws_bars(data2use), mean(data2use) );
xlim( [.375 2.625] )

hBar.BarWidth = .75;
hBar.FaceColor = [.5 .5 .5];
set(gca,'tickdir','out','xticklabel',STR.cond(1:2))
ylabel('FFT Amp.')
xlabel('Control')

[~,p,ci,stats] = ttest( data2use(:,1), data2use(:,2) );

text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )
suptitle(TIT)

saveas(h, [ direct.output TIT '.png' ] )


%% wavelet topography at peak

wtopo = NaN(N.channels,n.cond,Nsub);

for SUB = 1:Nsub
    for CC = 1:n.cond
        for EE = 1:N.channels

            erp = ERPG(:,EE,CC,SUB);

            P = morlet_transform(erp, t, 7, fc, FWHM_tc, squared);
            E = 1;

            tmp = abs( squeeze( P(E,:,:) ) ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT
            wtopo(EE,CC,SUB) = tmp(i);

        end
    end
end


%% plot wavelet topo

close all

limit = mean( wtopo, 3);
limit = [ min(limit(:)) max(limit(:)) ];

TIT = 'wavelet.topo';

h = figure;

for CC = 1:3
    
    subplot(1,3,CC)
    
    if CC < 3
        head = mean( wtopo(:,CC,:), 3);
    else
        head = mean( wtopo(:,2,:), 3) - mean( wtopo(:,1,:), 3);
        limit = [-1 +1].*max(abs(head));
    end
    
    topoplot( head, chanlocs, 'maplimits', limit )
    colorbar
    
    title( STR.cond{CC} )
    
end

maximize(h)
suptitle( TIT )
saveas(h, [ direct.output 'waveletTopo.png' ] )


%% FC5 (electrode 9)?

TIT = 'FC5';

subplot(1,3,1)
topoplot(head,chanlocs,'electrodes','labels')

subplot(1,3,2); cla; hold on

for CC = 1:2
    scatter( ones(Nsub,1)*CC, data2use(:,CC))
end

xlim([0 3])

subplot(1,3,3)
data2use = squeeze( wtopo(9,:,:) )';

[hBar, hErrorbar] = barwitherr( ws_bars(data2use), mean(data2use) );
xlim( [.375 2.625] )

hBar.BarWidth = .75;
hBar.FaceColor = [.5 .5 .5];
set(gca,'tickdir','out','xticklabel',STR.cond(1:2))
ylabel('FFT Amp.')
xlabel('Control')

[~,p,ci,stats] = ttest( data2use(:,1), data2use(:,2) );

text( 1.5, mean( get(gca,'ylim') ), [ 't(' num2str(stats.df) ') = ' num2str(stats.tstat) ', p = ' num2str(p) ], 'horizontalalignment', 'center' )
suptitle(TIT)

saveas(h, [ direct.output TIT '.png' ] )




