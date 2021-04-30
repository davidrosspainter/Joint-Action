clear; clc; close all; restoredefaultpath

addpath('..\external\');

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );

IN = 'spatialAttention\';

basicSettings
SRATE_EEG = 256;
fs = SRATE_EEG;
spatialAttentionSettings


%% group effects

missing = NaN(Nsub,n.cond);
rejected = NaN(Nsub,n.cond);

ERPG = NaN( n.x, N.channels, n.cond, Nsub );
AMPG = NaN( n2.x, N.channels, n.cond, Nsub );

for SUB = 1:Nsub
    
    [~,~,STR] = subStringGen( SUB, subCode );
    load( [ IN STR.SUB '.epoch.mat' ], 'ERP' )
    
%     missing(SUB,:) = num.missing;
%     rejected(SUB,:) = num.rejected;
    
    ERPG(:,:,:,SUB) = ERP;
    
    % ---- reduced epoch
    
    data2use = ERP(lim2.x(1):lim2.x(2),:,:);
    amp = abs( fft( data2use, n2.x ) )/n2.x;
    amp(2:end-1,:) = amp(2:end-1,:)*2; % double amplitudes
    
    AMPG(:,:,:,SUB) = amp;
    
end


%% all FFT

BEST = [28 29 61];

% STR.cond = {'solo.17' 'solo.19' 'joint17' 'joint19' };

for CC = 1:4
    
    spectra = squeeze( mean( mean( AMPG(:,BEST,:,:), 2), 4) );
    head = squeeze( mean( AMPG(idxHz,:,:,:), 4) );
    bars =  squeeze( mean( AMPG(idxHz,BEST,:,:), 2) );

end

%% spectra

close all

cond2use(1,:) = [1 3];
cond2use(2,:) = [2 4];

for CC = 1:2
    
    h = figure;
    data2use = mean( spectra(:,cond2use(CC,:)),2);
    plot(f.fft,data2use)
    xlim([15 21])
    
    for HH = 1:2
        line( f.fft(idxHz(HH))*[1 1], [0 data2use(idxHz(HH))], 'color', 'r' )
    end
    
    set(gca,'tickdir','out')
    xlabel('Frequency (Hz)')
    ylabel('SSVEP Amplitude (\muV)' )
    
    saveas(h, [ OUT 'fft.publish' num2str(CC) '.eps' ], 'epsc' )
end


%% topos

% STR.cond = {'solo.17' 'solo.19' 'joint17' 'joint19' };

STR.cond2 = {'soloT', 'jointT', 'soloD', 'jointD'};

close all

for CC = 1:4
    
    switch CC
        case 1
            data2use = mean( cat(1, squeeze( head(1,:,1) ), squeeze( head(2,:,2) ) ), 1);
        case 2
            data2use = mean( cat(1, squeeze( head(1,:,3) ), squeeze( head(2,:,4) ) ), 1);
        case 3
            data2use = mean( cat(1, squeeze( head(2,:,1) ), squeeze( head(1,:,2) ) ), 1);
        case 4
            data2use = mean( cat(2, squeeze( head(2,:,3) ), squeeze( head(1,:,4) ) ), 1);
    end


    
    h = figure;
    limit = [ 0 0.82 ];
    topoplot( data2use, chanlocs, 'maplimits', limit, 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'interp', 'electrodes', 'on');
    hc = colorbar;
    set(get(hc,'title'),'string','\muV');
        
    caxis()
    colormap(flipud(hot(1024)))
    
    saveas(h, [ OUT STR.cond2{CC} '.png' ] )
    
end


%% bars

%STR.cond2 = {'soloT', 'jointT', 'soloD', 'jointD'};

data2use2 = [];

for CC = 1:4
    
    switch CC
        case 1
            data2use = [ squeeze( bars(1,1,:) ), squeeze( bars(2,2,:) ) ];
        case 2
            data2use = [ squeeze( bars(1,3,:) ), squeeze( bars(2,4,:) ) ];
        case 3
            data2use = [ squeeze( bars(2,1,:) ), squeeze( bars(1,2,:) ) ];
        case 4
            data2use = [ squeeze( bars(2,3,:) ), squeeze( bars(1,4,:) ) ];
    end

    data2use = mean(data2use,2);
    data2use2 = [ data2use2 data2use ];
    
