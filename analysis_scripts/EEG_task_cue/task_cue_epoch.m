function task_cue_epoch( SUB )
    
    
    p = mfilename('fullpath');
    [~, OUT, ~] = fileparts(p);
    OUT = [ OUT '\' ]; mkdir( OUT );
   
    IN{1} = 'check_alignment3\';
    IN{2} = 'task_cue_group2\';
    
    
    %% load EEG
    
    subject_code_generation;
    [SESSION,PLAYER,STR2] = subStringGen( SUB, subCode );
    
    USE_THIS = [ IN{1} STR2.SUB '.EEG.mat' ];
    disp( ['loading...' USE_THIS] )
    
    tic
    load( USE_THIS, 'EEG_RS', 'trig', 'estimatedAlignmentError', 'eyeLatency', 'SRATE_EEG' )
    toc
   
    
    %% load channels to use
    load( [ IN{2} 'BEST.mat' ], 'BEST' )
    
    
    %% setup
    
    basicSettings
    fs = SRATE_EEG;
    taskCueSettings

    
    %% ANALYSE
    
    % ----- TYPE/LATENCY
    
    TYPE = trig.type(:,T.task_cue);
    LATENCY = trig.latency(:,T.task_cue);
    
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
        
        EPOCH = cat( 2, EPOCH, squeeze( mean( epoch(:,BEST,:), 2) ) );
        epochCode = cat(1, epochCode, CC*ones( size(epoch,3), 1) );

    end
   
    tic
    save( [ OUT STR2.SUB '.EPOCH.mat' ], 'EPOCH', 'epochCode', 'nRejected' );
    toc
