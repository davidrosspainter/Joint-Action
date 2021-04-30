function [data2use] = synchronyGroup2erp_permutation_function(PERM, data, n, number_of_channels, number_of_subjects, EEG_ARTIFACT_THREHOLD_RANGE, t, lab, TRIG, number_of_trials)

tic
    
ERP = NaN(n.x, number_of_channels, n.cond, number_of_subjects); % just Cz

for SUBJECT = 1:number_of_subjects
    for CC = 1:n.cond
        
        if PERM == 1
            type_to_use = data{SUBJECT}.TYPE();
        else
            type_to_use = data{SUBJECT}.TYPE(randperm(number_of_trials));
        end
        
        data2use = data{SUBJECT}.epoch(:,:,type_to_use == TRIG.task_cue(CC));
        data2use( :,:,any( squeeze( range( data2use ) ) > EEG_ARTIFACT_THREHOLD_RANGE ) ) = NaN;
        ERP(:,:,CC,SUBJECT) = nanmean(data2use,3);
    end
end

time_index = t >= -.5 & t <= 1.5;
ERP = ERP(time_index,:,:,:);
t2 = t(time_index);

% figure plot

is_plot = false;

if is_plot

    col = {'r' 'b', 'g'};

    h = figure; hold on
    line([-.5, +1.5], [0, 0], 'color', 'k', 'linestyle', '--')

    for CC = 1:3

        if CC < 3
            data2use = squeeze( ERP(:,ismember(lab,'Cz'),CC,:) )';
        else
            data2use = squeeze( ERP(:,ismember(lab,'Cz'),2,:) )' - squeeze( ERP(:,ismember(lab,'Cz'),1,:) )';
        end

        M = mean(data2use);
        E = ws_bars(data2use);

        %plot(t2, M', col{CC})
        boundedline(t2, M',E', col{CC})

    end

    legend({'', 'Solo' 'Joint', 'Joint-Solo'})
    set(gca,'tickdir','out')
    xlabel('Time (s)')
    ylabel('EEG Amplitude (uV)')
    
end

data2use = mean(squeeze( ERP(:,ismember(lab,'Cz'),2,:) )' - squeeze( ERP(:,ismember(lab,'Cz'),1,:) )');

toc

