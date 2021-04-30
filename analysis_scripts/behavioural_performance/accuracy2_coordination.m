close all; clear; restoredefaultpath

p = mfilename('fullpath');
[~, OUT, ext] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

IN = '..\data_manager\CheckFiles2\';

addpath('..\external')
addpath('..\common')

is_figure_visible = 'on';
is_load_fresh = true;

generate_global_variables


%%

load( [IN 'fname.mat'] )
fname.behave( cellfun( @isempty, fname.behave ) ) = [];


%%

results.accuracy = NaN(number_of_sessions, 3);
results.accuracy_hypothetical = NaN(number_of_sessions, 3);

results.MT = NaN(number_of_sessions, 3);
results.MT_hypothetical = NaN(number_of_sessions, 3);

results.RT = NaN(number_of_sessions, 3, 2); % cursors, conditions

if is_load_fresh
    for SESSION = 1:number_of_sessions
        
        
        disp('****************************')
        disp(num2str(SESSION))

        tic
        load([fname.direct_behav fname.behave{SESSION}], 'data', 'D', 'fliptime', 'triggers', 'f', 'TRIG', 'mon', 'n', 'options', 'cursor', 'array', 'sizes', 'str', 'observer');
        toc
        
        %% accuracy
        
        res = [];
        resH = [];
        
        for COND = 1:2
            
            %% ----- veridical
            
            switch COND
                case 1
                    CURSOR = 1:2;
                case 2
                    CURSOR = 3;
            end

            IDX = data(:,D.cond) == COND;
            res = [res nanmean(data(IDX, D.correct(CURSOR)))];
            
            
            %% ----- hypothetical
            
            switch COND
                case 2
                    CURSOR = 1:2;
                case 1
                    CURSOR = 3;
            end
            
            IDX = data(:,D.cond) == COND;
            resH = [resH nanmean(data(IDX, D.correct(CURSOR)))];

        end
        
        results.accuracy(SESSION,:) = res;
        results.accuracy_hypothetical(SESSION,:) = resH([2:3 1]);
        
        
        %% MT (on correct trials)
        
        res = [];
        resH = [];
        
        for CURSOR = 1:3
            
            %% ----- veridical
            
            switch CURSOR
                case 1
                    COND = 1;
                case 2
                    COND = 1;
                case 3
                    COND = 2;
            end
            
            IDX = data(:,D.cond) == COND & data(:, D.correct(CURSOR) ) == 1;
            res(CURSOR) = mean(data(IDX, D.MT(CURSOR)));
            
            
            %% ----- hypothetical

            switch CURSOR
                case 1
                    COND = 2;
                case 2
                    COND = 2;
                case 3
                    COND = 1;
            end
            
            IDX = data(:,D.cond) == COND & data(:, D.correct(CURSOR) ) == 1;
            resH(CURSOR) = mean(data(IDX, D.MT(CURSOR)));
            
        end
         
        results.MT(SESSION,:) = res;
        results.MT_hypothetical(SESSION,:) = resH;
        
        %% ---- RT
tic
        
        for COND = 1:2
            for CURSOR = 1:3
                IDX =   data(:,D.cond) == COND & ...
                        data(:,D.correct(CURSOR)) == 1;
                %IDX =   data(:,D.cond) == COND;
                              
                results.RT(SESSION,CURSOR,COND) = nanmean(data(IDX,D.RT(CURSOR))); 
   
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

veridical = [results.RT(:,1:2,1) results.RT(:,3,2)];
hypothetical = [results.RT(:,1:2,2) results.RT(:,3,1)];

% for SESSION = 1:number_of_sessions
%     veridical(SESSION,1:2) = sort(veridical(SESSION,1:2),'ascend');
% end

% M = mean(veridical);
% E = ws_bars(veridical);

RT_original = veridical;
RT_derived = hypothetical;


%% accuracy

veridical = results.accuracy*100;
hypothetical = results.accuracy_hypothetical*100;

