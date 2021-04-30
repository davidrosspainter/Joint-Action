close all; clear; restoredefaultpath

addpath('..\external')
addpath('..\common')

generate_global_variables

IN = '..\data_manager\CheckFiles2\';
load( [IN 'fname.mat'] )

p = mfilename('fullpath');
[~, OUT, ~] = fileparts(p);
OUT = [OUT '\']; mkdir(OUT); disp(OUT)

is_figure_visible = 'off';
is_load_fresh = false;


if is_load_fresh
    get_linear_regression_fit('veridical', OUT)
    get_linear_regression_fit('hypothetical', OUT)
end


%% load saved data

YLIMIT = [.35, .75];

close all
Original = plot_regression_fit('veridical', OUT, YLIMIT, [0.9, 0.9, 0.9]);
Reversed = plot_regression_fit('hypothetical', OUT, YLIMIT, [0.5, 0.5, 0.5]);

Original = Original';
Reversed = Reversed';

save([OUT 'linearRegressionFit.mat'], 'Original', 'Reversed', '-v6')