import scipy.io
import numpy as np
import common
import time
import os
import matplotlib.pyplot as plt
import FieldTrip2
import subprocess
import numpy as np

output_directory = common.set_output_directory('prepare_cursor_gaze2\\')
start = time.time()


class Number:
    axes = 2
    frames = 360
    trials = 480
    cursors = 3


class Ports:
    P1 = [1000, 1001]
    P2 = [1002, 1003]
    target_positions_solo = 1004
    P1_gaze_solo = [1005, 1006]
    P2_gaze_solo = [1007, 1008]
    joint = [1009, 1010]
    target_positions_joint = 1011
    P1_gaze_joint = [1012, 1013]
    P2_gaze_joint = [1014, 1015]


def close_buffers():
    try:
        subprocess.call("taskkill /F /IM buffer.exe /T")  # kill buffer
    except:
        print("buffer not running...")

    try:
        subprocess.call("taskkill /F /IM cmd.exe /T")  # kill cmd
    except:
        print("cmd not running...")


def buffer_trial2(port, array):

    path_buffer_executable = "D:\\Network.Buffer.DRP.19.07.20\\realtimeHack.10.11.17\\buffer.exe"
    host = 'localhost'

    command = "start cmd /K " + path_buffer_executable + " " + host.__str__() + " " + port.__str__() + " -&"
    print(command)

    subprocess.Popen(command, shell=True)  # start buffer

    ftc = FieldTrip2.Client()  # create buffer object
    ftc.connect(host, port)  # connect to buffer
    ftc.putHeader(array.shape[1], 0, FieldTrip2.DATATYPE_FLOAT32, None, None)  # put header - clears the buffer memory?

    ftc.putData(array.astype(np.float32))  # put data

    hdr = ftc.getHeader()  # get header
    # print(hdr)  # print header

    D2 = ftc.getData((0, hdr.nSamples-1))  # get data
    # print(np.shape(D2))  # print data

    return(D2)


## refresh and populate buffers

close_buffers()


class Labels:
    session = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20']


SESSION = 3
mat = scipy.io.loadmat('..\\visual_input\\movie_cursor_eye\\movie_data\\' + Labels.session[SESSION] + '.mat')

# ----- solo
cursor_xy = mat['CURSOR_XY2'][0, 0]

for CURSOR in [0, 1]:
    if CURSOR == 0:
        ports_to_use = Ports.P1
    elif CURSOR == 1:
        ports_to_use = Ports.P2

    for AXIS in [0, 1]:
        trajectory = np.transpose(cursor_xy[AXIS, :, :, CURSOR])
        np.transpose(buffer_trial2(port=ports_to_use[AXIS], array=trajectory))

target_position = mat['TARGET_POSITION'][0, 0]
buffer_trial2(port=Ports.target_positions_solo, array=target_position)

gaze = mat['GAZE'][0, 0]

for CURSOR in [0, 1]:

    if CURSOR == 0:
        ports_to_use = Ports.P1_gaze_solo
    elif CURSOR == 1:
        ports_to_use = Ports.P2_gaze_solo

    for AXIS in [0, 1]:
        trajectory = np.transpose(gaze[AXIS, :, :, CURSOR])
        np.transpose(buffer_trial2(port=ports_to_use[AXIS], array=trajectory))

# ----- joint
cursor_xy = mat['CURSOR_XY2'][1, 0]
ports_to_use = Ports.joint

for AXIS in [0, 1]:
    trajectory = np.transpose(cursor_xy[AXIS, :, :, 2])
    np.transpose(buffer_trial2(port=ports_to_use[AXIS], array=trajectory))

target_position = mat['TARGET_POSITION'][1, 0]
buffer_trial2(port=Ports.target_positions_joint, array=target_position)

gaze = mat['GAZE'][1, 0]

for CURSOR in [0, 1]:

    if CURSOR == 0:
        ports_to_use = Ports.P1_gaze_joint
    elif CURSOR == 1:
        ports_to_use = Ports.P2_gaze_joint

    for AXIS in [0, 1]:
        trajectory = np.transpose(gaze[AXIS, :, :, CURSOR])
        np.transpose(buffer_trial2(port=ports_to_use[AXIS], array=trajectory))

stop = time.time()
print(stop-start)
