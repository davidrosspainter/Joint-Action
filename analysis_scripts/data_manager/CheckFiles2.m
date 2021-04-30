close all; clear; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ext] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)


%% ----- settings

sessions2use = [2 3 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 21 22 23];

nPlayers = 2;
nSessions = 20;
nSubjects = nPlayers*nSessions;

fname.direct_behav = '..\..\data.exported\behave\';
fname.direct_dat = '..\..\data.exported\eeg\';

fname.direct_vhdr = '..\..\data.raw\eeg\';
fname.direct_idf = '..\..\data.raw\eye\';

fname.direct_eyeEvents = '..\..\data.exported\eye\events\';
fname.direct_eyeSamples = '..\..\data.exported\eye\samples\';


%% ----- check files

sessCount = 0;
fname.sessCount = cell(length(sessions2use),1);

for SESSION = sessions2use
    
    sessCount = sessCount + 1;
    
    fname.SESSION = SESSION;
    %fname.sessCount = sessCount;
    
    if SESSION < 10
        fname.str{sessCount,1} =  ['S0' num2str(SESSION)];
    else
        fname.str{sessCount,1} =  ['S' num2str(SESSION)];
    end
    
    if sessCount < 10
        fname.sessCount{sessCount,1} =  ['S0' num2str(sessCount)];
    else
        fname.sessCount{sessCount,1} =  ['S' num2str(sessCount)];
    end

    tmp = dir( [fname.direct_behav 'S' num2str(SESSION) '*test*.mat'] );
    
    if ~isempty(tmp)
        fname.behave{sessCount,1} = tmp.name;
    end
    
    
    %% directories && files
    
    for PLAYER = 1:nPlayers
    
        switch PLAYER
            case 1
                pstring = 'left';
            case 2
                pstring = 'right';
        end
        
        for FF = 1:5
            
            clear tmp fstring
            
            switch FF
                case 1
                     fstring = 'vhdr';
                     %tmp = dir( [fname.direct_vhdr '*' fname.str{sessCount,1} '*' pstring '*.' fstring ] );
   
                     tmp = dir( [fname.direct_vhdr '*' strrep( fname.str{sessCount,1}, 'S', '') '*' pstring '*.' fstring ] );
                     
                     if SESSION == 19 && PLAYER == 2
                         tmp = [];
                         tmp.name = 'JA_S19_2016-07-22_11-26-35-export.dat';
                     end
                     
                     
                     if SESSION == 13 && PLAYER == 2
                         TMP = [ tmp(1).name ' ' tmp(2).name ];
                         clear tmp
                         tmp.name = TMP;
                     end
                case 2
                     fstring = 'dat'; 
                    % tmp = dir( [fname.direct_dat '*' fname.str{sessCount,1} '*' pstring '*.' fstring ] );
                     tmp = dir( [fname.direct_dat '*' strrep( fname.str{sessCount,1}, 'S', '') '*' pstring '*.' fstring ] );
                     
                     if SESSION == 13 && PLAYER == 2
                         TMP = [ tmp(1).name ' ' tmp(2).name ];
                         clear tmp
                         tmp.name = TMP;
                     end
                     
                     if SESSION == 19 && PLAYER == 2
                         tmp = [];
                         tmp.name = 'JA_S19_2016-07-22_11-26-35-export.dat';
                     end
                case 3
                     fstring = 'idf';
                     tmp = dir( [fname.direct_idf '*' fname.str{sessCount,1} '*' pstring '*.' fstring ] );
                case 4
                    fstring = 'eyeEvents';
                    tmp = dir( [fname.direct_eyeEvents '*' fname.str{sessCount,1} '*' pstring '*Samples.txt' ] );
                case 5
                    fstring = 'eyeSamples';
                    tmp = dir( [fname.direct_eyeSamples '*' fname.str{sessCount,1} '*' pstring '*Samples.txt' ] );
            end
             
            if ~isempty(tmp)
                fname.( fstring ){sessCount,PLAYER} = tmp.name;
            end
            
        end    
    end
    
end

save( [ OUT 'fname.mat' ], 'fname', '-v6' )