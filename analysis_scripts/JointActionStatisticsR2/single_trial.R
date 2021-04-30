# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("single_trial/")

is_use_python = TRUE


filenames <- c('Accuracy', 'RT', 'MT', 'Curvature', 'Displace.', 'Gaze Dist.' , 'Behav. Coup.', 'Cue Amp.')
title_strings <- c('Accuracy', 'RT', 'MT', 'Curvature', 'Endpoint Displacement', 'Gaze Distance' , 'Behavioural Coupling', 'Task Cue Amplitude')

if (!is_use_python){
  fname = "D:\\JOINT.ACTION\\JointActionRevision\\analysis\\behavioural_performance\\collate_single_trial_results\\r_results.mat"
  DATA <- readMat(fname)
  measures <- c("r.accuracy", "r.RT", "r.MT", "r.curvature", "r.displacement", "r.gaze.distance", "r.behavioral.coupling", "r.task.cue.single.trial")
} else{
  
  print('using python!')
  
  library(reticulate)
  np <- import("numpy")
  
  npz <- np$load("..\\python_analysis\\collate_single_trial_results\\CorrelationsWithNeuralCoupling.npz")
  measures <- c('accuracy', 'RT', 'MT', 'curvature', 'endpoint_displacement', 'gaze_distance', 'behavioral_coupling', 'task_cue')
  
  for (i in seq(1, length(measures))){
    data_test <- npz$f[[measures[i]]] 
  }
  
}

y_limits = c()
y_limit = 0.4

for (i in seq(1,length(measures))){
  
  print("----------------------------------------")
  print(title_strings[i])
  
  if(!is_use_python){
    data_to_use <- DATA[[measures[i]]]  
  } else{
    print('using python!')
    data_to_use <- npz$f[[measures[i]]]  
  }
  
  data_to_use <- data_to_use[!is.na(data_to_use[,1]),]
  
  number_of_session_to_use <- nrow(data_to_use)
  
  df <- as_tibble(data.frame(subject_id = rep(seq(1, number_of_session_to_use), 2)))
  df$Control <- factor(c(rep("Solo", number_of_session_to_use*1),
                         rep("Joint", number_of_session_to_use*1)),
                       levels = globals$control_levels2)
  
  df$DV = c(data_to_use[,1], data_to_use[,2])
  
  filename = paste0("Neur. Coup. & ", filenames[i], ' (r)')
  title_to_use = bquote(paste(.(title_strings[i]), ' (', italic('r'), ')'))

  p <- control_plot(data = df,
               ylabel = title_to_use,
               xlabel = "Control",
               my_title = "",
               ylimit = c(-y_limit, +y_limit),
               filename = paste0(output_directory, filename, ".png"),
               plot_intercept=TRUE)
  
  
  y_limits = c(y_limits, max(abs(c(get_plot_limits(p)$ymin, get_plot_limits(p)$ymax))))
  
  print(t_test(df, DV ~ Control, paired=TRUE))
  my_summary(df, "Control")
  
  print(df %>% group_by(Control) %>% t_test(DV ~ 1, mu=0))
}


y_limit <- max(y_limits)

# multiple regression! ----------------------------------------------------

if (!is_use_python){
  fname = "D:\\JOINT.ACTION\\JointActionRevision\\analysis\\behavioural_performance\\endpoint_accuracy\\single_trial_measures.mat"
  DATA <- readMat(fname)
} else{
  
  print('using python!')
  
  npz <- np$load("..\\python_analysis\\collate_single_trial_results\\SingleTrialValues.npz")
  measures <- c('neural_coupling', 'accuracy', 'RT', 'MT', 'curvature', 'endpoint_displacement', 'gaze_distance', 'behavioral_coupling', 'task_cue', 'control_codes')
  
  for (i in seq(1, length(measures))){
    print(measures[i])
    data_test <- npz$f[[measures[i]]] 
  }

}

data_list <- vector(mode = "list", length = globals$number_of_sessions)

for (SESSION in seq(1,globals$number_of_sessions)){
  
  if (!is_use_python){
    
    IDX <- DATA$CONTROL[,SESSION] == 2
    
    neural_coupling <- DATA$neural.coupling[IDX, SESSION]
    accuracy <- DATA$accuracy[IDX, SESSION]
    RT <- DATA$RT[IDX, SESSION]
    endpoint_displacement <-DATA$endpoint.displacement[IDX, SESSION]
    behavioural_coupling <-DATA$behavioral.coupling[IDX, SESSION]
    
  }
  else{
    
    print('using python!')

    IDX <- npz$f[['control_codes']][,SESSION] == 2
    
    neural_coupling <- npz$f[['neural_coupling']][IDX,SESSION]
    accuracy <- npz$f[['accuracy']][IDX,SESSION]
    RT <- npz$f[['RT']][IDX,SESSION]
    endpoint_displacement <- npz$f[['endpoint_displacement']][IDX,SESSION]
    behavioural_coupling <-npz$f[['behavioral_coupling']][IDX,SESSION]
 
  }
  
  df <- as_tibble(data.frame(neural_coupling, accuracy, RT, endpoint_displacement, behavioural_coupling))
  
  model <- lm(scale(neural_coupling) ~ scale(accuracy) + scale(RT) + scale(endpoint_displacement) + scale(behavioural_coupling), data = df)
  result <- summary(model)
  res <- c(result$coefficients[1,1], result$coefficients[2,1], result$coefficients[3,1], result$coefficients[4,1], result$coefficients[5,1])
  
  data_list[[SESSION]] <- result$coefficients[,1]
  
}