TIT = 'Accuracy';
YLABEL = 'Accuracy (%)';
YLIMIT = [0 100];

veridical_versus_hypothetical(veridical, hypothetical, TIT, YLABEL, 'descend', OUT, YLIMIT)


%% MT

veridical = results.MT;
hypothetical = results.MT_hypothetical;

TIT = 'MT';
YLABEL = 'MT (ms)';
YLIMIT = [550 800];

veridical_versus_hypothetical(veridical, hypothetical, TIT, YLABEL, 'ascend', OUT, YLIMIT)


%% ----- save for statistical analysis

accuracy_original = results.accuracy*100;
accuracy_derived = results.accuracy_hypothetical*100;

MT_original = results.MT;
MT_derived = results.MT_hypothetical;

save([OUT 'cell_means.mat'], 'accuracy_original', 'accuracy_derived', 'MT_original', 'MT_derived', 'RT_original', 'RT_derived', '-v6')


%% accuracy #2 ...


rng(0)

xticklabel = {{'Mean Solo' 'Joint'}; {'Best' 'Worst' 'Joint'}};
ylimit = [0 100; 550 800];

close all


for MM = 1:2
    switch MM
        case 1
            
            veridical = results.accuracy*100;
            hypothetical = results.accuracy_hypothetical*100;
            
        case 2

            veridical = results.MT;
            hypothetical = results.MT_hypothetical;
            
    end
    
    h = figure;
    
    for PP = 1:2
        
        switch PP
            case 1
                M = [mean([mean(veridical(:,1:2),2) veridical(:,3)]) ; mean([mean(hypothetical(:,1:2),2) hypothetical(:,3)])]';
                E = [ws_bars([mean(veridical(:,1:2),2) veridical(:,3)]) ; ws_bars([mean(hypothetical(:,1:2),2) hypothetical(:,3)])]';
            case 2
                
                for SESSION = 1:number_of_sessions
                    veridical(SESSION,1:2) = sort(veridical(SESSION,1:2), 'descend');
                    hypothetical(SESSION,1:2) = sort(hypothetical(SESSION,1:2), 'descend');
                end
                
                M = [mean(veridical); mean(hypothetical)]';
                E = [ws_bars(veridical) ; ws_bars(hypothetical)]';
        end
        
        subplot(1,2,PP)
        barwitherr(E, M, 'barwidth', 1);
        hold on; set(gca,'tickdir','out', 'xticklabel', xticklabel{PP})
        xlabel('Control')
        
        if PP == 1
            
            ylabel('Accuracy (%)')
            
            N = number_of_sessions;
            
            for DD = 1:2
                switch DD
                    case 1
                        dataToUse = [mean(veridical(:,1:2),2) veridical(:,3)];
                        mod = -.15;
                    case 2
                        mod = +.15;
                        dataToUse = [mean(hypothetical(:,1:2),2) hypothetical(:,3)];
                end
                
                for CC = 1:2
                    scatter( CC*ones(N,1)+(rand(N,1)*2-1)*.075 + mod, sort(dataToUse(:,CC)), 50, 'k', '.')
                end
            end
            
        end
        
        if PP == 2
            
            for DD = 1:2
                switch DD
                    case 1
                        dataToUse = veridical;
                        mod = -.15;
                    case 2
                        mod = +.15;
                        dataToUse = hypothetical;
                end
                
                for CC = 1:3
                    scatter( CC*ones(N,1)+(rand(N,1)*2-1)*.075 + mod, sort(dataToUse(:,CC)), 25, 'k', '.')
                end
            end
            pos = [0.6976 0.8159 0.1839 0.0762]; pos(2) = pos(2) + .075;
            l = legend({'Veridical' 'Derived'}, 'location', pos, 'box', 'on')
            set(gca,'yticklabel',[])
            
        end
        
        %ylim(ylimit(MM,:))
        colormap([.75 .75 .75; 1 1 1])
        
    end
    
    
end