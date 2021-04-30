clear; clc; close all; restoredefaultpath

addpath('..\external\')
addpath('..\common\')

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = 'import_eyetracker_matlab2\';
load '..\data_manager\CheckFiles2\fname.mat'

generate_global_variables


%% settings

figure_visibility = 'off';
is_load_fresh = true;

sessions_to_use = [6 7 8 9 10 11 12 13 14 15 16 17 18 19 21 22 23]; % exclude 2 3 5

str.player = {'P1', 'P2'};

TRIG.fix = [1 2]; % Hz combo 1, 2
TRIG.task_cue = [3 4]; % solo, co-op
TRIG.move_cue = [5 6]; % left/right
TRIG.feedback = 7; % feedback onset

fs = 120;
dpp = (53.2/1920);

% Time	Type	Trial	L Mapped Diameter [mm]	R Mapped Diameter [mm]	L POR X [px]	L POR Y [px]	R POR X [px]	R POR Y [px]	Aux1


%% run analysis

if is_load_fresh
    
    for SESSION = sessions_to_use
        
        close all
        
        SESSION_COUNT = strfndw(fname.behave, ['S' num2str(SESSION) ' test*']);
        disp(['IDX = ' num2str(SESSION_COUNT)])
        disp(fname.behave{SESSION_COUNT})
        
        for PLAYER = 1:number_of_players
            
            %% ----- get data
            
            fname.EYE = ['S' num2str(SESSION) '.' str.player{PLAYER} '.eyeData.mat'];
            disp(fname.EYE)
            
            tic
            load([IN fname.EYE], 'samples', 'type', 'latency', 'header' )
            toc
            
            asdfasdf
            
            %% ----- get eye positions
            
            idx.x = [6 8];
            idx.y = [7 9];
            
            samples(samples == 0) = NaN; % raw data
            GAZE = [nanmean(samples(:,idx.x),2) nanmean(samples(:,idx.y),2)]; % mean of left and right eyes
            time = samples(:,1);
            
            %         h1 = figure('visible', figure_visibility);
            %         subplot(1,2,1); cla; hold on
            %         title('Raw Data')
            %         plot(GAZE(:,1))
            %         plot(GAZE(:,2))
            %         legend({'x', 'y'}, 'location', 'best')
            %         xlabel('Samples')
            %         ylabel('Pixels')
            
            
            %% ------ EYETRACKER PREPROCESSING
            
            % http://www.ncbi.nlm.nih.gov/pmc/articles/PMC2572936/
            
            % We identified and removed blink periods as the portions of the EyeLink II recorded data where the pupil information was missing.
            % We further added 200 ms before and after each period to also eliminate the initial and final parts of the blink, where the pupil is partially occluded.
            % We moreover removed those portions of the data corresponding to very fast decreases and increases in pupil area (>20 units per sample) plus the 200 ms before and after.
            % Such periods are probably due to partial blinks, where the pupil is never fully occluded (thus failing to be identified as a blink by EyeLink II) (33)
            
            % 33. Troncoso XG, Macknik SL, Martinez-Conde S. Microsaccades counteract perceptual filling-in. J Vision. 2008 in press.
            
            % We further added 200 ms before and after each period to also eliminate the initial and final parts of the blink, where the pupil is partially occluded.
            
            
            PUPIL = nanmean(samples(:,4:5),2);
            PUPIL( PUPIL == 0 ) = NaN;
            
            
            %% remove blinks
            
            f.remove = 0.2*fs;
            
            tmp = GAZE;
            tmp2 = GAZE;
            
            blinks = all( isnan(tmp), 2);
            blinks_IDX = find(blinks);
            blinks_IDX2 = NaN( length( blinks_IDX ), f.remove*2 + 1);
            
            for BB = 1 : length( blinks_IDX )
                blinks_IDX2( BB, : ) = blinks_IDX(BB) - f.remove : blinks_IDX(BB) + f.remove;
            end
            
            blinks_IDX2 = unique( blinks_IDX2 );
            blinks_IDX2( blinks_IDX2 < 0  ) = [];
            blinks_IDX2( blinks_IDX2 > length(tmp) ) = [];
            
            blinks2 = ismember( (1 : length(tmp) )', blinks_IDX2 );
            
            tmp2( blinks2, : ) = NaN;
            tmp3 = tmp2; % save for velocity removal
            
            PUPIL( blinks2 ) = NaN;
            
            TIT = [ STR.session{SESSION_COUNT} '.' str.player{PLAYER} '.blinkremoval' ];
            
            h = figure('visible', figure_visibility); hold on
            
            ax(1) = subplot(3,1,1); hold on
            plot( tmp(:,1), 'r' )
            plot( tmp(:,2), 'g' )
            
            legend( {'x' 'y'}, 'location', 'northeast' )
            
            plot( blinks*400, 'k' )
            plot( blinks2*500, 'm' )
            
            ax(2) = subplot(3,1,2); hold on
            plot( tmp2(:,1), 'r' )
            plot( tmp2(:,2), 'g' )
            
            ax(3) = subplot(3,1,3);
            plot( diff(PUPIL) )
            
            linkaxes(ax,'x')
            
            suptitle( TIT )
            saveas(h, [ OUT TIT '.png'] )
            
            
            %% remove partial blinks
            % 500 samples per second > 20 units per sample (units = pixels?)
            % cutoff = ( 500/120 ) * 50; % scale for sampling rate - original reference (33) - > 50 units per sample
            
            tmppartial = PUPIL;
            vel = [ NaN ; abs(diff(PUPIL)) ];
            
            cutoff = prctile( vel(:), 99.99 );
            
            Pblinks = vel>cutoff;
            blinks_IDX = find(Pblinks);
            blinks_IDX2 = NaN( length( blinks_IDX ), f.remove*2 + 1);
            
            for BB = 1 : length( blinks_IDX )
                blinks_IDX2( BB, : ) = blinks_IDX(BB) - f.remove : blinks_IDX(BB) + f.remove;
            end
            
            blinks_IDX2 = unique( blinks_IDX2 );
            blinks_IDX2( blinks_IDX2 < 0  ) = [];
            blinks_IDX2( blinks_IDX2 > length( tmppartial) ) = [];
            
            Pblinks2 = ismember( (1 : length( tmppartial) )', blinks_IDX2 );
            
            tmppartial(Pblinks2,:)=NaN;
            
            idx_remove = isnan(tmppartial);
            tmp3(idx_remove,:) = NaN;
            
            GAZE = tmp3;
            
            h = figure('visible', figure_visibility); hold on
            
            ax2(1) = subplot(2,1,1); hold on
            plot(Pblinks+nanmean(PUPIL),'k')
            plot(Pblinks2+nanmean(PUPIL),'m')
            plot(PUPIL, 'b')
            title('pupil ÿ')
            legend({'partial blinks' 'P blink removal' 'pupil diameter'}, 'location', 'SouthEast')
            
            ax2(2) = subplot(2,1,2); hold on
            plot(blinks*0.7, 'y')
            plot(vel, 'g')
            line( get(gca,'xlim'), [ cutoff cutoff ] , get(gca,'ylim'), 'color', 'k' )
            legend({'blinks' 'change in pupil ÿ' '99.9th %tile'})
            
            title('dÿ/dt')
            
            linkaxes(ax2,'x')
            
            TIT = [ STR.session{SESSION_COUNT} '.' str.player{PLAYER} '.partialblinkremoval' ];
            suptitle( TIT )
            saveas(h, [ OUT TIT '.png'] )
            
            
            %% processed.eye.
            
            h = figure('visible', figure_visibility); hold on
            
            ax(1) = subplot(2,1,1); hold on
            plot( GAZE(:,1), 'b')
            plot( GAZE(:,2), 'g')
            ylim( 1024/2 * [-1 +1] )
            legend( {'x' 'y'} )
            ylabel( 'pixels' )
            
            ax(3) = subplot(2,1,2); hold on
            plot( blinks, 'y' )
            plot(  Pblinks2*.5, 'k' )
            legend( {'blinks' 'pblinks' } )
            ylabel( 'blink logical' )
            
            xlabel( 'time' )
            linkaxes(ax,'x')
            
            TIT = [ STR.session{SESSION_COUNT} '.' str.player{PLAYER} '.processed.eye'  ];
            suptitle( TIT )
            
            saveas(h, [ OUT TIT '.png' ] )
            
            
            %% --- cleaned data
            
            h = figure;
            ax(1) = subplot(2,2,1);
            plot( [nanmean(samples(:,idx.x),2) nanmean(samples(:,idx.y),2)] )
            ax(2) = subplot(2,2,2);
            plot(  nanmean(samples(:,4:5),2) )
            ax(3) = subplot(2,2,3);
            plot( GAZE )
            ax(4) = subplot(2,2,4);
            plot( PUPIL )
            
            linkaxes(ax, 'x')
            
            TIT = [ STR.session{SESSION_COUNT} '.' str.player{PLAYER} '.cleaned'  ];
            suptitle( TIT )
            
            saveas(h, [ OUT TIT '.png' ] )
            
            
            %% ---- output data
            
            save( [ OUT STR.session{SESSION_COUNT} '.' str.player{PLAYER} '.processedEye.mat' ], 'samples', 'GAZE', 'PUPIL', 'type', 'latency', 'header', '-v6' )
            

            
                 
        end
    end
end








