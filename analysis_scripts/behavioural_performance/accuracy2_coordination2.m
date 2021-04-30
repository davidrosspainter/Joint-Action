close all; clear; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ext] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = '..\data_manager\CheckFiles2\';

addpath('..\external')
addpath('..\common')

is_figure_visible = 'on';
is_load_fresh = false;

generate_global_variables


%%

load( [IN 'fname.mat'] )
fname.behave( cellfun( @isempty, fname.behave ) ) = [];


%%

results.accuracy = NaN(number_of_sessions, 3, 2);
results.MT = NaN(number_of_sessions, 3, 2);
results.RT = NaN(number_of_sessions, 3, 2); % cursors, conditions

if is_load_fresh
    for SESSION = 1:number_of_sessions
        
        disp('****************************')
        disp(num2str(SESSION))

        tic
        load([fname.direct_behav fname.behave{SESSION}], 'data', 'D', 'observer');
        toc
        
        if SESSION == 20
            % find(~isnan(data(:,D.RT(1))),1,'last')
            keep = 1:960 <= 704;
        else
            keep = 1:960 <= 960;
        end
        
        close all
        h = figure('visible', 'on');
        subplot(2,1,1)
        plot(data(data(:,D.cond)==1&keep',D.correct(1:2)))
        title(mean(data(data(:,D.cond)==1&keep',D.correct(1:2))))
        subplot(2,1,2)
        plot(data(data(:,D.cond)==2&keep',D.correct(3)))
        title(mean(data(data(:,D.cond)==2&keep',D.correct(3))))
        suptitle(STR.session{SESSION})
        
        saveas(h, [OUT STR.session{SESSION} '.png'])
        
        for COND = 1:2
            for CURSOR = 1:3
                
                IDX = data(:,D.cond) == COND & keep';
                
                results.accuracy(SESSION,CURSOR,COND) = nanmean(data(IDX,D.correct(CURSOR)))*100;
                
                % ----- learning?
                
                dataToUse = data(IDX,D.correct(CURSOR));
                trialNumber = 1:length(dataToUse);
                [r,p] = corr(trialNumber',dataToUse)
                
                results.r(SESSION,CURSOR,COND) = r;
                results.p(SESSION,CURSOR,COND) = p;
                
                % ----- RT/MT
                
                IDX =   data(:,D.cond) == COND & ...
                        data(:,D.correct(CURSOR)) == 1
                
                results.RT(SESSION,CURSOR,COND) = nanmean(data(IDX,D.RT(CURSOR))); 
                results.MT(SESSION,CURSOR,COND) = nanmean(data(IDX,D.MT(CURSOR))); 

            end
        end
   
        results.slowStartPercentage(SESSION) = sum(data(data(:,D.cond)==2,D.RT(:,3)) > data(data(:,D.cond)==2,D.RT(:,1)) & data(data(:,D.cond)==2,D.RT(:,3)) > data(data(:,D.cond)==2,D.RT(:,2)))/480*100;
        
        toc
        
    end
    
    save( [ OUT 'results.mat' ], 'results' )   
    
else
    
    load( [ OUT 'results.mat' ], 'results' )
    
end


%% RT

RT_original = [results.RT(:,1:2,1) results.RT(:,3,2)];
RT_derived = [results.RT(:,1:2,2) results.RT(:,3,1)];

accuracy_original = [results.accuracy(:,1:2,1) results.accuracy(:,3,2)];
accuracy_derived = [results.accuracy(:,1:2,2) results.accuracy(:,3,1)];

MT_original = [results.MT(:,1:2,1) results.MT(:,3,2)];
MT_derived = [results.MT(:,1:2,2) results.MT(:,3,1)];

save([OUT 'cell_means.mat'], 'accuracy_original', 'accuracy_derived', 'MT_original', 'MT_derived', 'RT_original', 'RT_derived', '-v6')



%%

h = figure;
plot(accuracy_original)
legend({'1','2','J'})
saveas(h, [OUT 'accuracy.png'])