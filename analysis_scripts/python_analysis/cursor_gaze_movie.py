import numpy as np
import scipy.io
import importlib
import common
importlib.reload(common)
from scipy import signal

output_directory = common.set_output_directory('cursor_gaze_movie\\')

is_load_fresh = False

LOC_CODE = np.array([[3, 7],  # - uppermost left, lowermost right
                     [4, 8],  # - upper left, lower right
                     [5, 1],  # - lower left, upper right
                     [6, 2]])  # lowermost left, uppermost right

colour_location = np.array([[0.5, 0.25, 0.6],
                   [1, 0, 1],
                   [1, 0, 0],
                   [1, 0.36, 0],
                   [1, 1, 0],
                   [0, 1, 0],
                   [0, 1, 1],
                   [0, 0, 1]])

mat1 = scipy.io.loadmat(file_name="..\\data_manager\\CheckFiles2\\fname.mat")  # 'samples', 'GAZE', 'PUPIL', 'type'

CursorData = common.CursorData
dispatch_dictionary = {"CursorData": CursorData}


class Sizes:
    target = 76.9231
    cursor = 15
    gaze = 1/common.dpp


class Array:
    x = [269.8443, 111.7732, -111.7732, -269.8443, -269.8443, -111.7732, 111.7732, 269.8443]
    y = [111.7732, 269.8443, 269.8443, 111.7732, -111.7732, -269.8443, -269.8443, -111.7732]


## movie cursor eye - get gaze for movie

if is_load_fresh:

    def epoch(limit_seconds=[0, 2.5]):

        index = np.where(np.in1d(triggers, common.Trigger.task_cue))[0]

        limit_frames = np.multiply(limit_seconds, common.FS.eye).astype(int)
        number_frames = limit_frames[1] - limit_frames[0]

        start_index = latency_index[index+1] + limit_frames[0]
        stop_index = latency_index[index+1] + limit_frames[1]

        gaze = np.empty([number_frames, common.Number.axes, common.Number.trials])

        for TRIAL in range(0, common.Number.trials):
            gaze[:, :, TRIAL] = GAZE[start_index[TRIAL]:stop_index[TRIAL], :]

        for AXIS in range(0, common.Number.axes): # center
            gaze[:, AXIS, :] = gaze[:, AXIS, :] - np.nanmean(gaze[:, 0, :])

        gaze[:, 1, :] = gaze[:, 1, :]*-1  # invert the y axis
        gaze[:, 1, :] = gaze[:, 1, :] - np.nanmean(gaze[:, 1, :])  # shift y up

        return gaze


    limit_seconds1 = [0, +2.5]
    epoch_length1 = limit_seconds1[1] - limit_seconds1[0]
    common.Number.frames1 = int(epoch_length1*common.FS.eye)

    gaze = np.empty([common.Number.frames1, common.Number.axes, common.Number.trials, common.Number.players, common.Number.sessions])
    gaze[:] = np.nan

    for SESSION in np.array(range(0, 20)):

        common.print_stars()
        print(SESSION)

        if SESSION == 1:
            print('missing eye data...')
            continue

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

            # ----- epoch & resample and trim to prevent aliasing artifacts
            gaze[:, :, :, PLAYER, SESSION] = epoch(limit_seconds=limit_seconds1)


    ## ----- organise data by condition

    limit_seconds2 = np.array([-0.50, +3.00])
    epoch_length2 = limit_seconds2[1] - limit_seconds2[0]
    common.Number.frames2 = int(epoch_length2*common.FS.behaviour)
    frames2 = (limit_seconds2*common.FS.behaviour).astype(int)

    CD_results = [None] * common.Number.sessions

    for SESSION in np.array(range(0, 20)):

        common.print_stars()
        print(SESSION)

        if SESSION == 1:
            print('missing eye data...')
            continue

        # ----- load data

        filename = mat1['fname']['direct_behav'][0, 0][0] + mat1['fname']['behave'][0, 0][SESSION][0][0]
        print(filename)
        mat2 = scipy.io.loadmat(file_name=filename)
        data = mat2['data']

        # ----- get target position

        target_position = np.empty(common.Number.trials)
        target_position[:] = np.nan

        for TRIAL in range(0, common.Number.trials):
            target_position[TRIAL] = int(LOC_CODE[data[TRIAL, common.D.position_combo].astype(int)-1, data[TRIAL, common.D.location].astype(int)-1])-1

        target_position = target_position.astype(int)

        # ----- extract cursor information

        cursor_xy = mat2['cursor']['xy'][0][0]

        cursor_xy2 = np.empty([common.Number.axes, common.Number.frames2, common.Number.trials, common.Number.cursors])  # min length 505, max length 577 - but take 2.5 seconds
        cursor_xy2[:] = np.nan

        for TRIAL in range(0, common.Number.trials):
            index = range(data[TRIAL, common.D.move_cue_frame].astype(int)-1 + frames2[0], data[TRIAL, common.D.move_cue_frame].astype(int)-1 + frames2[1])
            cursor_xy2[:, :, TRIAL, :] = cursor_xy[:, index, TRIAL, :]

        # resample behavioural data to eye data sampling rate
        common.Number.frames3 = int(epoch_length2 * common.FS.eye)

        Y = np.transpose(cursor_xy2, (1, 0, 2, 3))
        Y = scipy.signal.resample(Y, common.Number.frames3)
        t = np.linspace(limit_seconds2[0], limit_seconds2[1], common.Number.frames3)

        index = (t >= limit_seconds1[0]) & (t <= limit_seconds1[1])
        Y = Y[index, :, :, :]
        Y = np.transpose(Y, (1, 0, 2, 3))

        cursor_xy2 = Y

        # ----- limit to control condition

        def limit_to_control_condition(CONTROL, data, cursor_xy2, target_position, gaze):

            CD = dispatch_dictionary["CursorData"]()

            CD.CONTROL = CONTROL
            CD.players_to_use = common.players[CONTROL]
            CD.index = data[:, common.D.cond] == CONTROL + 1
            CD.data = data[CD.index, :]
            CD.target_position = target_position[CD.index]
            CD.cursor_xy2 = cursor_xy2[:, :, CD.index, :]
            CD.gaze = gaze[:, :, CD.index, :]
            # CD.color_to_use = colour_location[CD.target_position, :] * np.tile(np.random.random(1)[0], (len(CD.target_position), 3)) # not implemented yet

            # if SESSION == 9999:  # 4?
            #     CD.cursor_xy2 = CD.cursor_xy2[:, 1:503, :, :]  # remove extra frame

            # for PLAYER in CD.players_to_use:  # remove trials with RTs that are too fast or too slow
            #     index = (CD.data[:, D.RT_fast[PLAYER]] is True) | (CD.data[:, D.RT_slow[PLAYER]] is True)
            #     CD.cursor_xy2[:, :, index, PLAYER] = np.nan
            #     CD.gaze[:, :, index, :] = np.NaN

            return CD

        CD_results[SESSION] = [None] * common.Number.control

        for CONTROL in range(0, common.Number.control):
            CD_results[SESSION][CONTROL] = limit_to_control_condition(CONTROL, data, cursor_xy2, target_position, gaze[:, :, :, :, SESSION])


    ## save results

    common.save_data(CD_results, output_directory + "CD_results.bin")
    test = common.load_data(output_directory + "CD_results.bin")

