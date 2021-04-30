function veridical_versus_hypothetical(veridical, hypothetical, TIT, YLABEL, sort_string, OUT, YLIMIT)

disp('##############################################')
disp('##############################################')
disp('##############################################')
disp('##############################################')
disp('##############################################')
disp(TIT)

close all
veridical_sorted = plotter(veridical, YLIMIT, TIT, YLABEL, OUT, [0.9, 0.9, 0.9], sort_string);
hypothetical_sorted = plotter(hypothetical, YLIMIT, [TIT ' Hypothetical'], YLABEL, OUT, [0.5, 0.5, .5], sort_string);

% veridical vs. hypothetical
disp('veridical vs. hypothetical ... mean solo ....')
[~, p, ~, ~] = ttest(mean(veridical(:,1:2), 2), mean(hypothetical(:,1:2), 2)); disp(p)
disp('veridical vs. hypothetical ... joint ....')
[~, p, ~, ~] = ttest(veridical(:,3), hypothetical(:,3)); disp(p)
disp('veridical vs. hypothetical ... best ....')
[~, p, ~, ~] = ttest(veridical_sorted(:,1), hypothetical_sorted(:,1)); disp(p)
disp('veridical vs. hypothetical ... worst ....')
[~, p, ~, ~] = ttest(veridical_sorted(:,2), hypothetical_sorted(:,2)); disp(p)

% control effect
disp('veridical vs. hypothetical ... mean control effect ....')
[~, p, ~, ~] = ttest( diff([mean(veridical(:,1:2), 2) veridical(:,3)], [], 2), diff([mean(hypothetical(:,1:2), 2) hypothetical(:,3)], [], 2) ); disp(p)

for PLAYER = 1:2
    disp([ 'veridical vs. hypothetical control effect .... PLAYER = ' num2str(PLAYER)])
    [~, p, ~, ~] = ttest( diff([veridical_sorted(:,PLAYER) veridical_sorted(:,3)], [], 2), diff([hypothetical_sorted(:,PLAYER) hypothetical_sorted(:,3)], [], 2) ); disp(p)
    disp([ 'veridical control effect .... PLAYER = ' num2str(PLAYER)])
    [~, p, ~, ~] = ttest( diff([veridical_sorted(:,PLAYER) veridical_sorted(:,3)], [], 2)); disp(p)
    disp([ 'hypothetical control effect .... PLAYER = ' num2str(PLAYER)])
    [~, p, ~, ~] = ttest( diff([hypothetical_sorted(:,PLAYER) hypothetical_sorted(:,3)], [], 2)); disp(p)
end