import mat73
import scipy.io
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from PIL import Image

import common

output_directory = '..//JointActionStatisticsR2//supplementary_data//'

##

def generate_csv_from_mat(filename):
    mat = mat73.loadmat(output_directory + filename)

    columns = mat['columns']
    rows = mat['rows']
    data = mat['data']

    if np.array_equal(rows, [0, 0]):
        df = pd.DataFrame(data, columns=columns)
    else:
        newRows = []

        if np.shape(rows).__len__() > 1:
            for i in range(0, len(rows)):
                newRows.append(rows[i][0])
        else:
            newRows = rows

        df = pd.DataFrame(data, columns=columns, index=newRows)

    df.to_csv(output_directory + filename.split(".mat")[0] + ".csv")

    return df


def plot_movie_frame(df):
    index = df.target_position.astype(int)

    plt.figure()
    plt.style.use('dark_background')
    plt.scatter(df.cursor_x, df.cursor_y, color=common.colors[index], marker="s", s=10)
    plt.scatter(df.player1_gaze_x, df.player1_gaze_y, edgecolors=common.colors[index], marker="o", facecolors='none',
                s=20)
    plt.scatter(df.player2_gaze_x, df.player2_gaze_y, edgecolors=common.colors[index], marker="o", facecolors='none',
                s=20)
    plt.axis('square')

    plt.xlabel('x (°)')
    plt.ylabel('y (°)')

    limit = 1080 / 2
    plt.xlim([-limit, +limit])
    plt.ylim([-limit, +limit])

    plt.title("Fig. 4f.csv")
    plt.savefig(output_directory + "Fig. 4f.csv.png")

    plt.style.use('default')


def get_movie_frame():
    common.Number.frames = 300
    filename = "cursor_gaze_movie\\CD_results.bin"
    CD_results = common.load_data(filename=filename)  # cursor data

    ##

    FRAME = 68
    SESSION = 9
    CONTROL = 1

    gaze = CD_results[SESSION][CONTROL].gaze[FRAME, :, :, :]  # (2, 480, 2)
    player1_gaze_x = gaze[0, :, 0]
    player1_gaze_y = gaze[1, :, 0]
    player2_gaze_x = gaze[0, :, 1]
    player2_gaze_y = gaze[1, :, 1]

    target_position = CD_results[SESSION][CONTROL].target_position  # (480, )

    cursor = CD_results[SESSION][CONTROL].cursor_xy2[:, FRAME, :, 2]  # (2, 480)
    cursor_x = np.transpose(cursor[0, :])
    cursor_y = np.transpose(cursor[1, :])

    data = np.array(np.transpose(
        [target_position, cursor_x, cursor_y, player1_gaze_x, player1_gaze_y, player2_gaze_x, player2_gaze_y]))

    df = pd.DataFrame(data, columns=['target_position', 'cursor_x', 'cursor_y', 'player1_gaze_x', 'player1_gaze_y',
                                     'player2_gaze_x', 'player2_gaze_y'])

    df.to_csv(output_directory + "Fig. 4f.csv")
    plot_movie_frame(df)


def convert_matfiles():
    filenames = ["Fig. 7d.mat",
                 "Fig. 6b - upper.mat",
                 "Fig. 6b - lower.mat",
                 'Fig. 6d.mat',
                 'Fig. 4e.mat',
                 'Fig. 8b.mat',
                 'Fig. 8c.mat',
                 'Fig. 8d.mat',
                 'Fig. 8f.mat',
                 'Fig. 8e.mat',
                 'Fig. 8i.mat',
                 'Fig. 8h - inset.mat',
                 'Fig. 8h.mat']

    df_dictionary = {}

    for filename in filenames:
        df_dictionary[filename] = generate_csv_from_mat(filename)


def endpoint_plot(df_endpoint):
    control_dictionary = {'HP_Solo': ['endpoint_HP_solo_x', 'endpoint_HP_solo_y'],
                          'LP_Solo': ['endpoint_LP_solo_x', 'endpoint_LP_solo_y'],
                          'Joint': ['endpoint_Joint_x', 'endpoint_Joint_y']}

    control_visibility_dictionary = {'HP_Solo Visible': 'Solo',
                                     'HP_Solo Invisible': 'Joint',
                                     'LP_Solo Visible': 'Solo',
                                     'LP_Solo Invisible': 'Joint',
                                     'Joint Visible': 'Joint',
                                     'Joint Invisible': 'Solo'}

    figure, axes = plt.subplots(len(common.Labels.visibility), len(common.Labels.control2))

    for CONTROL in common.Control2:
        for VISIBILITY in common.Visibility:
            title = CONTROL.name + " " + VISIBILITY.name
            # print(title)

            index = df_endpoint.control == control_visibility_dictionary[title]
            data = df_endpoint[index]

            plt.axes(axes[VISIBILITY.value, CONTROL.value])
            plt.scatter(data[control_dictionary[CONTROL.name][0]], data[control_dictionary[CONTROL.name][1]],
                        c=common.colors[data.target_position.astype(int) - 1], s=1)
            plt.title(title)
            plt.xlim([-13, +13])
            plt.ylim([-13, +13])

            plt.xlabel('x (°)')
            plt.ylabel('y (°)')

    plt.suptitle("Fig. 3c.csv")
    plt.tight_layout()
    plt.savefig(output_directory + "Fig. 3c.csv.png")