end


%%

data2use3 = [];

data2use3(:,1,1) = data2use2(:,1);
data2use3(:,1,2) = data2use2(:,2);
data2use3(:,2,1) = data2use2(:,3);
data2use3(:,2,2) = data2use2(:,4);

M = squeeze( mean(data2use3) );
E = ws_bars(data2use2);
E = [ E(1:2); E(3:4) ];

close all

h = figure;
[hBar, hErrorbar] = barwitherr(E,M);
xlim( [.375 2.625] )
set(gca,'tickdir','out')
ylabel('SSVEP Amplitude (\muV)' )
xlabel('Stimulus')
set(gca,'xticklabels', {'Target' 'Distractor' })
legend({'Solo' 'Joint'},'location','northeast')

saveas(h, [ OUT 'bars.publish.eps' ] , 'epsc' )


%% SPSS

STR.cond3 = {'soloT', 'jointT', 'soloD', 'jointD'};
STR.spss = [];

for CC = 1:n.cond
    
    STR.spss = [ STR.spss STR.cond3{CC} '\t' ] ;
end

out_name = [OUT 'spatialAttention.txt' ];

delete( out_name )
fid = fopen(out_name,'a+');

fprintf(fid, STR.spss);
fprintf(fid, '\n');
dlmwrite(out_name, data2use2, '-append', 'delimiter', '\t');
fclose(fid);


%% electrode settings

n.best = 3;
close all;

% STR.cond = {'solo.17' 'solo.19' 'joint17' 'joint19' };

STR.cond2 = {'17' '19'};
cond2use = [1 3; 2 4];
n.cond2 = 2;

AMPM = NaN( n2.x, N.channels, n.cond2 );
head = NaN( N.channels, n.Hz, n.cond2 );
BEST = NaN( n.best, n.Hz, n.cond2 );

for CC = 1:n.cond2

    h = figure;
    
    AMPM(:,:,CC) = nanmean( nanmean(AMPG(:,:,cond2use(CC,:),:),3), 4);

    for HH = 1:n.Hz
        
        head(:,HH,CC) = squeeze( AMPM( idxHz(HH), :, CC ) );
        [~,i] = sort(head(chan2use,CC), 'descend');
        tmp = i(1:n.best); tmp = chan2use(tmp);
        BEST(:,HH,CC) = tmp;
        
    end
    
    limit = head(:,:,CC); limit = [min(limit(:)) max(limit(:))];
    
    for HH = 1:n.Hz
    
        subplot(2,2,HH)

        topoplot( head(:,HH,CC), chanlocs, 'maplimits', limit, 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'flat', 'emarker2', {BEST(:,HH,CC) '.' 'b' 20} );
        hc = colorbar;
        set(get(hc,'title'),'string','\muV');

        subplot(2,2,HH+2)

        plot( f.fft, mean( AMPM(:,BEST(:,HH,CC),CC), 2) )
        xlim( [15 21] )
        
    end
    
    TIT = [ 'electrodes.' num2str( STR.cond2{CC} ) ];
    suptitle(TIT)
    
    saveas(h, [ OUT TIT '.png' ] )
end


%% all fft


return

%% ----- wavelet settings

% STR.cond2 = {'17' '19'};
% cond2use = [1 3; 2 4];
% n.cond2 = 2;

wAMPG = NaN( n.x, n.f, n.cond2, Nsub );

