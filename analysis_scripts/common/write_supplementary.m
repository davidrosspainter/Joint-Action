function write_supplementary(filename, header, data)
    
savepath = '..//JointActionStatisticsR2//supplementary_data//';
filename = [savepath, filename];
fid = fopen(filename, 'wt');
fprintf(fid, header);  % header
fclose(fid);
dlmwrite(filename, data, '-append', 'delimiter', ',')