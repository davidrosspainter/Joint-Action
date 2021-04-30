import scipy.io
import numpy as np
import common
import time
import os
import matplotlib.pyplot as plt
import FieldTrip2
import subprocess

output_directory = common.set_output_directory('prepare_cursor_gaze\\')

start = time.time()

mat = scipy.io.loadmat('..\\visual_input\\movie_cursor_eye\\test.mat')

cursor_xy = mat['CURSOR_XY2'][0, 0]
#np.save(file=output_directory + 'test.npy', arr=cursor_xy)
# #np.savetxt(fname=output_directory + 'test.npy', X=cursor_xy)
# del cursor_xy
# array = np.load(file=output_directory + 'test.npy', allow_pickle=True)
dimensions = cursor_xy.shape


class Number:
    axes = 2
    frames = 360
    trials = 480
    cursors = 3


Number.axes = dimensions[0]
Number.frames = dimensions[1]
Number.trials = dimensions[2]
Number.cursors = dimensions[3]
#
# cursor_xy = np.empty((Number.axes, Number.frames, Number.trials, Number.cursors))
# cursor_xy[:] = np.NaN
#
# for axis in range(0, Number.axes):
#     for frame in range(0, Number.frames):
#         for trial in range(0, Number.trials):
#             for cursor in range(0, Number.cursors):
#                 #print(array[axis, frame, trial, cursor])
#                 cursor_xy[axis, frame, trial, cursor] = array[axis, frame, trial, cursor]
#
# stop = time.time()
# print(stop-start)
# print('done!')




TRIAL = 1
CURSOR = 1

trajectory = np.transpose(cursor_xy[:, :, TRIAL, CURSOR])

plt.close('all')
plt.plot(trajectory[:, 0], trajectory[:, 1])
plt.xlim([-540, +540])
plt.ylim([-540, +540])

##


def close_buffers():
    try:
        subprocess.call("taskkill /F /IM buffer.exe /T")  # kill buffer
    except:
        print("buffer not running...")

    try:
        subprocess.call("taskkill /F /IM cmd.exe /T")  # kill cmd
    except:
        print("cmd not running...")


def buffer_trial(port, array):

    path_buffer_executable = "D:\\Network.Buffer.DRP.19.07.20\\realtimeHack.10.11.17\\buffer.exe"

    host = 'localhost'

    command = "start cmd /K " + path_buffer_executable + " " + host.__str__() + " " + port.__str__() + " -&"
    print(command)

    subprocess.Popen(command, shell=True)  # start buffer

    ftc = FieldTrip2.Client()  # create buffer object
    ftc.connect(host, port)  # connect to buffer
    ftc.putHeader(Number.axes, 0, FieldTrip2.DATATYPE_FLOAT32, None, None)  # put header - clears the buffer memory?

    ftc.putData(array.astype((np.float32)))  # put data

    hdr = ftc.getHeader()  # get header
    # print(hdr)  # print header

    D2 = ftc.getData((0, hdr.nSamples-1))  # get data
    # print(np.shape(D2))  # print data

    return(D2)


close_buffers()

CURSOR = 1
D2 = np.empty((2, Number.frames, 10))
D2[:] = np.nan

port = []

for TRIAL in range(0, 10):
    D2[:,:,TRIAL] = np.transpose(buffer_trial(port=TRIAL+1000, array=np.transpose(cursor_xy[:, :, TRIAL, CURSOR])))
    port.append(TRIAL+1000)


np.all(D2[:,:,:] == cursor_xy[:,:,0:10,1].astype(np.float32))

