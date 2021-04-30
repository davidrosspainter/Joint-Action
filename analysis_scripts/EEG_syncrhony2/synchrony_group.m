clear; clc; close all; restoredefaultpath

SRATE_EEG = 64;

addpath('..\common\')
addpath('..\external\topoplot_hack')
    
p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [ OUT '\' ]; mkdir( OUT );
    
IN = 'epoch_data\';

is_load_fresh = true;
is_correlate = true;

is_figure_visible = 'off';

generate_global_variables
synchrony_settings

time_start_load = tic;


if is_load_fresh
    
    
    %% ----- load epoch data ----- MEMORY INTENSIVE!!!!! (3 GB at 64 Hz)
    
    EPOCH2 = NaN( n.x, number_of_channels, number_of_trials, number_of_players, number_of_sessions, 'single' );
    type2 = NaN( number_of_trials, number_of_players, number_of_sessions, 'single' );
    
    proportion_missing = NaN(number_of_subjects, 1);
    
    for SUBJECT = 1:number_of_subjects
        
        tic
        
        [SESSION, PLAYER, STR2] = generate_subject_string(SUBJECT, generate_subject_code);
        tmp = load( [ IN STR2.SUBJECT '.epoch.' num2str(SRATE_EEG) '.mat' ] );

        EPOCH2(:,:,:,PLAYER,SESSION) = tmp.epoch;
        type2(:,PLAYER,SESSION) = tmp.TYPE;

        proportion_missing(SUBJECT) = sum(isnan(tmp.epoch(:)))/numel(tmp.epoch);
        
        toc
        
    end
    
    h = figure('visible', is_figure_visible);
    
    TIT = 'ProportionMissing.png';
    bar(proportion_missing)
    xlabel('Subject')
    ylabel('Proportion Missing')
    xlim([0 number_of_subjects+1])
    set(gca,'xtick',0:2:40)
    title(TIT)
    saveas(h,[OUT TIT])


    %% ---- check alignment of type between individuals within pairs (good!)
    
%     figure;
%     
%     col = {'r' 'b'};
%     
%     for SESSION = 1:number_of_sessions
%     
%         subplot(2,1,1); cla; hold on
%     
%         for PLAYER = 1:2
%             plot( type2(:,PLAYER,SESSION), col{PLAYER} )
%         end
%     
%         subplot(2,1,2); cla; hold on
%         plot(type2(:,2,SESSION) - type2(:,1,SESSION));
%         title(num2str(all(type2(:,2,SESSION) == type2(:,1,SESSION))));
%         
%         suptitle(generate_session_string(SESSION))
%         input('enter')
%     
%     end
    
    elapsed_time_load = toc(time_start_load)
    
    tic
    save([OUT 'group.EPOCH2.mat'], 'EPOCH2', 'type2')
    toc
    
else
    
    
    USE_THIS = [OUT 'group.EPOCH2.mat'];
    disp(['loading...' USE_THIS])
    tic
    load([OUT 'group.EPOCH2.mat'], 'EPOCH2', 'type2')
    toc
    
    
end


%% ---- time consuming ...

% 1.78 minutes/electrode at 16 cores 2.5 GHz = 1.81 hours for 61 electrodes

number_of_workers = 16;

p = gcp('nocreate'); % If no pool, do not create new one.

if isempty(p)
    parpool(number_of_workers)
end


if is_correlate

    time_start_correlate = tic;
    elapsed_time_electrode = NaN(number_of_channels,1);

    for ELECTRODE = 1:number_of_channels

        start_time_electrode = tic;

        epoch2use = squeeze( EPOCH2(:,ELECTRODE,:,:,:) );
        calculate_proportion_missing(EPOCH2)


        %% ----- sliding window

        tic

        RES = cell(nEpochs,1);

        parfor EE = 1:nEpochs  
            RES{EE} = synchrony_group_runner(epoch2use, win, EE, type2);
        end

        toc


        %%

        M = NaN(nEpochs,2);
        err = NaN(nEpochs,2);
        p = NaN(nEpochs,1);

        for EE = 1:nEpochs

            data2use = RES{EE}; 
            M(EE,:) = mean(data2use);
            err(EE,:) = ws_bars(data2use);
            [~,p(EE)] = ttest( data2use(:,1), data2use(:,2) );

        end


        %%

        TIT = [ 'synchrony.' lab{ELECTRODE} ];

        close all
        h = figure('visible', is_figure_visible);

        subplot(2,1,1)

        cla; hold on

        for CC = 1:2
            errorbar( win.t, M(:,CC), err(:,CC), col{CC} )
        end

        xlim( [ min(win.t) max(win.t) ] )

        legend( STR.cond, 'location', 'best' )

        subplot(2,1,2)
        plot(win.t,p)
        xlim([min(win.t) max(win.t)])
        suptitle(TIT)
        saveas(h, [ OUT TIT '.png' ] )

        toc


        %%

        save( [ OUT 'results.' lab{ELECTRODE} '.mat' ], 'M', 'err', 'p', 'win', 'ELECTRODE', 'RES' )
        elapsed_time_electrode(ELECTRODE) = toc(start_time_electrode)

    end

    elapsed_time_correlate = toc(time_start_correlate)
    
end


%% plot results

for ELECTRODE = 1:number_of_channels
       
    load( [ OUT 'results.' lab{ELECTRODE} '.mat' ], 'M', 'err', 'p', 'win', 'ELECTRODE' )

    m(:,:,ELECTRODE) = M;
    e(:,:,ELECTRODE) = err;
    
end

m = permute(m,[1 3 2]);
e = permute(e,[1 3 2]);


%%

TIT = 'synchrony.image';

close all
h = figure('visible', is_figure_visible);

limit = [ min(m(:)) max(m(:)) ];

for CC = 1:n.cond+1
    
    % ------
   
    subplot(3,1,CC)
    
    if CC < 3
        imagesc( win.t, [], m(:,channel_order2,CC)' )
        caxis(limit)
    else
        dm = m(:,:,2) - m(:,:,1);
        imagesc( win.t, [], dm(:,channel_order2)' )
        caxis( [-1 +1] .* max(abs(dm(:))) )
    end
    
    colorbar
    colormap('jet')

    % -----
    
    title( STR.cond{CC} )

end


suptitle(TIT)
saveas(h, [ OUT TIT '.png' ] )


%%

[v,ELECTRODE] = max( max(dm) );
idx = find( dm(:,ELECTRODE) == v );

mm = mean(m,3);

ELECTRODE2 = find( ismember( lab, lab( channel_order2(57) ) ) );
v = max(mm(:,ELECTRODE2));
idx2 = find( mm(:,ELECTRODE2) == v );

[v,ELECTRODE3] = max(max(mm));
idx3 = find( mm(:,ELECTRODE3) == v );


%%

for IDX = [idx idx2 idx3]

    TIT = [ 'synchrony.topo.' num2str( win.t(IDX) ) '.s' ];

    h = figure('visible', is_figure_visible);

    limit = m(IDX,:,:);
    limit = [ min(limit(:)) max(limit(:)) ];

    for CC = 1:n.cond+1

        subplot(3,1,CC)

        if CC < 3
            head = m(IDX,:,CC);
        else
            head = m(IDX,:,2) - m(IDX,:,1);
            limit = [-1 +1] .* max(abs(head));
        end

        topoplot( head, chanlocs, 'maplimits', limit )
        colorbar
        colormap('jet')

        title( STR.cond{CC} )

    end

   % maximize

    suptitle(TIT)
    saveas(h, [ OUT TIT '.png'] )

end