def trajectory_plot(df_trajectory):
    control_dictionary2 = {'HP_Solo': ['trajectory_HP_solo_x', 'trajectory_HP_solo_y'],
                           'LP_Solo': ['trajectory_LP_solo_x', 'trajectory_LP_solo_y'],
                           'Joint': ['trajectory_Joint_x', 'trajectory_Joint_y']}

    control_visibility_dictionary = {'HP_Solo Visible': 'Solo',
                                     'HP_Solo Invisible': 'Joint',
                                     'LP_Solo Visible': 'Solo',
                                     'LP_Solo Invisible': 'Joint',
                                     'Joint Visible': 'Joint',
                                     'Joint Invisible': 'Solo'}

    figure, axes = plt.subplots(len(common.Labels.visibility), len(common.Labels.control2))

    for CONTROL in common.Control2:
        for VISIBILITY in common.Visibility:
            title = CONTROL.name + " " + VISIBILITY.name
            # print(title)

            index = df_trajectory.control == control_visibility_dictionary[title]
            data = df_trajectory[index]

            plt.axes(axes[VISIBILITY.value, CONTROL.value])
            x, y = data[control_dictionary2[CONTROL.name][0]].astype(float), data[
                control_dictionary2[CONTROL.name][1]].astype(float)
            index = (np.isnan(x)) | (np.isnan(y)) | (x == 0) | (y == 0)
            x = x[~index]
            y = y[~index]

            x_edges = np.arange(-13, +13.1, .5)
            y_edges = np.arange(-13, +13.1, .5)

            H, x_edges, y_edges = np.histogram2d(x, y, bins=(
                x_edges, y_edges))  # histogram is more efficient and better scientifically than scatter and line plots
            H = H / H.sum()  # convert to proportion

            im = plt.imshow(H, interpolation='nearest', origin='lower',
                            extent=[x_edges[0], x_edges[-1], y_edges[0], y_edges[-1]],
                            cmap='hot')
            plt.clim(np.percentile(H, 1), np.percentile(H, 95))

            plt.title(title)
            plt.xlim([-13, +13])
            plt.ylim([-13, +13])
            plt.xlabel('x (°)')
            plt.ylabel('y (°)')

    plt.suptitle("Fig. 3a.csv")
    plt.tight_layout()
    plt.savefig(output_directory + "Fig. 3a.csv.png")


