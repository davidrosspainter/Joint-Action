%% ----- condition settings

STR.cond = {'Solo', 'Joint', 'Solo-Joint'};

COND{1} = TRIG.task_cue(1);
COND{2} = TRIG.task_cue(2);

n.cond = length( COND );

col = {'r' 'b' 'g'};


%% ----- epoch settings

lim.s = [-2.75 +3.25];

lim.x = lim.s*SRATE_EEG;
lim.x(2) = lim.x(2) - 1;
n.x = length( lim.x(1):lim.x(2) );

t = (lim.x(1):lim.x(2)) ./ SRATE_EEG;


%% ----- window settings

win.length_seconds = 0.5;
win.inc_seconds = .0156; % 1 samples at srate of 64 Hz

win.length = round(win.length_seconds*SRATE_EEG);
win.inc = round(win.inc_seconds*SRATE_EEG);

win.start = 1 : win.inc : n.x - win.length;
win.stop = win.start + win.length; % -1 ...

win.t = (mean([win.start;win.stop])./SRATE_EEG) + lim.s(1);

% [ min(win.t) max( win.t ) ]

nEpochs = length(win.start);