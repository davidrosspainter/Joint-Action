# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("Figure2/")

# load and organise -------------------------------------------------------

fname = "D:\\JOINT.ACTION\\JointActionRevision\\analysis\\behavioural_performance\\accuracy2_coordination2\\cell_means.mat"
DATA <- readMat(fname)

measures <- c("accuracy.original", "accuracy.derived", "MT.original", "MT.derived", "RT.original", "RT.derived")
decreasing = c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE)

count = 0
data = vector('list', length(measures))

for (MM in seq(1,length(measures))) {

  measure <- measures[MM]
  
  print("********************************")
  print(measure)
  
  for (SESSION in seq(1,globals$number_of_sessions)){
    DATA[[measure]][SESSION,1:2] = sort(DATA[[measure]][SESSION,1:2], decreasing = decreasing[MM])
  }
  
  DV <- c(DATA[[measure]][,1], DATA[[measure]][,2], DATA[[measure]][,3])
  
  Control <- c(rep("HP Solo", globals$number_of_sessions), rep("LP Solo", globals$number_of_sessions), rep("Joint", globals$number_of_sessions))
  Control <- factor(Control, levels = globals$control_levels)
  
  tmp <- data.frame(Control, DV)
  
  count = count + 1
  data[[count]] <- tmp
  
}

# new ---------------------------------------------------------------------

my_plots <- vector('list', 3)
subplot_label = c("b", "c", "d")

for (MM in seq(1,3)){
  
  cat("************************")
  cat('\n')
  
  if (MM==1){
    ylabel = "Accuracy (%)"
    CC = c(1, 2)
  } else if(MM==2){
    ylabel = "MT (ms)"
    CC = c(3, 4)
  } else if(MM==3){
    ylabel = "RT (ms)"
    CC = c(5, 6)
  }

  cat(ylabel)
  cat('\n')
  
  df <- rbind(data[[CC[1]]], data[[CC[2]]])
  df$Cursor = c(rep("Visible", 60), rep("Invisible", 60))
  df$Cursor = factor(df$Cursor, globals$cursor_levels)
  df$subject_id <- c(rep(seq(1,20),3))
  df_summary <- summarySE(df, measurevar = "DV", groupvars=c("Control", "Cursor"))
  
  p1 = control_cursor_plot(df, ylabel, paste0(str_replace(ylabel, "%", ""), ".png"))
  
  my_plots[[MM]] <- local({p <- p1})
  
  control_cursor_anova(df)

}


p3 <- grid.arrange(my_plots[[1]], my_plots[[3]], my_plots[[2]], ncol = 1)
print(p3)

width = 6
height = width/2*3

ggsave(plot=p3, paste0(output_directory, "Figure2.png"), width = width, height = height, dpi=900)




# endpoint accuracy -------------------------------------------------------



# load ----------------------------------------------------------------

fname = "D:\\JOINT.ACTION\\JointActionRevision\\analysis\\behavioural_performance\\endpoint_accuracy\\endpoint_accuracy.mat"
DATA <- readMat(fname)
measures <- c("curvature.experiment.sorting.Visible", "curvature.trial.sorting.Visible", "curvature.experiment.sorting.Invisible", "curvature.trial.sorting.Invisible")



# organise ---------------------------------------------------------------------

DV <- c(
  DATA$visible[,1],
  DATA$visible[,2],
  DATA$visible[,3],
  DATA$invisible[,1],
  DATA$invisible[,2],
  DATA$invisible[,3])

df <- as_tibble(data.frame(DV))
df$Cursor = c(rep("Visible", 60), rep("Invisible", 60))
df$Cursor = factor(df$Cursor, globals$cursor_levels)
df$subject_id <- c(rep(seq(1,globals$number_of_sessions),6))

df$Control <- rep(c(rep("HP Solo", globals$number_of_sessions), rep("LP Solo", globals$number_of_sessions), rep("Joint", globals$number_of_sessions)), 2)
df$Control <- factor(df$Control, levels = globals$control_levels)


# plot -----------------------------------------------------------------------

p = control_cursor_plot(df, expression(paste('Endpoint Displacement (°)')), paste0(output_directory, "endpoint_displacement.png"))
p <- p + ylim(0,10)
p
width = 6; height = 3
ggsave(plot=p, filename=paste0(output_directory,"endpoint_displacement.png"), width = width, height = height, dpi = 900)


control_cursor_spss_csv(df, paste0(output_directory, 'endpoint_displacement.csv'))
control_cursor_anova(df)