for SUB = 1:Nsub
    for CC = 1:n.cond2
    
        HH = CC;
        e2use = BEST(:,HH,CC);
        
        erp = mean( mean( ERPG(:,e2use,cond2use(CC,:),SUB), 2), 3);
    
        P = morlet_transform(erp, t, f.wavelet, fc, FWHM_tc, squared);
        E = 1;
        wAMPG(:,:,CC,SUB) = abs( squeeze( P(E,:,:) ) ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT
        
    end
end


%% ------ plot settings

wAMPGM = nanmean( wAMPG, 4);

TIT = 'wavelet.Settings';

STR.cond2{3} = '19-17';

h = figure;

limit = [ min( wAMPGM(:) ) max( wAMPGM(:) ) ];

for CC = 1:n.cond2+1
    
    subplot(3,1,CC)
    
    if CC <= n.cond2
        imagesc(t,f.wavelet,wAMPGM(:,:,CC)')
    else
        dwAMPGM = wAMPGM(:,:,2)'-wAMPGM(:,:,1)';
        imagesc(t,f.wavelet,dwAMPGM)
        limit = [-1 +1].*max(abs(dwAMPGM(:)));
    end
    
    colorbar
    colormap('jet')
    caxis(limit)
    
    title( STR.cond2{CC} )
    
end


saveas(h, [ OUT TIT '.png' ] )



%% all wavelet

for SUB = 1:Nsub
    for CC = 1:n.cond

        erp = mean( ERPG(:,unique(BEST(:)),CC,SUB), 2);
    
        P = morlet_transform(erp, t, f.wavelet, fc, FWHM_tc, squared);
        E = 1;
        wAMPG2(:,:,CC,SUB) = abs( squeeze( P(E,:,:) ) ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT
        
    end
end


%% difference


% STR.cond = {'solo.17' 'solo.19' 'joint17' 'joint19' };

cmaps;

figure;

for CC = 1:3
    
    
    switch CC
        case 1
            head = wAMPG2(:,:,2,:)-wAMPG2(:,:,1,:);
            head = mean(head,4);
        case 2
            head = wAMPG2(:,:,4,:)-wAMPG2(:,:,3,:);
            head = mean(head,4);
        case 3
            head1 = wAMPG2(:,:,2,:)-wAMPG2(:,:,1,:);
            head2 = wAMPG2(:,:,4,:)-wAMPG2(:,:,3,:);
            
            head = head2 - head1;
            
            head = mean(head,4);
    end
    
    subplot(3,1,CC)
    imagesc(t,f.wavelet,head')
	limit = [-1 +1].*max(abs(head(:)));
    colorbar
    colormap(kindlmann)
    caxis(limit)
    caxis()
    
end


%%

%% difference2


% STR.cond = {'solo.17' 'solo.19' 'joint17' 'joint19' };

cmaps;

figure;

for CC = 1:3
    
    
    switch CC
        case 1
            head = wAMPG2(:,:,3,:)-wAMPG2(:,:,1,:);
            head = mean(head,4);
        case 2
            head = wAMPG2(:,:,4,:)-wAMPG2(:,:,2,:);
            head = mean(head,4);
        case 3
            head1 = wAMPG2(:,:,3,:)-wAMPG2(:,:,1,:);
            head2 = wAMPG2(:,:,4,:)-wAMPG2(:,:,2,:);
            
            head2 = head2(:,41:-1:1,:,:);
            
            head = cat(3,head1,head2);
            head = mean(head,3);
            
            head = mean(head,4);
    end
    
    subplot(3,1,CC)
    imagesc(t,f.wavelet,head')
	limit = [-1 +1].*max(abs(head(:)));
    colorbar
    colormap(kindlmann)
    caxis(limit)
    caxis()
    
end


%%

% ----- test hypothesis

% STR.cond2 = {'17' '19'};
% cond2use = [1 3; 2 4];
% n.cond2 = 2;

wAMPGH = NaN( n.x, n.f, n.cond2, Nsub );

for SUB = 1:Nsub
    for CC = 1:n.cond
    
        if ismember(CC,cond2use(1,:))
            CC1 = 1;
        elseif  ismember(CC,cond2use(2,:))
            CC1 = 2;
        end
            
        HH = CC1;
        e2use = BEST(:,HH,CC1);
        
        erp = mean( ERPG(:,e2use,CC,SUB), 2);
    
        P = morlet_transform(erp, t, f.wavelet, fc, FWHM_tc, squared);
        E = 1;
        wAMPGH(:,:,CC,SUB) = abs( squeeze( P(E,:,:) ) ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT
        
    end
end

wAMPGHM = nanmean( wAMPGH, 4);

%% ----- plot!
% 
% STR.cond{5} = 'joint-solo.17';
% STR.cond{6} = 'joint-solo.19';
% 
% 
% 
% figure;
% 
% limit = [min(wAMPGHM(:)) max(wAMPGHM(:))];
% 
% for CC = 1:n.cond+2
%     
%     if ismember(CC,[1 3 5])
%         idx = f.wavelet >= 16 & f.wavelet <= 18;
%     elseif  ismember(CC,[2 4 6])
%         idx = f.wavelet >= 18 & f.wavelet <= 20;
%     end
%     
%     subplot(3,2,CC)
%     
%     if CC <= n.cond
%         imagesc(t,f.wavelet(idx),wAMPGHM(:,idx,CC)')
%     else
%         if CC == 5
%             dwAMPGHM = wAMPGHM(:,:,3)-wAMPGHM(:,:,1);
%         elseif CC == 6
%             dwAMPGHM = wAMPGHM(:,:,4)-wAMPGHM(:,:,2);
%         end
%         
%         test(:,:,CC-4) = dwAMPGHM;
%         
%         imagesc(t,f.wavelet(idx),dwAMPGHM(:,idx)')
%         limit = [-1 +1].*max(abs(dwAMPGHM(:)));
%     end
%     
%     colorbar
%     colormap('jet')
%     caxis(limit)
%     
%     title( STR.cond{CC} )
% 
% end





%%

ts = [];
ts2 = [];


for CC = 1:n.cond
    for HH = 1:n.Hz
        
        idx = f.wavelet == Hz(HH);
        %ts(:,HH,CC) = wAMPGHM(:,idx,CC);
  
        ts2(:,HH,CC,:) = wAMPGH(:,idx,CC,:);
    end 
end


%%

h1 = figure(1);
h2 = figure(2);

data2use2 = [];

for AA = 1:4
    
    figure(1);
    
    ax(AA) = subplot(2,2,AA); cla; hold on
    
    clear data2use2
    
    for PP = 1:2
        
        switch AA
            case 1
                switch PP
                    case 1
                        CC = 1; HH = 1;
                    case 2
                        CC = 3; HH = 1;
                end
            case 2
                switch PP
                    case 1
                        CC = 2; HH = 2;
                    case 2
                        CC = 4; HH = 2;
                end
            case 3
                switch PP
                    case 1
                        CC = 1; HH = 2;
                    case 2
                        CC = 3; HH = 2;
                end
            case 4
                switch PP
                    case 1
                        CC = 2; HH = 1;
                    case 2
                        CC = 4; HH = 1;
                end
        end
        
        data2use = squeeze( ts2(:,HH,CC,:) )';
        
        M = mean(data2use);
        E = ws_bars(data2use);
        errorbar( t, M, E, col{PP} )
        
        data2use2(:,:,PP) = data2use;
        data2use3(:,:,PP,AA) = data2use;
        
    end
    
    legend({'S' 'C'})
   % linkaxes(ax,'xy')
    
    clear p
    
    for TT = 1:size(data2use2,2)
        [~,p(TT)] = ttest( data2use2(:,TT,1), data2use2(:,TT,2) );
    end
    
    figure(2);
    
    subplot(2,2,AA)
    plot(t,p)
    
end

figure(1);
suptitle('wave.amp')
saveas(h1, [ OUT 'wave.amp.png' ] )

figure(2);
suptitle('p.value')
saveas(h2, [ OUT 'p.value.png' ] )


%% ----- average across frequencies

close all

data2use4(:,:,:,1) = mean( data2use3(:,:,:,[1 2]), 4 );
data2use4(:,:,:,2) = mean( data2use3(:,:,:,[3 4]), 4 );

h1 = figure(1);
h2 = figure(2);

clear ax

for AA = 1:2
    
    figure(1);
    
    ax(AA) = subplot(2,2,AA); hold on
    
    for PP = 1:2
        
        data2use = data2use4(:,:,PP,AA);
        
        M = mean(data2use);
        E = ws_bars(data2use);
        errorbar( t, M, E, col{PP} )
        ylim([0 .8])
    end
    
    legend({'S' 'C'})
       
    data2use2 = data2use4(:,:,:,AA);
        
    p = [];
    
    for TT = 1:size(data2use2,2)
        [~,p(TT)] = ttest( data2use2(:,TT,1), data2use2(:,TT,2) );
    end
    
    subplot(2,2,AA+2)

    plot(t,p)
    
    
end


%linkaxes(ax,'xy')



%%


