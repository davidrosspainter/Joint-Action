clear; clc; close all; restoredefaultpath

SRATE_EEG = 64;

addpath('..\common\')
addpath('..\external\topoplot_hack')
    
p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );
    
IN = 'synchrony2\';


addpath('..\common\')
addpath('..\external\topoplot_hack')
addpath('..\external\morlet_transform_hack')
addpath(genpath('..\external\kakearney-boundedline-pkg-50f7e4b'))
addpath(genpath('..\external\'))

is_load_fresh = true;

generate_global_variables
synchrony_settings


if is_load_fresh
    

    %% ----- load epoch data
    
    data = cell( number_of_subjects, 1);
    EPOCH = cell( number_of_subjects, 1);
    type = cell( number_of_subjects, 1);
    FNAME = cell( number_of_subjects, 1);
    
    ERP = NaN(n.x, number_of_channels, n.cond, number_of_subjects);
    
    for SUBJECT = 1:number_of_subjects
        
        disp(SUBJECT)
        
        [SESSION, PLAYER, STR2] = generate_subject_string(SUBJECT, subject_code);
        
        tic
        
        data{SUBJECT} = load( [ 'synchrony2\' STR2.SUBJECT '.epoch.' num2str(SRATE_EEG) '.mat' ] );

        return
        
        for CC = 1:n.cond
            data2use = data{SUBJECT}.epoch(:,:,data{SUBJECT}.TYPE == TRIG.task_cue(CC));
            data2use( :,:,any( squeeze( range( data2use ) ) > EEG_ARTIFACT_THREHOLD_RANGE ) ) = NaN;
            ERP(:,:,CC,SUBJECT) = nanmean(data2use,3);
        end
 
        data{SUBJECT} = [];
        
        toc
        
    end

    save([OUT 'ERP.mat'], 'ERP', '-v6')
    
else    
    load([OUT 'ERP.mat'], 'ERP')  
end


%%

ERPM = mean(ERP,4);


%%

close all

TIT = 'movement.offset.erp.png';

h = figure(1);
limit = max(abs(( ERPM(:) ))) .*[-1 +1];

for CC = 1:n.cond+1
   
    subplot(3,1,CC)
    if CC <= n.cond
        imagesc(t, [], ERPM(:,channel_order2,CC)')
    else
        data2use = ERPM(:,channel_order2,2)'-ERPM(:,channel_order2,1)';
        limit = [-1 +1] .*max(abs(data2use(:)));
        imagesc(t, [], data2use)
    end
    
    caxis(limit)
        
    colorbar
    colormap('jet')
    
    title( STR.cond{CC} )
    
  %  xlim([-1 +1] )
    
end

suptitle(TIT)

saveas(h, [ OUT TIT '.png' ] )




%%

dd = squeeze(ERPM(:,ismember(lab,'Cz'),:));

dd = [-1 +1].*max(abs(dd));

h = figure(3);

TIT = 'movement.offset';

subplot(3,3,1:3); hold on

for CC = 1:n.cond
    plot( t,  ERPM(:,ismember(lab,'Cz'),CC) )
end

legend({'S' 'C'})

xlim( [-.5 1.5])


for PP = 4:6
    switch PP
        case 4
            [v,idx] = min(abs(t-.208));
        case 5
            [v,idx] = min(abs(t-.47));
        case 6
            [v,idx] = min(abs(t-.784));
    end

    subplot(3,3,PP); cla
    topoplot( ERPM(idx,:,2), chanlocs, 'maplimits', dd )
    colorbar

    %plot( t,  ERPM(:,ismember(lab,'POz'),2) )
end




fc = 1;
FWHM_tc = 1;
f.wavelet = .5:.05:5;

n.f = length(f.wavelet);
squared = 'n';

erp = ERPM(:,ismember(lab,'Cz'),2);

P = morlet_transform(erp, t, f.wavelet, fc, FWHM_tc, squared);
E = 1;
A = abs( squeeze( P(E,:,:) ) ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT


subplot(3,3,7:9)
imagesc(t,f.wavelet,A')

xlim([-.5 +1.5])

set(gca,'Ydir','Normal')


colormap('parula')
colormap('hot')
suptitle(TIT)
saveas(h, [OUT TIT '.png' ] )


%% wavelet

close all

h = figure;
imagesc(t,f.wavelet,A')

xlim([-.5 +1.5])

set(gca,'Ydir','Normal')
colormap('hot')
set(gca,'tickdir','out')

xlabel('Time (s)')
ylabel('Frequency (Hz)')
colorbar

saveas(h, [OUT 'wavelet.eps'],'epsc')


%% topos

h = figure;

for PP = 4:6
    switch PP
        case 4
            [v,idx] = min(abs(t-.208));
        case 5
            [v,idx] = min(abs(t-.47));
        case 6
            [v,idx] = min(abs(t-.784));
    end

    subplot(3,3,PP); cla
    topoplot( mean( ERPM(idx,:,:),3), chanlocs, 'maplimits', dd )
    colorbar

    %plot( t,  ERPM(:,ismember(lab,'POz'),2) )
end

colormap(hot)

maximize

saveas(h,[OUT 'topos.eps'],'epsc')
saveas(h,[OUT 'topos.png'],'png')


%% figure plot

col = {'r' 'b'};

h = figure;

for CC = 1:2
    data2use = squeeze( ERP(:,ismember(lab,'Cz'),CC,:) )';

    M = mean(data2use);
    E = ws_bars(data2use);

    boundedline(t, M',E', col{CC})
    xlim([min(t) max(t)])
end

xlim( [-.5 1.5])

legend({'Solo' 'Joint'})
set(gca,'tickdir','out')
xlabel('Time (s)')
ylabel('EEG Amplitude (uV)')

saveas(h, [OUT 'erp.eps'], 'epsc' )

return


%% bar plot 

%test = mean( mean( squeeze( ERP(:,ismember(lab,'Cz'),:,:) ), 2), 3);
%test = mean( mean( squeeze(, 2), 3);

IDX = round([1477 1607 1760]*(SRATE_EEG)/SRATE_RECORDING);

h = figure;

data2use = squeeze(ERP(IDX,ismember(lab,'Cz'), :, :));

for TT = 1:3
     
    subplot(1,3,TT)

    data2use2 = squeeze( data2use(TT,:,:) )';
    
    [~,p,ci,stats] = ttest(data2use2(:,1),data2use2(:,2));
    
    errorbar(mean(data2use2),ws_bars(data2use2))
    ylim([-1.8 +1.8])
    xlim([.5 2.5])

    set(gca,'tickdir','out')
    
    
end

saveas(h, [OUT 'bar.eps'], 'epsc')