import time
import numpy as np
import scipy.io
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use("Qt5Agg")
import importlib
import common
importlib.reload(common)
import pandas as pd
from scipy import stats

output_directory = common.set_output_directory('eye_single_trial\\')

is_generate_heatmaps_and_distance = True

x_edges = np.arange(start=-13, stop=+13, step=.1)
y_edges = np.arange(start=-13, stop=+13, step=.1)

epoch_length1 = 2.5
limit_seconds1 = [[-epoch_length1, 0], [0, +epoch_length1]]
common.Number.frames1 = int(epoch_length1*common.FS.eye)

plt.hot()


def generate_subject_code():

    subject_code = np.empty([common.Number.subjects, 3])
    subject_code[:] = np.nan
    
    for SESSION in range(0, common.Number.sessions):
        for PLAYER in range(0, common.Number.players):
            SUBJECT = PLAYER + SESSION*2
            subject_code[SUBJECT, 0] = SUBJECT
            subject_code[SUBJECT, 1] = SESSION
            subject_code[SUBJECT, 2] = PLAYER

    subject_code = subject_code.astype('int')

    subject_code = pd.DataFrame({'subject': subject_code[:, 0],
                                 'session': subject_code[:, 1],
                                 'player': subject_code[:, 2]})

    return subject_code


subject_code = generate_subject_code()


def gaze_heatmap(limit_seconds=[0, 2.5], label="", is_save=False, triggers=None, latency_index=None, GAZE=None):

    index = np.where(np.in1d(triggers, common.Trigger.task_cue))[0]

    limit_frames = np.multiply(limit_seconds, common.FS.eye).astype(int)
    number_frames = limit_frames[1] - limit_frames[0]

    start_index = latency_index[index+1] + limit_frames[0]
    stop_index = latency_index[index+1] + limit_frames[1]

    gaze = np.empty([number_frames, common.Number.axes, common.Number.trials])

    for TRIAL in range(0, common.Number.trials):
        gaze[:, :, TRIAL] = GAZE[start_index[TRIAL]:stop_index[TRIAL], :] * common.dpp

    x = gaze[:, 0, :].flatten() - np.nanmean(gaze[:, 0, :].flatten())
    y = gaze[:, 1, :].flatten() - np.nanmean(gaze[:, 1, :].flatten())

    H = np.histogram2d(x, y, bins=[x_edges, y_edges], density=True)

    plot_heatmap(H[0], label)

    return H[0], gaze


def plot_heatmap(histogram_data, label, is_save=False):
    figure, axis = plt.subplots()
    image = axis.imshow(histogram_data, interpolation='nearest', aspect='equal', extent=[x_edges[0], x_edges[-1], y_edges[0], y_edges[-1]])
    axis.autoscale(False)
    figure.colorbar(image)
    axis.set_xlabel('x')
    axis.set_ylabel('y')
    axis.set_title(label)

    if is_save:
        figure.savefig(output_directory + label + '.png')


## get mean movement endpoint frame

#  0.4524 + 0.6628 = 1.1152 // original RT+MT but derivation lost?
mat = scipy.io.loadmat("..\\behavioural_performance\\accuracy2_coordination2\\cell_means.mat")


class BehaviouralResults:
    MT = None
    RT = None


class TimePoint:
    seconds = None
    fs = None
    frames = None

    def __init__(self, seconds, fs):
        self.seconds = seconds
        self.fs = fs
        self.frames = int(seconds*fs)
        print(self.frames)


common.populate_class(BehaviouralResults, [common.Number.sessions, common.Number.control])

mat['RT_original'][:, 0:1].mean() + mat['MT_original'].mean()

for CONTROL in range(0, common.Number.control):
    BehaviouralResults.RT[:, CONTROL] = mat['RT_original'][:, common.players[CONTROL]].mean(axis=1)
    BehaviouralResults.MT[:, CONTROL] = mat['MT_original'][:, common.players[CONTROL]].mean(axis=1)

movement_offset = TimePoint(seconds=(BehaviouralResults.RT.mean(axis=1).mean() + BehaviouralResults.MT.mean(axis=1).mean())/1000,
                            fs=common.FS.eye)


# 50% of action time
print(movement_offset.seconds*.5)

common.stop()



## extract data

start = time.time()

H = np.empty([len(y_edges)-1, len(x_edges)-1, common.Number.movement_epochs, common.Number.subjects])
H[:] = np.nan

gaze = np.empty([common.Number.frames1, common.Number.axes, common.Number.trials, common.Number.movement_epochs, common.Number.subjects])
gaze[:] = np.nan

distance = np.empty([common.Number.control, common.Number.movement_epochs, common.Number.sessions])
distance[:] = np.nan

