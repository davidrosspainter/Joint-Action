close all; clear; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ext] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = '..\data_manager\CheckFiles2\';
load( [IN 'fname.mat'] )

addpath('..\external')
addpath('..\common')

is_figure_visible = 'off';
is_load_fresh = true;
is_visualise = true;

generate_global_variables


%% ----- settings

mon.res = [1080*2 1080];
sizes.font = 40 * ( mon.res(2) / 1024 ) *2/3 *.9;

STR.control = {'Solo' 'Joint'};

LOC_CODE = [3 7 % - uppermost left, lowermost right
    4 8 % - upper left, lower right
    5 1 % - lower left, upper right
    6 2]; % lowermost left, uppermost right

col_location = [0.5 0.25 0.6
    1 0 1
    1 0 0
    1 0.36 0
    1 1 0
    0 1 0
    0 1 1
    0 0 1];

dpp = (53.2/1920);


%% ----- start cogent

colors = {[1 0 0], [0 1 0], [0 1 1]};

addpath('..\external\Cogent2000v1.33\Toolbox\')
cgopen(1920, 1080, 0, 144, 0)

cgpenwid(2)

cgfont('Lucida Console', sizes.font)
cgpencol(1,1,1)

cgflip(0,0,0)
cgflip(0,0,0)



%% eye data

load('..\eye_tracking\eye_single_trial\results.mat', 'results');



%% check target position

SESSION = 1;

filename = [fname.direct_behav fname.behave{SESSION} ];
disp(filename)
load( filename, 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer', 'array', 'sizes');

target_position = NaN(number_of_trials,1);

for TRIAL = 1:number_of_trials % align trials with movement cue onset
    target_position(TRIAL) = LOC_CODE(data(TRIAL,D.position_combo),data(TRIAL,D.location));
end
        

tmp = [data(:,D.position_combo) data(:,D.location) target_position];

unique_rows = unique(tmp,'rows')

CONTROL = 2;
index = data(:,D.cond) == CONTROL;

target_position2 = target_position(index)

     

%% first movie test

results2 = results;

% analyse

CURSOR_XY2 = [];
TARGET_POSITION = [];
GAZE = [];

COND = 2;

switch COND
    case 1
        players_to_use = 1:2;
    case 2
        players_to_use = 3;
end

% 5, 6, 19 - weird
% shit 11 player 1
% best [4 7 8 9 10 12 13 14 15 16 17 18 20]
% best 8

[4 7 8 9 10 12 13 14 15 16 17 18 20];

for SESSION_count = 1:20
    
    is_skip = false;
    
    for SESSION = SESSION_count
        
        % ---- load session behavioural data...
        
        disp('****************************')
        disp(num2str(SESSION))
        
        load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer', 'array', 'sizes');
       
        % ----- check alignment with eye
        
        if isempty(results2(SESSION).control)
            disp('skipping SESSION...')
            is_skip = true;
            continue
        end
        
        if all(results2(SESSION).control == data(:,D.cond))
            disp('aligned')
        else
            error('misaligned')
        end
        
        x = NaN(144*2.5, number_of_trials, 2);
        y = NaN(144*2.5, number_of_trials, 2);
        
        for PLAYER = 1:2
            x(:,:,PLAYER) = resample(results2(SESSION).GAZE_POST.x(:,:,PLAYER), 144, 120);
            y(:,:,PLAYER) = resample(results2(SESSION).GAZE_POST.y(:,:,PLAYER), 144, 120);
        end
        
        gaze = [];
        gaze(1,:,:,:) = x - mon.res(1)/4; % recenter to zero
        gaze(2,:,:,:) = y - mon.res(2)/4; % recenter to zero
        
        clear x y
        
        % ----- adjust centre and invert the y axis...
        
        for PLAYER = 1:number_of_players
            X = gaze(1,:,:,PLAYER);
            gaze(1,:,:,PLAYER) = gaze(1,:,:,PLAYER) - nanmean(X(:));
            
            Y = gaze(2,:,:,PLAYER);
            gaze(2,:,:,PLAYER) = gaze(2,:,:,PLAYER) - nanmedian(Y(:));
            gaze(2,:,:,PLAYER) = gaze(2,:,:,PLAYER)*-1;
            gaze(2,:,:,PLAYER) = gaze(2,:,:,PLAYER) + mon.res(2)/4;
        end
        
        % ----- extract cursor information - hack solution?
        
        cursor_xy = cursor.xy;
        cursor_xy2 = NaN(2, 144*2.5, number_of_trials, 3); % min length 505, max length 577 - but take 2.5 seconds
        target_position = NaN(number_of_trials,1);
        
        
        
        for TRIAL = 1:number_of_trials % align trials with movement cue onset
            cursor_xy2(:,:,TRIAL,:) = cursor_xy(:, data(:,D.move_cue_frame): data(:,D.move_cue_frame) + 144*2.5 - 1,TRIAL,:);
            target_position(TRIAL) = LOC_CODE(data(TRIAL,D.position_combo),data(TRIAL,D.location));
        end
        
        asdfasdfsafdsa
        
        
        % ----- limit to control condition
        
        index = data(:,D.cond) == COND;
        cursor_xy2 = cursor_xy2(:,:,index,:);
        target_position = target_position(index);
        data = data(index,:);
        gaze = gaze(:,:,index,:);
        results2(SESSION).control = results2(SESSION).control(index);
        
        if SESSION == 3
            cursor_xy2 = cursor_xy2(:,1:503,:,:); % remove extra frame
        end
        
        for PLAYER = players_to_use % remove trials with RTs that are too fast or too slow
            index = data(:,D.RT_fast(PLAYER)) == true | data(:,D.RT_slow(PLAYER)) == true;
            cursor_xy2(:,:,index,PLAYER) = NaN;
            gaze(:,:,index,:) = NaN;
        end
        
        CURSOR_XY2 = cat(3, CURSOR_XY2, cursor_xy2);
        TARGET_POSITION = cat(1, TARGET_POSITION, target_position);
        GAZE = cat(3, GAZE, gaze);
        
    end
    
    if is_skip
        continue
    end
    
    % play movie
    
    color_to_use = col_location(TARGET_POSITION,:);
    color_to_use2 = color_to_use .* repmat( rand(length(color_to_use),1), 1, 3);
    
    
    midpoint = [];
    
    % 25.1052  288.2319
    
    for FRAME = 1:5:1.5*144 % size(cursor_xy2,2)-7
        
        trials_to_use = 1:size(CURSOR_XY2,3);
        
        % draw cursors
        
        
        
        for PLAYER = players_to_use
            X = squeeze(CURSOR_XY2(1, FRAME, trials_to_use, PLAYER));
            Y = squeeze(CURSOR_XY2(2, FRAME, trials_to_use, PLAYER));
            cgrect(X', Y', repmat(sizes.cursor, size(X,1),1), repmat(sizes.cursor, size(X,1),1), color_to_use2(trials_to_use,:))
        end
        
        % draw eye gaze positions
        
        
        cgpenwid(.5)
        
        for PLAYER = 1:2
            X = squeeze(GAZE(1, FRAME, trials_to_use, PLAYER)) - 25.1052;
            Y = squeeze(GAZE(2, FRAME, trials_to_use, PLAYER)) - 288.2319;
            cgellipse(X', Y', repmat(1/dpp, size(X,1),1), repmat(1/dpp, size(X,1),1), color_to_use2(trials_to_use,:))
            midpoint = [midpoint; [nanmedian(X) nanmedian(Y)]];
            
        end
        
        
        cgpenwid(2)
        %
        
        for position = 1:n.positions
            cgellipse(array.x(position), array.y(position), sizes.target, sizes.target, [1 1 1]) % radius =  292.0774
        end
        
        time_string = sprintf('%.2f', FRAME/mon.ref);
        %     cgtext(['Pair Number = ' num2str(SESSION)], 0, 450)
        %     cgtext(['Trial = ' num2str(TRIAL) ', Control = ' STR.control{data(TRIAL,D.cond)}], 0, 400)
        cgtext(['Time = ' time_string  ' s'], 0, 350)
        
        cgflip(0,0,0)
        
    end
    
    
end





%% second movie test

%mkdir([OUT 'movie_data\'])


for SESSION = 1:number_of_sessions

    CURSOR_XY2 = cell(2,1);
    COLOR_TO_USE = cell(2,1);
    GAZE = cell(2,1);
    PLAYERS_TO_USE = cell(2,1);
    TARGET_POSITION = cell(2,1);

    % analyse

    for COND = 1:2

        results2 = results;

        switch COND
            case 1
                players_to_use = 1:2;
            case 2
                players_to_use = 3;
        end

        % 5, 6, 19 - weird
        % shit 11 player 1
        % best [4 7 8 9 10 12 13 14 15 16 17 18 20]
        % best 8

        is_skip = false;

        % ---- load session behavioural data...

        disp('****************************')
        disp(num2str(SESSION))

        load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer', 'array', 'sizes');

        % ----- check alignment with eye

        if isempty(results2(SESSION).control)
            disp('skipping SESSION...')
            is_skip = true;
            continue
        end

        if all(results2(SESSION).control == data(:,D.cond))
            disp('aligned')
        else
            error('misaligned')
        end

        x = NaN(144*2.5, number_of_trials, 2);
        y = NaN(144*2.5, number_of_trials, 2);

        for PLAYER = 1:2
            x(:,:,PLAYER) = resample(results2(SESSION).GAZE_POST.x(:,:,PLAYER), 144, 120);
            y(:,:,PLAYER) = resample(results2(SESSION).GAZE_POST.y(:,:,PLAYER), 144, 120);
        end

        gaze = [];
        gaze(1,:,:,:) = x - mon.res(1)/4; % recenter to zero
        gaze(2,:,:,:) = y - mon.res(2)/4; % recenter to zero

        clear x y

        % ----- adjust centre and invert the y axis...

        for PLAYER = 1:number_of_players
            X = gaze(1,:,:,PLAYER);
            gaze(1,:,:,PLAYER) = gaze(1,:,:,PLAYER) - nanmean(X(:));

            Y = gaze(2,:,:,PLAYER);
            gaze(2,:,:,PLAYER) = gaze(2,:,:,PLAYER) - nanmedian(Y(:));
            gaze(2,:,:,PLAYER) = gaze(2,:,:,PLAYER)*-1;
            %gaze(2,:,:,PLAYER) = gaze(2,:,:,PLAYER) + mon.res(2)/4;
        end

        % ----- extract cursor information - hack solution?

        cursor_xy = cursor.xy;
        cursor_xy2 = NaN(2, 144*2.5, number_of_trials, 3); % min length 505, max length 577 - but take 2.5 seconds
        target_position = NaN(number_of_trials,1);

        for TRIAL = 1:number_of_trials % align trials with movement cue onset
            cursor_xy2(:,:,TRIAL,:) = cursor_xy(:, data(:,D.move_cue_frame): data(:,D.move_cue_frame) + 144*2.5 - 1,TRIAL,:);
            target_position(TRIAL) = LOC_CODE(data(TRIAL,D.position_combo),data(TRIAL,D.location));
        end

        % ----- limit to control condition

        index = data(:,D.cond) == COND;
        cursor_xy2 = cursor_xy2(:,:,index,:);
        target_position = target_position(index);
        data = data(index,:);
        gaze = gaze(:,:,index,:);
        results2(SESSION).control = results2(SESSION).control(index);

        if SESSION == 3
            cursor_xy2 = cursor_xy2(:,1:503,:,:); % remove extra frame
        end

        for PLAYER = players_to_use % remove trials with RTs that are too fast or too slow
            index = data(:,D.RT_fast(PLAYER)) == true | data(:,D.RT_slow(PLAYER)) == true;
            cursor_xy2(:,:,index,PLAYER) = NaN;
            gaze(:,:,index,:) = NaN;
        end

        size(cursor_xy2)
        size(color_to_use)
        size(gaze)

        color_to_use = col_location(target_position,:) .* repmat( rand(length(target_position),1), 1, 3); % add random hue variation

        CURSOR_XY2{COND} = cursor_xy2;
        COLOR_TO_USE{COND} = color_to_use;
        GAZE{COND} = gaze;
        PLAYERS_TO_USE{COND} = players_to_use;
        TARGET_POSITION{COND} = target_position;

        size(CURSOR_XY2{COND})
        size(GAZE{COND})
        size(COLOR_TO_USE{COND})
        size(PLAYERS_TO_USE{COND})

    end

    if is_skip
        continue
    end
    
    save([OUT 'movie_data\' STR.session{SESSION} '.mat'], 'CURSOR_XY2', 'GAZE', 'COLOR_TO_USE', 'PLAYERS_TO_USE', 'TARGET_POSITION', '-v7')
    
end


%% play movie

xmod = [-1080/2 +1080/2];

for FRAME = 1:5:1.5*144 % size(cursor_xy2,2)-7

    for COND = 1:2    
        movie_function(CURSOR_XY2{COND}, PLAYERS_TO_USE{COND}, sizes, COLOR_TO_USE{COND}, GAZE{COND}, dpp, FRAME, xmod(COND), n, array, mon, str.cond{COND})
    end

    time_string = sprintf('%.2f', FRAME/mon.ref);
    cgtext(['Time = ' time_string  ' s'], 0, 350)
    
    cgflip(0,0,0)
   
end


%% movie test


trials_to_use = 1:size(cursor_xy2,3);

% draw cursors
for PLAYER = players_to_use
    X = squeeze(cursor_xy2(1, FRAME, trials_to_use, PLAYER)) + xmod;
    Y = squeeze(cursor_xy2(2, FRAME, trials_to_use, PLAYER));
    cgrect(X', Y', repmat(sizes.cursor, size(X,1),1), repmat(sizes.cursor, size(X,1),1), color_to_use(trials_to_use,:))
end

% draw eye gaze positions
cgpenwid(.5)

for PLAYER = 1:2
    X = squeeze(gaze(1, FRAME, trials_to_use, PLAYER)) + xmod;
    Y = squeeze(gaze(2, FRAME, trials_to_use, PLAYER));
    cgellipse(X', Y', repmat(1/dpp, size(X,1),1), repmat(1/dpp, size(X,1),1), color_to_use(trials_to_use,:))
end

% draw target positions
cgpenwid(2)

for position = 1:n.positions
    cgellipse(array.x(position) + xmod, array.y(position), sizes.target, sizes.target, [1 1 1]) % radius =  292.0774
end


cgtext([cond_string], xmod, 350)