def export_endpoints_and_trajectories():
    results_mat = scipy.io.loadmat("..\\behavioural_performance\\endpoint_accuracy\\results.mat")
    curvature_mat = scipy.io.loadmat("..\\behavioural_performance\\curvature_runner\\collated_curvature_results.mat")

    collated_curvature_results = curvature_mat['collated_curvature_results']  # (960, 3, 20)

    # print(collated_curvature_results.shape)

    def get_endpoints_and_trajectories(SESSION, verbose=False):

        session = np.repeat(SESSION + 1, common.Number.trials)  # (960,)
        trial = np.array((range(1, common.Number.trials + 1)))  # (960,)

        control = results_mat['results'][SESSION]['control'][0].flatten()  # (960,)
        control = np.array(control, dtype=object)

        control[control == 1] = common.Labels.control[0]
        control[control == 2] = common.Labels.control[1]

        target_position = results_mat['results'][SESSION]['target_position'][0].flatten()  # (960,)
        endpoint = results_mat['results'][SESSION]['endpoint'][0]  # (2, 960, 3)
        endpoint_displacement = results_mat['results'][SESSION]['endpoint_displacement'][0]  # (960, 3)
        trajectory = results_mat['results'][SESSION]['trajectory'][0]  # (2, 1008, 960, 3)

        # sort by best performer on endpoint displacement
        for TRIAL in range(1, common.Number.trials):
            index = np.argsort(endpoint_displacement[TRIAL, 0:2])

            if verbose:
                print(endpoint_displacement[TRIAL, 0:2])
                print(index)

            endpoint_displacement[TRIAL, 0:2] = endpoint_displacement[TRIAL, index]
            endpoint[:, TRIAL, 0:2] = endpoint[:, TRIAL, index]

        endpoint_HP_solo_x = endpoint[0, :, 0]
        endpoint_HP_solo_y = endpoint[1, :, 0]
        endpoint_LP_solo_x = endpoint[0, :, 1]
        endpoint_LP_solo_y = endpoint[1, :, 1]
        endpoint_Joint_x = endpoint[0, :, 2]
        endpoint_Joint_y = endpoint[1, :, 2]

        columns = ['session', 'trial', 'control', 'target_position', 'endpoint_HP_solo_x', 'endpoint_HP_solo_y',
                   'endpoint_LP_solo_x', 'endpoint_LP_solo_y', 'endpoint_Joint_x', 'endpoint_Joint_y']
        data = np.transpose(np.array(
            [session, trial, control, target_position, endpoint_HP_solo_x, endpoint_HP_solo_y, endpoint_LP_solo_x,
             endpoint_LP_solo_y, endpoint_Joint_x, endpoint_Joint_y]))
        df_endpoint = pd.DataFrame(data, columns=columns)

        curvature = collated_curvature_results[:, :, SESSION]

        if SESSION == 20:
            curvature[705:common.Number.trials] = np.nan  # controller disconnected

        # sort by best performer on trajectory displacement
        for TRIAL in range(1, common.Number.trials):
            index = np.argsort(curvature[TRIAL, 0:2])
            curvature[TRIAL, 0:2] = curvature[TRIAL, index]
            trajectory[:, :, TRIAL, 0:2] = trajectory[:, :, TRIAL, index]

        trajectory_HP_solo_x = trajectory[0, :, :, 0].flatten('K')  # (2, 1008, 960, 3)
        trajectory_HP_solo_y = trajectory[1, :, :, 0].flatten('K')  # (2, 1008, 960, 3)
        trajectory_LP_solo_x = trajectory[0, :, :, 1].flatten('K')  # (2, 1008, 960, 3)
        trajectory_LP_solo_y = trajectory[1, :, :, 1].flatten('K')  # (2, 1008, 960, 3)
        trajectory_Joint_x = trajectory[0, :, :, 2].flatten('K')  # (2, 1008, 960, 3)
        trajectory_Joint_y = trajectory[1, :, :, 2].flatten('K')  # (2, 1008, 960, 3)

        session = np.repeat(SESSION + 1, common.Number.frames * common.Number.trials)  # (967680,)
        trial = np.repeat(np.array((range(1, common.Number.trials + 1))), common.Number.frames)  # (967680,)
        frame = np.resize(range(1, common.Number.frames + 1), common.Number.frames * common.Number.trials)  # (967680,)

        control = np.repeat(results_mat['results'][SESSION]['control'][0].flatten(), common.Number.frames)  # (967680,)
        control = np.array(control, dtype=object)
        control[control == 1] = common.Labels.control[0]
        control[control == 2] = common.Labels.control[1]

        target_position = np.repeat(results_mat['results'][SESSION]['target_position'][0].flatten(),
                                    common.Number.frames)  # (967680,)

        columns = ['session', 'trial', 'control', 'target_position', 'frame', 'trajectory_HP_solo_x',
                   'trajectory_HP_solo_y', 'trajectory_LP_solo_x', 'trajectory_LP_solo_y', 'trajectory_Joint_x',
                   'trajectory_Joint_y']
        data = np.transpose(np.array(
            [session, trial, control, target_position, frame, trajectory_HP_solo_x, trajectory_HP_solo_y,
             trajectory_LP_solo_x, trajectory_LP_solo_y, trajectory_Joint_x, trajectory_Joint_y]))
        df_trajectory = pd.DataFrame(data, columns=columns)

        if verbose:
            print(control.shape)
            print(target_position.shape)
            print(endpoint.shape)
            print(endpoint_displacement.shape)
            print(trajectory.shape)
            print(session.shape)
            print(trial.shape)
            print(data.shape)
            print(curvature.shape)

        return df_endpoint, df_trajectory

    df_endpoint_list = []
    df_trajectory_list = []

    for SESSION in range(0, common.Number.sessions):
        common.print_stars()
        print(SESSION)
        df_endpoint, df_trajectory = get_endpoints_and_trajectories(SESSION, False)

        df_endpoint_list.append(df_endpoint)
        df_trajectory_list.append(df_trajectory)

    df_endpoint = pd.concat(df_endpoint_list)
    df_trajectory = pd.concat(df_trajectory_list)

    df_endpoint.to_csv(output_directory + 'Fig. 3c.csv')
    df_trajectory.to_csv(output_directory + 'Fig. 3a.csv')

    ## plot endpoints

    endpoint_plot(df_endpoint)

    ## plot trajectories
    trajectory_plot(df_trajectory)


## setup

plt.close('all')
convert_matfiles()
export_endpoints_and_trajectories()

## Fig. 2
plt.close('all')
print('Fig. 2')


def control_visibility_plot(filename, ylabel):
    df = pd.read_csv(output_directory + filename)

    M = np.empty([common.Visibility.__len__(), common.Labels.control2.__len__()])
    M[:] = np.nan
    E = np.empty([common.Visibility.__len__(), common.Labels.control2.__len__()])
    E[:] = np.nan

    for CONTROL in common.Control2:
        for VISIBILITY in common.Visibility:
            # print(CONTROL.name, VISIBILITY.name)
            index = (df.Control == common.Labels.control2[CONTROL.value]) & (df.Cursor == VISIBILITY.name)
            M[VISIBILITY.value, CONTROL.value] = df.DV[index].mean()
            E[VISIBILITY.value, CONTROL.value] = df.DV[index].std() / np.sqrt(index.sum())

    x = np.array([[0, 1, 2], [0, 1, 2]])

    plt.figure()

    for i in range(0, 2):
        plt.errorbar(x=x[i, :], y=M[i, :], yerr=E[i, :])
    plt.legend(common.Labels.visibility, title='Visibility')

    plt.xticks(ticks=[0, 1, 2], labels=common.Labels.control2)
    plt.xlabel('Control')
    plt.ylabel(ylabel)
    plt.title(filename)
    plt.savefig(output_directory + filename + ".png")


