function res = permF(EPOCH, win, EE, type)
    
    EEG_ARTIFACT_THREHOLD_RANGE = 200;
    
    number_of_sessions = size(EPOCH, 4);
    number_of_trials = size(EPOCH, 2);
    
    res = NaN(number_of_sessions,2);
    
    for SESSION = 1:number_of_sessions
        
        r = NaN(number_of_trials,1);
        
        for TRIAL = 1:number_of_trials 
            if ~any( squeeze( range( EPOCH(win.start(EE):win.stop(EE),TRIAL,:,SESSION) ) ) > EEG_ARTIFACT_THREHOLD_RANGE )
                r(TRIAL,1) = corr( EPOCH(win.start(EE):win.stop(EE),TRIAL,1,SESSION), EPOCH(win.start(EE):win.stop(EE),TRIAL,2,SESSION) );
            end
        end
        
        res(SESSION,:) = grpstats( r, type(:,1,SESSION), {'mean'} );
        
    end
    
end