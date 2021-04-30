##

import subprocess
import os
import time
from datetime import datetime
import common
import numpy as np


def list_directories(folder):
    return [
        d for d in (os.path.join(folder, d1) for d1 in os.listdir(folder))
        if os.path.isdir(d)
    ]


def log_print(string):
    print(string)
    f.write(str(string) + '\n')


def get_sorted_subdirectories(path):
    return sorted(list_directories(path), key=str.lower)


def run_zip(output_file, input_path):

    start = time.time()

    cmd = [executable_path, 'a', output_file, input_path + '/*']
    system = subprocess.Popen(cmd, stderr=subprocess.STDOUT, stdout=subprocess.PIPE)

    try:
        log_print(system.communicate()[0].decode('ascii'))
    except Exception as e:
        # log_print(e)
        log_print('communicate failed?')

    log_print(time.time() - start)


log_output_path = common.set_output_directory("backup_project\\")

executable_path = "D:\\Program Files (x86)\\7za920\\7za"

parent_input_path = 'D:\\JOINT.ACTION\\JointActionRevision\\'
parent_output_path = 'E:\\JOINT_ACTION_BACKUPS\\joint-action-backup-2020.01.19\\'


##

filename = log_output_path + datetime.now().strftime("%Y-%m-%d %H.%M.%S") + '.txt'
f = open(filename, 'w')

directories = get_sorted_subdirectories(parent_input_path)

start = time.time()

for d in directories:

    log_print(common.get_stars())
    log_print(d)

    folder_name = str.split(d, parent_input_path)[1]

    if np.in1d(folder_name, ['PROGRAM', 'notes'])[0]:

        log_print('zip top level...')
        filename_out = parent_output_path + folder_name + ".zip"
        log_print(filename_out)

        run_zip(filename_out, d)

    else:

        log_print('zip subdirectories...')

        directories2 = get_sorted_subdirectories(d)

        for d2 in directories2:
            filename_out = parent_output_path + folder_name + str.split(d2, d)[1] + ".zip"
            log_print(d2)
            log_print(filename_out)

            run_zip(filename_out, d2)

stop = time.time() - start
log_print(stop)

f.close()
