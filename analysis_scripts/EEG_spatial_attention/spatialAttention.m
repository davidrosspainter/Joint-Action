function spatialAttention( SUB )


p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );

IN = 'check_alignment3\';

% ----- load EEG
subject_code_generation;
[~,~,STR] = subStringGen( SUB, subCode );

USE_THIS = [ IN STR.SUB '.EEG.mat' ];
disp( ['loading...' USE_THIS] )

tic
load( USE_THIS, 'EEG_RS', 'trig', 'estimatedAlignmentError', 'eyeLatency', 'SRATE_EEG' )
toc


%% ----- setup
basicSettings
fs = SRATE_EEG;
spatialAttentionSettings


%% ----- TYPE/LATENCY

% STR.cond = {'solo.17' 'solo.19' 'joint17' 'joint19' };
% n.cond = length(STR.cond);

TYPE = NaN(N.trials,1);

for CC = 1:n.cond
    switch CC
        case 1 % 'solo.17'
            IDX = (( trig.type(:,T.fix) == TRIG.fix(1) & trig.type(:,T.move_cue) == TRIG.move_cue(1) ) | ( trig.type(:,T.fix) == TRIG.fix(2) & trig.type(:,T.move_cue) == TRIG.move_cue(2) )) & trig.type(:,T.task_cue) == TRIG.task_cue(1);
        case 2 % 'solo.19'
            IDX = (( trig.type(:,T.fix) == TRIG.fix(1) & trig.type(:,T.move_cue) == TRIG.move_cue(2) ) | ( trig.type(:,T.fix) == TRIG.fix(2) & trig.type(:,T.move_cue) == TRIG.move_cue(1) )) & trig.type(:,T.task_cue) == TRIG.task_cue(1);
        case 3 % 'joint.17'
            IDX = (( trig.type(:,T.fix) == TRIG.fix(1) & trig.type(:,T.move_cue) == TRIG.move_cue(1) ) | ( trig.type(:,T.fix) == TRIG.fix(2) & trig.type(:,T.move_cue) == TRIG.move_cue(2) )) & trig.type(:,T.task_cue) == TRIG.task_cue(2);
        case 4 % 'joint.19'
            IDX = (( trig.type(:,T.fix) == TRIG.fix(1) & trig.type(:,T.move_cue) == TRIG.move_cue(2) ) | ( trig.type(:,T.fix) == TRIG.fix(2) & trig.type(:,T.move_cue) == TRIG.move_cue(1) )) & trig.type(:,T.task_cue) == TRIG.task_cue(2);
    end
   
    TYPE(IDX) = CC;
    
end

LATENCY = trig.latency(:,T.move_cue);

num.total = length(LATENCY);
num.missing = sum( isnan( LATENCY ) );
num.rejected = 0;

start = round( LATENCY + lim.x(1) );
stop = round( LATENCY + lim.x(2) );

epoch = NaN( n.x, N.channels, length(LATENCY), 'single' );

for E = 1:length(LATENCY)
    if ~isnan(start(E)) && ~isnan(stop(E))
        
        data2use = EEG_RS(start(E):stop(E),:);
        
        if ~any( range(data2use) > 100 )    
            data2use = detrend(data2use,'linear');
            data2use = data2use - repmat( data2use( t == 0,:), size(data2use,1), 1);
            epoch(:,:,E) = data2use;
        else
            num.rejected = num.rejected + 1;
        end
    end
end

ERP = NaN( n.x, N.channels, n.cond, 'single' );

for CC = 1:n.cond
   ERP(:,:,CC) = nanmean( epoch(:,:,TYPE == CC), 3);
end

tic
save( [ OUT STR.SUB '.epoch.mat' ], 'epoch', 'TYPE', 'ERP', 'num' );
toc