control = np.empty([common.Number.trials, common.Number.sessions])
control[:] = np.nan
trial_gaze_distance = np.empty([common.Number.trials, common.Number.sessions])
trial_gaze_distance[:] = np.nan

for SESSION in np.array(range(0, 20)):

    common.print_stars()
    print(SESSION)

    if SESSION == 1:
        print('missing eye data...')
        continue

    plt.close('all')
    figure1, axes1 = plt.subplots(1, 2)
    figure2, axes2 = plt.subplots(1, 2)

    control_triggers = np.empty([common.Number.trials, common.Number.players])
    control_triggers[:] = np.nan

    for PLAYER in range(0, common.Number.players):

        SUBJECT = PLAYER + SESSION*2
        print(SUBJECT)

        filename = '..\\eye_tracking\\preprocess_eye_data2\\' + common.Labels.session[SESSION] + '.' + common.Labels.player[PLAYER] + ".processedEye.mat"
        print(filename)
        mat = scipy.io.loadmat(file_name=filename)  # 'samples', 'GAZE', 'PUPIL', 'type'

        samples = mat['samples']
        eye_time = mat['samples'][:, 0]/1000000 - mat['samples'][0, 0]/1000000  # seconds starting at zero
        GAZE = mat['GAZE']

        triggers = mat['type'].squeeze()
        latency_index = mat['latency_index'].squeeze()

        index = np.where(np.in1d(triggers, common.Trigger.task_cue))[0]
        control_triggers[:, PLAYER] = triggers[index] - 2

        axes1[PLAYER].plot(eye_time/60, GAZE[:, 0], linewidth=.5)
        axes1[PLAYER].plot(eye_time/60, GAZE[:, 1], linewidth=.5)
        axes1[PLAYER].legend(['x', 'y'])
        axes1[PLAYER].set_xlabel('Time (minutes)')
        axes1[PLAYER].set_ylabel('Pixels')
        axes1[PLAYER].set_title(common.Labels.player[PLAYER])

        markerline, stemlines, baseline = axes2[PLAYER].stem(eye_time[latency_index]/60, triggers)
        plt.setp(stemlines, 'linewidth', .1)

        axes2[PLAYER].set_xlabel('Time (minutes)')
        axes2[PLAYER].set_ylabel('Trigger Value')
        axes2[PLAYER].set_title(common.Labels.player[PLAYER])

        for EPOCH in range(0, common.Number.movement_epochs):
            H[:, :, EPOCH, SUBJECT], gaze[:, :, :, EPOCH, SUBJECT] = gaze_heatmap(limit_seconds=limit_seconds1[EPOCH],
                                                                                  label=common.Labels.session[SESSION] + '.' + common.Labels.player[PLAYER] + "." + common.Labels.epoch[EPOCH],
                                                                                  is_save=True,
                                                                                  triggers=triggers,
                                                                                  latency_index=latency_index,
                                                                                  GAZE=GAZE)

    figure1.suptitle(common.Labels.session[SESSION-1] + ".data")
    figure1.savefig(output_directory + common.Labels.session[SESSION-1] + ".data.png")

    figure2.suptitle(common.Labels.session[SESSION-1] + ".triggers")
    figure2.savefig(output_directory + common.Labels.session[SESSION-1] + ".triggers.png")

    if np.all(control_triggers[:, 0] == control_triggers[:, 1]):
        print('aligned...')
    else:
        raise Exception('misaligned!')

    # ----- distances

    subject_to_use = np.array(subject_code[subject_code.session == SESSION].subject)

    M = np.empty([common.Number.control, common.Number.movement_epochs])
    M[:] = np.nan
    E = np.empty([common.Number.control, common.Number.movement_epochs])
    E[:] = np.nan

    figure1, axes1 = plt.subplots(1, 2)

    for EPOCH in range(0, common.Number.movement_epochs):
        # gaze_distance = np.empty([common.Number.frames, common.Number.trials])
        gaze_distance = np.sqrt(np.square(gaze[:, 0, :, EPOCH, subject_to_use[0]] - gaze[:, 0, :, EPOCH, subject_to_use[1]]) +
                                np.square(gaze[:, 1, :, EPOCH, subject_to_use[0]] - gaze[:, 1, :, EPOCH, subject_to_use[1]]))

        for CONTROL in range(0, common.Number.control):
            index = control_triggers[:, 0] == CONTROL + 1
            M[CONTROL, EPOCH] = np.nanmean(np.nanmean(gaze_distance[:, index], axis=0))
            E[CONTROL, EPOCH] = np.nanstd(np.nanmean(gaze_distance[:, index], axis=0))/np.sqrt(common.Number.trials/2)

        axes1[EPOCH].bar(x=[0, 1], height=M[:, EPOCH], yerr=E[:, EPOCH])
        axes1[EPOCH].set_xticks(ticks=[0, 1])
        axes1[EPOCH].set_xticklabels(labels=common.Labels.control)
        axes1[EPOCH].set_xlabel("Control")
        axes1[EPOCH].set_ylabel("Inter-Gaze Distance (°)")
        axes1[EPOCH].set_title(common.Labels.epoch[EPOCH])

    figure1.suptitle(common.Labels.session[SESSION-1] + ".distance")
    figure1.savefig(output_directory + common.Labels.session[SESSION-1] + ".distance.png")

    distance[:, :, SESSION] = M

    # results for single trial analyses

    #tmp = np.nanmean(gaze_distance, axis=0)  # mean across all frames
    trial_gaze_distance[:, SESSION] = gaze_distance[movement_offset.frames, :]  # value at movement offset

    tmp = control_triggers[:, 0]
    control[:, SESSION] = tmp

