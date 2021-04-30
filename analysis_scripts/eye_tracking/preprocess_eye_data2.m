function preprocess_eye_data2(SESSION, PLAYER)
    
p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

str.player = {'P1', 'P2'};

output_filename = [generate_session_string(SESSION) '.' str.player{PLAYER}];
disp(output_filename)

figure_visibility = 'off';


%% ----- get data

fname.EYE = ['import_eyetracker_matlab3\\' generate_session_string(SESSION) '.' str.player{PLAYER} '.eyeData.mat'];
disp(fname.EYE)

tic
load([fname.EYE], 'samples', 'type', 'latency', 'header', 'aligned', 'latency_index')
toc

fs = 120;


%% ----- get eye positions

idx.x = [6 8];
idx.y = [7 9];

samples(samples == 0) = NaN; % raw data
GAZE = [nanmean(samples(:,idx.x),2) nanmean(samples(:,idx.y),2)]; % mean of left and right eyes
time = (samples(:,1) - samples(1,1))/1000000;

%         h1 = figure('visible', figure_visibility);
%         subplot(1,2,1); cla; hold on
%         title('Raw Data')
%         plot(GAZE(:,1))
%         plot(GAZE(:,2))
%         legend({'x', 'y'}, 'location', 'best')
%         xlabel('Samples')
%         ylabel('Pixels')


%% ----- delta time

h = figure('visible', figure_visibility); hold on

TIT = [ output_filename '.deltaTime' ];

hist(diff(time),1000)
xlabel('\DeltaTime (s)')
ylabel('Count')
title( TIT )
saveas(h, [ OUT TIT '.png'] )


%% ------ triggers

h = figure('visible', figure_visibility); hold on

TIT = [ output_filename '.triggers' ];

stem(latency, type)
xlabel('\deltaTime (s)')
ylabel('Count')
title( TIT )
saveas(h, [ OUT TIT '.png'] )


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

TIT = [ output_filename '.blinkremoval' ];
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

TIT = [ output_filename '.partialblinkremoval' ];
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

TIT = [ output_filename '.processed.eye'  ];
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

TIT = [ output_filename '.cleaned'  ];
suptitle( TIT )

saveas(h, [ OUT TIT '.png' ] )


%% ---- output data

save( [ OUT output_filename '.processedEye.mat' ], 'samples', 'type', 'latency', 'header', 'aligned', 'latency_index', 'GAZE', 'PUPIL', 'type', 'latency', '-v6')