control_visibility_plot('Fig. 2b.csv', 'Accuracy (%)')
control_visibility_plot('Fig. 2c.csv', 'RT (ms)')
control_visibility_plot('Fig. 2d.csv', 'MT (ms)')

## Fig. 3
plt.close('all')
print('Fig. 3')

df_trajectory = pd.read_csv(output_directory + "Fig. 3a.csv")
trajectory_plot(df_trajectory)
control_visibility_plot('Fig. 3b.csv', 'Curvature (°)')
df_endpoint = pd.read_csv(output_directory + "Fig. 3c.csv")
endpoint_plot(df_endpoint)
control_visibility_plot('Fig. 3d.csv', 'Endpoint Displacement (°)')

## Fig. 4
plt.close('all')
print('Fig. 4')


def gaze_heatmap(filename, limits):
    df = pd.read_csv(output_directory + filename)

    x = np.resize(df.x, (259, 259))
    y = np.resize(df.y, (259, 259))
    value = np.resize(df.value, (259, 259))

    plt.figure()
    im = plt.imshow(value, cmap='hot', extent=[x[:].min(), x[:].max(), y[:].min(), y[:].max()])
    cbar = plt.colorbar(im)
    cbar.ax.set_title('Prob.')

    plt.xlabel('x (°)')
    plt.ylabel('y (°)')
    plt.clim(limits[0], limits[1])

    plt.title(filename)
    plt.savefig(output_directory + filename + ".png")


gaze_heatmap("Fig. 4a.csv", [0, .70])
gaze_heatmap("Fig. 4b.csv", [0, .03])


def control_plot(filename, ylabel, ylim=None):
    df = pd.read_csv(output_directory + filename)

    M = np.empty([common.Labels.control.__len__()])
    M[:] = np.nan
    E = np.empty([common.Labels.control.__len__()])
    E[:] = np.nan

    count = 0
    for CONTROL in common.Labels.control:
        index = (df.Control == CONTROL)
        M[count] = df.DV[index].mean()
        E[count] = df.DV[index].std() / np.sqrt(index.sum())
        count = count + 1

    x = np.array([0, 1])

    plt.figure()
    plt.errorbar(x=x, y=M, yerr=E)

    plt.xticks(ticks=[0, 1], labels=common.Labels.control)
    plt.xlabel('Control')
    plt.ylabel(ylabel)
    plt.title(filename)

    if not(ylim is None):
        plt.ylim(ylim[0], ylim[1])

    plt.savefig(output_directory + filename + ".png")


control_plot("Fig. 4c.csv", 'Inter-Gaze Distance (°)')
control_plot("Fig. 4d.csv", 'Inter-Gaze Distance (°)')


##

def gaze_cusor_plot(filename):
    df = pd.read_csv(output_directory + filename)

    plt.figure()
    plt.errorbar(df.index, df.cursor_solo_mean, df.cursor_solo_SE)
    plt.errorbar(df.index, df.cursor_joint_mean, df.cursor_joint_SE)
    plt.errorbar(df.index, df.gaze_solo_mean, df.gaze_solo_SE)
    plt.errorbar(df.index, df.gaze_joint_mean, df.gaze_joint_SE)
    plt.legend(['Cursor Solo', 'Cursor Joint', 'Gaze Solo', 'Gaze Joint'], title='Point of Interest')
    plt.xlabel('Proportion of Action Time')
    plt.ylabel('Distance to Target (°)')
    plt.title(filename)
    plt.savefig(output_directory + filename + ".png")


gaze_cusor_plot("Fig. 4e.csv")

df = pd.read_csv(output_directory + "Fig. 4f.csv")
plot_movie_frame(df)

## Fig. 5
plt.close('all')
print('Fig. 5')


def control_accuracy_plot(filename, ylabel):
    df = pd.read_csv(output_directory + filename)

    M = np.empty([common.Accuracy.__len__(), common.Control.__len__()])
    M[:] = np.nan
    E = np.empty([common.Accuracy.__len__(), common.Control.__len__()])
    E[:] = np.nan

    for CONTROL in common.Control:
        for ACCURACY in common.Accuracy:
            # print(CONTROL.name, VISIBILITY.name)
            index = (df.Control == common.Labels.control[CONTROL.value]) & (df.Accuracy == ACCURACY.name)
            M[ACCURACY.value, CONTROL.value] = df.DV[index].mean()
            E[ACCURACY.value, CONTROL.value] = df.DV[index].std() / np.sqrt(index.sum())

    x = np.array([[0, 1], [0, 1]])

    plt.figure()

    for i in range(0, 2):
        plt.errorbar(x=x[i, :], y=M[i, :], yerr=E[i, :])

    plt.legend(common.Labels.accuracy, title="Accuracy")

    plt.xticks(ticks=[0, 1], labels=common.Labels.control)
    plt.xlabel('Control')
    plt.ylabel(ylabel)
    plt.title(filename)
    plt.tight_layout()
    plt.savefig(output_directory + filename + ".png")


