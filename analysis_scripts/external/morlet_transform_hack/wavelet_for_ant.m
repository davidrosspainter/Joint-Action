close all
clear
clc

addpath( [ cd '\morlet_transform_hack' ] )


%% signal settings

Hz = 10;
d = 1;
fs = 200;
nx = fs*d;
t = 1/fs:1/fs:d;

f.fft = 0:1/d:fs-1/d;

phase = [0 90 180 270];
phase_in_rad = degtorad(phase);


%% wavelet settings

fc = 1;
FWHM_tc = 6;

f.wavelet = 5:15;
squared = 'n';
plot_fig = true; % must be true or otherwise an error - don't know why

F = 0:20;

[IDX_Hz, real_Hz] = find_Hz_IDX(f.wavelet, Hz );

[f_settings, sigma_t, sigma_f, t_settings, W, hFigWavelet] = morlet_design_dp2(fc, FWHM_tc, F, Hz, plot_fig);
morlet_design_dp2(fc, FWHM_tc, F, Hz, plot_fig);

options.plot = 1;


%% generate signal

h = figure;

for HH = 1:length(phase)
    
    disp(HH)
    
    %% contstruct signal
    
    y(:,HH) = sin(2*pi*Hz*t  + phase_in_rad(HH) ); %
    
    
    %% fft
    
    amp(:,HH) = abs( fft( y(:,HH) ) ./ nx );
    amp(2:end-2,HH) = amp(2:end-2,HH)*2;
    
    
    %% wavelet analaysis!
    
    x = y(:,HH);
    
    P = morlet_transform(x,t,f.wavelet,fc,FWHM_tc,squared);
    E = 1;
    A = abs( squeeze( P(E,:,:) )' ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT
    
    AA(:,:,HH) = abs( squeeze( P(E,:,:) )' );
    PP(:,:,HH) = squeeze( P(E,:,:) )';
    ANG(:,:,HH) = angle( squeeze( P(E,:,:) )' );
    

    if options.plot
        
        ax(1 +(HH-1)*4) = subplot(4,4,1 + (HH-1)*4);
        plot( t, y(:,HH) )
        
        ylim([-2 +2] )
        xlim( [0 d] )
        
        set(gca,'tickdir', 'out', 'xtick', 0:5 )
        set(gca,'xticklabel',[])
        xlabel('Time (s)' )
        
        
        %% fft
        
        ax(2 +(HH-1)*4) = subplot(4,4, 2 + (HH-1)*4);
        plot( f.fft, amp(:,HH) )
        xlim( [0 20] )
        ylim( [0 1] )
        
        xlabel('Frequency (Hz)' )
        set(gca,'tickdir', 'out' )
        set(gca,'ytick', [0:0.5:1] )
        
        
        %% plot wavelet settings
        ax(3 +(HH-1)*4) = subplot(4,4,3 + (HH-1)*4 );
        imagesc(t, f.wavelet, A );
        ylabel( 'Frequency (Hz)' )
        xlabel( 'Time (s)' )
        get(gca,'clim')
        
        h1 = colorbar;
        set(get(h1,'title'),'string','MCA');
        
        ax(4 +(HH-1)*4) = subplot(4,4,4 + (HH-1)*4 );
        imagesc(t, f.wavelet, ANG(:,:,HH) );
        ylabel( 'Frequency (Hz)' )
        xlabel( 'Time (s)' )
        get(gca,'clim')
        
        
        h1 = colorbar;
        set(get(h1,'title'),'string','Phase');
        
    end
    
    
    
end

linkaxes( ax( [1 5 9 13] ), 'xy' )
linkaxes( ax( [2 6 10 14] ), 'xy' )
linkaxes( ax( [3 7 11 15] ), 'xy' )
linkaxes( ax( [4 8 12 16] ), 'xy' )
