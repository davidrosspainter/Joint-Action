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