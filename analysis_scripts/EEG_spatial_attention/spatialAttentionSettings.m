%% ----- condition settings

STR.cond = {'solo.17' 'solo.19' 'joint.17' 'joint.19' };
n.cond = length(STR.cond);

col = {'r' 'b'};


%% ----- epoch settings (entire epoch)

lim.s = [0 +2];

lim.x = lim.s*fs; lim.x(2) = lim.x(2) - 1;
n.x = length( lim.x(1):lim.x(2) );

t = ( lim.x(1) : lim.x(2) ) ./ fs;


%% ----- FFT settings (reduced epoch)

lim2.s = [+1 +2];

lim2.x = lim2.s*fs; lim2.x(2) = lim2.x(2) - 1;
n2.x = length( lim2.x(1):lim2.x(2) );

t2 = ( lim2.x(1) : lim2.x(2) ) ./ fs;

n.s = lim2.s(2) - lim2.s(1);
f.fft = 0 : 1/n.s : fs - 1/n.s;

Hz = [17 19]; n.Hz = length(Hz);
[~,idxHz] = find( ismember( f.fft, Hz ) );
realHz = f.fft( idxHz );


%% ----- wavelet settings

fc = 1;
FWHM_tc = 30;
f.wavelet = 16:.1:20;

n.f = length(f.wavelet);
squared = 'n';