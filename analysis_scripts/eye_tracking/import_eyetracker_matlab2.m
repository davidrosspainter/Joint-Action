function import_eyetracker_matlab2(SESSION, PLAYER)
    
    p = mfilename('fullpath');
    [~, OUT, ~] = fileparts(p);
    OUT = [OUT '\']; mkdir(OUT); disp(OUT)
    
    IN = '..\data_manager\CheckFiles2\';
    load( [IN 'fname.mat'] )
    
    addpath('..\external\')
    addpath('..\common\')
    
    is_figure_visible = 'off';

    event_codes = 1; % joint action
    N.trials = 960;

    str.player = {'P1', 'P2'};
    str.side = {'left', 'right'};
    
    fname.OUT = ['S' num2str(SESSION) '.' str.player{PLAYER}];
    disp(fname.OUT)

    % events --- > binocular / either eye ticked messages ticked
    % samples --- > mapped pupil diameter, gaze position, binocular / either

    header = {'Time',	'Type',	'Trial',	'L Mapped Diameter [mm]',	'R Mapped Diameter [mm]',	'L POR X [px]',	'L POR Y [px]',	'R POR X [px]',	'R POR Y [px]'};

    
    %% get triggers from behavioural data
    
    idx = ismember( fname.str, generate_session_string(SESSION) );
    disp( [fname.direct_behav fname.behave{idx}] )
    load( [fname.direct_behav fname.behave{idx}],  'triggers', 'TRIG', 'n', 'data', 'D', 'btriggers' )
    
    TRIGGERS = [];
    
    for TRIAL = 1:N.trials
        TRIGGERS = [ TRIGGERS; triggers(:,TRIAL) ];
    end
    
    DTRIGGERS = [ 1; diff(TRIGGERS) ] > 0;
    IDX = find(DTRIGGERS);
    
    DTRIGGERS = TRIGGERS(DTRIGGERS);
    
    h = figure('visible', is_figure_visible); hold on
    TIT = [fname.behave{idx} '.png'];
    
    plot(TRIGGERS)
    plot(IDX, DTRIGGERS,'r+')
    
    title(TIT)
    saveas(h, [OUT TIT])
    
    TYPE = DTRIGGERS;
    
    
    %% convert latency to eye units
    
    IDX = find([ 1; diff(TRIGGERS) ] > 0);
    
    IDX = round((IDX*1000000)/144);
    IDX = IDX-IDX(1);
    
    IDX_eye = find(TYPE == TRIG.rest_trial); % eye tracking triggers

    
    %% ready load of eye data
    
    if SESSION < 10; placeholder = '0'; else placeholder = ''; end
    
    DD = dir([fname.direct_eyeSamples 'S' placeholder num2str(SESSION) '_' str.side{PLAYER} '*Samples.txt']);
    
    fname.samples = DD.name;
    fname.events = DD.name;
    
    disp( fname.samples )
    disp( fname.events )
    
    
    %% read samples
    
    fileID = fopen([fname.direct_eyeSamples fname.samples]);
    
    C = textscan(fileID,'%u64 %s %u64 %f %f %f %f %f %f', 'Headerlines', 39);
    
    %         if SESSION == 23 && side == 1
    %            C = textscan(fileID,'%u64 %s %u64 %f %f %f %f %f %f', 'Headerlines', 40);
    %         end
    
    fclose(fileID);
    
    samples = NaN( length(C{1}), 8 );
    
    for CC = [1 3:9]
        %             if SESSION == 23 && side == 1 % not sure why... giving it a try
        %                 samples(1:length(C{CC}),CC) = C{CC};
        %             else
        samples(:,CC) = C{CC};
    end
    
    
    %% read events file
    
    fileID = fopen( [ fname.direct_eyeEvents fname.events ] );
    C = textscan(fileID, '%s', 'Headerlines', 39);
    fclose(fileID);
    
    
    %% latency
    
    tmp = C{1}( find( ( strcmp( C{1}, 'MSG' ) ) ) - 1 );
    
    latency = NaN( length(tmp), 1);
    
    for TT = 1:length(tmp)
        
        if ~mod( str2num( tmp{TT} ), 1 )
            latency(TT,1) = str2num( tmp{TT} );
        end
        
    end
    
    
    %% type
    
    tmp = C{1}( find( ( strcmp( C{1}, 'MSG' ) ) ) + 4 );
    
    type = NaN( length(tmp), 1);
    
    for TT = 1:length(tmp)
        
        if ~mod( str2num( tmp{TT} ), 1 )
            type(TT,1) = str2num( tmp{TT} );
        end
        
    end
    
    % --- remove start and end triggers if necessary
    
    latency( ~ismember( type, event_codes ) ) = [];
    type( ~ismember( type, event_codes ) ) = [];
    
    % --- remove extraneous recording triggers (if necessary)
    if SESSION == 1
        latency( 1:3 ) = [];
        type( 1:3 ) = [];
    end
    
    
    %% trial triggers - joint action
    
    n.trials_block = 64;
    n.blocks = 15;
    
    trial_counter = [];
    
    for BLOCK = 1:n.blocks
        trial_counter = [ trial_counter; 0; ones(n.trials_block,1) ];
    end
    
    trial_counter(end+1) = 0;
    
    
    % ---- remove rests
    
    type = type( trial_counter == 1);
    latency = latency( trial_counter == 1);
     
    % ---- test plot
    
    h = figure('visible', is_figure_visible); hold on
    TIT = [fname.OUT '.recordedTriggers.png'];
    
    ax(1) = subplot(2,1,1);
    stem(latency - latency(1), type)
    
    ax(2) = subplot(2,1,2);
    plot( [NaN; diff(latency) ] )
    
    suptitle(TIT)
    saveas(h, [OUT TIT])
    

	%% reconstruct eye tracking latency

    TYPE_EYE = [];
    LATENCY_EYE = [];

    for TRIAL = 1:n.trials
        idx_trial = IDX_eye(TRIAL):IDX_eye(TRIAL)+4;
        TYPE_EYE = [TYPE_EYE; TYPE(idx_trial)];
        LATENCY_EYE = [LATENCY_EYE; IDX(idx_trial)+latency(TRIAL)- IDX(IDX_eye(TRIAL))];
    end

    
     %% plot reconstructed triggers

    h = figure('visible', is_figure_visible); hold on
    TIT = [fname.OUT '.reconstructedTriggers.png'];
    
    subplot(2,1,1)
    stem(LATENCY_EYE, TYPE_EYE);
    
    ax(1) = subplot(2,1,2);
    stem(latency, type);
    ax(2) = suptitle('recorded triggers');

    suptitle(TIT);
    linkaxes(ax, 'x')
    saveas(h, [OUT TIT])

    
    %% save output

    clear type latency
    
    type = TYPE_EYE;
    latency = LATENCY_EYE;

    
    %% test correspondence with behavioural file
        
    cond_test.behave = data(:,D.cond)+2;

    cond_test.eye = type;
    cond_test.eye = cond_test.eye(ismember(cond_test.eye,TRIG.task_cue));
    
    aligned = all(cond_test.behave == cond_test.eye);
    disp(aligned)

    
    %% save output
    latency_index = find([ 1; diff(TRIGGERS) ] > 0);
    
    save( [ OUT fname.OUT '.eyeData.mat' ], 'samples', 'type', 'latency', 'header', 'aligned', 'latency_index')
    
    
    
    %       Numeric Input Type   Specifier   Output Class
    %       ------------------   ---------   ------------
    %       Integer, signed        %d          int32
    %                              %d8         int8
    %                              %d16        int16
    %                              %d32        int32
    %                              %d64        int64
    %       Integer, unsigned      %u          uint32
    %                              %u8         uint8
    %                              %u16        uint16
    %                              %u32        uint32
    %                              %u64        uint64
    %       Floating-point number  %f          double
    %                              %f32        single
    %                              %f64        double
    %                              %n          double