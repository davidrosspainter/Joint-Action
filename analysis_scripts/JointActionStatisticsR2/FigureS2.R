# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("FigureS2/")

fname = "D:\\JOINT.ACTION\\JointActionRevision\\analysis\\EEG_synchrony\\partPermutation2\\single_trial_correlations_accuracy_behavioral_neural.mat"
DATA <- readMat(fname)

df <- as_tibble(data.frame(subject_id = rep(seq(1, globals$number_of_sessions), 2)))
df$Control <- factor(c(rep("Solo", globals$number_of_sessions*1),
                       rep("Joint", globals$number_of_sessions*1)),
                     levels = globals$control_levels2)


# graph -------------------------------------------------------------------

for (i in seq(1,2)){
  
  print("----------------------------------------")
  print(i)
  
  if(i==1){
    
    df$DV <- c(DATA$behavioural.neural[,1], DATA$behavioural.neural[,2])
    
    control_plot(data = df,
                 ylabel = "Neural & Behav. Coupling (r)",
                 xlabel = "",
                 my_title = "",
                 ylimit = NULL,
                 filename = paste0(output_directory, "behavioural_neural.png"))
    
  }
  else if(i==2){
    
    df$DV <- c(DATA$accuracy.neural[,1], DATA$accuracy.neural[,2])
    
    control_plot(data = df,
                 ylabel = "Neural Coupling & Accuracy (r)",
                 xlabel = "",
                 my_title = "",
                 ylimit = NULL,
                 filename = paste0(output_directory, "accuracy_neural.png"))
  }
  
  print(t_test(df, DV ~ Control, paired=TRUE))
  my_summary(df, "Control")
  
  print(df %>% group_by(Control) %>% t_test(DV ~ 1, mu=0))
}

