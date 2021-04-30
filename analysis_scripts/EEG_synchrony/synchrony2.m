function synchrony2(SUBJECT, SRATE_EEG)

% ----- epochs trial data with adjustment
    
addpath('..\common\')
    
p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );
    
IN = ['..\EEG_preprocessing\check_alignment3\SRATE_EEG_' num2str(SRATE_EEG) '\'];


%% ----- LOAD EEG

subject_code = generate_subject_code;
[SESSION, PLAYER, STR] = generate_subject_string(SUBJECT, subject_code);

USE_THIS = [IN STR.SUBJECT '.EEG.mat'];
disp( ['loading...' USE_THIS] )

tic
load( USE_THIS, 'EEG_RS', 'trig', 'estimatedAlignmentError', 'eyeLatency', 'SRATE_EEG' ) % EEG resampled
toc


%% ----- SETTINGS

generate_global_variables
synchrony_settings


%% ----- TYPE/LATENCY

TYPE = trig.type(:,T.task_cue);
LATENCY = trig.latency(:,T.move_cue);


%% ----- adjust latency ...

load( [ fname.direct_behav fname.behave{SESSION} ], 'data', 'D' )

for CC = 1:n.cond
    
    IDX = data(:,D.cond) == CC;
    
    switch CC
        case 1
            latencyOffset = ( data( :, D.RT(PLAYER) ) + data(:, D.MT(PLAYER) ) ) ./ 1000*SRATE_EEG;
        case 2
            latencyOffset = ( data( :, D.RT(3) ) + data(:, D.MT(3) ) ) ./ 1000*SRATE_EEG;
    end
    
    LATENCY(IDX) = LATENCY(IDX) + latencyOffset(IDX);
    
end


%% ----- epoch

num.total = length(LATENCY);
num.missing = sum( isnan( LATENCY ) );

start = round( LATENCY + lim.x(1) );
stop = round( LATENCY + lim.x(2) );

epoch = NaN( n.x, number_of_channels, length(LATENCY), 'single' );

for E = 1:length(LATENCY)
    if ~isnan(start(E)) && ~isnan(stop(E)) && start(E) > 0 && stop(E) < size(EEG_RS,1)

        data2use = EEG_RS(start(E):stop(E),:);
        data2use = detrend(data2use,'linear');
        data2use = data2use - repmat( data2use( t == 0,:), size(data2use,1), 1);
        epoch(:,:,E) = data2use;

    end
end

mean_epoch = mean( epoch, 3);

tic
save( [ OUT STR.SUBJECT '.epoch.' num2str(SRATE_EEG) '.mat' ], 'epoch', 'TYPE', 'mean_epoch' );
toc