control_accuracy_plot(filename='Fig. 5b.csv', ylabel='Displace. Correlation (r)')
control_accuracy_plot(filename='Fig. 5c.csv', ylabel='Onset Correlation (r)')
control_accuracy_plot(filename='Fig. 5d.csv', ylabel='Offset Correlation (r)')

## Fig. 6
plt.close('all')
print('Fig. 6')


def xy_plot(filename, x, y, xlim, ylim, xlabel, ylabel):
    df = pd.read_csv(output_directory + filename)
    plt.figure()
    plt.plot(df[x], df[y], 'k')
    plt.xlim(xlim)
    plt.ylim(ylim)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.suptitle(filename)
    plt.tight_layout()
    sns.despine()
    plt.savefig(output_directory + filename + ".png")


xy_plot(filename='Fig. 6a - upper.csv',
        x='frequency',
        y='amplitude',
        xlim=[2, 20],
        ylim=[0, 2.5],
        xlabel='Frequency (Hz)',
        ylabel='Amp. (μV)')

xy_plot(filename='Fig. 6a - lower.csv',
        x='time',
        y='amplitude',
        xlim=[0, 1.5],
        ylim=None,
        xlabel='Time (s)',
        ylabel='Amp. (μV)')


def SSVEP_wavelet_plot(filename, cmap, clim):
    df = pd.read_csv(output_directory + filename)

    plt.figure()
    im = plt.imshow(np.transpose(np.array(df.iloc[:, 1:-1])),
                    extent=[df['Unnamed: 0'].min(), df['Unnamed: 0'].max(), 9, 5],
                    cmap=cmap,
                    aspect='auto')

    plt.title(filename)
    plt.xlabel('Time (s)')
    plt.ylabel('Freq. (Hz)')

    plt.clim(clim)
    cbar = plt.colorbar(im)
    cbar.ax.set_title("Amp. (μV)")

    plt.tight_layout()
    plt.savefig(output_directory + filename + ".png")


SSVEP_wavelet_plot("Fig. 6b - upper.csv", 'hot_r', [0, +1.8])
SSVEP_wavelet_plot("Fig. 6b - lower.csv", 'viridis_r', [-.11, +.11])

control_plot("Fig. 6c.csv", 'SSVEP Amp. (μV)')

chanlocs = scipy.io.loadmat("..\\common\\chanlocs.mat")

columns = ['labels', 'theta', 'radius', 'X', 'Y', 'Z', 'sph_theta', 'sph_phi', 'sph_radius', 'type']
df_chanlocs = pd.DataFrame(data=[], columns=columns)

for i in range(0, chanlocs['chanlocs'][0].__len__()):
    df_chanlocs = df_chanlocs.append({
        'labels': chanlocs['chanlocs'][0][i][0][0],
        'theta': chanlocs['chanlocs'][0][i][1][0][0],
        'radius': chanlocs['chanlocs'][0][i][2][0][0],
        'X': chanlocs['chanlocs'][0][i][3][0][0],
        'Y': chanlocs['chanlocs'][0][i][4][0][0],
        'Z': chanlocs['chanlocs'][0][i][5][0][0],
        'sph_theta': chanlocs['chanlocs'][0][i][6][0][0],
        'sph_phi': chanlocs['chanlocs'][0][i][7][0][0],
        'sph_radius': chanlocs['chanlocs'][0][i][8][0][0],
        'type': chanlocs['chanlocs'][0][i][9][0][0],
    }, ignore_index=True)


def plot_topography(df, df_chanlocs, axis, variable, title=None, cmap='hot_r', cbar_title='μV'):
    ax = plt.subplot(axis, projection='3d')
    sc = ax.scatter(df_chanlocs.X, df_chanlocs.Y, df_chanlocs.Z, c=df[variable], cmap=cmap, s=100)
    cbar = plt.colorbar(sc, fraction=0.025, pad=0, ax=[ax], location='left')
    cbar.ax.set_title(cbar_title)

    plt.gca().view_init(18.31168831168884, -153.0194805194802)

    frame = plt.gca()
    frame.axes.xaxis.set_ticklabels([])
    frame.axes.yaxis.set_ticklabels([])
    frame.axes.zaxis.set_ticklabels([])

    plt.title(title)


def subplot_topographies(filename, topography_dictionary, cbar_title=None):
    df = pd.read_csv(output_directory + filename)

    for topography in topography_dictionary:
        # print(topography)

        plot_topography(df,
                        df_chanlocs,
                        axis=topography_dictionary[topography][0],
                        variable=topography,
                        title=topography_dictionary[topography][1],
                        cmap=topography_dictionary[topography][2],
                        cbar_title=cbar_title)

        plt.suptitle(filename)
        plt.savefig(output_directory + filename + '.png')


subplot_topographies(filename="Fig. 6d.csv",
                     topography_dictionary={'mean': [121, 'Mean of Solo & Joint', 'hot_r'],
                                            'Joint-Solo': [122, 'Joint-Solo', 'viridis_r']})

## Fig. 7
plt.close('all')
print('Fig. 7')

xy_plot(filename='Fig. 7a.csv',
        x='frequency',
        y='amplitude',
        xlim=[15, 21],
        ylim=[0, .8],
        xlabel='Frequency (Hz)',
        ylabel='Amp. (μV)')

