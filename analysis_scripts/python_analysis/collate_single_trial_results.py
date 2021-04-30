import numpy as np
import scipy.io
import mat73
import importlib
import common
importlib.reload(common)
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter
from scipy import stats
from PIL import Image

output_directory = common.set_output_directory('collate_single_trial_results\\')


## ----- data structures

class SingleTrialValues:
    control_codes = None
    accuracy = None
    RT = None
    MT = None
    curvature = None
    endpoint_displacement = None
    gaze_distance = None
    behavioral_coupling = None
    task_cue = None
    neural_coupling = None


class CorrelationsWithNeuralCoupling:
    accuracy = None
    RT = None
    MT = None
    curvature = None
    endpoint_displacement = None
    gaze_distance = None
    behavioral_coupling = None
    task_cue = None


common.populate_class(SingleTrialValues, [common.Number.trials, common.Number.sessions])
common.populate_class(CorrelationsWithNeuralCoupling, [common.Number.sessions, common.Number.control])


class Cursors:
    accuracy = None
    MT = None
    RT = None
    curvature = None
    endpoint_displacement = None


common.populate_class(Cursors, [common.Number.trials, common.Number.cursors, common.Number.sessions])


class Data:
    filenames = scipy.io.loadmat(file_name="..\\data_manager\\CheckFiles2\\fname.mat")
    endpoints = scipy.io.loadmat(file_name="..\\behavioural_performance\\endpoint_accuracy\\results.mat")


## ----- get control codes

exclude_gaze_sessions = [0, 1, 2]

SingleTrialValues.gaze_distance = scipy.io.loadmat(file_name='eye_single_trial\gaze_results.mat')['gaze_distance']
SingleTrialValues.gaze_distance[:, exclude_gaze_sessions] = np.nan

SingleTrialValues.behavioral_coupling = scipy.io.loadmat(file_name="..\\behavioural_performance\\accuracy3\\behavioral_coupling.mat")['behavioral_coupling']
SingleTrialValues.task_cue = mat73.loadmat(filename="..\\EEG_task_cue\\task_cue_single_trial\\task_cue_single_trial.mat")["task_cue_single_trial"]
SingleTrialValues.neural_coupling = mat73.loadmat("..\\EEG_synchrony\\partPermutation2\\results.mat")["results"]["coupling"]

control_eye = scipy.io.loadmat(file_name='eye_single_trial\gaze_results.mat')['control'].astype(int)

for SESSION in range(0, common.Number.sessions):

    common.print_stars()
    print(SESSION)

    filename = Data.filenames['fname']['direct_behav'][0, 0][0] + Data.filenames['fname']['behave'][0, 0][SESSION][0][0]
    print(filename)

    mat2 = scipy.io.loadmat(file_name=filename)
    data = mat2['data']

    SingleTrialValues.control_codes[:, SESSION] = data[:, common.D.cond]

    Cursors.accuracy[:, :, SESSION] = data[:, common.D.correct]
    Cursors.MT[:, :, SESSION] = data[:, common.D.MT]
    Cursors.RT[:, :, SESSION] = data[:, common.D.RT]

    filename = "..\\behavioural_performance\\curvature_runner\\" + common.Labels.session2[SESSION] + ".curvature_results.mat"
    Cursors.curvature[:, :, SESSION] = mat73.loadmat(filename)['curvature_results']

    Cursors.endpoint_displacement[:, :, SESSION] = Data.endpoints['results']['endpoint_displacement'][SESSION][0]

    # for measures with three cursors on each trial, get mean of solo on solo trials; get joint cursor on joint trials

    for TRIAL in range(0, common.Number.trials):

        players_to_use = common.players[SingleTrialValues.control_codes[TRIAL, SESSION].astype(int)-1]

        SingleTrialValues.endpoint_displacement[TRIAL, SESSION] = np.nanmean(Cursors.endpoint_displacement[TRIAL, players_to_use, SESSION])
        SingleTrialValues.curvature[TRIAL, SESSION] = np.nanmean(Cursors.curvature[TRIAL, players_to_use, SESSION])
        SingleTrialValues.accuracy[TRIAL, SESSION] = np.nanmean(Cursors.accuracy[TRIAL, players_to_use, SESSION])
        SingleTrialValues.MT[TRIAL, SESSION] = np.nanmean(Cursors.MT[TRIAL, players_to_use, SESSION])
        SingleTrialValues.RT[TRIAL, SESSION] = np.nanmean(Cursors.RT[TRIAL, players_to_use, SESSION])

    # correlate with neural coupling

    df = pd.DataFrame({'control': SingleTrialValues.control_codes[:, SESSION],
                      'accuracy': SingleTrialValues.accuracy[:, SESSION],
                      'RT': SingleTrialValues.RT[:, SESSION],
                      'MT': SingleTrialValues.MT[:, SESSION],
                      'curvature': SingleTrialValues.curvature[:, SESSION],
                      'endpoint_displacement': SingleTrialValues.endpoint_displacement[:, SESSION],
                      'gaze_distance': SingleTrialValues.gaze_distance[:, SESSION],
                      'behavioral_coupling': SingleTrialValues.behavioral_coupling[:, SESSION],
                      'task_cue': SingleTrialValues.task_cue[:, SESSION],
                      'neural_coupling': SingleTrialValues.neural_coupling[:, SESSION]})

    for CONTROL in range(0, common.Number.control):
        print(CONTROL)

        index = df.control == CONTROL + 1
        results = df[index].corr().neural_coupling[1:-1]

        CorrelationsWithNeuralCoupling.accuracy[SESSION, CONTROL] = results.accuracy
        CorrelationsWithNeuralCoupling.RT[SESSION, CONTROL] = results.RT
        CorrelationsWithNeuralCoupling.MT[SESSION, CONTROL] = results.MT
        CorrelationsWithNeuralCoupling.curvature[SESSION, CONTROL] = results.curvature
        CorrelationsWithNeuralCoupling.endpoint_displacement[SESSION, CONTROL] = results.endpoint_displacement
        CorrelationsWithNeuralCoupling.gaze_distance[SESSION, CONTROL] = results.gaze_distance
        CorrelationsWithNeuralCoupling.behavioral_coupling[SESSION, CONTROL] = results.behavioral_coupling
        CorrelationsWithNeuralCoupling.task_cue[SESSION, CONTROL] = results.task_cue


