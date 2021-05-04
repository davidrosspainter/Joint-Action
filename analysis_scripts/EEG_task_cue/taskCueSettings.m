%% ----- condition settings

STR.cond = {'Solo' 'Joint' 'Joint-Solo'};

COND{1} = TRIG.task_cue(1);
COND{2} = TRIG.task_cue(2);

n.cond = length( COND );

% TYPE = trig.type(:,T.task_cue);
% LATENCY = trig.latency(:,T.fix);


%% ----- epoch settings

lim.s = [1 2]; % DERP - 0:2 - > 1:2 4/10/18
lim.s = [0 1];
lim.s = [0 1.429];

lim.x = round(lim.s*fs); lim.x(2) = lim.x(2) - 1;
n.x = length( lim.x(1):lim.x(2) );

t = ( lim.x(1) : lim.x(2) ) ./ fs;


%% ----- FFT settings

n.s = lim.s(2) - lim.s(1);
n.s = n.x/fs;

f.fft = 0 : 1/n.s : fs - 1/n.s;

Hz = 7;
[~,idxHz] = min( abs( f.fft - Hz ) );
realHz = f.fft( idxHz );


%% ----- wavelet settings

fc = 1;
FWHM_tc = 2.5;
f.wavelet = 5:.05:9;

n.f = length(f.wavelet);
squared = 'n';