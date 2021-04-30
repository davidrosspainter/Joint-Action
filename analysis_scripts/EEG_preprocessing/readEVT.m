function [TYPE, LATENCY] = readEVT( fname, fs )

%% load triggers

% disp('loading triggers')

evt = [];

fid = fopen( fname );
tline = fgetl(fid);
count = 0;

while ischar(tline)
    % disp(tline)
    
    tline = fgetl(fid);

    if ischar(tline)
        
        count = count + 1;
        
        if count > 2
            
%             if sum( ismember(tline, 'Impedance' ) ) == 9
%                 sdfsdf
%             end
            
            C = strsplit(tline, '\t');
            
            for CC = 1:size(C,2)
                
                if ~isempty( str2num( C{CC} ) )
                    evt(count-2,CC) = str2num( C{CC} );
                else
                    evt(count-2,CC) = NaN;
                end
            end
        end
    end
end

fclose(fid);

%% artifacts

% artifact_start = evt( evt(:,2) == 21, : );
% artifact_stop = evt( evt(:,2) == 22, : );
% nArtifacts = size( artifact_start, 1);
%
% artifact_start(:,1) = ( artifact_start(:,1) ./ 1000000);
% artifact_start(:,1) = round( artifact_start(:,1) .* fs );
%
% artifact_stop(:,1) = ( artifact_stop(:,1) ./ 1000000);
% artifact_stop(:,1) = round( artifact_stop(:,1) .* fs );
%
% artifact_datapoints = [];
%
% for AA = 1:nArtifacts
%     artifactDatapoints = [ artifact_datapoints; ( artifact_start(AA,1) : artifact_stop(AA,1) )' ];
% end


%% triggers

%triggers = evt( evt(:,2) == 1, : );

triggers = evt( ismember( evt(:,2), [1 2] ), : ); % -- retain impedences

TYPE = triggers(:,3);
TYPE( TYPE == 0 ) = NaN;
LATENCY = triggers(:,1);

%% IMPEDENCE!

% remove = TYPE == 0; % remove non-triggers
%
% TYPE(remove) = [];
% LATENCY(remove) = [];

%%

% - convert LATENCY to data point
LATENCY = (LATENCY ./ 1000000);
LATENCY = round( LATENCY .* fs );