import scipy.io
import numpy as np
import common
import time
import os
import matplotlib.pyplot as plt
import importlib
import FieldTrip2
importlib.reload(FieldTrip2)
import subprocess
import numpy as np
import keyboard


output_directory = common.set_output_directory('prepare_cursor_gaze2\\')
start = time.time()


class Labels:
    session = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20']


class Number:
    axes = 2
    frames = 360
    trials = 480
    cursors = 3


class Ports:
    P1 = [1, 2]
    P2 = [3, 4]
    target_positions_solo = 5
    P1_gaze_solo = [6, 7]
    P2_gaze_solo = [8, 9]
    joint = [10, 11]
    target_positions_joint = 12
    P1_gaze_joint = [13, 14]
    P2_gaze_joint = [15, 16]
    session = 17
    status = 18


def close_buffers():
    try:
        subprocess.call("taskkill /F /IM buffer.exe /T")  # kill buffer
    except:
        print("buffer not running...")

    try:
        subprocess.call("taskkill /F /IM cmd.exe /T")  # kill cmd
    except:
        print("cmd not running...")


def start_buffer_and_put_data(port, array):
    start_buffer(port, array.shape[1])

    ftc = FieldTrip2.Client()  # create buffer object
    ftc.connect("localhost", port)  # connect to buffer
    ftc.putData(array.astype(np.float32))  # put data
    hdr = ftc.getHeader()  # get header
    D2 = ftc.getData((0, hdr.nSamples-1))  # get data
    return D2


def start_buffer(port, nChannels):
    path_buffer_executable = "D:\\Network.Buffer.DRP.19.07.20\\realtimeHack.10.11.17\\buffer.exe"
    host = 'localhost'

    command = "start cmd /K " + path_buffer_executable + " " + host.__str__() + " " + port.__str__() + " -&"
    print(command)

    subprocess.Popen(command, shell=True)  # start buffer

    ftc = FieldTrip2.Client()  # create buffer object
    ftc.connect(host, port)  # connect to buffer
    ftc.putHeader(nChannels, 0, FieldTrip2.DATATYPE_FLOAT32, None, None)  # put header - clears the buffer memory?
    ftc.disconnect()


def prepare_integer_array(integer):
    array = np.empty([1, 1])
    array[0, 0] = integer
    return array


def flush_buffer(port):
    ftc = FieldTrip2.Client()  # create buffer object
    ftc.connect("localhost", port)  # connect to buffer
    hdr = ftc.getHeader()  # get header
    ftc.putHeader(hdr.nChannels, 0, FieldTrip2.DATATYPE_FLOAT32, None, None)  # clears the buffer memory! hack?
    ftc.disconnect()


def put_data(port, array):
    ftc = FieldTrip2.Client()  # create buffer object
    ftc.connect("localhost", port)  # connect to buffer
    ftc.putData(array.astype(np.float32))  # put data


def get_number_of_samples(port):
    ftc = FieldTrip2.Client()  # create buffer object
    ftc.connect("localhost", port)  # connect to buffer
    hdr = ftc.getHeader()
    return hdr.nSamples


def get_all_data(port):
    ftc = FieldTrip2.Client()  # create buffer object
    ftc.connect("localhost", port)  # connect to buffer
    hdr = ftc.getHeader()
    data = ftc.getData([0, hdr.nSamples-1])
    return data


def flush_all_buffers():
    ports_to_use = np.concatenate([Ports.P1,
                                   Ports.P2,
                                   [Ports.target_positions_solo],
                                   Ports.P1_gaze_solo,
                                   Ports.P2_gaze_solo,
                                   Ports.joint,
                                   [Ports.target_positions_joint],
                                   Ports.P1_gaze_joint,
                                   Ports.P2_gaze_joint,
                                   [Ports.session]])

    for port in ports_to_use:
        flush_buffer(port)




## buffer data

close_buffers()


## start buffers
port_info = [(Ports.P1, 360),
             (Ports.P2, 360),
             ([Ports.target_positions_solo], 1),
             (Ports.P1_gaze_solo, 360),
             (Ports.P2_gaze_solo, 360),
             (Ports.joint, 360),
             ([Ports.target_positions_joint], 1),
             (Ports.P1_gaze_joint, 360),
             (Ports.P2_gaze_joint, 360),
             ([Ports.session], 1),
             ([Ports.status], 1)]

for port in port_info:
    for p in port[0]:
        start_buffer(p, port[1])


## run interactive routine

is_escape = False

flush_buffer(Ports.status)
flush_all_buffers()

sessions_to_use = np.array(range(3, 20))

for SESSION in sessions_to_use:

    # ----- load data...
    print(Labels.session[SESSION])
    mat = scipy.io.loadmat('..\\visual_input\\movie_cursor_eye\\movie_data\\' + Labels.session[SESSION] + '.mat')

    # ----- SESSION
    put_data(port=Ports.session, array=prepare_integer_array(SESSION))

    # ----- solo
    cursor_xy = mat['CURSOR_XY2'][0, 0]

    for CURSOR in [0, 1]:
        if CURSOR == 0:
            ports_to_use = Ports.P1
        elif CURSOR == 1:
            ports_to_use = Ports.P2

        for AXIS in [0, 1]:
            trajectory = np.transpose(cursor_xy[AXIS, :, :, CURSOR])
            put_data(port=ports_to_use[AXIS], array=trajectory)

    target_position = mat['TARGET_POSITION'][0, 0]
    put_data(port=Ports.target_positions_solo, array=target_position)

    gaze = mat['GAZE'][0, 0]

    for CURSOR in [0, 1]:

        if CURSOR == 0:
            ports_to_use = Ports.P1_gaze_solo
        elif CURSOR == 1:
            ports_to_use = Ports.P2_gaze_solo

        for AXIS in [0, 1]:
            trajectory = np.transpose(gaze[AXIS, :, :, CURSOR])
            put_data(port=ports_to_use[AXIS], array=trajectory)

    # ----- joint
    cursor_xy = mat['CURSOR_XY2'][1, 0]
    ports_to_use = Ports.joint

    for AXIS in [0, 1]:
        trajectory = np.transpose(cursor_xy[AXIS, :, :, 2])
        put_data(port=ports_to_use[AXIS], array=trajectory)

    target_position = mat['TARGET_POSITION'][1, 0]
    put_data(port=Ports.target_positions_joint, array=target_position)

    gaze = mat['GAZE'][1, 0]

    for CURSOR in [0, 1]:

        if CURSOR == 0:
            ports_to_use = Ports.P1_gaze_joint
        elif CURSOR == 1:
            ports_to_use = Ports.P2_gaze_joint

        for AXIS in [0, 1]:
            trajectory = np.transpose(gaze[AXIS, :, :, CURSOR])
            put_data(port=ports_to_use[AXIS], array=trajectory)

    stop = time.time()
    print(stop-start)

    if SESSION == sessions_to_use[-1]:
        put_data(port=Ports.status, array=prepare_integer_array(99))  # ready
        break
    else:
        put_data(port=Ports.status, array=prepare_integer_array(1))  # ready

    # ------ status
    put_data(Ports.status, prepare_integer_array(9))
    number_of_samples = get_number_of_samples(Ports.status)

    # wait for unity

    while True:
        if number_of_samples != get_number_of_samples(Ports.status):
            is_wait_for_unity = False
            print('connected...')
            break
        else:
            time.sleep(1)
            print('waiting...')

        if keyboard.is_pressed('Esc'):  # if key 'q' is pressed
            print('you pressed escape!')
            is_escape = True
            break

    # clear ports
    flush_all_buffers()

    if is_escape:
        break
