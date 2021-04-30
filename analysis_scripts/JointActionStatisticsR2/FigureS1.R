# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("FigureS1/")

dpp = (53.2/1920); # degrees/pixel

fname = "D:\\JOINT.ACTION\\JointActionRevision\\analysis\\visual_input\\visual_input\\input.mat"
DATA <- readMat(fname)

df <- data.frame(subject_id = rep(seq(1,globals$number_of_sessions), 4))

df$Control <- c(rep(globals$control_levels2[1], globals$number_of_sessions*2),
                rep(globals$control_levels2[2], globals$number_of_sessions*2))

df$Control = factor(df$Control, levels=globals$control_levels2)


df$Accuracy = c(rep(globals$accuracy_levels[2], globals$number_of_sessions),
                rep(globals$accuracy_levels[1], globals$number_of_sessions),
                rep(globals$accuracy_levels[2], globals$number_of_sessions),
                rep(globals$accuracy_levels[1], globals$number_of_sessions))

df$Accuracy = factor(df$Accuracy, levels=globals$accuracy_levels)

df$DV <- c(DATA$soloInput[,1]*dpp, DATA$soloInput[,2]*dpp, DATA$jointInput[,1]*dpp, DATA$jointInput[,2]*dpp)  

control_accuracy_plot2 <- function(data, ylabel, filename, ylimit, legend_position){
  
  df_summary <- summarySE(df, measurevar = "DV", groupvars=c("Control", "Accuracy"))
  
  p <- ggplot(df, aes(x = Control, y = DV, fill = Accuracy)) +
    geom_flat_violin(aes(fill = Accuracy), position = position_nudge(x = .1, y = 0), adjust = 1.5, trim = FALSE, alpha = .5, colour=NA, width=.75)+
    geom_boxplot(aes(x = Control, y = DV, fill = Accuracy), outlier.shape = NA, width = .1, colour = "black")+
    geom_point(aes(x = as.numeric(Control)-.15, y = DV, colour = Accuracy), position = position_jitter(width = .05), size = 3, shape = 20, alpha=.5)+
    
    geom_line(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, group = Accuracy, colour = Accuracy), linetype = 3, size = 1)+
    geom_point(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, group = Accuracy, colour = Accuracy), shape = 18, size = 1) +
    geom_errorbar(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, group = Accuracy, colour = Accuracy, ymin = DV_mean-se, ymax = DV_mean+se), width = .05, size = 1)+
    
    theme_cowplot()+
    scale_color_aaas() +
    scale_fill_aaas()+
    theme(plot.margin=grid::unit(c(1, 1, 1, 1), "mm"),
          legend.position = legend_position,
          legend.justification = .5,
          legend.title = element_text(size=11),
          legend.text = element_text(size=11),
          axis.title = element_text(size=11),
          axis.text = element_text(size=11),
          plot.title = element_text(size=12, hjust = .5, face='plain'),
          axis.line = element_line(colour = 'black', size = 1),
          axis.ticks = element_line(colour = "black", size = 1))+
    
    ylab(ylabel)+
    xlab("Trial Type")+
    ggtitle("")
  
  if(!is.null(ylimit)){
    p <- p + ylim(ylimit)
  }
  
  print(p)  
  ggsave(plot=p, filename, width = 3, height = 3, dpi = 900)
  
  return(p)  
  
}

control_accuracy_plot2(df, ylabel = "Maximum ICD (°)", paste0(output_directory, "FigureS1.png"), NULL, c(.35,.95))


# anova -------------------------------------------------------------------




control_accuracy_anova(df)