test <- do.call(rbind.data.frame, data_list)

names(test) <- c('Intercept', 'accuracy', 'RT', 'endpoint_displacement', 'behavioural_coupling')




# plot beta weights -------------------------------------------------------


Measure <-
c(rep("Accuracy",globals$number_of_sessions), 
  rep("RT",globals$number_of_sessions),
  rep("Endpoint Disp.",globals$number_of_sessions),
  rep("Coup.",globals$number_of_sessions))

my_labels <- c("Accuracy",
               "RT", 
               "Endpoint\nDisplacement",
               "Behavioural\nCoupling")

DV <- c(test$accuracy, test$RT, test$endpoint_displacement, test$behavioural_coupling)
  
DF <- as_tibble(data.frame(Measure, DV))
DF$Measure <- factor(DF$Measure, levels=c('Accuracy', 'RT', 'Endpoint Disp.', 'Coup.'))

beta_plot <- function(data, ylabel, xlabel, my_title, ylimit, filename){
  
  df_summary <- summarySE(data, measurevar = "DV", groupvars=c("Measure"))
  
  p <- ggplot(data, aes(x = Measure, y = DV))+
    geom_hline(yintercept=0, linetype='dotted') +
    geom_flat_violin(position = position_nudge(x = .1, y = 0), adjust = 1.5, trim = FALSE, alpha = 1, colour='gray', fill='gray', width=.75)+
    geom_boxplot(aes(x = Measure, y = DV), outlier.shape = NA, width = .1, colour = "black")+
    geom_point(aes(x = as.numeric(Measure)-.15, y = DV), position = position_jitter(width = .05), size = 3, shape = 20, alpha=.5)+
    
    #geom_line(data = df_summary, aes(x = as.numeric(Measure)+.1, y = DV_mean), linetype = 3, size = 1)+
    geom_point(data = df_summary, aes(x = as.numeric(Measure)+.1, y = DV_mean), shape = 18, size = 1) +
    geom_errorbar(data = df_summary, aes(x = as.numeric(Measure)+.1, y = DV_mean, ymin = DV_mean-se, ymax = DV_mean+se), width = .05, size = 1)+
    ylab(ylabel) +
    xlab(xlabel) +
    theme_cowplot() +
    guides(fill = FALSE, colour = FALSE) +
    #geom_signif(comparisons = list(c(1,2)), map_signif_level=TRUE, test="t.test", test.args=list(alternative = "two.sided", paired=TRUE))+
    #scale_y_continuous(breaks=seq(0,30,10), limits=c(0,30))+
    ggtitle(my_title)+
    theme(plot.title=element_text(size=12, hjust = .5, face='plain'),
          plot.margin=grid::unit(c(1, 1, 1, 1), "mm"),
          axis.line = element_line(colour = 'black', size = 1),
          axis.ticks = element_line(colour = "black", size = 1))+
    scale_x_discrete(labels=my_labels)
    
  
  if(!is.null(ylimit)){
    p <- p + ylim(ylimit)
  }
  
  ggsave(plot=p, filename, width = 6, height = 3, dpi = 900)
  
  print(p)
  return(p)
}


beta_plot(data = DF,
             ylabel = expression(paste(italic(beta), " Weight for Joint Action")),
             xlabel = "Metric",
             my_title = "",
             ylimit = NULL,
             filename = paste0(output_directory, "beta_weights", ".png"))



# stats -------------------------------------------------------------------

print_summary <- function(data){
  result = array(data=NA, dim=c(1,3))
  
  result[1,1] = length(data)
  result[1,2] = as.numeric(sprintf(mean(data), fmt = '%#.2f'))
  result[1,3] = as.numeric(sprintf(sd(data), fmt = '%#.2f'))
  
  colnames(result) <- c('n', 'mean', 'sd')
  print(result)
}

metrics_to_use = c('accuracy', 'RT', 'endpoint_displacement', 'behavioural_coupling')

for (METRIC in metrics_to_use){
  print_stars()
  print(METRIC)
  print_summary(test[[METRIC]])
  print(t.test(test[[METRIC]], mu = 0, alternative = "two.sided"))
}

print_summary(sort(test$endpoint_displacement)[4:globals$number_of_sessions])
t.test(sort(test$endpoint_displacement)[4:globals$number_of_sessions], mu = 0, alternative = "two.sided")

# can two outperform one? -------------------------------------------------


fname = "D:\\JOINT.ACTION\\JointActionRevision\\analysis\\behavioural_performance\\accuracy2_coordination2\\cell_means.mat"
DATA <- readMat(fname)

