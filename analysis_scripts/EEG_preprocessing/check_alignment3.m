function estimatedAlignmentError = check_alignment3(SUBJECT, SRATE_EEG)
    
    
	addpath('..\external\besa_matlab_readers\')
    
    p = mfilename('fullpath');
    [~, OUT, ~] = fileparts(p);
    OUT = [ OUT '\' ]; if ~exist(OUT, 'dir'); mkdir(OUT); end;
    OUT = [ OUT 'SRATE_EEG_' num2str(SRATE_EEG) '\' ]; if ~exist(OUT, 'dir'); mkdir(OUT); end;
    disp(OUT)
    
    IN = '..\eye_tracking\import_eye_data\';
    
    is_figure_visible = 'off';
    
    basic_settings
    [SESSION, PLAYER, STR] = generate_subject_string(SUBJECT, generate_subject_code);
    
    
    %% load triggers/timings from behaviour file
    
    disp( [ fname.direct_behav fname.behave{SESSION} ] )
    load( [ fname.direct_behav fname.behave{SESSION} ], 'triggers', 'TRIG', 'fliptime', 'n' )
    
    mtype = [];
    mlatency = [];
    trial_counter = [];
    
    
    % trial triggers
    
    for TRIAL = 1:n.trials
        
        tmp = triggers(:,TRIAL);
        dtmp = [1; diff(tmp) > 0 ];
        
        mtype = [mtype; tmp(find(dtmp))];
        mlatency = [mlatency; fliptime.trial(find(dtmp), TRIAL)];
        trial_counter = [trial_counter; TRIAL*ones(5,1)];
        
    end
    
    
    % insert rests
    
    mtype2 = [];
    mlatency2 = [];
    trial_counter2 = [];
    
    for BLOCK = 1:n.blocks
        IDX = (1 : number_of_trials_per_block * number_of_triggers_per_trial) + (BLOCK - 1) * (number_of_trials_per_block * number_of_triggers_per_trial); IDX = IDX';
        mtype2 = [mtype2; TRIG.rest_block; mtype(IDX)];
        mlatency2 = [mlatency2; fliptime.rest_block(1,BLOCK); mlatency(IDX)];
        trial_counter2 = [trial_counter2; 0; trial_counter(IDX)];
    end
    
    
    % end rests
    
    mtype2 = [ mtype2; TRIG.rest_block ];
    mlatency2 = [ mlatency2; fliptime.rest_block(1,end) ];
    trial_counter2 = [ trial_counter2; 0 ];
    
    mlatency2 = mlatency2 - mlatency2(1);
    mlatency2 = mlatency2*SRATE_RECORDING;
    
    
    % plot
    
    h = figure('visible', is_figure_visible);
    
    ax(1) = subplot(2,1,1);
    stem( mlatency2, mtype2 )
    title('triggers')
    
    ax(2) = subplot(2,1,2);
    stem( mlatency2, trial_counter2 )
    title('trial numbers')
    
    suptitle( [ STR.SUBJECT '.behavioural.triggers' ] )
    linkaxes( ax, 'x' )
    
    saveas(h, [ OUT STR.SUBJECT '.png' ] )
    
    save( [ OUT STR.SUBJECT '.behavioural.triggers.mat' ], 'mtype2', 'mlatency2', 'trial_counter2' )
    
    
    %% get EEG events from .evt
    
    disp( [ fname.direct_dat strrep( fname.dat{SESSION,PLAYER}, '.dat', '.evt' ) ] )
    
    if SUBJECT == 22
        
        [type1, latency1] = readEVT( [ fname.direct_dat 'JA_S13_right_2016-07-07_11-25-45-export.evt' ], SRATE_RECORDING );
        [type2, latency2] = readEVT( [ fname.direct_dat 'JA_S13_right_2016-07-07_12-54-05-export.evt' ], SRATE_RECORDING );
        
        %     addpath('E:\toolboxes\besa_matlab_readers')
        %     [~, EEG, ~] = readBESAsb( [ fname.direct_dat 'JA_S13_right_2016-07-07_11-25-45-export.dat' ] );
        
        type = [type1; type2];
        latency = [ latency1 ; latency2 + 2346001 ];
        
    else
        USE_THIS = [ fname.direct_dat strrep( fname.dat{SESSION,PLAYER}, '.dat', '.evt' ) ];
        
        if ~exist(USE_THIS,'file')
            USE_THIS = strrep(USE_THIS, '.evt', '-export.evt');
        end
        
        disp(USE_THIS)
        [type, latency] = readEVT( USE_THIS, SRATE_RECORDING );
    end
    
    % messages.latency = latency( isnan( type ) );
    % messages.position = find( isnan( type ) );
    
    latency( isnan( type ) ) = [];
    type( isnan( type ) ) = [];
    
    
    
    %% INDIVIDUAL SPOT FIX
    
    L = latency;
    
    disp( length(L) == length( mlatency2 ) )
    
    switch SUBJECT
        case 5
            L = deleteTriggers( L, [667 728 2172 2628 3215 3232 3343 3448 3515 3562 3586 3609 3661 3684 3722 3836 3876 3962 4063 4098 4162 4193 4278 4362 4385 4409 4483 4660 4694 4716 4810], 1 );
        case 6
            L = insertTriggers( L, 2205, 6 );
        case 11
            L = deleteTriggers( L, [20 21 29 31 65 83 108 120 126 256 306 398 438 477 562 642 717 1098 1113 1516 1594 1606 1799 2029 2069 2478 2508 2842 3416 3729 3778 3846 3878 3914 3958 4040 4052 4139 4147 4221 4298 4300 4366 4413 4511 4554 4675 4689], 1);
        case 13
            L = deleteTriggers( L, [668 1357 1431 2492 2992 3109 3789 4020], 1);
        case 15
            L = deleteTriggers( L, [973 1105 1178 1763 2361 2432 2629 2659 2720 3070 4735], 1 );
        case 20
            L = insertTriggers( L, 3418, 6 );
            L = insertTriggers( L, 3516, 7 );
        case 21
            L = insertTriggers( L, 1542, 6 );
        case 22
            L = insertTriggers( L, 3300, 436 );
        case 23
            L = deleteTriggers( L, 46, 1 );
            L = deleteTriggers( L, 653, 1 );
            L = deleteTriggers( L, 675, 1 );
            L = deleteTriggers( L, 786, 1 );
            L = deleteTriggers( L, 997, 1 );
            L = deleteTriggers( L, 1121, 1 );
            L = insertTriggers( L, 1816, 7 );
            L = deleteTriggers( L, 2091, 1 );
            L = deleteTriggers( L, 2126, 1 );
            L = deleteTriggers( L, 2181, 1 );
            L = deleteTriggers( L, 2475, 1 );
            L = deleteTriggers( L, 2649, 1 );
            L = deleteTriggers( L, 2834, 1 );
            L = deleteTriggers( L, 3437, 1 );
            L = deleteTriggers( L, 3471, 1 );
            L = deleteTriggers( L, 3552, 1 );
            L = deleteTriggers( L, 3791, 1 );
            L = deleteTriggers( L, 3811, 1 );
            L = deleteTriggers( L, 3921, 1 );
            L = deleteTriggers( L, 3938, 1 );
            L = deleteTriggers( L, 4238, 1 );
            L = deleteTriggers( L, 4393, 1 );
            L = deleteTriggers( L, 4570, 1 );
            L = deleteTriggers( L, 4605, 1 );
            L = deleteTriggers( L, 4615, 1 );
            L = deleteTriggers( L, 4633, 1 );
            L = deleteTriggers( L, 4640, 1 );
            L = deleteTriggers( L, 4714, 1 );
        case 25
            L = deleteTriggers( L, [10 111 256 285 315 361 384 392 496 518 552 570 624 640 644 ], 1 );
            L = deleteTriggers( L, [677], 2);
            L = deleteTriggers( L, [678], 1);
            L = deleteTriggers( L, [687 708 712 740 763 818 911 982 1013 1024 1056 1157 1283 1286], 1);
            L = deleteTriggers( L, [1291 1294 1385 1388 1441 1459 1505 1570 1580 1593 1595 1701 1715 1740 1757 1785 1796 ...
                1839 1952 1962 1976 1990 2011 2117 2117 2195 2249 2277 2277 2309 2333 ...
                2343 2348 2371 2372 2381 2439 2493 2505 2523 2633 2669 2673 2680 ...
                2708 2803 2874 2924 2926 2965 3132 3189 3212 3231 3241 3433 ...
                3438 3560 3629 3651 3688 4167 4224 4288 4375 4449 4461 4666 ...
                4681 4692 4780], 1);
        case 27
            L = deleteTriggers( L, 1, 1);
        case 29
            L = deleteTriggers( L, [422 436 1031 1108 1166 1191 1250 1289 1329 1395 1592 1717 1729 1755 1821 1841 2141 2744 2774 2873 2887 3035 3053 3083 3093 3139 3156 3176 3215 3215 3231 3245 3416 3419 ...
                3431 3445 3456 3526 3636 3705 3807 3808 3829 3885 4027 4098 4098 4175 4362 4380 4394 4448 4479 4494 4525 4542 4550 4606 4667 4749 4797], 1);
        case 30
            L = insertTriggers( L, 2275, 7);
            L = insertTriggers( L, 2833, 6);
            L = insertTriggers( L, 3918, 9);
        case 31
            L = deleteTriggers( L, [13 16 123 323 451 620 644 790 819 913 954 1050 1305 2891 2944 2984 3654 4175 4220 4408 4573 4810], 1);
        case 33
            L = deleteTriggers( L, [2 39 56 75 89 111 118 126 128 138 174 195 230 240 241 310 352 401 401 414 456 476 530 561 660 665 668 763 782 789 797 801 862 882 887 956 1025 1027 1064 ...
                1131 1169 1178 1212 1254 1359 1467 1533 1535 1550 1647 1655 1715 1726 1773 1775 1805 1816 1881 1896 1966 2043 2068 2257 2394 2452 2477 2639 2652 2794 2843 2922 2981 3015 3049 ...
                3056 3100 3250 3290 3291 3371 3391 3438 3546 3581 3661 3696 3727 3757 3877 3882 4015 4210 4274 4314 4369 4474 4585], 1);
        case 35
            L = insertTriggers( L, 2788, 5);
            L = insertTriggers( L, 3329, 6);
        case 37
            L = deleteTriggers( L, 1, 1);
            L = deleteTriggers( L, 1857, 3);
        case 38
            L = deleteTriggers( L, 1857, 3);
            L = insertTriggers( L, 2028, 122);
    end
    
    
    %%
    
    h = figure('visible', is_figure_visible);
    cla; hold on
    
    TIT = [ STR.SUBJECT '.latencyAlignment' ];
    
    plot( diff( mlatency2 ), 'b' )
    plot( diff( L ), 'r' )
    
    title(TIT)
    legend( {'matlab' 'evt'} )
    
    saveas(h, [ OUT TIT '.png' ] )
    
    
    %%
    
    h = figure('visible', is_figure_visible);
    
    plot( diff( mlatency2(1:4816) ) - diff( L(1:4816) ) )
    
    TIT = [ STR.SUBJECT '.latencyAlignment2' ];
    title(TIT)
    
    saveas(h, [ OUT TIT '.png' ] )
    
    
    %% REMOVE RESTS
    
    TYPE2 = mtype2( trial_counter2 ~= 0 );
    LATENCY2 = L( trial_counter2 ~= 0 );
    mlatency3 = mlatency2( trial_counter2 ~= 0 );
    
    % find trial properties
    
    trig.type = NaN( number_of_trials, number_of_triggers_per_trial );
    trig.latency = NaN( number_of_trials, number_of_triggers_per_trial );
    
    trig.type(:,T.rest_trial) = TYPE2(1 : number_of_triggers_per_trial : end); % TYPE of rest
    trig.type(:,T.fix)        = TYPE2(2 : number_of_triggers_per_trial : end); % TYPE of fixation, Hz combo triggers
    trig.type(:,T.task_cue)   = TYPE2(3 : number_of_triggers_per_trial : end); % TYPE of task cue(solo/coop)
    trig.type(:,T.move_cue)   = TYPE2(4 : number_of_triggers_per_trial : end); % TYPE of move cue (left/right)
    trig.type(:,T.feedback)   = TYPE2(5 : number_of_triggers_per_trial : end); % TYPE of feedback
    
    trig.latency(:,T.rest_trial) = LATENCY2(1 : number_of_triggers_per_trial : end); % LATENCY of rest
    trig.latency(:,T.fix)        = LATENCY2(2 : number_of_triggers_per_trial : end); % LATENCY of fixation, Hz combo triggers
    trig.latency(:,T.task_cue)   = LATENCY2(3 : number_of_triggers_per_trial : end); % LATENCY of task cue(solo/coop)
    trig.latency(:,T.move_cue)   = LATENCY2(4 : number_of_triggers_per_trial : end); % LATENCY of move cue (left/right)
    trig.latency(:,T.feedback)   = LATENCY2(5 : number_of_triggers_per_trial : end); % LATENCY of feedback
    
    % compare trigger timings
    
    L = mlatency2( mtype2 ~= TRIG.rest_block );
    LL = NaN(n.trials,number_of_triggers_per_trial);
    
    for TT = 1:n.trials
        LL( TT, : ) = L( (TT-1)*number_of_triggers_per_trial + 1 : (TT)*number_of_triggers_per_trial );
    end
    
    data2use1 = cumsum( diff( LL, [], 2 ) ./ SRATE_RECORDING, 2 ) * 1000;
    data2use2 = cumsum( diff( trig.latency, [], 2 ) ./ SRATE_RECORDING, 2 ) * 1000;
    data2use3 = data2use1 - data2use2;
    
    estimatedAlignmentError = max( abs( data2use1 - data2use2 ), [], 2 );
    
    h = figure('visible', is_figure_visible);
    
    TIT = [ STR.SUBJECT '.estimatedAlignmentError'  ];
    
    ax(1)=subplot(4,1,1);
    imagesc( data2use1' )
    colorbar
    
    title(TIT)
    
    ax(2)=subplot(4,1,2);
    imagesc( data2use2' )
    colorbar
    
    ax(3)=subplot(4,1,3);
    imagesc( data2use3' )
    colorbar
    
    ax(4)=subplot(4,1,4);
    plot( estimatedAlignmentError )
    xlim( [1 number_of_trials] )
    colorbar
    
    linkaxes(ax,'x')
    
    saveas(h, [ OUT TIT '.png' ] )
    
    if ~ismember( SUBJECT, [3 4] )
        
        if exist([IN STR.SUBJECT '.eye.mat'], 'file')
            
            %% load
            tmp = load([IN STR.SUBJECT '.eye.mat'], 'latency');
            eyeLatency = tmp.latency;
        
            %% align eye triggers

            mlatency4 = mlatency3( 1 : number_of_triggers_per_trial : end );
            dM = diff( mlatency4 ) ./ 500; % s

            L = eyeLatency;

            if ismember(SUBJECT, [37 38])
                L = deleteTriggers( L, [1 65 129 193 257 321 371 385 449 513 577 ...
                    641 705 769 833 897], 1);
                L = L(1:960);
            else

                if length(L) > 976
                    L = deleteTriggers( L, 1, 1 );
                end

                L = deleteTriggers( L, 1:64:972, 1);

            end

            dL = diff( L ) ./ 1e6; % s

            % cla; hold on
            % plot( dM, 'b' )
            % plot( dL, 'r' )
            % ylim([5 8])

            h = figure('visible', is_figure_visible);

            TIT = [ STR.SUBJECT '.eyeAlignment' ];

            subplot(2,1,1)
            cla; hold on
            plot( dM, 'b' )
            plot( dL, 'r' )

            if ismember(SUBJECT, [37 38])
                ylim( [0 30] )
            end

            title(TIT)

            subplot(2,1,2)
            plot( dM-dL )

            if ismember(SUBJECT, [37 38])
                ylim( [-10e-3 +10e-3] )
            end

            saveas(h, [ OUT TIT '.png' ] )

            eyeLatency = L;

        else
            eyeLatency = [];
        end
    else
        warning([IN STR.SUBJECT '.eye.mat was not found!'])
        eyeLatency = [];
    end
        
    
    %% load EEG
    
    disp('loading EEG...')
        
    if SUBJECT == 22
        
        EEG = [];
        
        for EE = 1:2
            
            switch EE
                case 1
                    fname2use = 'JA_S13_right_2016-07-07_11-25-45-export.dat';
                case 2
                    fname2use = 'JA_S13_right_2016-07-07_12-54-05-export.dat';
            end
            
            disp([ fname.direct_dat fname2use ])
            
            tic
            [~, tmp, ~] = readBESAsb([fname.direct_dat fname2use]);
            toc
            
            tmp = squeeze( tmp(1:number_of_channels,:,:) )';
            
            EEG = [ EEG; tmp ];
            
            clear tmp
        end
        
    else
        
        USE_THIS = [fname.direct_dat fname.dat{SESSION,PLAYER}];
        
        if ~exist(USE_THIS,'file')
            USE_THIS = strrep(USE_THIS, '-export.dat', '.dat');
        end
        
        disp(USE_THIS)
        
        tic
        [~, EEG, ~] = readBESAsb( USE_THIS );
        toc
        
        EEG = squeeze( EEG(1:number_of_channels,:,:) )';
        
    end
    
    h = figure('visible', is_figure_visible);
    
    TIT = [ STR.SUBJECT '.finalAlignment'  ];
    
    ax(1) = subplot(2,1,1);
    stem( trig.latency(:), trig.type(:) )
    xlim( [ 1 size(EEG,1) ] )
    
    title(TIT)
    
    ELECTRODE = 61;
    
    ax(2) = subplot(2,1,2);
    plot( 1:size(EEG,1), EEG(:,ELECTRODE) )
    ylim( [-100 +100] )
    xlim( [ 1 size(EEG,1) ] )
    title( channel_order{ELECTRODE} )
    linkaxes(ax,'x')
    
    saveas(h, [ OUT TIT '.png' ] )
    
    
    %% downsample EEG - 2000 Hz
    
    disp('resampling...')
    
    % md = max(max(abs(round( trig.latency )/2000 - round( trig.latency * (SRATE_EEG/2000) )/SRATE_EEG)))
    % (md*1000)/(1000/7)*100
    % 4*40*(SRATE_EEG)/2000
    
    tic
    trig.latency = round( trig.latency * (SRATE_EEG/SRATE_RECORDING) );
    EEG_RS = resample(EEG, SRATE_EEG, SRATE_RECORDING);
    toc
    
    disp('single precision...')
    
    tic
    EEG_RS = single(EEG_RS);
    toc
    
    h = figure('visible', is_figure_visible);
    
    TIT = [ STR.SUBJECT '.ultimateAlignment'  ];
    
    ax(1) = subplot(2,1,1);
    stem( trig.latency(:), trig.type(:) )
    xlim( [ 1 size(EEG_RS,1) ] )
    
    title(TIT)
    
    ax(2) = subplot(2,1,2);
    plot( 1:size(EEG_RS,1), EEG_RS(:,61) )
    ylim( [-100 +100] )
    xlim( [ 1 size(EEG_RS,1) ] )
    
    linkaxes(ax,'x')
    
    saveas(h, [ OUT TIT '.png' ] )
    
    
    %% save EEG with trigger timing
    
    disp('saving....')
    
    tic
    disp([ OUT STR.SUBJECT '.EEG.mat' ])
    save( [ OUT STR.SUBJECT '.EEG.mat' ], 'EEG_RS', 'trig', 'estimatedAlignmentError', 'eyeLatency', 'SRATE_EEG' )
    toc