xy_plot(filename='Fig. 7b.csv',
        x='frequency',
        y='amplitude',
        xlim=[15, 21],
        ylim=[0, .7],
        xlabel='Frequency (Hz)',
        ylabel='Amp. (μV)')


def control_relevance_plot(filename, ylabel):
    df = pd.read_csv(output_directory + filename)

    M = np.empty([common.Relevance.__len__(), common.Control.__len__()])
    M[:] = np.nan
    E = np.empty([common.Relevance.__len__(), common.Control.__len__()])
    E[:] = np.nan

    for CONTROL in common.Control:
        for RELEVANCE in common.Relevance:
            # print(CONTROL.name, VISIBILITY.name)
            index = (df.Control == common.Labels.control[CONTROL.value]) & (df.Relevance == RELEVANCE.name)
            # print(index.sum())
            M[RELEVANCE.value, CONTROL.value] = df.DV[index].mean()
            E[RELEVANCE.value, CONTROL.value] = df.DV[index].std() / np.sqrt(index.sum())

    x = np.array([[0, 1], [0, 1]])

    plt.figure()

    for i in range(0, 2):
        plt.errorbar(x=x[i, :], y=M[i, :], yerr=E[i, :])

    plt.legend(common.Labels.relevance, title="Relevance")

    plt.xticks(ticks=[0, 1], labels=common.Labels.control)
    plt.xlabel('Control')
    plt.ylabel(ylabel)
    plt.title(filename)
    plt.tight_layout()
    plt.savefig(output_directory + filename + ".png")


control_relevance_plot(filename="Fig. 7c.csv", ylabel='SSVEP Amplitude (μV)')

subplot_topographies(filename="Fig. 7d.csv",
                     topography_dictionary={'soloT': [221, 'Solo Target', 'hot_r'],
                                            'jointT': [222, 'Joint Target', 'hot_r'],
                                            'soloD': [223, 'Solo Distractor', 'hot_r'],
                                            'jointD': [224, 'Joint Distractor', 'hot_r']})

## Fig. 8
plt.close('all')
print('Fig. 8')


def plot_correlations_time_series(filename, cmap, clim):
    df = pd.read_csv(output_directory + filename)
    plt.figure()
    plt.imshow(np.transpose(np.array(df.iloc[:, 1:-1])), cmap=cmap,
               extent=[df.iloc[0, 0], df.iloc[-1, 0], common.Number.channels - 1, 0], aspect='auto')
    cbar = plt.colorbar()
    cbar.ax.set_title('r')
    plt.clim(clim[0], clim[1])
    plt.xlabel('Time (s)')
    plt.ylabel('Electrode')
    plt.title(filename)
    plt.savefig(output_directory + filename + ".png")


plot_correlations_time_series("Fig. 8b.csv", 'hot_r', [-.11, +.11])
plot_correlations_time_series("Fig. 8c.csv", 'hot_r', [-.11, +.11])
plot_correlations_time_series("Fig. 8d.csv", 'hot_r', [0, 1e-4 / 2])


def plot_Cz_series(filename):
    df = pd.read_csv(output_directory + filename)

    plt.close('all')
    plt.plot(df.time, df.solo)
    plt.plot(df.time, df.joint)
    plt.plot(df.time, df['joint-solo'])
    plt.plot(df.time, df.significance * .09)
    plt.xlim([-2.5, +3.0])
    plt.xlabel('Time (s)')
    plt.ylabel('Correlation (r)')
    plt.legend(['Solo', 'Joint', 'Joint-Solo', 'Significance'])
    plt.title(filename)
    plt.savefig(output_directory + filename + ".png")


plot_Cz_series("Fig. 8e.csv")

df = pd.read_csv(output_directory + "Fig. 8f.csv")

subplot_topographies(filename="Fig. 8f.csv",
                     topography_dictionary={'joint minus solo': [111, 'Joint Minus Solo', 'hot_r']},
                     cbar_title='r')

control_accuracy_plot("Fig. 8g.csv", "Inter-Brain Correlation (r)")


def action_offset_plot(filename):
    df = pd.read_csv(output_directory + filename)

    plt.figure()
    plt.errorbar(df.iloc[:, 0], df.solo_mean, df.solo_SE)
    plt.errorbar(df.iloc[:, 0], df.joint_mean, df.joint_SE)
    plt.xlim([-.5, 1.5])
    plt.ylim([-2, +2])
    plt.xlabel('Time (s)')
    plt.ylabel('EEG Amp. (μV)')
    plt.legend(['Solo', 'Joint'], title='Control')
    plt.title(filename)
    plt.savefig(output_directory + filename + ".png")


action_offset_plot("Fig. 8h.csv")


subplot_topographies(filename="Fig. 8h - inset.csv",
                     topography_dictionary={'P1': [131, 'P1', 'hot'],
                                            'N2': [132, 'P1', 'hot'],
                                            'P3': [133, 'P1', 'hot']})


