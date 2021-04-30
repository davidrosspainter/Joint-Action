clear; clc; close all; restoredefaultpath

addpath('..\external\')
addpath('..\common\')

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = 'import_eyetracker_matlab2\';
load '..\data_manager\CheckFiles2\fname.mat'

number_of_sessions = 20;
number_of_players = 2;

str.side = {'left', 'right'};
str.player = {'P1', 'P2'};

is_load_fresh = true;
is_figure_visible = 'off';

sessions_to_use = [6 7 8 9 10 11 12 13 14 15 16 17 18 19 21 22 23]; % exclude 2 3 5

generate_global_variables

%% triggers

TRIG.fix = [1 2]; % Hz combo 1, 2
TRIG.task_cue = [3 4]; % solo, co-op
TRIG.move_cue = [5 6]; % left/right
TRIG.feedback = 7; % feedback onset

COND = TRIG.move_cue;

str.COND = {'solo' 'coop'};
mon.res = [1920 1080];

options.loadFresh = true;

vXEdge = 1:2:mon.res(1);
vYEdge = 1:2:mon.res(2);

fs = 120;


%%

is_use_preprocessed_data = true;

if is_load_fresh
    
    ses_count = 0;
    
    for SESSION = sessions_to_use

        close all

        ses_count = ses_count + 1;
        disp(SESSION)

        SESSION_string = ['S' num2str(SESSION) ' test*'];
        XXX = strfndw(fname.behave, SESSION_string);
        disp(fname.behave{XXX})
        
        for CC = 1:2
            
            for PLAYER = 1:number_of_players
                
                
                %% ----- getdata
                
                fname.EYE = ['S' num2str(SESSION) '.' str.player{PLAYER} '.eyeData.mat'];
                load( [ IN fname.EYE ], 'samples', 'type', 'latency', 'header' )
      
                sdfgdfsg
                
                fname.save = ['S' num2str(SESSION) '_' str.side{PLAYER}];
                fname.tit = [ 'S' num2str(SESSION) ' ' str.side{PLAYER}];
                
                if is_use_preprocessed_data
                    tmp = load( [ 'preprocess_eye_data\' STR.session{XXX} '.' str.player{PLAYER} '.processedEye.mat' ], 'samples', 'GAZE', 'PUPIL', 'type' );
                    
                    if ~(length(tmp.samples) == length(samples))
                        error('potential misalignment!')
                    else
                        warning('using preprocessed data...')
                    end

                    samples = tmp.samples;                
                    GAZE = tmp.GAZE;
                    GAZE(GAZE == 0) = NaN; % probably not necessary
                    
                else
                   
                    idx.x = [6 8];
                    idx.y = [7 9];

                    samples(samples == 0) = NaN;
                    GAZE = [ nanmean(samples(:,idx.x),2) nanmean(samples(:,idx.y),2)];
                    
                end
                
                
                %% ----- get eye positions
                
                time = samples(:,1);
                
                
                %% Pre-move cue
                
                lim.s = [-1 0];
                lim.S = lim.s*1000000;
                f.trial = (lim.s(2) - lim.s(1))*fs;
                
                
                %% where to look?
                
                IDX = find(ismember(type, TRIG.task_cue(CC)));
                
                start_time = latency(IDX+1)+lim.S(1);
                stop_time = latency(IDX+1)+lim.S(2);
                
                gaze.x = nan(f.trial, length(start_time));
                gaze.y = nan(f.trial, length(start_time));
                
                for O = 1:length(start_time)
                    idx.trial = find(time >= start_time(O) & time < stop_time(O));
                    gaze.x(1:length(idx.trial),O) = GAZE(idx.trial, 1);
                    gaze.y(1:length(idx.trial),O) = GAZE(idx.trial, 2);
                end
                
                if size(gaze.x,1)>f.trial
                    gaze.x = gaze.x(1:f.trial,:);
                    gaze.y = gaze.y(1:f.trial,:);
                end
                
                
                %% recentre
                
                GAZEIM = round([gaze.y(:) gaze.x(:)]);
                vXEdge = 1:2:mon.res(1);
                vYEdge = 1:2:mon.res(2);
                gazehist = hist2d( GAZEIM, vYEdge, vXEdge );
                
                imagesc(gazehist>30)
                [~, center.x] = max(max(gazehist, [], 1), [], 2);
                [~, center.y] = max(max(gazehist, [], 2), [], 1);
                
                GAZE(:,1) = GAZE(:,1) - center.x + mon.res(1)/4;
                GAZE(:,2) = GAZE(:,2) - center.y + mon.res(2)/4;
                
                gaze.x = gaze.x - center.x + mon.res(1)/4;
                gaze.y = gaze.y - center.y + mon.res(2)/4;
                
                
                %% pre-move cue
                
                GAZEHIST.X.pre(:,:,PLAYER, CC) =  gaze.x;
                GAZEHIST.Y.pre(:,:,PLAYER, CC) =  gaze.y;
                
                GAZEIM = round([gaze.y(:) gaze.x(:)]);
                vXEdge = 1:2:mon.res(1);
                vYEdge = 1:2:mon.res(2);
                
                gazehist = hist2d( GAZEIM, vYEdge, vXEdge );
                GAZEHIST.pre(:,:,PLAYER) = gazehist;
                
                RESULT.GAZEHIST.premove(:,:,CC,PLAYER, ses_count) = gazehist;
                
                
                %% Pre-task cue
                
                lim.s = [-1 0];
                lim.S = lim.s*1000000;
                f.trial = (lim.s(2) - lim.s(1))*fs;
                
                
                %% where to look?
                
                IDX = find(ismember(type, TRIG.task_cue(CC)));
                
                start_time = latency(IDX)+lim.S(1);
                stop_time = latency(IDX)+lim.S(2);
                
                gaze.x = nan(f.trial, length(start_time));
                gaze.y = nan(f.trial, length(start_time));
                
                for O = 1:length(start_time)
                    idx.trial = find(time >= start_time(O) & time < stop_time(O));
                    gaze.x(1:length(idx.trial),O) = GAZE(idx.trial, 1);
                    gaze.y(1:length(idx.trial),O) = GAZE(idx.trial, 2);
                end
                
                %% pre-task cue
                
                GAZEHIST.X.pretask(:,:,PLAYER, CC) =  gaze.x;
                GAZEHIST.Y.pretask(:,:,PLAYER, CC) =  gaze.y;
                
                GAZEIM = round([gaze.y(:) gaze.x(:)]);
                vXEdge = 1:2:mon.res(1);
                vYEdge = 1:2:mon.res(2);
                
                gazehist = hist2d( GAZEIM, vYEdge, vXEdge );
                GAZEHIST.pretask(:,:,PLAYER) = gazehist;
                
                RESULT.GAZEHIST.pretask(:,:,CC,PLAYER, ses_count) = gazehist;
                
                %% post-move cue
                
                COND = TRIG.move_cue;
                
                lim.s = [0 2.5];
                lim.S = lim.s*1000000;
                
                f.trial = (lim.s(2) - lim.s(1))*fs;
                time = samples(:,1);
                
                %% where to look?
                
                start_time = latency(IDX+1)+lim.S(1);
                stop_time = latency(IDX+1)+lim.S(2);
                
                gaze.x = nan(f.trial, length(start_time));
                gaze.y = nan(f.trial, length(start_time));
                for O = 1:length(start_time)
                    idx.trial = find(time >= start_time(O) & time < stop_time(O));
                    gaze.x(1:length(idx.trial),O) = GAZE(idx.trial, 1);
                    gaze.y(1:length(idx.trial),O) = GAZE(idx.trial, 2);
                end
                
                %% post-move cue
                
                GAZEHIST.X.post(:,:,PLAYER, CC) =  gaze.x;
                GAZEHIST.Y.post(:,:,PLAYER, CC) =  gaze.y;
                
                GAZEIM = round([gaze.y(:) gaze.x(:)]);
                vXEdge = 1:2:mon.res(1);
                vYEdge = 1:2:mon.res(2);
                
                gazehist = hist2d( GAZEIM, vYEdge, vXEdge );
                GAZEHIST.post(:,:,PLAYER) = gazehist;
                
                RESULT.GAZEHIST.postmove(:,:,CC,PLAYER, ses_count) = gazehist;
            end
            
            
            %% change name
            
            fname.titdiff = [str.COND{CC} ' ' 'S' num2str(SESSION) ' Left - Right'];
            fname.tit = [str.COND{CC} ' ' 'S' num2str(SESSION) ];
            fname.savediff = [str.COND{CC} ' ' 'S' num2str(SESSION) '_difference'];
            fname.save = [str.COND{CC} ' ' 'S' num2str(SESSION) ];
            
            %% Pretask
            
            gazehist = (GAZEHIST.pretask(:,:,1) +  GAZEHIST.pretask(:,:,2))./2;
            
            h=figure('visible', is_figure_visible);
            imagesc(vXEdge, vYEdge, gazehist, [0 20])
            xlim([ 300 mon.res(1)-300])
            colormap(hot);
            
            title ([fname.tit ' pretask cue']);
            
            set(gcf,'units','pixels','position',[0,0,400,400])
            axis('square')
            saveas(h, [OUT fname.save '_pretaskcue.png']);
            
            IM{1, 1+2*(CC-1)} = imread( [OUT fname.save '_pretaskcue.png']);
            
            
            %% pretask Difference
            
            gazehist = GAZEHIST.pretask(:,:,1) -  GAZEHIST.pretask(:,:,2);
            
            h=figure('visible', is_figure_visible);
            imagesc(vXEdge, vYEdge, gazehist, [-20 20])
            xlim([ 300 mon.res(1)-300])
            colormap(jet);
            
            title ([fname.titdiff ' pretask cue']);
            
            set(gcf,'units','pixels','position',[0,0,400,400])
            axis('square')
            saveas(h, [OUT fname.savediff '_pretaskcue.png']);
            
            IM{1, 2+2*(CC-1)} = imread( [OUT fname.savediff '_pretaskcue.png']);
            
            
            %% Pre-move
            
            gazehist = (GAZEHIST.pre(:,:,1) + GAZEHIST.pre(:,:,2))./2;
            
            h=figure('visible', is_figure_visible);
            imagesc(vXEdge, vYEdge, gazehist, [0 20])
            xlim([ 300 mon.res(1)-300])
            colormap(hot);
            title ([fname.tit ' pre move cue']);
            
            set(gcf,'units','pixels','position',[0,0,400,400])
            axis('square')
            saveas(h, [OUT fname.save '_premovecue.png']);
            
            IM{2, 1+2*(CC-1)} = imread( [OUT fname.save '_premovecue.png']);
            
            
            %% difference - premove
            
            gazehist = GAZEHIST.pre(:,:,1) -  GAZEHIST.pre(:,:,2);
            
            h=figure('visible', is_figure_visible);
            imagesc(vXEdge, vYEdge, gazehist, [-20 20])
            xlim([ 300 mon.res(1)-300])
            colormap(jet);
            title ([fname.titdiff ' pre move cue']);
            
            set(gcf,'units','pixels','position',[0,0,400,400])
            axis('square')
            saveas(h, [OUT fname.savediff '_premovecue.png']);
            
            IM{2, 2+2*(CC-1)} = imread( [OUT fname.savediff '_premovecue.png']);
            
            
            %% post movecue
            gazehist = (GAZEHIST.post(:,:,1) + GAZEHIST.post(:,:,2))./2;
            
            h=figure('visible', is_figure_visible);
            imagesc(vXEdge, vYEdge, gazehist, [0 20])
            disp(str.COND{CC})
            disp(sum(abs(gazehist(:))))
            xlim([ 300 mon.res(1)-300])
            colormap(hot);
            
            title ([fname.tit ' post move cue']);
            
            set(gcf,'units','pixels','position',[0,0,400,400])
            axis('square')
            saveas(h, [OUT fname.save '_postmovecue.png']);
            
            IM{3, 1+2*(CC-1)} = imread( [OUT fname.save '_postmovecue.png']);
            
            
            %% post movecue difference
            
            gazehist = GAZEHIST.post(:,:,1) -  GAZEHIST.post(:,:,2);
            
            h=figure('visible', is_figure_visible);
            imagesc(vXEdge, vYEdge, gazehist, [-20 20])
            disp(str.COND{CC})
            disp(sum(abs(gazehist(:))))
            xlim([ 300 mon.res(1)-300])
            colormap(jet);
            
            title ([fname.titdiff ' post move cue']);
            set(gcf,'units','pixels','position',[0,0,400,400])
            axis('square')
            saveas(h, [OUT fname.savediff '_postmovecue.png']);
            
            IM{3, 2+2*(CC-1)} = imread( [OUT fname.savediff '_postmovecue.png']);
            
        end
        
        
        %% distances - pretaskcue
        clear dist
        fname.save = ['S' num2str(SESSION) '_difference'];
        
        n.trials = 480;
        lim.s = [-1 0];
        f.trial = (lim.s(2) - lim.s(1))*fs;
        
        GAZEHIST.X.pretask(GAZEHIST.X.pretask==0) = NaN;
        GAZEHIST.Y.pretask(GAZEHIST.Y.pretask==0) = NaN;
        
        for CC = 1:2
            for trial = 1:n.trials
                for frame = 1:f.trial
                    dist(frame,trial,CC) = sqrt(abs((GAZEHIST.X.pretask(frame,trial,1, CC)-GAZEHIST.X.pretask(frame,trial,2, CC)))^2+abs((GAZEHIST.Y.pretask(frame,trial,1, CC)-GAZEHIST.Y.pretask(frame,trial,2, CC)))^2);
                end
            end
        end
        
        Mdist = squeeze(nanmean(nanmean(dist,2),1));
        Edist = squeeze(nanstd(nanmean(dist,1)))/sqrt(n.trials);
        RESULT.mdist(:,1, ses_count) = Mdist;
        
        h = figure('visible', is_figure_visible);
        errorbar_groups(Mdist', Edist', 'bar_colors', [0.9 0.9 0.8], 'FigID', h)
        set(gca, 'xtick', 1:2, 'xticklabel', str.COND)
        xlabel('Condition')
        ylabel('distance between P1 and P2 gaze (px)')
        title('pre-task cue')
        
        ylim([min(Mdist)-10 max(Mdist)+10])
        set(gcf,'units','pixels','position',[0,0,400,400])
        
        axis('square')
        saveas(h, [OUT fname.save '_distance_pretask.png']);
        IM{1,5} = imread( [OUT fname.save '_distance_pretask.png']);
        
    
        
        %% distances - premovecue
        clear dist
        
        GAZEHIST.X.pre(GAZEHIST.X.pre==0) = NaN;
        GAZEHIST.Y.pre(GAZEHIST.Y.pre==0) = NaN;
        for CC = 1:2
            for trial = 1:n.trials
                for frame = 1:f.trial
                    dist(frame,trial,CC) = sqrt(abs((GAZEHIST.X.pre(frame,trial,1, CC)-GAZEHIST.X.pre(frame,trial,2, CC)))^2+abs((GAZEHIST.Y.pre(frame,trial,1, CC)-GAZEHIST.Y.pre(frame,trial,2, CC)))^2);
                end
            end
        end
        
        Mdist = squeeze(nanmean(nanmean(dist,2),1));
        Edist = squeeze(nanstd(nanmean(dist,1)))/sqrt(n.trials);
        RESULT.mdist(:,2, ses_count) = Mdist;
        
        h=figure('visible', is_figure_visible);
        errorbar_groups(Mdist', Edist', 'bar_colors', [0.9 0.9 0.8], 'FigID', h)
        set(gca, 'xtick', 1:2, 'xticklabel', str.COND)
        xlabel('Condition')
        ylabel('distance between P1 and P2 gaze (px)')
        title('pre-move cue (post-task cue)')
        
        ylim([min(Mdist)-10 max(Mdist)+10])
        set(gcf,'units','pixels','position',[0,0,400,400])
        axis('square')
        
        saveas(h, [OUT fname.save '_distance_premove.png']);
        IM{2, 5} = imread( [OUT fname.save '_distance_premove.png']);
        
        
        %% distances - postmovecue
        clear dist
        
        lim.s = [0 2.5];
        f.trial = (lim.s(2) - lim.s(1))*fs;
        
        GAZEHIST.X.post(GAZEHIST.X.post==0) = NaN;
        GAZEHIST.Y.post(GAZEHIST.Y.post==0) = NaN;
        for CC = 1:2
            for trial = 1:n.trials
                for frame = 1:f.trial
                    dist(frame,trial,CC) = sqrt(abs((GAZEHIST.X.post(frame,trial,1, CC)-GAZEHIST.X.post(frame,trial,2, CC)))^2+abs((GAZEHIST.Y.post(frame,trial,1, CC)-GAZEHIST.Y.post(frame,trial,2, CC)))^2);
                end
            end
        end
        
        Mdist = squeeze(nanmean(nanmean(dist,2),1));
        Edist = squeeze(nanstd(nanmean(dist,1)))/sqrt(n.trials);
        RESULT.mdist(:,3, ses_count) = Mdist;
        
        h = figure('visible', is_figure_visible);
        errorbar_groups(Mdist', Edist', 'bar_colors', [0.9 0.9 0.8], 'FigID', h)
        set(gca, 'xtick', 1:2, 'xticklabel', str.COND)
        xlabel('Condition')
        ylabel('distance between P1 and P2 gaze (px)')
        title('post-move cue')
        
        ylim([min(Mdist)-10 max(Mdist)+10])
        
        set(gcf,'units','pixels','position',[0,0,400,400])
        saveas(h, [OUT fname.save '_distance_postmove.png']);
        
        IM{3, 5} = imread( [OUT fname.save '_distance_postmove.png']);
        
        %% write
        imwrite( cell2mat(IM),[ OUT 'S' num2str(SESSION) '_movecuemaps.png'] )
        
    end
    
    %% alltogether
    
    OUT = [OUT 'all\']; mkdir(OUT);
    save([OUT 'RESULT.mat'], 'RESULT')
    clear IM
    
    
else
    
    OUT = [OUT 'all\']; mkdir(OUT);
    load([OUT 'RESULT.mat'], 'RESULT')
    
end

str.COND = { 'solo' 'joint' 'solo-joint'};
str.period =  {'pretask' 'premove' 'postmove'};


%% Pretask

for PERIOD = 1:3
    
    GAZEHIST = squeeze(cat(5, RESULT.GAZEHIST.(str.period{PERIOD})(:,:,:,1,:),RESULT.GAZEHIST.(str.period{PERIOD})(:,:,:,2,:)));
    GAZEHIST = squeeze(nanmean(GAZEHIST,4));
    
    for CC = 1:3
        if CC <3
            gazehist = GAZEHIST(:,:,CC);
            clim = [0 8];
            cm = hot;
        else
            gazehist = GAZEHIST(:,:,1)-GAZEHIST(:,:,2);
            clim = [-0.5 0.5];
            cm = jet;
        end
        
        h=figure('visible', is_figure_visible);
        
        imagesc(vXEdge, vYEdge, gazehist, clim)
        xlim([ 300 mon.res(1)-300])
        colormap(cm);
        
        title ([str.COND{CC} ' ' str.period{PERIOD} 'cue']);
        
        set(gcf,'units','pixels','position',[0,0,400,400])
        axis('square')
        saveas(h, [OUT str.COND{CC} '_' str.period{PERIOD} 'cue.png']);
        
        IM{PERIOD, CC} = imread( [OUT str.COND{CC} '_' str.period{PERIOD} 'cue.png']);
    end
end


%% distance

Mdist = mean(RESULT.mdist,3);

for PP = 1:3
    Edist(:,PP) = ws_bars(squeeze(RESULT.mdist(:,PP,:))');
end

for PP = 1:3
    
    h=figure('visible', is_figure_visible);
    
    errorbar_groups(Mdist(:,PP)', Edist(:,PP)', 'bar_colors', [0.9 0.9 0.9], 'FigID', h, 'bar_names', {'solo' 'joint'});
    title([str.period{PP} 'cue']);
    ylabel('distance between P1 and P2 gaze (px)')
    
    ylim([min(Mdist(:,PP))-10 max(Mdist(:,PP))+10])
    
    disp([str.period{PP} ':'])
    [~,P,~,stats] = ttest(RESULT.mdist(1,PP,:), RESULT.mdist(2,PP,:))
    
    saveas(h, [OUT str.COND{CC} '_' str.period{PERIOD} 'differeces.png']);
    IM{PP, 4} = imread( [OUT str.COND{CC} '_' str.period{PERIOD} 'differeces.png']);
end

imwrite( cell2mat(IM),[ OUT  'ALL_movecuemaps.png'] )


%% IMAGES TO PUT in illustrator
% -- draw axis
dpp = (53.2/1920);

h=figure('visible', is_figure_visible);
axis('square')
set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

xlim([ -660 660]*dpp )
ylim([ -660 660]*dpp)

xlim([ -660 660]*dpp .* 13/18.2875 ) % DRP
ylim([ -660 660]*dpp .* 13/18.2875 )

xlabel('x (° of visual angle)')
ylabel('y (° of visual angle)')

saveas(h, [OUT 'axis.eps'], 'epsc')


%%

for PERIOD = 1:3
    
    GAZEHIST = squeeze(cat(5, RESULT.GAZEHIST.(str.period{PERIOD})(:,:,:,1,:),RESULT.GAZEHIST.(str.period{PERIOD})(:,:,:,2,:)));
    GAZEHIST = squeeze(nanmean(GAZEHIST,4));
    
    for CC = 1:2
        gazehist = GAZEHIST(:,:,CC);
        clim = [0 8];
        cm = hot;

        h = figure('visible', is_figure_visible);    
        imagesc(vXEdge*dpp-mean(vXEdge*dpp), vYEdge*dpp-mean(vYEdge*dpp)-.5, gazehist,clim)
        xlim( [-1 +1] .* 13 )
        ylim( [-1 +1] .* 13 )
        colormap(cm);
        title ([str.COND{CC} ' ' str.period{PERIOD} 'cue']);  
        axis('square')
        axis('off')
        saveas(h, [OUT str.COND{CC} '_' str.period{PERIOD} 'cue.png']);
        
    end
end


%%

for PERIOD =1
    
    GAZEHIST = squeeze(cat(5, RESULT.GAZEHIST.(str.period{PERIOD})(:,:,:,1,:),RESULT.GAZEHIST.(str.period{PERIOD})(:,:,:,2,:)));
    GAZEHIST = squeeze(nanmean(GAZEHIST,4));
    
    for CC = 1
        gazehist = GAZEHIST(:,:,CC);
        clim = [0 8];
        cm = hot;
        
        h=figure('visible', is_figure_visible);
        
        imagesc(vXEdge*dpp-mean(vXEdge*dpp), vYEdge*dpp-mean(vYEdge*dpp)-.5, gazehist, clim)

        xlim( [-1 +1] .* 13 )
        ylim( [-1 +1] .* 13 )
        
        colormap(cm);
        
        title ([str.COND{CC} ' ' str.period{PERIOD} 'cue']);
        
        axis('square')
        axis('off')
        
        colorbar
        
        saveas(h, [OUT 'CBAR.eps'], 'epsc');
        
    end
end


%%

str.spss = [];
spss.out = [];

for PP = 1:3
    for CC = 1:2
        str.spss = [ str.spss 'EyeDist_' str.period{PP} 'cue_' str.COND{CC} '\t'];
        data2use = squeeze(RESULT.mdist(CC,PP,:) )*dpp;
        
        spss.out = [spss.out data2use];
    end
end

out_name = [OUT 'JointAction_EyeData.txt' ];

delete( out_name )
fid = fopen(out_name,'a+');

fprintf(fid, str.spss);
fprintf(fid, '\n');
dlmwrite(out_name, spss.out, '-append', 'delimiter', '\t');
fclose(fid);


%% distance

close all

Mdist = mean(RESULT.mdist,3)*dpp;

for PP = 1:3
    Edist(:,PP) = ws_bars(squeeze(RESULT.mdist(:,PP,:))')*dpp;
end

for PP = 1:3
    
    h=figure('visible', is_figure_visible);
    
    errorbar_groups(Mdist(:,PP)', Edist(:,PP)', 'bar_colors', [0.9 0.9 0.9], 'FigID', h, 'bar_names', {'solo' 'joint'});
    title([str.period{PP} 'cue']);
    ylabel('distance between P1 and P2 gaze (px)')
    
    ylim([min(Mdist(:,PP))-10*dpp max(Mdist(:,PP))+10*dpp])
    
    disp([str.period{PP} ':'])
    [~,P,~,stats] = ttest(RESULT.mdist(1,PP,:), RESULT.mdist(2,PP,:))
    
    set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')
    
    if PP == 2 || PP == 3
        ylim([1.5 4.0])
    end
    
    saveas(h, [OUT str.period{PP} 'differeces.png']);
    saveas(h, [OUT str.period{PP} 'differeces.eps'], 'epsc');
end

data2use = ([    squeeze( RESULT.mdist(1,2,:) ), squeeze( RESULT.mdist(2,2,:) ) ...
    squeeze( RESULT.mdist(1,3,:) ), squeeze( RESULT.mdist(2,3,:) ) ])*dpp


