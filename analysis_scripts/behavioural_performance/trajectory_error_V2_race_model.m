close all; clear; restoredefaultpath

addpath('..\external')
addpath('..\common')
addpath(genpath('D:\JointActionRevision\analysis\external\kakearney-boundedline-pkg-50f7e4b'))

number_of_sessions = 20;
number_players = 2;

IN = '..\data_manager\CheckFiles2\';
load( [IN 'fname.mat'] )

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

is_figure_visible = 'on';
is_load_fresh = true;

n.trials = 960;
dpp = (53.2/1920); % degrees/pixel
n.cursors = 3;


generate_global_variables



%% load saved data


n.trialmax = n.trials/2;
n.sessions = 17;

RESULT.trajectx = NaN(216,n.trialmax,3,n.sessions);
RESULT.trajecty = NaN(216,n.trialmax,3,n.sessions);
RESULT.R = NaN(3,n.trialmax, n.sessions);

for SESSION = 1:number_of_sessions
    
    load( ['trajectory_error_V2\' 'S' STR.session{SESSION} '.trajectories.mat'], 'TRAJECT2', 'R', 'E')
    
    for CURS = 1:3
        RESULT.trajectx(:,1:size(TRAJECT2.x{CURS},2),CURS,SESSION)=TRAJECT2.x{CURS}; %(points,trajectories,cursors,sessions)
        RESULT.trajecty(:,1:size(TRAJECT2.x{CURS},2),CURS,SESSION)=TRAJECT2.y{CURS};
    end
    
    RESULT.Ex(:,:,SESSION) = E.x;
    RESULT.Ey(:,:,SESSION) = E.y;
    
    tmp = R';
    
    for TRIAL = 1:size(tmp,1)
        tmp(TRIAL, 1:2) = sort(tmp(TRIAL,1:2), 'descend');
    end
    
    RESULT.R(:,1:size(R,2),SESSION) = tmp';
    
end



%% linear regression results.

h = figure('visible', is_figure_visible); hold on
Rplot = squeeze(nanmean(RESULT.R,2));

[~, idxmax] = max(Rplot([1 2],:));
idxmax2 = [idxmax' abs(idxmax'-3) ones(number_of_sessions,1)*3];

for SESSION = 1:number_of_sessions
    Rplot(:,SESSION) = Rplot(idxmax2(SESSION,:),SESSION);
end

Mr = nanmean(Rplot,2);
Er = ws_bars(Rplot');
errorbar_groups(Mr',Er, 'bar_colors', [0.75 0.75 0.75], 'bar_names', {'HP Solo' 'LP Solo' 'Joint'}, 'FigID', h)

xlabel('Control')
ylabel('Explained Variance ({\it r}^2)')

%title('fit of linear regression')
%ylim([0.55 0.75])

set(gca, 'LineWidth', 1.5, 'TickDir', 'out', 'box','off', 'FontSize', 14, 'FontName', 'Arial')

saveas(h, [OUT 'regression fit.png' ] )
saveas(h, [OUT 'regression fit.eps' ], 'epsc' )

disp('***********************')
[H,P,CI,stats] = ttest(Rplot(3,:),  Rplot(2,:))
[H,P,CI,stats] = ttest(Rplot(3,:),  Rplot(1,:))
disp(mean(Rplot'))
disp(std(Rplot'))


%%

str.spss = ['Trajectory_Rsquared_Solo_goodfit\t' 'Trajectory_Rsquared_Solo_poorfit\t'  'Trajectory_Rsquared_Joint\t'   ];
spss.out = Rplot';


%% export to SPSS

out_name = [OUT 'JointAction_Trajectories.txt' ];

delete( out_name )
fid = fopen(out_name,'a+');

fprintf(fid, str.spss);
fprintf(fid, '\n');
dlmwrite(out_name, spss.out, '-append', 'delimiter', '\t');
fclose(fid);
