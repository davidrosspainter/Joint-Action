function task_cue2( SUB )
    
    p = mfilename('fullpath');
    [~, OUT, ~] = fileparts(p);
    OUT = [ OUT '\' ]; mkdir( OUT );
    
    IN = 'check_alignment3\';
    
    %STR.cond = {'Solo' 'Joint' 'Solo-Joint'};
    subject_code_generation;
    [SESSION,PLAYER,STR2] = subStringGen( SUB, subCode );
    
    
    %% load data
    
    USE_THIS = [ IN STR2.SUB '.EEG.mat' ];
    disp( ['loading...' USE_THIS] )
    
    tic
    load( USE_THIS, 'EEG_RS', 'trig', 'estimatedAlignmentError', 'eyeLatency', 'SRATE_EEG' )
    toc
    
    
    basicSettings
    fs = SRATE_EEG;
    taskCueSettings
    
    
    % ----- TYPE/LATENCY
    
    TYPE = trig.type(:,T.task_cue);
    LATENCY = trig.latency(:,T.task_cue);
    
    % ----- make ERP
    
    ERP = NaN( n.x, N.channels, n.cond );
    AMP = NaN( n.x, N.channels, n.cond );
    
    EPOCH = [];
    epochCode = [];
    
    nRejected = zeros(n.cond,1);
    
    for CC = 1:n.cond
        
        latency = LATENCY( ismember( TYPE, COND{CC} ) );
        
        num.total(CC) = length(latency);
        num.missing(CC) = sum( isnan( latency ) );
        
        latency( isnan(latency) ) = [];
        
        start = round( latency + lim.x(1) );
        stop = round( latency + lim.x(2) );
        
        epoch = NaN( n.x, N.channels, length(latency) );
        
        for E = 1:length(latency)
            
            data2use = EEG_RS(start(E):stop(E),:);
            data2use = detrend(data2use,'linear');
            
            if isempty(find(t == 0)) % if no zero point % DRP 4/10/2018
                data2use = data2use - repmat( data2use( 1,:), size(data2use,1), 1);
            else
                data2use = data2use - repmat( data2use( t == 0,:), size(data2use,1), 1);
            end
            
            if ~any( abs( data2use(:) ) > 100 ) % DRP 4/10/2018
                epoch(:,:,E) = data2use;
            else
                nRejected(CC) = nRejected(CC) + 1;
            end
            
        end
        
        TIT = [ STR2.SUB '.erpImage.' STR.cond{CC} '.png' ];
        
        close all
        
        h = figure('visible',options.visible);
        
        subplot(2,1,1)
        imagesc( nanmean( epoch, 3 )' )
        colorbar
        
        idx = any( squeeze( range( epoch, 1 ) > 200 ) );
        num.rejected(CC) = sum(idx);
        epoch( :, :, idx ) = NaN;
        
        subplot(2,1,2)
        imagesc( nanmean( epoch, 3 )' )
        colorbar
        colormap('jet')
        
        title( num.total(CC) - num.rejected(CC) )
        suptitle(TIT)
        
        saveas(h, [ OUT TIT '.png' ] )
        
        ERP(:,:,CC) = nanmean(epoch,3);
        
        amp = abs( fft( ERP(:,:,CC) ) )/n.x;
        amp(2:end-1,:) = amp(2:end-1,:)*2; % double amplitudes
        
        AMP(:,:,CC) = amp;
        
        
        %% ---- save for perm test ---- extra to save
        
        %     load( 'taskCueGroup\BEST.mat', 'BEST' )
        %
        %     EPOCH = cat( 2, EPOCH, squeeze( mean( epoch(:,BEST,:), 2) ) );
        %     epochCode = cat(1, epochCode, CC*ones( size(epoch,3), 1) );
        
    end
    
    
    for CC = 1:n.cond
        
        h = figure('visible',options.visible);
        
        head = AMP( idxHz, :, CC );
        [v,i] = sort( head(chan2use), 'descend');
        BEST = i(1:4);
        
        spectra = mean( AMP(:,chan2use(BEST), CC ), 2);
        erp = mean( ERP(:, chan2use(BEST), CC ), 2);
        
        P = morlet_transform(erp, t, f.wavelet, fc, FWHM_tc, squared);
        E = 1;
        A = abs( squeeze( P(E,:,:) )' ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT
        
        TIT = [  STR2.SUB '.' STR.cond{CC} '.' num2str(Hz) '.Hz' ];
        
        % ----- topoplot
        
        subplot(3, 2, 1)
        
        topoplot( head, chanlocs, 'maplimits', [min(head) max(head)], 'colormap', colormap('jet'), 'conv', 'on', 'shading', 'flat', 'emarker2', {chan2use(BEST) '.' 'b' 20} );
        hc = colorbar;
        set(get(hc,'title'),'string','\muV');
        
        % ----- spectra
        
        subplot(3, 2, 2)
        
        plot(f.fft, spectra)
        xlim( [Hz-2 Hz+2] )
        xlim([2 21] )
        
        line([Hz Hz], get(gca,'ylim'), 'color', 'r')
        
        xlabel( 'Frequency (Hz)' )
        ylabel( 'FFT Amp. (\muV)' )
        
        % ----- erps
        
        subplot(3, 2, [3 4])
        
        plot(t, erp )
        xlim( [lim.s(1) lim.s(2)] )
        xlabel( 'Time (s)' )
        ylabel( 'EEG Amp. (\muV)' )
        colorbar
        
        % ----- wavelet
        
        subplot(3, 2, [5 6])
        
        imagesc(t, f.wavelet, A );
        
        xlabel( 'Time (s)' )
        ylabel( 'Frequency (Hz)' )
        hc = colorbar;
        set(get(hc,'title'),'string','\muV');
        
        colormap(jet)
        suptitle( TIT )
        
        saveas(h, [ OUT TIT '.png' ] )
        
    end
    
    
    %%
    
    tic
    save( [ OUT STR2.SUB '.ERP.AMP.mat' ], 'ERP', 'AMP', 'num', 'STR', 'nRejected' )
    toc
    
    % tic ---- extra?
    % save( [ OUT 'EPOCH.' STR2.SUB '.mat' ], 'EPOCH', 'epochCode' );
    % toc
