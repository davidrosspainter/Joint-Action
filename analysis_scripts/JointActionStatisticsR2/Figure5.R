# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("Figure5/")


DATA = c("onset", "offset", "displacement")
ylabels = c(expression(paste("Onset Correlation (", italic("r"), ")")),
            expression(paste("Offset Correlation (", italic("r"), ")")),
            expression(paste("Displace. Correlation (", italic("r"), ")")))

count = 1

for (data in DATA){

  cat('*****************************\n')
  cat(data)
  cat('\n\n')
  
  df <- as_tibble(data.frame(subject_id = rep(seq(1,globals$number_of_sessions), 4)))
  
  df$Control <- factor(c(rep("Solo",globals$number_of_sessions*2),
                         rep("Joint",globals$number_of_sessions*2)),
                       levels = globals$control_levels2)
  
  df$Accuracy <- factor(c(rep("Error",globals$number_of_sessions),
                          rep("Correct",globals$number_of_sessions),
                          rep("Error",globals$number_of_sessions),
                          rep("Correct",globals$number_of_sessions)),
                        levels = globals$accuracy_levels)
    
  if (data == "displacement"){
    file = "..\\behavioural_performance\\analyse_behaviour6_force\\displacement.txt"  
    tmp <- read.delim(file, header = TRUE, sep = "\t", dec = ".")
    df$DV <- c(tmp$error_solo, tmp$correct_solo, tmp$error_joint, tmp$correct_joint)
  }
  else{
    file = paste0("..\\behavioural_performance\\accuracy3\\", data, ".txt")  
    tmp <- read.delim(file, header = TRUE, sep = "\t", dec = ".")
    df$DV <- c(tmp$solo.error, tmp$solo.correct, tmp$joint.error, tmp$joint.correct)
  }
  
  p <- control_accuracy_plot(df, ylabels[count], paste0(output_directory, data, ".png"), c(-1, +1), c(.75,.2))
  #limits = get_plot_limits(p)
  #print(limits)
  count = count + 1
  control_accuracy_anova(df)
  control_accuracy_spss_csv(df, paste0(output_directory, data, ".csv"))
}