measures <- c("accuracy.original", "accuracy.derived", "MT.original", "MT.derived", "RT.original", "RT.derived")

accuracy_original <- as_tibble(data.frame(DATA[['accuracy.original']]))
colnames(accuracy_original) <- globals$control_levels

for (SESSION in seq(1,globals$number_of_sessions)){
  accuracy_original[SESSION,1:2] = sort(accuracy_original[SESSION,1:2], decreasing = TRUE)
}

mean(accuracy_original$`HP Solo`)
mean(accuracy_original$`LP Solo`)
mean(accuracy_original$`Joint`)

two_heads <- accuracy_original$`Joint` - accuracy_original$`HP Solo`
session_id <- seq(1,globals$number_of_sessions)

df_two_heads <- as_tibble(data.frame(session_id, two_heads, test$endpoint_displacement))


# model <- lm(scale(accuracy_original$Joint) ~ scale(test.endpoint_displacement), data = df_two_heads)
# result <- summary(model)

cor.test(test$endpoint_displacement, accuracy_original$Joint)
cor.test(test$endpoint_displacement, accuracy_original$`HP Solo`)
cor.test(test$endpoint_displacement, accuracy_original$`HP Solo` - accuracy_original$Joint)
cor.test(test$endpoint_displacement, accuracy_original$`LP Solo`)
cor.test(test$endpoint_displacement, accuracy_original$`LP Solo` - accuracy_original$Joint)


accuracy_original$Joint[order(test$endpoint_displacement)]




# learning effects --------------------------------------------------------

data_list <- vector(mode = "list", length = globals$number_of_sessions)

r = matrix(data=NA, nrow=globals$number_of_sessions, ncol=3)

for (SESSION in seq(1,globals$number_of_sessions)){
  
  for (CONTROL in c(2)){
    if (!is_use_python){
      index <- DATA$CONTROL[,SESSION] == CONTROL
      neural_coupling <- DATA$neural.coupling[index, SESSION]
      endpoint_displacement <-DATA$endpoint.displacement[index, SESSION]
    }
    else{
      print('using python!')
      index <- npz$f[['control_codes']][,SESSION] == CONTROL
      
      trial <- seq(1, globals$number_of_trials/2)
      neural_coupling <- npz$f[['neural_coupling']][index,SESSION]
      accuracy <- npz$f[['accuracy']][index,SESSION]
      RT <- npz$f[['RT']][index,SESSION]
      MT <- npz$f[['MT']][index,SESSION]
      curvature <- npz$f[['curvature']][index,SESSION]
      endpoint_displacement <- npz$f[['endpoint_displacement']][index,SESSION]
      gaze_distance <- npz$f[['gaze_distance']][index,SESSION]
      task_cue <- npz$f[['task_cue']][index,SESSION]
    }
  }

  tmp <- cor.test(trial, neural_coupling)
  r[SESSION,1] = tmp$estimate
  
  tmp <- cor.test(trial, endpoint_displacement)
  r[SESSION,2] = tmp$estimate

  if (SESSION == 1){
    gaze_distance <- 0
  }  
  
  df <- as_tibble(data.frame(trial, neural_coupling, accuracy, RT, MT, curvature, endpoint_displacement, gaze_distance, task_cue))

  model <- lm(scale(trial) ~ scale(neural_coupling) + scale(accuracy) + scale(RT) + scale(MT) + scale(curvature) + scale(endpoint_displacement) + scale(task_cue), data = df)
  result <- summary(model)
  # res <- c(result$coefficients[2,1], result$coefficients[3,1])
  
  data_list[[SESSION]] <- result$coefficients[2:8,1]

}

test <- do.call(rbind.data.frame, data_list)

metrics = c('Neural Coupling', 'Accuracy', 'RT', 'MT', 'Curvature', 'Endpoint Displacement', 'Task Cue')
names(test) <- metrics

for (METRIC in seq(1, length((metrics)))){
  print(metrics[METRIC])
  result <- t.test(test[[metrics[METRIC]]], mu = 0, alternative = "two.sided")
  print(result)
}

t.test(test$endpoint_displacement, mu = 0, alternative = "two.sided")

Measure <- c()
DV <- c()

for (METRIC in seq(1, length((metrics)))){
  Measure <- c(Measure, rep(metrics[METRIC], globals$number_of_sessions))
  DV <- c(DV, test[[metrics[METRIC]]])
}

DF <- as_tibble(data.frame(Measure, DV))
DF$Measure <- factor(DF$Measure, levels=metrics)


my_labels <- c("Neural\nCoupling",
               "Endpoint\nDisplacement")


my_labels = c('Neural\nCoupling', 'Accuracy', 'RT', 'MT', 'Curvature', 'Endpoint\nDisplacement', 'Task\nCue')

beta_plot(data = DF,
          ylabel = expression(paste(italic(beta), " Weight for Joint Action")),
          xlabel = "Metric",
          my_title = "",
          ylimit = NULL,
          filename = paste0(output_directory, "beta_weights_trial", ".png"))