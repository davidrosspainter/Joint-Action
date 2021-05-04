import os
import numpy as np
import pickle
from PIL import Image
from enum import Enum


def set_output_directory(output_directory):
    if not os.path.isdir(output_directory):
        os.mkdir(output_directory)
    return output_directory


def get_stars(n=100):
    return ('*' * (int(n/len('*'))+1))[:n]


def print_stars(n=100):
    print(get_stars(n))


colors = np.array([[0.5, 0.25, 0.6],
                   [1, 0, 1],
                   [1, 0, 0],
                   [1, 0.36, 0],
                   [1, 1, 0],
                   [0, 1, 0],
                   [0, 1, 1],
                   [0, 0, 1]])


class Labels:
    player = ['P1', 'P2']
    control = ['Solo', 'Joint']
    control2 = ['HP Solo', 'LP Solo', 'Joint']
    epoch = ['Pre-Action', 'Action']
    session = ['S01', 'S02', 'S03', 'S04', 'S05', 'S06', 'S07', 'S08', 'S09', 'S10', 'S11', 'S12', 'S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19', 'S20']
    session2 = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20']
    visibility = ['Visible', 'Invisible']
    accuracy = ['Correct', 'Error']
    relevance = ['Target', 'Distractor']


class Control(Enum):
    Solo = 0
    Joint = 1


class Control2(Enum):
    HP_Solo = 0
    LP_Solo = 1
    Joint = 2


class Visibility(Enum):
    Visible = 0
    Invisible = 1


class Accuracy(Enum):
    Correct = 0
    Error = 1


class Relevance(Enum):
    Target = 0
    Distractor = 1


class Number:
    sessions = 20
    players = 2
    subjects = sessions*players

    channels = 61

    trials = 960
    trials_control = trials/2

    blocks = 15
    trials_per_block = trials/blocks

    triggers_per_trial = 5
    triggers_total = trials * triggers_per_trial + blocks + 1  # expected to be present in the EEG recordings

    axes = 2
    movement_epochs = 2
    control = 2

    cursors = 3
    target_positions = 8

    frames = 1008


class Trigger:
    fix = [1, 2]  # Hz combo 1, 2
    task_cue = [3, 4]  # solo, co-op
    move_cue = [5, 6]  # left/right
    feedback = 7  # feedback onset
    rest_trial = 8
    rest_block = 255


class Monitor:
    resolution = [1920, 1080]
    refresh_rate = 144


class FS:
    eye = 120
    behaviour = 144


dpp = (53.2/1920)


def load_data(filename):
    try:
        with open(filename, 'rb') as f:
            data = pickle.load(f)
    except:
        data = None
    return data


def save_data(data, filename):
    with open(filename, "wb") as f:
        pickle.dump(data, f)


class CursorData:
    CONTROL = None
    players_to_use = None
    index = None
    data = None
    target_position = None
    cursor_xy = None
    gaze = None
    color_to_use = None


players = np.array([[0, 1], [2]], dtype=object)


class D:
    block = 1 - 1
    trial = 2 - 1
    trial_block = 3 - 1
    cond = 4 - 1
    location = 5 - 1
    Hz_combo = 6 - 1
    rest_frames = 7 - 1
    fix_frame = 8 - 1
    task_cue_frame = 9 - 1
    move_cue_frame = 10 - 1
    feedback_frame = 11 - 1
    breaking_frame = 12 - 1
    RT_lower_frame = 13 - 1
    RT_upper_frame = 14 - 1
    MT_upper_frames = np.array([15, 16,17]) - 1
    RT = np.array([18, 19, 20]) - 1
    MT = np.array([21, 22, 23]) - 1
    HT = np.array([24, 25, 26]) - 1
    react_frame = np.array([27, 28, 29]) - 1
    inside_frame = np.array([30, 31, 32]) - 1
    RT_fast = np.array([33, 34, 35]) - 1
    RT_slow = np.array([36, 37, 38]) - 1
    MT_slow = np.array([39, 40, 41]) - 1
    leaving = np.array([42, 43, 44]) - 1
    leaving_frame = np.array([45, 46, 47]) - 1
    correct = np.array([48, 49, 50]) - 1
    position_combo = 51 - 1
    pre_move_cue_frames = 52 - 1


def ws_bars(x):

    # within subjects error bars
    # assumes subject as row and condition as column

    subject_mean = np.nanmean(x, axis=1).reshape([len(x),1])
    grand_mean = np.nanmean(subject_mean)

    x = x - (np.tile(subject_mean, (1, x.shape[1])) - grand_mean)
    error = np.nanstd(x, axis=0,  ddof=1)/np.sqrt(x.shape[0])

    return error


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


def np_nan(shape):
    array = np.empty(shape)
    array[:] = np.nan
    return array


def populate_class(class_name, shape):
    attributes = [attribute for attribute in dir(class_name) if not callable(getattr(class_name, attribute)) and not attribute.startswith("__")]
    for attribute in attributes:
        setattr(class_name, attribute, np_nan(shape))


def stop():
    raise Exception('stop!')
