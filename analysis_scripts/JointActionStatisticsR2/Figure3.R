  # prepare ----------------------------------------------------------------
  
  rm(list = ls())
  source("common.R")
  
  clean_start()
  load_libraries()
  globals = get_globals()
  output_directory = set_output_directory("Figure3/")
  
  # load ----------------------------------------------------------------
  
  fname = r"(D:\\JOINT.ACTION\\JointActionRevision\\analysis\\behavioural_performance\\curvature_runner\\curvature_results.mat)"
  measures <- c("curvature.experiment.sorting.Visible", "curvature.trial.sorting.Visible", "curvature.experiment.sorting.Invisible", "curvature.trial.sorting.Invisible")
  DATA <- readMat(fname)
  
  
  # organise ---------------------------------------------------------------------
  
  DV <- c(
    DATA$curvature.trial.sorting.original[,1],
    DATA$curvature.trial.sorting.original[,2],
    DATA$curvature.trial.sorting.original[,3],
    DATA$curvature.trial.sorting.reversed[,1],
    DATA$curvature.trial.sorting.reversed[,2],
    DATA$curvature.trial.sorting.reversed[,3])
  
  df <- as_tibble(data.frame(DV))
  df$Cursor = c(rep("Visible", 60), rep("Invisible", 60))
  df$Cursor = factor(df$Cursor, globals$cursor_levels)
  df$subject_id <- c(rep(seq(1,globals$number_of_sessions),6))
  
  df$Control <- rep(c(rep("HP Solo", globals$number_of_sessions), rep("LP Solo", globals$number_of_sessions), rep("Joint", globals$number_of_sessions)), 2)
  df$Control <- factor(df$Control, levels = globals$control_levels)
  
  
  # plot -----------------------------------------------------------------------
  
  # p = control_cursor_plot(df, expression(paste('|', Sigma, 'Curvature| (°)')), paste0(output_directory, "curvature.png"))
  p = control_cursor_plot(df, expression(paste('Curvature (°)')), paste0(output_directory, "curvature.png"))
  control_cursor_spss_csv(df, paste0(output_directory, 'curvature.csv'))
  control_cursor_anova(df)
  
  
  