def plot_action_offset_wavelet(filename, cmap, clim, xlim):
    df = pd.read_csv(output_directory + filename)
    plt.figure()
    plt.imshow(np.flipud(np.transpose(np.array(df.iloc[:, 1:-1]))), cmap=cmap,
               extent=[df.iloc[0, 0], df.iloc[-1, 0], 0, 5], aspect='auto')
    cbar = plt.colorbar()
    cbar.ax.set_title('μV')
    plt.clim(clim[0], clim[1])
    plt.xlim(xlim[0], xlim[1])
    plt.xlabel('Time (s)')
    plt.ylabel('Frequency (Hz)')
    plt.title(filename)
    plt.savefig(output_directory + filename + ".png")


plot_action_offset_wavelet(filename='Fig. 8i.csv', cmap='hot', clim=[0, 1.2], xlim=[-.5, 1.5])

## Fig. 9
plt.close('all')
print('Fig. 9')

filename_tuple_list = [('Fig. 9a.csv', 'Accuracy (r)'),
                       ('Fig. 9b.csv', 'RT (r)'),
                       ('Fig. 9c.csv', 'MT (r)'),
                       ('Fig. 9d.csv', 'Curvature (r)'),
                       ('Fig. 9e.csv', 'Endpoint Displacement (r)'),
                       ('Fig. 9f.csv', 'Gaze Duration (r)'),
                       ('Fig. 9g.csv', 'Behavioural Coupling (r)'),
                       ('Fig. 9h.csv', 'Task Cue Amplitude (r)')]

for filename in filename_tuple_list:
    control_plot(filename=filename[0], ylabel=filename[1], ylim=[-.4, +.4])


def beta_weight_plot(filename):
    df = pd.read_csv(output_directory + filename)

    M = np.empty(df.Measure.unique().__len__())
    M[:] = np.nan

    E = np.empty(df.Measure.unique().__len__())
    E[:] = np.nan

    count = 0
    for MEASURE in df.Measure.unique():
        index = df.Measure == MEASURE
        # print(index)
        M[count] = df[index].DV.mean()
        E[count] = df[index].DV.std() / np.sqrt(index.sum())
        count = count + 1

    plt.close('all')
    plt.errorbar(range(0, df.Measure.unique().__len__()), M, E)
    plt.xticks(ticks=range(0, 4), labels=['Accuracy', 'RT', 'Endpoint\nDisplacement', 'Behavioural\nCoupling'])
    plt.xlabel('Metric')
    plt.ylabel('β Weight for Joint Action')

    plt.title(filename)
    plt.tight_layout()

    plt.savefig(output_directory + filename + ".png")


beta_weight_plot('Fig. 9i.csv')

## Fig. 10
plt.close('all')
print('Fig. 10')

control_accuracy_plot("Fig. 10b.csv", "Maximum ICD (°)")

## results montage!
plt.close('all')
print('results montage!')

# filenames = [['Fig. 2b.csv.png', 'Fig. 2c.csv.png', 'Fig. 2d.csv.png'],
#              ['Fig. 3a.csv.png', 'Fig. 3b.csv.png', 'Fig. 3c.csv.png', 'Fig. 3d.csv.png'],
#              ['Fig. 4a.csv.png', 'Fig. 4b.csv.png', 'Fig. 4c.csv.png', 'Fig. 4d.csv.png', 'Fig. 4e.csv.png', 'Fig. 4f.csv.png'],
#              ['Fig. 5b.csv.png', 'Fig. 5c.csv.png', 'Fig. 5d.csv.png'],
#              ['Fig. 6a - upper.csv.png', 'Fig. 6a - lower.csv.png', 'Fig. 6b - upper.csv.png', 'Fig. 6b - lower.csv.png', 'Fig. 6c.csv.png',
#               'Fig. 6d.csv.png'],
#              ['Fig. 7a.csv.png', 'Fig. 7b.csv.png', 'Fig. 7c.csv.png', 'Fig. 7d.csv.png'],
#              ['Fig. 8b.csv.png', 'Fig. 8c.csv.png', 'Fig. 8d.csv.png', 'Fig. 8e.csv.png', 'Fig. 8f.csv.png', 'Fig. 8g.csv.png', 'Fig. 8h.csv.png',
#               'Fig. 8h - inset.csv.png', 'Fig. 8i.csv.png'],
#              ['Fig. 9a.csv.png', 'Fig. 9b.csv.png', 'Fig. 9c.csv.png', 'Fig. 9d.csv.png', 'Fig. 9e.csv.png', 'Fig. 9f.csv.png', 'Fig. 9g.csv.png',
#               'Fig. 9h.csv.png', 'Fig. 9i.csv.png'],
#              ['Fig. 10b.csv.png']]


