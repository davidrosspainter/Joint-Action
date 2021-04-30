function import_eye_data(SUBJECT)

    
p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = '..\data_manager\CheckFiles2\';
load( [IN 'fname.mat'] )

addpath('..\external\')
addpath('..\common\')

is_figure_visible = 'off';

if ismember(SUBJECT,[3 4]) % no eye data
    return
end

subject_code = generate_subject_code;
[SESSION,PLAYER,STR] = generate_subject_string(SUBJECT, subject_code);

header = {'Time', 'Type', 'Trial', 'L Mapped Diameter [mm]', 'R Mapped Diameter [mm]', 'L POR X [px]', 'L POR Y [px]', 'R POR X [px]', 'R POR Y [px]'};

STR.side = {'left' 'right'};

tmp = dir( [ fname.direct_eyeSamples fname.str{SESSION} '*' STR.side{PLAYER} '*.txt'] );
fname.samples = tmp.name;

tmp = dir( [ fname.direct_eyeEvents fname.str{SESSION} '*' STR.side{PLAYER} '*.txt'] );
fname.events = tmp.name;

disp( fname.samples )
disp( fname.events )


%% read events file

tic
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

event_codes = 1; % joint action
latency( ~ismember( type, event_codes ) ) = [];
type( ~ismember( type, event_codes ) ) = [];

% ---- test plot

h = figure('visible', is_figure_visible);

ax(1) = subplot(2,1,1);
stem(latency - latency(1), type)

ax(2) = subplot(2,1,2);
plot( [NaN; diff(latency) ] )

suptitle( STR.SUB )
saveas(h, [ OUT STR.SUB '.png' ] )


%% read samples

fileID = fopen( [ fname.direct_eyeSamples fname.samples ] );

C = textscan(fileID,'%u64 %s %u64 %f %f %f %f %f %f', 'Headerlines', 39);

fclose(fileID);

samples = NaN( length(C{1}), 8 );

for CC = [1 3:9]
    samples(:,CC) = C{CC};
end

disp(length(type))
disp(length(latency))

save( [ OUT STR.SUB '.eye.mat' ], 'samples', 'type', 'latency', 'header' )

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

