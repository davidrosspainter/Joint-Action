import pandas as pd
from pdf2image import convert_from_path
import time
import os
import common

output_directory = common.set_output_directory('trajectories\\')

data_path = r'D:\JOINT.ACTION\JointActionRevision\analysis\JointActionStatisticsR2\Figure2_new'

number_of_control = 3
number_of_visibility = 2
number_of_figure = 2

str_control = ['HP Solo', 'LP Solo', 'Joint']
str_visibility = ['Visible', 'Invisible']
str_figure = ["endpoint", "trajectory"]

figure_list = []
i = 0

for VISIBILITY in str_visibility:
    for CONTROL in str_control:
        figure_list.append([VISIBILITY, CONTROL, i])
        i += 1

figure_key = pd.DataFrame(figure_list, columns=['visibility', 'control', 'i'])

for FIGURE in [0]:

    figure_list = []

    for i, row in figure_key.iterrows():

        filename = data_path + '\\group.' + str_figure[FIGURE] + "." + row.control + " " + row.visibility + ".pdf"
        print(filename)
        print(os.path.isfile(filename))

        tic = time.perf_counter()

        pages = convert_from_path(pdf_path=filename,
                                  dpi=900,
                                  fmt='pdf')

        pages[0].save(output_directory + str_figure[FIGURE] + "." + row.control + " " + row.visibility + ".png")
        figure_list.append(pages[0])

        toc = time.perf_counter()
        print(f"{toc - tic:0.4f} elapsed seconds")

    common.get_concat_tile_resize([[figure_list[0], figure_list[1], figure_list[2]],
                            [figure_list[3], figure_list[4], figure_list[5]]]).\
        save(output_directory + str_figure[FIGURE] + '.summary.png')