else:
    test = common.load_data(output_directory + "CD_results.bin")


## psychopy setup

is_play_movies = True

if is_play_movies:

    import psychopy.visual
    #import psychopy.event

    win = psychopy.visual.Window(
        size=[1920, 1080],
        units="pix",
        fullscr=False,
        color=[-1, -1, -1],
        screen=1
    )

    target_stimulus = psychopy.visual.Circle(
        win=win,
        units="pix",
        radius=Sizes.target/2,
        fillColor=None,
        lineColor=[1, 1, 1],
        lineWidth=2,
        pos=[0, 0]
    )

    cursor_stimulus = psychopy.visual.Rect(
        win=win,
        units="pix",
        size=Sizes.cursor/2,
        fillColor=[1, 1, 1],
        lineColor=None,
        lineWidth=0,
        pos=[0, 0]
    )

    gaze_stimulus = psychopy.visual.Circle(
        win=win,
        units="pix",
        size=Sizes.gaze,
        fillColor=None,
        lineColor=[1, 1, 1],
        lineWidth=1,
        pos=[0, 0]
    )

    text_stimulus = psychopy.visual.TextStim(
        win=win,
        units="pix",
        text="hello world",
        pos=[0, 0],
    )

    colour_location2 = np.array([[0, -0.5, 0],
                                [1, -1, 0],
                                [1, -1, -1],
                                [1, +.5, -1],
                                [1, 1, -1],
                                [-1, 1, -1],
                                [-1, 1, 1],
                                [-1, -1, 1]])

    x_modifier = [-1080/2, +1080/2]

    ##

    sessions_to_use = [9]
    time_vector = np.linspace(0, 2.5, test[0][0].cursor_xy2.shape[1])
    frame_step = 1

    def play_movie(DATA, SESSION):
        for FRAME in np.arange(0, test[0][0].cursor_xy2.shape[1], frame_step):

            trials_to_use = range(0, int(common.Number.trials/2))

            for CONTROL in range(0, common.Number.control):

                cd = DATA[SESSION][CONTROL]

                # draw cursors
                for PLAYER in cd.players_to_use:

                    X = cd.cursor_xy2[0, FRAME, trials_to_use, PLAYER].flatten() + x_modifier[cd.CONTROL]
                    Y = cd.cursor_xy2[1, FRAME, trials_to_use, PLAYER].flatten()

                    for TRIAL in range(0, len(trials_to_use)):
                        cursor_stimulus.pos = [X[TRIAL], Y[TRIAL]]
                        cursor_stimulus.fillColor = colour_location2[cd.target_position[trials_to_use][TRIAL]]
                        cursor_stimulus.draw()

                # gaze
                for PLAYER in range(0, common.Number.players):
                    X = cd.gaze[FRAME, 0, trials_to_use, PLAYER].flatten() + x_modifier[cd.CONTROL]
                    Y = cd.gaze[FRAME, 1, trials_to_use, PLAYER].flatten()

                    for TRIAL in range(0, len(trials_to_use)):
                        gaze_stimulus.pos = [X[TRIAL], Y[TRIAL]]
                        gaze_stimulus.lineColor = colour_location2[cd.target_position[trials_to_use][TRIAL]]
                        gaze_stimulus.draw()

                # draw targets
                for TARGET in range(0, common.Number.target_positions):
                    target_stimulus.pos = [Array.x[TARGET] + x_modifier[cd.CONTROL], Array.y[TARGET]]
                    target_stimulus.draw()

            text_stimulus.text = time_vector[FRAME].__str__()
            text_stimulus.draw()

            win.flip()


    for SESSION in sessions_to_use:

        common.print_stars()
        print(SESSION)
        print(common.Labels.session2[SESSION])

        if SESSION == 1:
            print('missing eye data...')
            continue

        play_movie(test, SESSION)


    ##

    win.close()
    # win.clearBuffer()
    # psychopy.event.waitKeys()