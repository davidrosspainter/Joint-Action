function write_supplementary2(filename, columns, rows, data)
savePath = '..//JointActionStatisticsR2//supplementary_data//';
save([savePath filename], 'columns', 'rows', 'data', '-v7.3')