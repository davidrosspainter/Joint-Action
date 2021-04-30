import moviepy.video.io.ImageSequenceClip
import os
import common
import time
import numpy as np

output_directory = common.set_output_directory("save_movies\\")

sessions_to_use = np.array(range(0, 20))

for SESSION in sessions_to_use:

    common.print_stars()
    print(SESSION)

    if SESSION == 1:
        print('missing eye data...')
        continue

    start = time.time()

    image_folder = 'D:\\JOINT.ACTION\\JointActionRevision\\analysis\\Unity2\\RESULTS2\\' + common.Labels.session2[SESSION] + '\\'
    image_files = [image_folder + '/' + img for img in os.listdir(image_folder) if img.endswith(".png")]

    clip = moviepy.video.io.ImageSequenceClip.ImageSequenceClip(image_files, fps=30)
    clip.write_videofile(output_directory + common.Labels.session2[SESSION] + '.mp4')

    stop = time.time()
    print(stop-start)
