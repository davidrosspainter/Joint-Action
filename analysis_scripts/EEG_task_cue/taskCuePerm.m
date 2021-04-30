close all; clear; clc; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );

IN = 'task_cue_epoch\';

addpath('..\common\')
generate_global_variables
EEG_SRATE = 256;
fs = EEG_SRATE;

taskCueSettings

addpath('..\external\morlet_transform_hack')

%% load data

epoch = cell(number_of_subjects,1);
code = cell(number_of_subjects,1);

for SUBJECT = 1:number_of_subjects
    [SESSION, PLAYER, STR] = generate_subject_string(SUBJECT, generate_subject_code);
    disp([ IN STR.SUBJECT '.EPOCH.mat' ])
    load( [ IN STR.SUBJECT '.EPOCH.mat' ], 'EPOCH', 'epochCode' );
    epoch{SUBJECT} = EPOCH;
    code{SUBJECT} = epochCode;
end


%%

parpool(8)


%%

Nperm = 1000;
DATA2USE = cell(Nperm,1);

parfor PERM = 1:Nperm
    DATA2USE{PERM} = permF2(n, f, number_of_subjects, epoch, code, t, fc, FWHM_tc, squared, PERM );
end


%% distribution & cutoffs

permDist = [];

for PERM = 1:Nperm
    permDist = [ permDist ; DATA2USE{PERM}(:,f.wavelet==Hz) ];
end


%%

h = figure; cla; hold on

TIT = 'permDistribution';

alpha = 1e-3;
alpha = alpha*100;

hist(permDist,1000)
cutoff = prctile( permDist, [alpha/2 100-alpha/2] );

for CC = 1:2
   line( [cutoff(CC) cutoff(CC)], get(gca,'ylim'), 'color', 'r' ) 
end

xlim([-.1 +.1])
set(gca,'tickdir','out')
suptitle(TIT)
saveas(h, [ OUT 'permDistribution.png' ] )
saveas(h, [ OUT 'permDistribution.eps' ], 'epsc' )


%%

h = figure;
subplot(2,1,1)
data2use = DATA2USE{1}(:,:);
imagesc(t, f.wavelet, data2use')

xlim([0 1.5])

subplot(2,1,2); cla; hold on
data2use = DATA2USE{1}(:,f.wavelet==Hz);
plot(t, data2use' < min(cutoff) | data2use' > max(cutoff), 'k' );

[v,i] = max( data2use' );
line( [ t(i) t(i) ], get(gca,'ylim') )

xlim([0 1.5])

saveas(h, [ OUT 'newP.png' ] )
saveas(h, [ OUT 'newP.eps' ], 'epsc' )

save([OUT 'peak_time_point.mat'], 't', 'i')

%%

h = figure;
data2use = DATA2USE{1}(:,f.wavelet == Hz);

subplot(2,1,1); cla; hold on
plot(t, data2use, 'k' );

set(gca,'ylim',[-1 +1].*max( abs (get(gca,'ylim')) ) );

for CC = 1:n.cond
    line( get(gca,'xlim'), [cutoff(CC) cutoff(CC)], 'color', 'r' ) 
end

plot(t, data2use, 'k' );

[v,i] = max(data2use);

scatter( t(i), v )
text( t(i), v*1.1, [ 'p < ' num2str( 1/length(permDist) ) ], 'horizontalalignment', 'center', 'verticalalignment', 'middle'  )

subplot(2,1,2)
plot(t, data2use' < min(cutoff) | data2use' > max(cutoff), 'k' );

TIT = 'permResults';
suptitle(TIT)

saveas(h, [OUT 'permResults.png' ] )
saveas(h, [OUT 'permResults.eps' ], 'epsc' )

save( [OUT 'i.mat' ], 'i' )

% TIT = 'taskCueWavelet';
% close all
% 
% h = figure;
% limit = nanmean( wAMPG, 4); limit = [ min(limit(:)) max(limit(:)) ];
% 
% for CC = 1:3
% 
%     subplot(3, 1, CC)
% 
%     if CC < 3
%         imagesc(t, f.wavelet, nanmean( wAMPG(:,:,CC,:), 4)' );
%         caxis( limit )
%     else
%         data2use = nanmean( wAMPG(:,:,2,:), 4) - nanmean( wAMPG(:,:,1,:), 4);
%         imagesc(t, f.wavelet, data2use' );
%         caxis( [-1 +1] .* max( abs( data2use(:) ) ) );
%     end
%     
% 	title( STR.cond{CC} )
%     
%     xlabel( 'Time (s)' )
%     ylabel( 'Frequency (Hz)' )
%     hc = colorbar;
%     set(get(hc,'title'),'string','\muV');
%     
%     colormap(jet)
% 
% end






