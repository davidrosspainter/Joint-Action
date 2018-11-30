input('press enter')

reset(RandStream.getGlobalStream,sum(100*clock))
seed_state = rng;

close all
clear
clc

%           (                      )
%           |\    _,--------._    / |
%           | `.,'            `. /  |
%           `  '              ,-'   '
%            \/_         _   (     /
%           (,-.`.    ,',-.`. `__,'
%            |/#\ ),-','#\`= ,'.` |
%            `._/)  -'.\_,'   ) ))|
%            /  (_.)\     .   -'//
%           (  /\____/\    ) )`'\
%            \ |V----V||  ' ,    \
%             |`- -- -'   ,'   \  \      _____
%      ___    |         .'    \ \  `._,-'     `-
%         `.__,`---^---'       \ ` -'
%            -.______  \ . /  ______,-
%                    `.     ,'


%% observer

observer.number = 23;
observer.name = [ 'S' num2str(observer.number) ];

options.practice = 0; % 0 = test, 1 = practice

if mod(observer.number,2) % odd = solo red, coop green; even = solo green, coop red
    options.color_combo = 1; % odd sessions
else
    options.color_combo = 2; % even sessions
end

str.color_combo = {'solo red, coop green' 'solo green, coop red'};
str.practice = {'test' 'practice'};

observer.date = date;
observer.start_clock = clock;
observer.fname = [ observer.name ' ' str.practice{options.practice+1} ' ' observer.date ' ' num2str(observer.start_clock(4)) '-' num2str(observer.start_clock(5)) '-' num2str(observer.start_clock(6)) '.mat' ];


%% directories

direct.stim = [ cd '\stim\'];
direct.data = [ cd '\data\' ];


%% diary

diary( [ direct.data observer.fname '.txt' ] )

observer


%% monitor

% ############# USE CONFIG 3 in premium mosiac mode

mon.num = 1;
mon.config = 3;

switch mon.config
    case 1
        mon.res = [2560/2 1440];
        mon.ref = 144;
    case 2
        mon.res = [1920 1080];
        mon.ref = 60;
    case 3 % ############# USE CONFIG 3 in premium mosiac mode
        mon.res = [3840 1080];
        mon.ref = 144;
    case 4
        mon.res = [1920 1080];
        mon.ref = 144;
    case 5
        mon.res = [3840 1080];
        mon.ref = 60;
    case 6
        mon.res = [2560 1440];
        mon.ref = 144;
    case 7
        mon.res = [1920 1080/2];
        mon.ref = 60;
    case 8
        mon.res = [3840 1080];
        mon.ref = 60;
end

mon.xcenter = [ -mon.res(1)/4 +mon.res(1)/4 ];
mon.mm = [527 296];

color.background = [0 0 0];

% ----- equiluminant colors

color.red = [255 0 0] ./255;
color.green = [0 165 0] ./255;

switch options.color_combo
    case 1
        color.solo = color.red;
        color.coop = color.green;
    case 2
        color.coop = color.green;
        color.solo = color.red;
end


%% options

options.controllers = 1;
options.rest = 1;

options.parallel_triggers = 1;

if options.practice == 1
    options.serial_triggers = 0;
else
    options.serial_triggers = 1;
end

options.preview_stim = 0;
options.plot = 0;

options.test_frames = 0;


%% ports

port.com = {'COM7' 'COM8'};
str.com = { 'eyetracker1' 'eyetracker2' };

port.parallel = 'D050'; % ----- EEG CHANNELS (port D030)
str.parallel = 'eeg';
    
if options.parallel_triggers
    
    % ----- parallel
    
    parallel.io.obj = io64; % eeg trigger create an instance of the io64 object
    parallel.status = io64( parallel.io.obj ); % eeg trigger initialise the inpout64.dll system driver
    
    parallel.io.address = hex2dec( port.parallel ); % physical address of the destinatio I/O port; 378 is standard LPT1 output port address
    io64( parallel.io.obj, parallel.io.address, 0 ); % set the trigger port to 0 - i.e. no trigger
    
end

if options.serial_triggers
    
    % ----- serial
    
    clear s1
    delete(instrfindall)
    
    s1 = serial( port.com{1} );
    s2 = serial( port.com{2} );
    
    tic; fopen(s1); toc
    tic; fopen(s2); toc
    
end
    

%% condition information

n.mon = 2;
n.player = 2;
n.cond = 2;
n.Hz_combo = 2;

str.cond = {'solo' 'co-op'};
str.location = {'left' 'right'};
str.Hz_combo = { '17 left, 19 right' '19 left, 17 right' };
str.player = {'P1' 'P2'};


%% array

n.locations = 8;

array.t = linspace( 0, 2*pi - 2*pi/n.locations, n.locations ) + 2*pi/n.locations/2;
array.t_deg = rad2deg(array.t);

array.r = ones(1,n.locations)*300*(100/83)*(100/99)*(8/10);

[array.x, array.y] = pol2cart(array.t, array.r);

if options.plot
    
    h = figure;
    scatter(array.x, array.y)
    axis equal
    
    for PP = 1:n.locations
        text( array.x(PP), array.y(PP), num2str(PP) )
    end
    
end

n.locations = 2; % left or right hemifield
n.positions = 8; % actual positions

n.position_combo = 4;

% 1 - 22.5000
% 2 - 67.5000
% 3 - 112.5000
% 4 - 157.5000
% 5 - 202.5000
% 6 - 247.5000
% 7 - 292.5000
% 8 - 337.5000

% left, right

LOC_CODE = [3 7 % - uppermost left, lowermost right
    4 8 % - upper left, lower right
    5 1 % - lower left, upper right
    6 2]; % lowermost left, uppermost right

% for POSC = 1:n.position_combo
%     str.position{ POSC } = [ 'left ' num2str(array.t_deg(LOC_CODE(POSC,1))) ', right ' num2str(array.t_deg(LOC_CODE(POSC,2))) ];
% end

str.position = {'uppermost left, lowermost right'
    'upper left, lower right'
    'lower left, upper right'
    'lowermost left, uppermost right' };


%% cursor settings

n.cursors = 2;

cursor.speed = ( 5*144/mon.ref ) * 1.5;
cursor.sensitivity = 0.1; % physics 2


%% trial settings

if options.practice == false
    n.blocks = 15;
    n.trials_block = 64;
else
    n.blocks = 1;
    n.trials_block = 32;
end


%% timing

fs = mon.ref;

s.rest_block = 20;

% ----- animation periods

s.rest_trial = 1.0;
s.fix = .5763889;
s.task_cue = 2.0 - s.fix;

s.move_cue = [0.5 1.0];

s.movement = 2.5; % flicker period after movement cue

s.feedback = 0.5;
s.flicker = s.fix + s.task_cue + max(s.move_cue) + s.movement;

% ----- performance cutoffs

s.RT_min = 0.2;
s.RT_max = 0.8; % reaction

s.MT_max = 1.5; % move
s.HT = 0.2; % hold

s.trial_max = s.rest_trial + s.fix + s.task_cue + max(s.move_cue) + s.movement + s.feedback;
s.trial_min = s.rest_trial + s.fix + s.task_cue + min(s.move_cue) + s.movement + s.feedback;

FIELDS = fieldnames(s);

for FF = 1:length(FIELDS)
    
    if length( s.( FIELDS {FF} ) ) == 1
        f.( FIELDS {FF} ) = round( s.( FIELDS {FF} ) * fs );
    elseif length( s.( FIELDS {FF} ) ) == 2
        f.( FIELDS {FF} ) = round( s.( FIELDS {FF} ) .* fs );
        f.( FIELDS {FF} ) = round(linspace(f.( FIELDS {FF} )(1), f.( FIELDS {FF} )(2), n.trials_block));
    end
    
end

f.rest = f.rest_trial;


%% block settings

n.trials = n.blocks * n.trials_block;

D.block = 1;
D.trial = 2;
D.trial_block = 3;
D.cond = 4;
D.location = 5;
D.Hz_combo = 6;

D.rest_frames = 7;
D.fix_frame = 8;
D.task_cue_frame = 9;
D.move_cue_frame = 10;
D.feedback_frame = 11;
D.breaking_frame = 12;

D.RT_lower_frame = 13;
D.RT_upper_frame = 14;
D.MT_upper_frames = 15:17;

D.RT = 18:20;
D.MT = 21:23;
D.HT = 24:26;

D.react_frame = 27:29;
D.inside_frame = 30:32;

D.RT_fast = 33:35;
D.RT_slow = 36:38;
D.MT_slow = 39:41;
D.leaving = 42:44;
D.leaving_frame = 45:47;

D.correct = 48:50;

D.position_combo = 51; % 1 - 4
D.pre_move_cue_frames = 52;

DFIELDS = fieldnames(D);

data = NaN( n.trials, D.pre_move_cue_frames );

for BLOCK = 1:n.blocks
    
    block = NaN( n.trials_block, max(D.correct) );
    
    block(:,D.cond) = sort( repmat( (1:n.cond)', n.trials_block/n.cond, 1 ) );
    block(:,D.location) = repmat( sort( repmat( (1:n.locations)', n.trials_block/n.cond/2, 1) ), n.cond, 1);
    block(:,D.Hz_combo) = repmat( sort( repmat( (1:n.Hz_combo)', n.trials_block/n.cond/2/2, 1) ), n.cond*2, 1);
    
    if options.practice
        block(:,D.position_combo) = repmat( [1 2 3 4]', n.trials_block/4, 1);
    else
        block(:,D.position_combo) = repmat( [1 1 2 2 3 3 4 4]', n.trials_block/8, 1);
    end
    
    block(:,D.block) = BLOCK;
    block = block( randperm(n.trials_block), : );
    block(:,D.trial_block) = 1:n.trials_block;
    
    % ----- frames
    
    block(:,D.pre_move_cue_frames) = f.move_cue( randperm( n.trials_block ) );
    
    block(:,D.rest_frames)    = f.rest;
    block(:,D.fix_frame)      = 1 + f.rest;
    block(:,D.task_cue_frame) = 1 + f.rest + f.fix;
    block(:,D.move_cue_frame) = 1 + f.rest + f.fix + f.task_cue + block(:,D.pre_move_cue_frames);
    block(:,D.feedback_frame) = 1 + f.rest + f.fix + f.task_cue + block(:,D.pre_move_cue_frames) + f.movement;
    block(:,D.breaking_frame) = 1 + f.rest + f.fix + f.task_cue + block(:,D.pre_move_cue_frames) + f.movement + f.feedback;
    block(:,D.RT_lower_frame) = 1 + f.rest + f.fix + f.task_cue + block(:,D.pre_move_cue_frames) + f.RT_min;
    block(:,D.RT_upper_frame) = 1 + f.rest + f.fix + f.task_cue + block(:,D.pre_move_cue_frames) + f.RT_max;
    
    data( ( 1 : n.trials_block ) + (BLOCK-1)*n.trials_block, : ) = block;
    
    clear block
    
end

data(:,D.trial) = 1:n.trials;


%% animation gen

TRIG.fix = [1 2]; % Hz combo 1, 2
TRIG.task_cue = [3 4]; % solo, co-op
TRIG.move_cue = [5 6]; % left/right
TRIG.feedback = 7; % feedback onset
TRIG.rest_trial = 8;
TRIG.rest_block = 255;


A.rest = 1;
A.neutral_cue_cursor = 2;
A.task_cue = 3;
A.task_cursor = 4;
A.targets = 5;
A.move_cue = 6;
A.feedback = 7;
A.trigger = 8;

A.FIELDS = fieldnames(A);

ANIMATE = zeros( f.trial_max, A.trigger, n.trials );

for TRIAL = 1:n.trials
    
    if options.plot
        close all
        figure; hold on
    end
    
    for AA = 1:7
        
        switch AA
            case A.rest
                IDX = 1                                                                                 : f.rest;
            case A.neutral_cue_cursor
                IDX = 1 + f.rest                                                                        : f.rest + f.fix;
            case A.task_cue
                IDX = 1 + f.rest + f.fix                                                                : f.rest + f.fix + f.task_cue;
            case A.task_cursor
                IDX = 1 + f.rest + f.fix                                                                : f.rest + f.fix + f.task_cue + data(TRIAL,D.pre_move_cue_frames) + f.movement;
            case A.targets
                IDX = 1 + f.rest                                                                        : f.rest + f.fix + f.task_cue + data(TRIAL,D.pre_move_cue_frames) + f.movement;
            case A.move_cue
                IDX = 1 + f.rest + f.fix + f.task_cue + data(TRIAL,D.pre_move_cue_frames)               : f.rest + f.fix + f.task_cue + data(TRIAL,D.pre_move_cue_frames) + f.movement;
            case A.feedback
                IDX = 1 + f.rest + f.fix + f.task_cue + data(TRIAL,D.pre_move_cue_frames) + f.movement	: f.rest + f.fix + f.task_cue + data(TRIAL,D.pre_move_cue_frames) + f.movement + f.feedback;
        end

        ANIMATE( IDX, AA, TRIAL ) = true;
        
    end
    
    if options.plot
        
        ax(1) = subplot(3,1,1);
        plot( ANIMATE( :, :, TRIAL ) .* repmat( 1:size(ANIMATE,2), size(ANIMATE,1), 1) )
        legend( A.FIELDS, 'location', 'northwest' )
        
        ax(2) = subplot(3,1,2);
        
        for DD = 7:14
            line( [data(TRIAL,DD) data(TRIAL,DD) ], [0. .5], 'color', 'r' )
            text( data(TRIAL,DD), .05*(DD-7), DFIELDS{DD}, 'interpreter', 'none' )
        end
        
    end
    
    
    %% triggers
    
    for FRAME = 1 : f.trial_max
        
        switch FRAME
            case 1
                ANIMATE( FRAME : FRAME + 3, A.trigger, TRIAL ) = TRIG.rest_trial;
                
            case data(TRIAL,D.fix_frame)
                ANIMATE( FRAME : FRAME + 3, A.trigger, TRIAL ) = TRIG.fix( data(TRIAL,D.Hz_combo) );
                
            case data(TRIAL,D.task_cue_frame)
                ANIMATE( FRAME : FRAME + 3, A.trigger, TRIAL ) = TRIG.task_cue( data(TRIAL,D.cond) );
                
            case data(TRIAL,D.move_cue_frame)
                ANIMATE( FRAME : FRAME + 3, A.trigger, TRIAL ) = TRIG.move_cue( data(TRIAL,D.location) );
                
            case data(TRIAL,D.feedback_frame)
                ANIMATE( FRAME : FRAME + 3, A.trigger, TRIAL ) = TRIG.feedback;
        end
        
    end
    
    if options.plot
        
        ax(3) = subplot(3,1,3); hold on
        plot( ANIMATE( :, A.trigger, TRIAL ) )
        
        linkaxes(ax,'x')
        xlim( [0 f.trial_max] )
        
    end
    
end

triggers = squeeze( ANIMATE(:,A.trigger,:) );
TRIGGERS = ( triggers ~= 0 ) * 255; % for splitter cable

DTRIGGERS = [ ones(1,n.trials); diff(triggers) ] > 0; % for alignment with EEG file
trigger_onset = triggers .* DTRIGGERS;


%% rest triggers

btriggers = zeros(f.rest_block, 1);
btriggers( 1:3 ) = TRIG.rest_block;


%% flicker generation

Hz.intended = [17 19 7];

n.Hz = length( Hz.intended );

for H = 1:n.Hz
    s.Hz(H) = 1000/Hz.intended(H)/1000;
    f.Hz(H) = round( s.Hz(H) * mon.ref );
    Hz.actual(H) = mon.ref/f.Hz(H);
    f.flick{H} = 1 : f.Hz(H) : f.trial_max;
    f.Hz_exact(H) = s.Hz(H) * mon.ref;
end


%% ----- counterphase flicker (arbitrary method)

% http://bmcneurosci.biomedcentral.com/articles/10.1186/s12868-015-0234-7

counterphase = NaN( f.trial_max, n.Hz );

for H = 1 : n.Hz
    
    % starting...
    
    n.flips = ceil( f.trial_max/f.Hz_exact(H) ) + 1;
    flip_frames = ( ( 1 : n.flips ) .* f.Hz_exact(H) )';
    
    state = NaN( f.trial_max*2, 1 );
    INTENSITY = 0;
    CURRENT_FRAME = 1;
    
    for FLIP = 1:n.flips
        
        switch INTENSITY
            case 0
                INTENSITY = 1;
            case 1
                INTENSITY = 0;
        end
        
        state( CURRENT_FRAME : floor( flip_frames(FLIP) ) ) = INTENSITY;
        
        switch INTENSITY
            case 0
                state( floor( flip_frames(FLIP) + 1 ) ) = 1 - rem( flip_frames(FLIP), floor( flip_frames(FLIP) ) );
            case 1
                state( floor( flip_frames(FLIP) + 1 ) ) = rem( flip_frames(FLIP), floor( flip_frames(FLIP) ) );
        end
        
        CURRENT_FRAME = floor( flip_frames(FLIP) + 1 ) + 1;
        
    end
    
    % close all
    % plot(state)
    
    counterphase( 1 : f.trial_max, H ) = state( 1 : f.trial_max );
    
end

figure
line( 1:f.trial_max, counterphase(:,3), 'Color', 'r')


%% individualised flicker start points (aligns peripheral flicker phase to movement cue)

frame_counter = [ -max(f.move_cue) : 0 1 : f.trial_max - max(f.move_cue)-1 ];
flicker_start = NaN(n.trials,1);

for TRIAL = 1:n.trials
    flicker_start(TRIAL,1) = find( frame_counter == -data(TRIAL,D.pre_move_cue_frames) );
end


%% pre-allocate

COMBO = [1 2; 2 1];

cursor.inc = NaN(2, f.trial_max, n.trials, n.cursors+1 );
cursor.xy = NaN(2, f.trial_max, n.trials, n.cursors+1 );
cursor.thumb = NaN(2, f.trial_max, n.trials, n.cursors );
ICD = NaN(f.trial_max,n.trials);

fliptime.trial = NaN(f.trial_max, n.trials);
fliptime.rest_block = NaN(f.rest_block, n.blocks+1);


%% controllers

direct.controllers = [ cd '\MATLAB_Joystick_control-master\' ];
addpath( direct.controllers )

controllerLibrary = NET.addAssembly( [ direct.controllers 'SharpDX.XInput.dll' ] );

myController1 = SharpDX.XInput.Controller(SharpDX.XInput.UserIndex.One);
myController2 = SharpDX.XInput.Controller(SharpDX.XInput.UserIndex.Two);

VibrationLevel = SharpDX.XInput.Vibration; % initialise vibration
controller.stick_max = 32768;
controller.vibrate_max = 65025;

myController1
myController2


%% start cogent

cgopen( mon.res(1), mon.res(2), 0, mon.ref, mon.num)

cgfont('Lucida Console', 40 * ( mon.res(2) / 1024 ) *2/3 )
cgpencol(1,1,1)

cgflip( color.background)
cgflip( color.background)


%% stimulus sizes & critical distance

sizes.target = 50*20/13;
sizes.cursor = 15;

sizes.task_cue = 292.0774*(5/8);
sizes.move_cue = 20;

target.critical_distance = sizes.target/2 - sizes.cursor/2;


%% target ( 1 )

spritenum.target = 1;

cgloadbmp(spritenum.target, [ direct.stim 'target.bmp' ] )
cgtrncol(spritenum.target, 'w' )


%% cursors ( 6 : 8 )

spritenum.cursor_w = 6;
spritenum.cursor_g = 7;
spritenum.cursor_r = 8;


switch options.color_combo
    case 1
        
        bmp = {
            'cursor_white.bmp'
            'cursor_green.bmp'
            'cursor_red.bmp'};
        
    case 2
        
        bmp = {
            'cursor_white.bmp'
            'cursor_red.bmp'
            'cursor_green.bmp'};
        
end

count = 0;

for CC = spritenum.cursor_w : spritenum.cursor_r
    
    count = count + 1;
    cgloadbmp(CC, [ direct.stim bmp{ count } ] )
    cgtrncol(CC, 'n' )
    
    cgsetsprite(0)
    
    if options.preview_stim
        
        disp('**********')
        disp( CC )
        
        cgdrawsprite(  CC, 0, 0, sizes.task_cue, sizes.task_cue )
        cgflip( color.background )
        pause(1)
    end
    
    
end


%% phase-scrambled checkerboards ( 1001 : 1008 )

% column indices rather than sprite numbers

spritenum.target1 = 1;
spritenum.target2 = 2;

spritenum.taskcue_w = 3;
spritenum.taskcue_r = 4;
spritenum.taskcue_g = 5;


switch options.color_combo
    case 1
        
        bmp = {
            'target1.bmp'
            'target2.bmp'
            
            'task_cue_white1.bmp'
            'task_cue_red1.bmp'
            'task_cue_green1.bmp'
            
            'task_cue_white2.bmp'
            'task_cue_red2.bmp'
            'task_cue_green2.bmp'};
        
    case 2
        
        bmp = {
            'target1.bmp'
            'target2.bmp'
            
            'task_cue_white1.bmp'
            'task_cue_green1.bmp'
            'task_cue_red1.bmp'
            
            'task_cue_white2.bmp'
            'task_cue_green2.bmp'
            'task_cue_red2.bmp'};
        
end

for SPRITE = 1 : length(bmp)
    
    disp(SPRITE)
    
    im = imread( [ direct.stim bmp{ SPRITE } ] );
    [stim.w, stim.h, ~] = size(im);
    
    cgloadbmp( SPRITE + 1000, [ direct.stim bmp{ SPRITE } ] )
    cgtrncol(  SPRITE + 1000, 'n' )
    cgsetsprite(0)
    
    if options.preview_stim
        
        disp('**********')
        disp(  SPRITE + 1000 )
        
        cgdrawsprite(  SPRITE + 1000, 0, 0 )
        cgflip( color.background )
        pause(1)
    end
    
end


%% phase scrambled checkerboards - merged intensities ( 1009 : 1044 )

LUT.checkerboard = [];

count = 0;
merged = unique( counterphase(:,1:2) ); % frequencies for checkerboards
merged = unique( round( merged * 255 ) ) ./ 255;

for POS = 1
    
    im1 = imread( [ direct.stim bmp{ POS } ] );
    im1 = double( im1(:,:,1) ) ./ 255; im1 = fliplr(im1); im1 = imrotate(im1,90);
    
    im2 = imread( [ direct.stim bmp{ POS + 1 } ] );
    im2 = double( im2(:,:,1) ) ./ 255; im2 = fliplr(im2); im2 = imrotate(im2,90);
    
    for MM = 1:length(merged)
        
        count = count + 1;
        
        LUT.checkerboard(count,:) = [POS merged(MM) merged(MM)*255 count + 1008 NaN ];
        
        % disp( LUT.checkerboard(count,:) )
        
        im3 = im1 .* merged(MM) + im2 .* (1 - merged(MM) );
        
        cgloadarray( count + 1008, stim.w, stim.h, [ im3(:) im3(:) im3(:) ], stim.w, stim.h )
        cgtrncol(  count + 1008, 'n' )
        cgsetsprite(0)
        
        if options.preview_stim
            
            disp('**********')
            disp( count + 1008 )
            
            cgdrawsprite( count + 1008, 0, 0 )
            cgflip( color.background )
            pause(.1)
        end
    end
end


%% task cue - merged intensities ( 1045 : 1068 )

count = 36;
merged = unique( counterphase(:,3) ); % frequencies for task cue
merged = unique( round( merged * 255 ) ) ./ 255;

for POS = 1:3
    
    im1 = imread( [ direct.stim bmp{ 2+POS } ] );
    im1 = double( im1 ) ./ 255; % im1 = fliplr(im1); im1 = imrotate(im1,90);
    
    im2 = imread( [ direct.stim bmp{ 2+POS + 3 } ] );
    im2 = double( im2 ) ./ 255; % im2 = fliplr(im2); im2 = imrotate(im2,90);
    
    for MM = 1:length(merged)
        
        count = count + 1;
        LUT.checkerboard(count,:) = [POS+2 merged(MM) merged(MM)*255 count + 1008 NaN ];
        
        % disp( LUT.checkerboard(count,:) )
        
        im3 = im1 .* merged(MM) + im2 .* (1 - merged(MM) );
        
        r = im3(:,:,1);
        g = im3(:,:,2);
        b = im3(:,:,3);
        
        cgloadarray( count + 1008, stim.w, stim.h, [ r(:) g(:) b(:) ], stim.w, stim.h )
        cgtrncol( count + 1008, 'n' )
        cgsetsprite(0)
        
        if options.preview_stim
            
            disp('**********')
            disp( count + 1008 )
            
            cgdrawsprite( count + 1008, 0, 0 )
            cgflip( color.background )
            pause(.1)
        end
        
    end
    
end


%% sprite numbers - counterphase

checkerboard_state = NaN(f.trial_max,n.Hz);

for H = 1:n.Hz
    for FRAME = 1:f.trial_max;
        [~,v] = min( abs( LUT.checkerboard(:,2) - counterphase(FRAME,H) ) );
        v = LUT.checkerboard(v,3);
        checkerboard_state(FRAME,H) = v;
    end
end


%% test locations

if options.preview_stim
    
    cgdrawsprite(spritenum.taskcue_w + 1000, 0, 0, sizes.task_cue, sizes.task_cue )
    cgdrawsprite(spritenum.cursor_w, 0, 0, sizes.task_cue, sizes.task_cue )
    
    cgdrawsprite( spritenum.uppermost_left, 0, 0, sizes.move_cue, sizes.move_cue )
    
    for P = 1:n.positions
        cgdrawsprite( spritenum.target1 + 1000, array.x(P), array.y(P), sizes.task_cue, sizes.task_cue )
    end
    
    cgflip( color.background )
    
end


%% more sprite numbers ( 111 : 113 )

spritenum.feedback = 111;
spritenum.ready = 112;
spritenum.rest = 113;


%% feedback sprites ( 114 : 121 )

spritenum.solo_fast = 114;
spritenum.solo_slow = 115;
spritenum.solo_left = 116;
spritenum.solo_correct = 117;

spritenum.team_fast = 118;
spritenum.team_slow = 119;
spritenum.team_left = 120;
spritenum.team_correct = 121;

for SPRITE = 114:121
    
    cgmakesprite( SPRITE, mon.res(1)/2, mon.res(2), color.background )
    cgsetsprite( SPRITE )
    
    switch SPRITE
        case spritenum.solo_fast
            cgtext( 'too fast', 0, 0 )
        case spritenum.solo_slow
            cgtext( 'too slow', 0, 0 )
        case spritenum.solo_left
            cgtext( 'missed target', 0, 0 )
        case spritenum.solo_correct
            cgtext( 'correct', 0, 0 )
        case spritenum.team_fast
            cgtext( 'too fast', 0, 0 )
        case spritenum.team_slow
            cgtext( 'too slow', 0, 0 )
        case spritenum.team_left
            cgtext( 'missed target', 0, 0 )
        case spritenum.team_correct
            cgtext( 'correct', 0, 0 )
    end
    
    cgsetsprite( 0 )
    
    if options.preview_stim
        disp('**********')
        disp( SPRITE )
        
        cgdrawsprite( SPRITE, 0, 0 )
        cgflip( color.background )
        pause(.1)
    end
    
end


%% endogenous cues ( 201 : 208 )

bmp = { 'uppermost_left.bmp'
        'upper_left.bmp'
        'lower_left.bmp'
        'lowermost_left.bmp'
        ...
        'uppermost_right.bmp'
        'upper_right.bmp'
        'lower_right.bmp'
        'lowermost_right.bmp'};

spritenum.uppermost_left = 201;
spritenum.upper_left = 202;
spritenum.lower_left = 203;
spritenum.lowermost_left = 204;

spritenum.uppermost_right = 205;
spritenum.upper_right = 206;
spritenum.lower_right = 207;
spritenum.lowermost_right = 208;

for SPRITE = 1:8
    
    cgloadbmp( SPRITE + 200, [ direct.stim bmp{SPRITE} ] )
    cgtrncol( SPRITE + 200, 'n')
    cgsetsprite( 0 )
    
    if options.preview_stim
        disp('**********')
        disp( SPRITE + 200 )
        
        cgdrawsprite( SPRITE + 200, 0, 0 )
        cgflip( color.background )
        pause(.1)
    end
    
end


%% numbers for feedback ( 300 : 309 )

sizes.font = 40 * ( mon.res(2) / 1024 ) *2/3 *.9;
sizes.font_w = 625/2;
sizes.font_h = 924/2;

for SPRITE = 0:9
    
    cgloadbmp( SPRITE + 300, [ direct.stim num2str(SPRITE) '.bmp' ] )
    cgtrncol( SPRITE + 300, 'n')
    cgsetsprite( 0 )
    
    if options.preview_stim
        disp('**********')
        disp( SPRITE + 300 )
        
        cgdrawsprite( SPRITE + 300, 0, 0 )
        cgflip( color.background )
        pause(.1)
    end
    
end


%% make RT+MT sprites ( 7001 : 9300 )

% known bug - if RT+MT

sizes.spacing = ( (sizes.font_w/sizes.font_h)*sizes.font*1.1)/2;
sizes.spacing2 = ( (sizes.font_w/sizes.font_h)*sizes.font*1.1)/2 .* [-3 -1 +1 +3 ];

sizes.numbersprite = ( max( sizes.spacing2 ) + sizes.spacing ) * 2;

tic

for SPRITE = 1 : 2300 % RT+MT
    
    STR.sprite = num2str(SPRITE);
    
    NN2 = 4 - length( STR.sprite );
    
    for NN = 1:NN2
        STR.sprite = [ '0' STR.sprite ];
    end
    
    spritenum.test = 7000 + SPRITE;
    
    cgmakesprite( spritenum.test, sizes.numbersprite, sizes.font, color.background )
    cgsetsprite( spritenum.test )
    
    for NN = 1:4
        cgdrawsprite( 300 + str2num(STR.sprite(NN)), sizes.spacing2(NN), 2, (sizes.font_w/sizes.font_h)*sizes.font*1.1, sizes.font )
    end
    
    cgsetsprite(0)
    
    if options.preview_stim
        disp('**********')
        disp( spritenum.test )
        
        cgdrawsprite( spritenum.test, 0, 0 )
        cgflip( color.background )
        % pause(.1)
    end
    
end

toc


%% rest sprites ( 401 - 402 / 401 - 416 )

for BLOCK = 1:n.blocks + 1
    
    cgmakesprite( 400 + BLOCK, mon.res(1), mon.res(2), color.background )
    cgsetsprite( 400 + BLOCK )
    
    for MON = 1:2
        if BLOCK <= n.blocks
            cgtext( [ 'block ' num2str(BLOCK) ' of ' num2str(n.blocks) ], mon.xcenter(MON), 0 )
        else
            cgtext( 'end, please wait', mon.xcenter(MON), 0 )
        end
    end
    
    cgsetsprite( 0 )
    
    
    if options.preview_stim
        disp('**********')
        disp( 400 + BLOCK )
        
        cgdrawsprite( 400 + BLOCK, 0, 0 )
        cgflip( color.background )
        pause(.5)
    end
    
end


%% trial loop

for TRIAL = 1:n.trials
    
    options.test_frames = 0;
    
    % ----- block rest
    
    if ismember(TRIAL, 1 : n.trials_block : n.trials ) && ~options.practice && options.rest
        
        BLOCK = (TRIAL-1)/n.trials_block + 1;
        
        for FRAME = 1:f.rest_block
            
            cgdrawsprite( 400 + BLOCK, 0, 0 )
            fliptime.rest_block(FRAME,BLOCK) = cgflip( color.background );
            
            if options.parallel_triggers
                io64( parallel.io.obj, parallel.io.address, btriggers(FRAME) )
            end
            
            if options.serial_triggers
                % ----- serial
                
                if FRAME == 1
                    fprintf(s1, '' ); % EYETRACKER 1
                    fprintf(s2, '' ); % EYETRACKER 2
                end
                
            end
        end
    end
    
    % ----- ready trial
    
    disp( '*************' )
    disp( num2str(TRIAL) )
    disp( str.cond{ data(TRIAL,D.cond) } )
    disp( str.location{ data(TRIAL,D.location) } )
    disp( str.Hz_combo{ data(TRIAL,D.Hz_combo) } )
    disp( str.position{ data(TRIAL,D.position_combo) } )
    
    
    pos = data(TRIAL,D.position_combo);
    code = LOC_CODE(pos,:);
    
    % ##### initialise variables
    
    % ----- reaction / movement time
    
    use.MT_upper = [NaN NaN NaN]; % maximum MT - depends on invidual RT
    
    use.RT = [NaN NaN NaN]; % actual RT
    use.MT = [NaN NaN NaN]; % actual MT
    use.HT = [NaN NaN NaN]; % actual holding time (MT + holding period)
    
    use.react = [NaN NaN NaN]; % reaction frame
    use.inside = [NaN NaN NaN]; % frame inside
    
    % errors/feedback
    
    use.RT_fast = [0 0 0]; % if RT too fast
    use.RT_slow = [0 0 0]; % if RT too slow
    use.MT_slow = [0 0 0]; % if MT too slow
    
    use.leaving = [0 0 0]; % if left area
    use.leaving_frame = [NaN NaN NaN];
    
    use.correct = [0 0 0]; % if correct 1 or 0
    
    use.ICD = NaN; % distance between two cursors
    use.sprite = NaN; % object/task cue
    use.x = NaN; % for drawing cursor/task cue solo
    use.y = NaN; % for drawing cursor/task cue solo
    
    dist = [NaN NaN NaN];
    
    tic
    
    for FRAME = 1:f.trial_max
        
        if FRAME == data(TRIAL,D.breaking_frame)
            break
        end
        
        % ############## CALCULATE MOVEMENT
        
        for CURSOR = 1:n.cursors
            
            % ---- read controllers
            
            if options.controllers
                
                switch CURSOR
                    case 1
                        State = myController1.GetState();
                    case 2
                        State = myController2.GetState();
                end
                
                ButtonStates = ButtonStateParser_dp(State.Gamepad.Buttons); % Put this into a structure
                
                cursor.thumb(1, FRAME, TRIAL, CURSOR) = +double( State.Gamepad.RightThumbX ) / controller.stick_max;
                cursor.thumb(2, FRAME, TRIAL, CURSOR) = +double( State.Gamepad.RightThumbY ) / controller.stick_max;
                
            else
                cursor.thumb(1, FRAME, TRIAL, CURSOR) = 0;
                cursor.thumb(2, FRAME, TRIAL, CURSOR) = 0;
            end
            
            ThumbX = cursor.thumb(1, FRAME, TRIAL, CURSOR);
            ThumbY = cursor.thumb(2, FRAME, TRIAL, CURSOR);
            
            % ---- calculate increment
            
            DIST = sqrt( ThumbX.^2 + ThumbY.^2 );
            
            if abs( DIST ) <= cursor.sensitivity;
                ThumbX = 0; % dead zone
                ThumbY = 0; % dead zone
            end
            
            recorded_angles = wrapTo360( atan2d( ThumbY, ThumbX ) );
            DIST = sqrt( ThumbX.^2 + ThumbY.^2 );
            
            if DIST > 1; DIST = 1; end
            
            xinc = cosd(recorded_angles)*DIST*cursor.speed;
            yinc = sind(recorded_angles)*DIST*cursor.speed;
            
            cursor.inc(1,FRAME,TRIAL,CURSOR) = xinc; % xinc
            cursor.inc(2,FRAME,TRIAL,CURSOR) = yinc; % yinc
            
            % ----- calculate movement
            
            if FRAME == 1
                cursor.xy(1,FRAME,TRIAL,CURSOR) = 0;
                cursor.xy(2,FRAME,TRIAL,CURSOR) = 0;
            else
                cursor.xy(1,FRAME,TRIAL,CURSOR) = xinc + cursor.xy(1,FRAME-1,TRIAL,CURSOR);
                cursor.xy(2,FRAME,TRIAL,CURSOR) = yinc + cursor.xy(2,FRAME-1,TRIAL,CURSOR);
            end
            
        end
        
        % ----- calculate movement co-op
        
        CURSOR = 3;
        
        if any( cursor.inc(:,FRAME,TRIAL,1) ) && any( cursor.inc(:,FRAME,TRIAL,2) ) % movement not equal to zero for both players
            xinc = mean( cursor.inc(1,FRAME,TRIAL,1:2) );
            yinc = mean( cursor.inc(2,FRAME,TRIAL,1:2) );
        else
            xinc = 0;
            yinc = 0;
        end
        
        cursor.inc(1,FRAME,TRIAL,CURSOR) = xinc;
        cursor.inc(2,FRAME,TRIAL,CURSOR) = yinc;
        
        if FRAME == 1
            cursor.xy(1,FRAME,TRIAL,CURSOR) = 0;
            cursor.xy(2,FRAME,TRIAL,CURSOR) = 0;
        else
            cursor.xy(1,FRAME,TRIAL,CURSOR) = xinc + cursor.xy(1,FRAME-1,TRIAL,CURSOR);
            cursor.xy(2,FRAME,TRIAL,CURSOR) = yinc + cursor.xy(2,FRAME-1,TRIAL,CURSOR);
        end
        
        % cursor.xy(1, FRAME, TRIAL, 3) = mean( cursor.xy(1, FRAME, TRIAL, 1:2), 4);
        % cursor.xy(2, FRAME, TRIAL, 3) = mean( cursor.xy(2, FRAME, TRIAL, 1:2), 4);
        
        
        % ############## EVALUATE MOVEMENT
        
        for CURSOR = 1:n.cursors+1
            
            DIST = any( cursor.inc(:,FRAME,TRIAL,CURSOR) );
            
            % ----- evaluate RT
            
            if DIST ~= 0 && isnan( use.react(CURSOR) )
                
                use.react(CURSOR) = FRAME;
                use.RT(CURSOR) = ( use.react(CURSOR) - data(TRIAL,D.move_cue_frame) ) ./ mon.ref * 1000;
                
                if FRAME <= data(TRIAL,D.RT_lower_frame)
                    use.RT_fast(CURSOR) = true;
                elseif FRAME >= data(TRIAL,D.RT_upper_frame)
                    use.RT_slow(CURSOR) = true;
                end
                
                % ---- MT limits
                
                use.MT_upper(CURSOR) = FRAME + f.MT_max;
                
            end
            
            
            % ----- evaluate movement
            
            % ----- cursor-target distance
            
            use.x = array.x( code(data(TRIAL,D.location)) );
            use.y = array.y( code(data(TRIAL,D.location)) );
            
            
            dist(CURSOR) =  sqrt(   ( cursor.xy(1, FRAME, TRIAL, CURSOR) - use.x ) .^2 + ...
                ( cursor.xy(2, FRAME, TRIAL, CURSOR) - use.y ) .^2 );
            
            if isnan( use.inside(CURSOR) )
                
                if dist(CURSOR) <= target.critical_distance
                    use.inside(CURSOR) = FRAME;
                    use.MT(CURSOR) = ( use.inside(CURSOR) - use.react(CURSOR) ) ./ mon.ref * 1000;
                elseif FRAME > use.MT_upper(CURSOR)
                    use.MT_slow(CURSOR) = true;
                end
                
            else
                
                % ###################### LEAVING IS GETTING OVERWRITTEN!
                % seems okay - can reconstruct first leaving frame if
                % necessary
                
                if dist(CURSOR) > target.critical_distance
                    use.leaving(CURSOR) = true;
                    use.leaving_frame(CURSOR) = FRAME;
                elseif FRAME == use.inside(CURSOR) + f.HT
                    use.HT(CURSOR) = FRAME;
                end
                
            end
            
        end
        
        
        % ######################### draw stimuli
        
        for MON = 1:n.mon
            
            % ----- display rest
            
            if ANIMATE(FRAME,A.rest,TRIAL)
            end
            
            
            % ----- display neutral_cue_cursor
            
            use.x = [];
            use.y = [];
            use.sprite = [];
            use.RGB = [];
            use.spritenum = [];
            
            if ANIMATE(FRAME,A.neutral_cue_cursor,TRIAL)
                
                use.x = 0 + mon.xcenter(MON);
                use.y = 0;
                
                use.sprite = spritenum.taskcue_w;
                
                use.RGB = checkerboard_state(FRAME - data(TRIAL,D.rest_frames), 3);
                
                use.spritenum = LUT.checkerboard(   LUT.checkerboard(:,1) == use.sprite & ...
                    LUT.checkerboard(:,3) == use.RGB, 4);
                
                cgdrawsprite( use.spritenum, use.x, use.y, sizes.task_cue, sizes.task_cue )
                cgdrawsprite( spritenum.cursor_w, use.x, use.y, sizes.task_cue, sizes.task_cue )
                
            end
            
            
            % ----- display task cue
            
            use.x = [];
            use.y = [];
            use.sprite = [];
            use.RGB = [];
            use.spritenum = [];
            
            if ANIMATE(FRAME,A.task_cue,TRIAL)
                
                use.x = 0 + mon.xcenter(MON);
                use.y = 0;
                
                switch data(TRIAL,D.cond)
                    case 1
                        use.sprite = spritenum.taskcue_r;
                    case 2
                        use.sprite = spritenum.taskcue_g;
                end

                use.RGB = checkerboard_state(FRAME - data(TRIAL,D.rest_frames), 3);
                
                use.spritenum = LUT.checkerboard(   LUT.checkerboard(:,1) == use.sprite & ...
                    LUT.checkerboard(:,3) == use.RGB, 4);
                
                cgdrawsprite( use.spritenum, use.x, use.y, sizes.task_cue, sizes.task_cue )
                
            end
            
            
            % ----- display targets
            
            use.x1 = [];
            use.y1 = [];
            use.RGB1 = [];
            use.spritenum1 = [];
            
            use.x2 = [];
            use.y2 = [];
            use.RGB2 = [];
            use.spritenum2 = [];
            
            if ANIMATE(FRAME,A.targets,TRIAL)
                
                use.sprite = spritenum.target1;
                
                LOC = 1;
                use.x1 = mon.xcenter(MON)+array.x(code(LOC));
                use.y1 = array.y(code(LOC));
                
                use.RGB1 = checkerboard_state(FRAME + flicker_start(TRIAL), COMBO( data(TRIAL,D.Hz_combo), LOC) );
                
                LOC = 2;
                use.x2 = mon.xcenter(MON)+array.x(code(LOC));
                use.y2 = array.y(code(LOC));
                use.RGB2 = checkerboard_state(FRAME + flicker_start(TRIAL), COMBO( data(TRIAL,D.Hz_combo), LOC) );
                
                use.spritenum1 = LUT.checkerboard(  LUT.checkerboard(:,1) == use.sprite & ...
                    LUT.checkerboard(:,3) == use.RGB1, 4);
                
                use.spritenum2 = LUT.checkerboard(  LUT.checkerboard(:,1) == use.sprite & ...
                    LUT.checkerboard(:,3) == use.RGB2, 4);
                
                cgdrawsprite( use.spritenum1, use.x1, use.y1, sizes.task_cue, sizes.task_cue )
                cgdrawsprite( use.spritenum2, use.x2, use.y2, sizes.task_cue, sizes.task_cue )
                
                
                for LOC = 1:n.locations
                    cgdrawsprite( spritenum.target, array.x(code(LOC)) + mon.xcenter(MON), array.y(code(LOC)), sizes.target, sizes.target )
                end
                
            end
            
            
            % ----- display task cursor
            
            use.x = [];
            use.y = [];
            
            if ANIMATE(FRAME,A.task_cursor,TRIAL)
                switch data(TRIAL,D.cond)
                    case 1
                        use.x = cursor.xy(1, FRAME, TRIAL, MON) + mon.xcenter(MON);
                        use.y = cursor.xy(2, FRAME, TRIAL, MON);
                        cgdrawsprite( spritenum.cursor_r, use.x, use.y, sizes.task_cue, sizes.task_cue )
                    case 2
                        use.x = cursor.xy(1, FRAME, TRIAL, 3) + mon.xcenter(MON);
                        use.y = cursor.xy(2, FRAME, TRIAL, 3);
                        cgdrawsprite( spritenum.cursor_g, use.x, use.y, sizes.task_cue, sizes.task_cue )
                end
            end
            
            
            % ----- draw move cue
            
            if ANIMATE(FRAME,A.move_cue,TRIAL)
                
                switch data(TRIAL,D.position_combo);
                    case 1 % 'uppermost left, lowermost right'
                        if data(TRIAL,D.location) == 1
                            cuesprite = spritenum.uppermost_left;
                        elseif data(TRIAL,D.location) == 2
                            cuesprite = spritenum.lowermost_right;
                        end
                    case 2 % 'upper left, lower right'
                        if data(TRIAL,D.location) == 1
                            cuesprite = spritenum.upper_left;
                        elseif data(TRIAL,D.location) == 2
                            cuesprite = spritenum.lower_right;
                        end
                    case 3 % 'lower left, upper right'
                        if data(TRIAL,D.location) == 1
                            cuesprite = spritenum.lower_left;
                        elseif data(TRIAL,D.location) == 2
                            cuesprite = spritenum.upper_right;
                        end
                    case 4 % 'lowermost left, uppermost right'
                        if data(TRIAL,D.location) == 1
                            cuesprite = spritenum.lowermost_left;
                        elseif data(TRIAL,D.location) == 2
                            cuesprite = spritenum.uppermost_right;
                        end
                end
                
                cgdrawsprite( cuesprite, mon.xcenter(MON), 0, sizes.move_cue, sizes.move_cue)
                
            end
            
            
            % ----- display feedback
            
            if ANIMATE(FRAME,A.feedback,TRIAL)
                
                if FRAME == data(TRIAL,D.feedback_frame) %% ?
                    prepare_feedback_replay3;
                end
                
                cgdrawsprite( spritenum.feedback, 0, 0 )
                
            end
            
        end
        
        fliptime.trial(FRAME,TRIAL) = cgflip( color.background );
        
        %         if FRAME > data(TRIAL,D.rest_frames)
        %             input( num2str(FRAME) )
        %         end
        %
        %         if FRAME > 1
        %
        %             if trigger_onset(FRAME+1,TRIAL)
        %                 disp( triggers(FRAME+1,TRIAL) )
        %                 input( num2str(FRAME+1) )
        %             end
        %
        %         end
        %
        %         if trigger_onset(FRAME,TRIAL)
        %             disp( triggers(FRAME+1,TRIAL) )
        %             input( num2str(FRAME) )
        %         end
        %
        %         if ismember( ANIMATE(FRAME,A.trigger,TRIAL), TRIG.move_cue )
        %             options.test_frames = 1;
        %         end
        %         if FRAME == data(TRIAL,D.task_cue_frame)-1
        %             options.test_frames = 1;
        %         end
        %
        
        if options.test_frames
            input( num2str( FRAME ) )
        end
        
        
        % ----- triggers
        
        if options.parallel_triggers
            
            % ----- parallel
            
            io64( parallel.io.obj, parallel.io.address, TRIGGERS(FRAME,TRIAL) )
        end
        
        if options.serial_triggers
            % ----- serial
            
            if FRAME == 1
                fprintf(s1, '' ); % EYETRACKER 1
                fprintf(s2, '' ); % EYETRACKER 2
            end
            
        end
        
    end
    
    toc
    
    % ----- save trial data
    
    data(TRIAL, [   D.MT_upper_frames D.RT D.MT D.HT D.react_frame D.inside_frame D.RT_fast D.RT_slow D.MT_slow D.leaving D.leaving_frame D.correct] ) = ...
                [   use.MT_upper use.RT use.MT use.HT use.react use.inside use.RT_fast use.RT_slow use.MT_slow use.leaving use.leaving_frame use.correct ];
    
    
    % ---- ensure controller state is set to zero
    
    while 1 && options.controllers
        
        gamepad_state = [0 0; 0 0];
        
        for CURSOR = 1:n.cursors
            
            % ---- read controllers
            
            switch CURSOR
                case 1
                    State = myController1.GetState();
                case 2
                    State = myController2.GetState();
            end
            
            ButtonStates = ButtonStateParser_dp(State.Gamepad.Buttons); % Put this into a structure
            
            gamepad_state(CURSOR,1) = State.Gamepad.RightThumbX < 5000;
            gamepad_state(CURSOR,2) = State.Gamepad.RightThumbY < 5000;
            
        end
        
        if all( gamepad_state(:) )
            break
        end
    end
    
    
end


%% end rest

if options.rest && ~options.practice
    
    BLOCK = n.blocks+1;
    
    for FRAME = 1:f.rest_block
        
        cgdrawsprite( 400 + BLOCK, 0, 0 )
        fliptime.rest_block(FRAME,BLOCK) = cgflip( color.background );
        
        if options.parallel_triggers
            
            io64( parallel.io.obj, parallel.io.address, btriggers(FRAME) )
            
            % ----- serial
            
        end
        
        if options.serial_triggers
            
            if FRAME == 1
                fprintf(s1, '' ); % EYETRACKER 1
                fprintf(s2, '' ); % EYETRACKER 2
            end
            
        end
        
    end
end


%% timing?

ft = diff(fliptime.trial);
figure
plot(ft)


%% end

observer.stop_clock = clock;
tic; save( [ direct.data observer.fname ] ); toc

cgshut
cogstd('spriority','normal');

observer

diary off