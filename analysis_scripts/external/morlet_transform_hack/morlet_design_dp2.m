function [f, sigma_t, sigma_f, t, W, hFigWavelet] = morlet_design_dp2(fc, FWHM_tc, F, Hz, plot_fig )

sigma_tc = FWHM_tc / sqrt(8*log(2));
t = linspace(-4*sigma_tc,4*sigma_tc,1000);
%W = morlet_wavelet(t,fc,sigma_tc);

% Complex Morlet wavelet
W = (sigma_tc*sqrt(pi))^(-0.5) * exp( -(t.^2)/(2*sigma_tc^2) ) .* exp(1i*2*pi*fc*t);

%display example resolutions
f = sort( [ F Hz ] ); %Hz
f = unique(f);
sigma_t = sigma_tc*fc ./f; %standard deviation in time
sigma_f = 1./(2*pi*sigma_t); %standard deviation in time

%[f, sigma_t, sigma_f, t, W] = morlet_design(sOptions.MorletFc, sOptions.MorletFwhmTc);
% Plot the values

if plot_fig

    hFigWavelet = figure;
    % Frequency resolution
    subplot(2,2,1);
    plot(f, sigma_f);
    title('Spectral resolution' );
    xlabel('Frequency (Hz)');
    ylabel('FWHM (Hz)');


    % Time resolution
    subplot(2,2,3);
    plot(f, sigma_t);
    title('Temporal resolution', 'Interpreter', 'none');
    xlabel('Frequency (Hz)');
    ylabel('FWHM (sec)');

    % Plot morlet wavelet
    hAxes = subplot(2,2,[2,4]);
    plot(t,real(W),'linewidth',2)
    hold on
    plot(t,imag(W),'r','linewidth',2)
    title('Complex Morlet wavelet');
    set(hAxes, 'XLim', [t(1), t(end)], 'YLim', [-1,1]*1.05*max(real(W)) )
    legend( {'Real' 'Imaginary'}, 'location', 'northeast' )       

    suptitle( [ 'fc = ' num2str(fc) ', FWHM tc = ' num2str(FWHM_tc) ] )  

end

disp( 'Hz sigma_f sigma_t' )
disp( [ Hz' sigma_f( ismember(f, Hz ) )' sigma_t( ismember(f, Hz ) )' ] )