filenames = ['Fig. 2b.csv.png', 'Fig. 2c.csv.png', 'Fig. 2d.csv.png',
             'Fig. 3a.csv.png', 'Fig. 3b.csv.png', 'Fig. 3c.csv.png', 'Fig. 3d.csv.png',
             'Fig. 4a.csv.png', 'Fig. 4b.csv.png', 'Fig. 4c.csv.png', 'Fig. 4d.csv.png', 'Fig. 4e.csv.png', 'Fig. 4f.csv.png',
             'Fig. 5b.csv.png', 'Fig. 5c.csv.png', 'Fig. 5d.csv.png',
             'Fig. 6a - upper.csv.png', 'Fig. 6a - lower.csv.png', 'Fig. 6b - upper.csv.png', 'Fig. 6b - lower.csv.png', 'Fig. 6c.csv.png',
             'Fig. 6d.csv.png',
             'Fig. 7a.csv.png', 'Fig. 7b.csv.png', 'Fig. 7c.csv.png', 'Fig. 7d.csv.png',
             'Fig. 8b.csv.png', 'Fig. 8c.csv.png', 'Fig. 8d.csv.png', 'Fig. 8e.csv.png', 'Fig. 8f.csv.png', 'Fig. 8g.csv.png', 'Fig. 8h.csv.png',
             'Fig. 8h - inset.csv.png', 'Fig. 8i.csv.png',
             'Fig. 9a.csv.png', 'Fig. 9b.csv.png', 'Fig. 9c.csv.png', 'Fig. 9d.csv.png', 'Fig. 9e.csv.png', 'Fig. 9f.csv.png', 'Fig. 9g.csv.png',
             'Fig. 9h.csv.png', 'Fig. 9i.csv.png',
             'Fig. 10b.csv.png']

filenames = ['Fig. 2b.csv.png', 'Fig. 2c.csv.png', 'Fig. 2d.csv.png',
             'Fig. 3a.csv.png', 'Fig. 3b.csv.png', 'Fig. 3c.csv.png', 'Fig. 3d.csv.png',
             'Fig. 4a.csv.png', 'Fig. 4b.csv.png', 'Fig. 4c.csv.png', 'Fig. 4d.csv.png', 'Fig. 4e.csv.png', 'Fig. 4f.csv.png',
             'Fig. 5b.csv.png', 'Fig. 5c.csv.png', 'Fig. 5d.csv.png',
             'Fig. 6a - upper.csv.png', 'Fig. 6a - lower.csv.png', 'Fig. 6b - upper.csv.png', 'Fig. 6b - lower.csv.png', 'Fig. 6c.csv.png',
             'Fig. 6d.csv.png',
             'Fig. 7a.csv.png', 'Fig. 7b.csv.png', 'Fig. 7c.csv.png', 'Fig. 7d.csv.png',
             'Fig. 8b.csv.png', 'Fig. 8c.csv.png', 'Fig. 8d.csv.png', 'Fig. 8e.csv.png', 'Fig. 8f.csv.png', 'Fig. 8g.csv.png', 'Fig. 8h.csv.png',
             'Fig. 8h - inset.csv.png', 'Fig. 8i.csv.png',
             'Fig. 9a.csv.png', 'Fig. 9b.csv.png', 'Fig. 9c.csv.png', 'Fig. 9d.csv.png', 'Fig. 9e.csv.png', 'Fig. 9f.csv.png', 'Fig. 9g.csv.png',
             'Fig. 9h.csv.png', 'Fig. 9i.csv.png',
             'Fig. 10b.csv.png']

def get_concat_h_multi_resize(im_list, resample=Image.BICUBIC):
    min_height = min(im.height for im in im_list)
    im_list_resize = [im.resize((int(im.width * min_height / im.height), min_height), resample=resample)
                      for im in im_list]
    total_width = sum(im.width for im in im_list_resize)
    dst = Image.new('RGB', (total_width, min_height))
    pos_x = 0
    for im in im_list_resize:
        dst.paste(im, (pos_x, 0))
        pos_x += im.width
    return dst


def get_concat_v_multi_resize(im_list, resample=Image.BICUBIC):
    min_width = min(im.width for im in im_list)
    im_list_resize = [im.resize((min_width, int(im.height * min_width / im.width)), resample=resample)
                      for im in im_list]
    total_height = sum(im.height for im in im_list_resize)
    dst = Image.new('RGB', (min_width, total_height))
    pos_y = 0

    for im in im_list_resize:
        dst.paste(im, (0, pos_y))
        pos_y += im.height
    return dst


def get_concat_tile_resize(im_list_2d, resample=Image.BICUBIC):
    im_list_v = [get_concat_h_multi_resize(im_list_h, resample=resample) for im_list_h in im_list_2d]
    return get_concat_v_multi_resize(im_list_v, resample=resample)

# IM = []
#
# for i in range(0, len(filenames)):
#     IM2 = []
#     for j in range(0, len(filenames[i])):
#         IM2.append(Image.open(output_directory + filenames[i][j]))
#     IM.append(IM2)
# get_concat_tile_resize(IM).save(output_directory + "supplementary_data.png")


IM = []

for i in range(0, len(filenames)):
    IM.append(Image.open(output_directory + filenames[i]))


get_concat_v_multi_resize(IM).save(output_directory + "supplementary_data.png")

##

def merge_images(title, output_directory=""):



    images = [output_directory + title + " - Discipline.png",

              output_directory + title + " - Rate the Session.png",

              output_directory + title + " - Which aspects of the session did you find most enjoyable and useful.png"]



    im = []



    for i in images:

        print(i)

        im.append(Image.open(i))



    im2 = [[im[0]], [im[1]], [im[2]]]