scipy.io.savemat(file_name=output_directory + "gaze_results.mat",
                 mdict={'gaze_distance': trial_gaze_distance, 'control': control})


## mean heatmaps

plt.close('all')

# one session was excluded for missing data for both players; two additional sessions were excluded for inaccurate eye tracking results determined by the gaze heat maps

# recordings_to_exclude = np.array([[0, 1],
#                                   [1, 0],
#                                   [1, 1],
#                                   [2, 1],
#                                   [6, 1],
#                                   [13, 0]])

recordings_to_exclude = np.array([[0, 1],
                                  [1, 0],
                                  [1, 1],
                                  [2, 1]])

recordings_to_exclude = np.concatenate((np.reshape(recordings_to_exclude[:, 1] + recordings_to_exclude[:, 0]*2, (recordings_to_exclude.shape[0], 1)), recordings_to_exclude), axis=1)

recordings_to_exclude = pd.DataFrame({'subject': recordings_to_exclude[:, 0],
                                      'session': recordings_to_exclude[:, 1],
                                      'player': recordings_to_exclude[:, 2]})

for index, RECORDING in recordings_to_exclude.iterrows():
    print(index)
    label = RECORDING.subject.__str__() + "." + RECORDING.session.__str__() + "." + RECORDING.player.__str__()
    plot_heatmap(H[:, :, 1, RECORDING.subject], label, False)

recordings_to_use = np.array(range(0, common.Number.subjects))
recordings_to_use = recordings_to_use[~np.in1d(recordings_to_use, recordings_to_exclude.subject)]

mean_H = np.nanmean(H[:, :, :, recordings_to_use], axis=3)

for EPOCH in range(0, common.Number.movement_epochs):
    plot_heatmap(mean_H[:, :, EPOCH], common.Labels.epoch[EPOCH], is_save=True)

np.savez(file=output_directory + 'mean_H.npz', mean_H=mean_H, x_edges=x_edges, y_edges=y_edges)

## colormap export for r

hot = matplotlib.cm.get_cmap('hot')

intensity = np.linspace(0, 1, 256)
rgba = hot(intensity)

np.savez(file=output_directory + 'rgba.npz', rgba=rgba)

stop = time.time()
print((stop-start)/60)

## gaze distance

sessions_to_use = np.array(range(0, common.Number.sessions))
sessions_to_use = sessions_to_use[~np.in1d(sessions_to_use, recordings_to_exclude.session.unique())]

distance_to_use = distance[:, :, sessions_to_use]
M = np.nanmean(distance_to_use, axis=2)
E = np.nanstd(distance_to_use, axis=2)/np.sqrt(distance_to_use.shape[2])

figure1, axes1 = plt.subplots(1, 2)

for EPOCH in range(0, common.Number.movement_epochs):
    common.print_stars()
    print(common.Labels.epoch[EPOCH])

    axes1[EPOCH].bar(x=[0, 1], height=M[:, EPOCH], yerr=E[:, EPOCH])
    axes1[EPOCH].set_xticks(ticks=[0, 1])
    axes1[EPOCH].set_xticklabels(labels=common.Labels.control)
    axes1[EPOCH].set_xlabel("Control")
    axes1[EPOCH].set_ylabel("Inter-Gaze Distance (°)")
    axes1[EPOCH].set_title(common.Labels.epoch[EPOCH])

    epoch_data = np.transpose(distance_to_use[:, EPOCH, :])

    result = stats.ttest_rel(epoch_data[:, 0], epoch_data[:, 1])
    print(np.mean(epoch_data, axis=0))
    print(result)

figure1.suptitle("distance")
figure1.savefig(output_directory + common.Labels.session[SESSION-1] + "distance.png")

np.savez(file=output_directory + 'distance_to_use.npz', distance_to_use=distance_to_use)
