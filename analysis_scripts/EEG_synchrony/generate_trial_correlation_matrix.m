% to be run after loading the data from synchronyGroup - in place of old
% sliding window calculation correlation (this produces the same results
% but much faster ---- months -> < 1 hour.

clear; clc; close all; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );

addpath('..\common\')
addpath('..\external\topoplot_hack')
addpath('..\external\')

is_load_fresh = false;

is_figure_visible = 'on';

IN = {'synchronyGroup\' 'synchrony\'};

generate_global_variables
SRATE_EEG = 64;
synchrony_settings


%% get epoch correlation values (channels vectorized)

CHANGE_THIS = win.length + 1; % win.length should == win.length

if is_load_fresh

    disp('loading...')
    
    tic
    load([IN{1} 'group.EPOCH2.mat'], 'EPOCH2', 'type2')
    toc
    
    r3 = NaN(number_of_trials, number_of_sessions, nEpochs, number_of_channels);

    tic_load = tic;
    
    for ELECTRODE = 1:number_of_channels % parfor

        tic
        
        EPOCH = EPOCH2(:,ELECTRODE,:,:,:);

        r2 = NaN(number_of_trials, number_of_sessions, nEpochs );

        for EE = 1:nEpochs

            a = squeeze(EPOCH(win.start(EE):win.stop(EE),:,:,1,:));
            b = squeeze(EPOCH(win.start(EE):win.stop(EE),:,:,2,:));

            idx = repmat( range(a) > EEG_ARTIFACT_THREHOLD_RANGE | range(b) > EEG_ARTIFACT_THREHOLD_RANGE, CHANGE_THIS, 1, 1); % remove outliers

            a(idx) = NaN;
            b(idx) = NaN;

            a = permute(a,[2 3 1]);
            b = permute(b,[2 3 1]);

            az = bsxfun(@minus, a, mean(a,3));
            bz = bsxfun(@minus, b, mean(b,3));

            % Standard Pearson correlation coefficient formula

            a2 = az .^ 2;
            b2 = bz .^ 2;
            ab = az .* bz;
            r = sum(ab, 3) ./ sqrt(sum(a2, 3) .* sum(b2, 3));

            r2(:,:,EE) = r;

        end

        r3(:,:,:,ELECTRODE) = r2;

        toc
        
    end

    toc_load = toc(tic_load)
    
    r4 = single(r3);
    
    tic
    save([OUT 'r4.mat'], 'r4')
    toc
    
    
    % clean up, free some memory
    clear EPOCH EPOCH2 r3 r2 epoch2use

else
    
	tic
    
    disp(['loading... ' IN 'group.EPOCH2.mat'])
    load([IN{1} 'group.EPOCH2.mat'], 'type2')
    load([OUT 'r4.mat'], 'r4')
    
    toc
    
end


%% examine correlation by condition and trial accuracy at electrode Cz

type2 = NaN( number_of_trials, number_of_players, number_of_sessions, 'single' );
ACC = NaN( number_of_trials, number_of_sessions );

for SUBJECT = 1:number_of_subjects
    
    disp(SUBJECT)
    
    [SESSION, PLAYER, STR2] = generate_subject_string(SUBJECT, subject_code);
    load([IN{2} STR2.SUBJECT '.epoch.' num2str(SRATE_EEG) '.mat'], 'TYPE' );
    
    type2(:,PLAYER,SESSION) = TYPE;
    
    
	%% get accuracy
    
    load( [fname.direct_behav fname.behave{SESSION} ], 'data', 'D' );
    
    acc = NaN(number_of_trials,1);
    
    for COND = 1:2
        
        IDX = data(:,D.cond) == COND;
        
        switch COND
            case 1
                p2use = 1:2;
            case 2
                p2use = 3;
        end
        
        tmp = data(IDX, D.correct(p2use) );
        
        if COND == 1
            tmp = all(tmp,2);
        end
        
        acc(IDX) = tmp;
        
    end
    
     ACC(:,SESSION) = acc;
     
     
end


%% examine Cz...

e2use = find( ismember(lab,'Cz') );

type2use = type2;

res = NaN(nEpochs,2,number_of_sessions);
res2 = NaN(nEpochs,4,number_of_sessions);

for SESSION = 1:number_of_sessions

    data2use = squeeze( r4(:,SESSION,:,e2use) );
    res(:,:,SESSION) = grpstats( data2use,  type2(:,1,SESSION), {'mean'} )';
    res2(:,:,SESSION) = grpstats( data2use, [ type2(:,1,SESSION) ACC(:,SESSION) ], {'mean'} )';
    
end

m = nanmean(res,3);
m2 = nanmean(res2,3);


%%

TIT = 'CzTimeCourse';

h = figure;

subplot(2,1,1)
plot(win.t,m)
ylim([-.02 +.1])
xlim([-2.5 +3])
legend({'solo' 'joint'}, 'location', 'best')

subplot(2,1,2)
plot(win.t,m2)
ylim([-.02 +.1])
xlim([-2.5 +3])
legend({'S incorrect' 'S correct', 'J incorrect' 'J correct'}, 'location', 'best')

suptitle(TIT)
saveas(h, [OUT TIT '.png'])


%% correlation at time point of maximum difference 

[v, i] = max(m(:,2)-m(:,1));
data2use = squeeze( res2(i,:,:) )';

M = mean(data2use);
E = ws_bars(data2use);

M = [ M(1:2) ; M(3:4) ];
E = [ E(1:2) ; E(3:4) ];

h = figure;
[hBar, hErrorbar] = barwitherr(E,M);
xlim( [.375 2.625] )
set(gca,'tickdir','out')
ylabel('Correlation (\Deltar)' )
xlabel('Control')
set(gca,'xticklabels', {'Solo' 'Joint' })
legend({'Error' 'Correct'},'location','northeast')

saveas(h, [ OUT 'bars.publish.eps' ] , 'epsc' )
saveas(h, [ OUT 'bars.publish.png' ] , 'png' )

save([OUT 'i.mat'], 'i', 'v', 't')


%% SPSS

STR.cond3 = {'soloE', 'soloC', 'jointE', 'jointC'};

STR.spss = [];

for CC = 1:4
    
    STR.spss = [ STR.spss STR.cond3{CC} '\t' ] ;
end


out_name = [OUT 'accuracy.Cz.txt' ];

delete( out_name )
fid = fopen(out_name,'a+');

fprintf(fid, STR.spss);
fprintf(fid, '\n');
dlmwrite(out_name, data2use, '-append', 'delimiter', '\t');
fclose(fid);


%% ----- synchrony image again...

synchrony_image = single(NaN(nEpochs,number_of_channels,n.cond+1,number_of_sessions));

for SESSION = 1:number_of_sessions

    disp(SESSION)
    data2use = squeeze( r4(:,SESSION,:,:) );
    
    for CC = 1:n.cond
        idx = type2(:,1,SESSION) == TRIG.task_cue(CC);
        synchrony_image(:,:,CC,SESSION) = squeeze(mean(data2use(idx,:,:)));
    end

end

synchrony_image(:,:,3,:) = synchrony_image(:,:,2,:)-synchrony_image(:,:,1,:);


%%

TIT = 'synchrony.image';

close all
h = figure('visible', is_figure_visible);

m = nanmean(synchrony_image,4);


for CC = 1:n.cond+1
    
    % ------
   
    subplot(3,1,CC)
        
    imagesc( win.t, [], m(:,channel_order2,CC)' )
    
    if CC < n.cond+1
        data2use = m(:,:,1:2);
        limit = [ min(m(:)) max(m(:)) ];
    else
        data2use = m(:,:,3);
        limit = [-1 +1] .* max(abs(data2use(:)));
    end

    caxis(limit)
    colorbar
    colormap('jet')

    % -----
    
    title( STR.cond{CC} )

end

suptitle(TIT)
saveas(h, [ OUT TIT '.png' ] )
