# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("Figure4/")

library(reticulate)
np <- import("numpy")
library(reshape2)
library(plotly)

is_use_python = TRUE
graphics.off()

# load and organise -------------------------------------------------------

epoch_levels = c("Pre-Action Epoch", "Action Epoch")

if(!is_use_python){
  
  number_tracked = 17

  
  filename = "..\\eye_tracking\\eyetrack_heatmap_cond2_dist2\\all\\JointAction_EyeData.txt"
  tmp <- read.delim(filename, header = TRUE, sep = "\t", dec = ".")
  
  df <- as_tibble(data.frame(subject_id = rep(seq(1, number_tracked), 4)))
  
  df$Control <- factor(c(rep("Solo", number_tracked*2), rep("Joint", number_tracked*2)), levels = globals$control_levels2)
  df$Epoch <- factor(c(rep(epoch_levels[1], number_tracked),
                       rep(epoch_levels[2], number_tracked),
                       rep(epoch_levels[1], number_tracked),
                       rep(epoch_levels[2], number_tracked)), levels = epoch_levels)
  
  df$DV <- c(tmp$EyeDist_premovecue_solo, tmp$EyeDist_postmovecue_solo, tmp$EyeDist_premovecue_joint, tmp$EyeDist_postmovecue_joint)
  
} else{
  
  npz <- np$load("..\\python_analysis\\eye_single_trial\\distance_to_use.npz")
  distance_to_use <- npz$f[["distance_to_use"]]
  
  number_tracked = dim(distance_to_use)[3]
  
  df <- as_tibble(data.frame(subject_id = rep(seq(1, number_tracked), 4)))
  
  df$Control <- factor(c(rep("Solo", number_tracked*2), rep("Joint", number_tracked*2)), levels = globals$control_levels2)
  df$Epoch <- factor(c(rep(epoch_levels[1], number_tracked),
                       rep(epoch_levels[2], number_tracked),
                       rep(epoch_levels[1], number_tracked),
                       rep(epoch_levels[2], number_tracked)), levels = epoch_levels)
  
  
   
  df$DV <- c(distance_to_use[1,1,], distance_to_use[1,2,], distance_to_use[2,1,], distance_to_use[2,2,])
  
}


# ANOVA -------------------------------------------------------------------

res.aov <- anova_test(data = df, dv = DV, wid = subject_id, within = c(Control, Epoch), effect.size="pes")
get_anova_table(res.aov)


# plot -----------------------------------------------------------------------

for(epoch in epoch_levels){

  print('*************************')
  print(epoch)
  p = control_plot(df[df$Epoch == epoch,], 'Inter-Gaze Distance (°)', "Control", "", c(0,6), paste0(output_directory, epoch, "icd.png"))  

  # ----- follow-up tests
  
  test <- df[df$Epoch == epoch,] %>%
    pairwise_t_test(
      DV ~ Control, paired = TRUE,
      p.adjust.method = "bonferroni"
    )
  
  df_summary <- summarySE(df[df$Epoch == epoch,], measurevar = "DV", groupvars=c("Control"))
  print(df_summary)
  
  print(test)
    
}


# hot color map -------------------------------------------------------------------

rgb2hex <- function(x) rgb(x[1], x[2], x[3], maxColorValue = 1)

npz <- np$load("..\\python_analysis\\eye_single_trial\\rgba.npz")
rgba <- npz$f[["rgba"]]

hex_color = c()

for (i in seq(1, dim(rgba)[1])) {
  hex_color = c(hex_color, rgb2hex(rgba[i,1:3]))
}


# heatmaps ----------------------------------------------------------------

npz <- np$load("..\\python_analysis\\eye_single_trial\\mean_H.npz")
mean_H <- npz$f[["mean_H"]]
x_edges <- npz$f[["x_edges"]]
y_edges <- npz$f[["y_edges"]]

reshape_histogram_data <- function(EPOCH){

  datalist = list()
  
  i = 0;
  nbins = length(x_edges)-1
  
  for(x in seq(1, nbins)){
    for(y in seq(1, nbins)){
      i = i + 1
      datalist[[i]] = c(x_edges[x], y_edges[y], mean_H[y,x,EPOCH])
    }
  }
  
  H_data <- as_tibble(do.call(rbind, datalist))
  colnames(H_data) <- c('x', 'y', 'value')
  
  return (H_data)
}

plot_heatmap <- function(H_data, EPOCH, limits, is_show_legend){
  
  if(is_show_legend){
    legend_position = 'right'
  }
  else{
    legend_position = 'none'
  }
  
  p <- ggplot(H_data, aes(x, y)) +
    geom_raster(aes(fill=value)) +
    labs(x=expression(paste(italic("x"), " (°)")),
         y=expression(paste(italic("y"), " (°)")),
         title = epoch_levels[EPOCH])+
    theme_cowplot()+
    scale_fill_gradientn(colours=hex_color, oob = scales::squish, limits = limits) +
    theme(plot.margin=grid::unit(c(1, 1, 1, 1), "mm"),
          legend.position = legend_position,
          legend.justification = .5,
          legend.title = element_text(size=13), legend.text = element_text(size=13),
          axis.title = element_text(size=14),
          axis.text = element_text(size=14),
          plot.title=element_text(size=15, hjust = .5, face='plain'),
          axis.line = element_line(colour = 'black', size = 1),
          axis.ticks = element_line(colour = "black", size = 1))+
    scale_x_continuous(expand = c(0, 0))+
    scale_y_continuous(expand = c(0, 0))+
    coord_fixed()
  
  print(p)
  
  filename <- paste0(output_directory, epoch_levels[EPOCH], '.pdf')
  width = 8.5; height = 8.5
  ggsave(plot = p, filename = filename, width = width, height = height, device = "pdf", units="cm")
  
  filename <- paste0(output_directory, epoch_levels[EPOCH], '.png')
  ggsave(plot = p, filename = filename, width = width, height = height, device = "png", units="cm")
  
  return (p)
  
}

limits = list(2)
limits[[1]] = c(0, .70)
limits[[2]] = c(0, .03)

for (EPOCH in seq(1, length(epoch_levels))){
  H_data <- reshape_histogram_data(EPOCH)
  
  print(max(H_data$value))
  
  p <- plot_heatmap(H_data, EPOCH, limits[[EPOCH]], FALSE)
}