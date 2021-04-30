# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("Figure6/")


# load and organise -------------------------------------------------------

filename = "..\\EEG_task_cue\\task_cue_group2\\Control_cue.mat"
DATA <- readMat(filename)

df <- as_tibble(data.frame(subject_id = rep(seq(1, globals$number_of_participants), 2)))

df$Control <- as.factor(c(rep("Solo",globals$number_of_participants),rep("Joint",globals$number_of_participants)))
df$Control <- factor(df$Control, levels = globals$control_levels2)
df$DV <- c(DATA$control.cue[,1], DATA$control.cue[,2])

# plot -----------------------------------------------------------------------

p = control_plot(df, expression(paste("SSVEP Amp. (", italic(mu), "V)")), "Control", "", c(), paste0(output_directory, "Figur6.png"))


# analyse -----------------------------------------------------------------------

test <- df %>%
pairwise_t_test(
  DV ~ Control, paired = TRUE,
  p.adjust.method = "bonferroni"
)

df_summary <- summarySE(df, measurevar = "DV", groupvars=c("Control"))
print(df_summary)

print(test)