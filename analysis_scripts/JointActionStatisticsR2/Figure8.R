# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("Figure8/")


# load and organise -------------------------------------------------------

file = "..\\EEG_synchrony\\generate_trial_correlation_matrix\\accuracy.Cz.txt"
tmp <- read.delim(file, header = TRUE, sep = "\t", dec = ".")

df <- as_tibble(data.frame(subject_id = rep(seq(1,globals$number_of_sessions), 4)))

df$Control <- factor(c(rep("Solo",globals$number_of_sessions*2),
                       rep("Joint",globals$number_of_sessions*2)),
                     levels = globals$control_levels2)

df$Accuracy <- factor(c(rep("Error",globals$number_of_sessions),
                        rep("Correct",globals$number_of_sessions),
                        rep("Error",globals$number_of_sessions),
                        rep("Correct",globals$number_of_sessions)),
                      levels = globals$accuracy_levels)

df$DV <- c(tmp$soloE, tmp$soloC, tmp$jointE, tmp$jointC)


# plot -----------------------------------------------------------------------

control_accuracy_plot(df, expression(paste("Inter-Brain Correlation (", italic("r"), ")")), paste0(output_directory, "Figure8.png"), NULL, c(.25,.95))
control_accuracy_anova(df)
control_accuracy_spss_csv(df, paste0(output_directory, "inter-brain_correlations.csv"))