## plot results

plt.close('all')

common.Labels.measure = ['Accuracy', 'RT', 'MT', 'Cuvature', 'Displacement', 'Gaze Distance', 'Behavioral Coupling', 'Task Cue']

measures = [CorrelationsWithNeuralCoupling.accuracy,
            CorrelationsWithNeuralCoupling.RT,
            CorrelationsWithNeuralCoupling.MT,
            CorrelationsWithNeuralCoupling.curvature,
            CorrelationsWithNeuralCoupling.endpoint_displacement,
            CorrelationsWithNeuralCoupling.gaze_distance,
            CorrelationsWithNeuralCoupling.behavioral_coupling,
            CorrelationsWithNeuralCoupling.task_cue]

figure_list = []
y_limits = common.np_nan([len(measures), 2])
y_limit_to_use = 0.10847384173267931

for MEASURE in range(0, len(measures)):
    
    common.print_stars()
    print(common.Labels.measure[MEASURE])

    r = measures[MEASURE]
    r = r[~((np.isnan(r[:, 0])) | (np.isnan(r[:, 1]))), :]  # remove nans

    results1 = scipy.stats.ttest_1samp(r, 0)
    results2 = scipy.stats.ttest_rel(r[:, 0], r[:, 1])
    
    figure, axes = plt.subplots()

    axes.bar(x=[0, 1], height=np.nanmean(r, axis=0), yerr=common.ws_bars(r), color=[.75, .75, .75])
    axes.set_xticks(ticks=[0, 1])
    axes.set_xticklabels(labels=common.Labels.control)
    axes.set_xlabel("Control")
    axes.set_ylabel("Corr. with Neural Coupling (r)")
    axes.set_title(common.Labels.measure[MEASURE])
    axes.annotate('%.3f' % results2[1], (.5, np.nanmean(r, axis=0).mean()))
    axes.yaxis.set_major_formatter(FormatStrFormatter('%.2f'))

    y_limits[MEASURE, :] = plt.ylim()
    plt.ylim([-y_limit_to_use, +y_limit_to_use])

    for CONTROL in range(0, common.Number.control):
        axes.annotate('%.3f' % results1[1][CONTROL], ([0, 1][CONTROL], np.nanmean(r, axis=0)[CONTROL]))

    figure.savefig(output_directory + common.Labels.measure[MEASURE] + ".png")

    figure_list.append(Image.open(output_directory + common.Labels.measure[MEASURE] + ".png"))

common.get_concat_tile_resize([[figure_list[0], figure_list[1]],
                               [figure_list[2], figure_list[3]],
                               [figure_list[4], figure_list[5]],
                               [figure_list[6], figure_list[7]]]).save(output_directory + 'single_trial_correlations.png')

y_limit_to_use = np.max(np.abs(y_limits))


## save results

np.savez(file=output_directory + 'CorrelationsWithNeuralCoupling.npz',
         accuracy=CorrelationsWithNeuralCoupling.accuracy,
         RT=CorrelationsWithNeuralCoupling.RT,
         MT=CorrelationsWithNeuralCoupling.MT,
         curvature=CorrelationsWithNeuralCoupling.curvature,
         endpoint_displacement=CorrelationsWithNeuralCoupling.endpoint_displacement,
         gaze_distance=CorrelationsWithNeuralCoupling.gaze_distance,
         behavioral_coupling=CorrelationsWithNeuralCoupling.behavioral_coupling,
         task_cue=CorrelationsWithNeuralCoupling.task_cue)

np.savez(file=output_directory + 'SingleTrialValues.npz',
         neural_coupling=SingleTrialValues.neural_coupling,
         accuracy=SingleTrialValues.accuracy,
         RT=SingleTrialValues.RT,
         MT=SingleTrialValues.MT,
         curvature=SingleTrialValues.curvature,
         endpoint_displacement=SingleTrialValues.endpoint_displacement,
         gaze_distance=SingleTrialValues.gaze_distance,
         behavioral_coupling=SingleTrialValues.behavioral_coupling,
         task_cue=SingleTrialValues.task_cue,
         control_codes=SingleTrialValues.control_codes)
