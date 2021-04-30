# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("Figure2_new/")


# load and organise -------------------------------------------------------

fname = "D:\\JOINT.ACTION\\JointActionRevision\\analysis\\behavioural_performance\\endpoint_accuracy\\results.mat"
DATA <- readMat(fname)

fname = "D:\\JOINT.ACTION\\JointActionRevision\\analysis\\behavioural_performance\\endpoint_accuracy\\array.mat"
array <- readMat(fname)

array.x <- array$array[[4]]
array.y <- array$array[[5]]
dpp = (53.2 / 1920) # degrees/pixel
sizes.target <- 76.9231 * dpp


# setup ---------------------------------------------------------------

library(reshape2)

number_of_control = 2
number_of_visibility = 2
number_of_players = 2
number_of_figure_types = 2
number_of_targets = 8

str_control = c('HP Solo', 'LP Solo', 'Joint')
str_visibility = c('Visible', 'Invisible')
str_figure = c("endpoints", "trajectories")

col_target = c(
  rgb(0.5, 0.25, 0.6),
  rgb(1, 0, 1),
  rgb(1, 0, 0),
  rgb(1, 0.36, 0),
  rgb(1, 1, 0),
  rgb(0, 1, 0),
  rgb(0, 1, 1),
  rgb(0, 0, 1))


figure_key <- as_tibble(data.frame(matrix(ncol = 3, nrow = 0)))
colnames(figure_key) <- c('VISIBILITY', 'CONTROL', 'i')

i = 0

for (VISIBILITY in str_visibility) {
  for (CONTROL in str_control) {
    i <- i + 1
    de <- data.frame(VISIBILITY, CONTROL, i)
    names(de) <- c('VISIBILITY', 'CONTROL', 'i')
    figure_key <- rbind(figure_key, de)
  }
}


ED <-
  array(dim = c(
    globals$number_of_sessions,
    number_of_control + 1,
    number_of_visibility
  ))

graphics.off()

endpoint_plot <- function(df, plot_title, filename){
  p <- force(ggplot(df) +
             geom_point(data=df,
                        aes(x = x, y = y),
                        size = 1,
                        shape = 20,
                        alpha = .5,
                        color = col_target[df$target_position]) +
             ggtitle(plot_title) +
             xlim(c(-1,+1) * 13) +
             ylim(c(-1,+1) * 13) +
             xlab(expression(paste(italic('x'), ' (°)'))) +
             ylab(expression(paste(italic('y'), ' (°)'))) +
             theme_cowplot() +
             theme(
               plot.margin = grid::unit(c(1, 1, 1, 1), "mm"),
               legend.position = 'top',
               legend.justification = .5,
               legend.text = element_text(size = 13),
               axis.title = element_text(size = 11),
               axis.text = element_text(size = 11),
               plot.title = element_text(
                 size = 14,
                 hjust = .5,
                 face = 'plain'
               ),
               axis.line = element_line(colour = 'black', size = 1),
               axis.ticks = element_line(colour = "black", size = 1)
             ))
  
  for (TARGET in seq(1, number_of_targets)) {
    p <- p + annotate( "path", x = array.x[TARGET] * dpp + sizes.target / 2 * cos(seq(0, 2 * pi, length.out = 100)), y = array.y[TARGET] * dpp + sizes.target / 2 * sin(seq(0, 2 * pi, length.out = 100)))
  }
  
  width = 3*2/3; height = 3*2/3*1.8521/1.6301
  ggsave(plot = p, filename = filename, width = width, height = height, dpi = 900)
 
  return(p) 
}

trajectory_plot <- function(df, plot_title, filename){
  p <- force(ggplot(df) +
               geom_path(aes(x=x, y=y, group=trial),
                         data=df,
                         color = col_target[df$target_position],
                         size = .25,
                         alpha = .5) +
               ggtitle(plot_title) +
               xlim(c(-1,+1) * 13) +
               ylim(c(-1,+1) * 13) +
               xlab(expression(paste(italic('x'), ' (°)'))) +
               ylab(expression(paste(italic('y'), ' (°)'))) +
               theme_cowplot() +
               theme(
                 plot.margin = grid::unit(c(1, 1, 1, 1), "mm"),
                 legend.position = 'top',
                 legend.justification = .5,
                 legend.text = element_text(size = 13),
                 axis.title = element_text(size = 11),
                 axis.text = element_text(size = 11),
                 plot.title = element_text(
                   size = 14,
                   hjust = .5,
                   face = 'plain'
                 ),
                 axis.line = element_line(colour = 'black', size = 1),
                 axis.ticks = element_line(colour = "black", size = 1)
               ))
  
  for (TARGET in seq(1, number_of_targets)) {
    p <- p + annotate( "path", x = array.x[TARGET] * dpp + sizes.target / 2 * cos(seq(0, 2 * pi, length.out = 100)), y = array.y[TARGET] * dpp + sizes.target / 2 * sin(seq(0, 2 * pi, length.out = 100)))
  }
  
  width = 3*2/3; height = 3*2/3*1.8521/1.6301
  ggsave(plot = p, filename = filename, width = width, height = height, dpi = 900)
  
  return(p) 
}

plot_summary <- function(subplots, filename){
  p2 <- plot_grid(subplots[[1]], subplots[[2]], subplots[[3]], subplots[[4]], subplots[[5]], subplots[[6]], nrow=2, ncol=3)
  #print(p2)
  width = 8.5; height = 6.4379
  ggsave(plot = p2, filename = filename, width = width, height = height, dpi = 900)
  return(p2)
}

endpoint_plot_by_condition <- function(){
  
  subplots <- vector(mode = "list", length = nrow(figure_key))
  subplots2 <- vector(mode = "list", length = nrow(figure_key))
  
  DF <- vector(mode = "list", length = nrow(figure_key))
  DF2 <- vector(mode = "list", length = nrow(figure_key))
  
  for (i in seq(1, nrow(figure_key))){
    
    VISIBILITY = figure_key[i,'VISIBILITY']
    CONTROL = figure_key[i,'CONTROL']
    
    if (CONTROL %in% str_control[1:2]){
      
      PLAYER = match(CONTROL, str_control[1:2])
      
      if (VISIBILITY == 'Visible') {
        COND = 1
      } else if (VISIBILITY == 'Invisible') {
        COND = 2
      }
      
      # figure 1
      
      FIGURE = 1
      
      endpoint <- results.endpoint[, results.control == COND, 1:2]
      endpoint_displacement <- results.endpoint_displacement[results.control == COND, 1:2]
      target_position <- results.target_position[results.control == COND]
      
      # sort by best performer on endpoint displacement
      
      for (TRIAL in seq(1, globals$number_of_trials / 2)) {
        index <- order(endpoint_displacement[TRIAL, ], decreasing = FALSE)
        endpoint_displacement[TRIAL, ] <- endpoint_displacement[TRIAL, index]
        endpoint[, TRIAL, ] <- endpoint[, TRIAL, index]
      }
      
      ED[SESSION, 1:2, match(VISIBILITY, str_visibility)] = mean(endpoint_displacement, na.rm = TRUE)
      
      plot_title <- paste(str_control[PLAYER], VISIBILITY)
      filename <- paste0(output_directory, 'endpoint.', paste(as.character(SESSION), str_figure[FIGURE], str_control[PLAYER], VISIBILITY), '.png')
      
      DF[[i]] <- as_tibble(data.frame(matrix(ncol = 3, nrow = globals$number_of_trials/2)))
      names(DF[[i]]) <- c('target_position', 'x', 'y')
      DF[[i]]$x <- endpoint[1, , PLAYER]
      DF[[i]]$y <- endpoint[2, , PLAYER]
      DF[[i]]$target_position <- target_position
      
      subplots[[i]] <- endpoint_plot(DF[[i]], plot_title, filename)
      
      # figure 2
      
      FIGURE = 2
      
      trajectory = results.trajectory[,,results.control == COND, 1:2]
      target_position = results.target_position[results.control == COND]
      
      curvature_to_use = curvature_results[results.control == COND, 1:2]
      
      # sort by best performer on trajectory displacement
      
      for (TRIAL in seq(1, globals$number_of_trials / 2)) {
        index <- order(curvature_to_use[TRIAL, ], decreasing = FALSE)
        trajectory[,,TRIAL,] = trajectory[,,TRIAL,index]
      }
      
      plot_title <- paste(str_control[PLAYER], VISIBILITY)
      filename <- paste0(output_directory, 'trajectory.', paste(as.character(SESSION), str_figure[FIGURE], str_control[PLAYER], VISIBILITY), '.png')
      
      df.x <- as_tibble(as.data.frame.table(drop(results.trajectory[1,,results.control == COND,PLAYER])))
      names(df.x) <- c('frame', 'trial', 'x')
      
      df.y <- as_tibble(as.data.frame.table(drop(results.trajectory[2,,results.control == COND,PLAYER])))
      names(df.y) <- c('frame', 'trial', 'y')
      
      df.xy <- df.x %>% right_join(df.y, by=c('frame', 'trial'))
      df.xy$trial <- as.numeric(df.xy$trial)
      df.xy$frame <- as.numeric(df.xy$frame)
      df.xy$target_position <- target_position[df.xy$trial]
      
      DF2[[i]] = df.xy
      
      subplots2[[i]] <- trajectory_plot(DF2[[i]], plot_title, filename)
      

    } else if (CONTROL %in% str_control[3]){
      
      PLAYER = match(CONTROL, str_control)
      
      if (VISIBILITY == 'Visible') {
        COND = 2
      } else if (VISIBILITY == 'Invisible') {
        COND = 1
      }
      
      # figure 1
      
      FIGURE = 1
      
      endpoint <- results.endpoint[, results.control == COND, 3]
      endpoint_displacement <- results.endpoint_displacement[results.control == COND, 3]
      target_position <- results.target_position[results.control == COND]
      ED[SESSION, 3, match(VISIBILITY, str_visibility)] = mean(endpoint_displacement, na.rm = TRUE)
      
      plot_title <- paste(str_control[PLAYER], VISIBILITY)
      filename <- paste0(output_directory, paste(as.character(SESSION), str_figure[FIGURE], str_control[PLAYER], VISIBILITY), '.png')
      
      DF[[i]] <- as_tibble(data.frame(matrix(ncol = 3, nrow = globals$number_of_trials/2)))
      names(DF[[i]]) <- c('target_position', 'x', 'y')
      DF[[i]]$target_position <- target_position
      DF[[i]]$x <- endpoint[1,]
      DF[[i]]$y <- endpoint[2,]
      
      subplots[[i]] <- endpoint_plot(DF[[i]], plot_title, filename)
      
      # figure 2
      
      FIGURE = 2
      
      plot_title <- paste(str_control[PLAYER], VISIBILITY)
      filename <- paste0(output_directory, 'trajectory.', paste(as.character(SESSION), str_figure[FIGURE], str_control[PLAYER], VISIBILITY), '.png')
      
      df.x <- as_tibble(as.data.frame.table(drop(results.trajectory[1,,results.control == COND,PLAYER])))
      names(df.x) <- c('frame', 'trial', 'x')
      
      df.y <- as_tibble(as.data.frame.table(drop(results.trajectory[2,,results.control == COND,PLAYER])))
      names(df.y) <- c('frame', 'trial', 'y')
      
      df.xy <- df.x %>% right_join(df.y, by=c('frame', 'trial'))
      df.xy$trial <- as.numeric(df.xy$trial)
      df.xy$frame <- as.numeric(df.xy$frame)
      df.xy$target_position <- target_position[df.xy$trial]
      
      DF2[[i]] = df.xy
      
      subplots2[[i]] <- trajectory_plot(DF2[[i]], plot_title, filename)
    }
  }
  
  p2 <- plot_summary(subplots, paste0(output_directory, 'summary.endpoint.', as.character(SESSION), '.png'))
  p2 <- plot_summary(subplots2, paste0(output_directory, 'summary.trajectory.', as.character(SESSION), '.png'))
  
  outputs = list(DF, DF2)
  
  return(outputs)
  
}

DF = vector('list', globals$number_of_sessions)
DF2 = vector('list', globals$number_of_sessions)

fname <- paste0("..\\behavioural_performance\\curvature_runner\\collated_curvature_results.mat")
tmp <- readMat(fname)

for (SESSION in seq(1, globals$number_of_sessions)){
  
  print_stars()
  print(SESSION)
  
  SESSION_MODIFIER = (SESSION - 1) * 5
  
  results.control <- as.vector(DATA$results[[1 + SESSION_MODIFIER]])
  results.target_position <- as.vector(DATA$results[[2 + SESSION_MODIFIER]])
  results.endpoint <- DATA$results[[3 + SESSION_MODIFIER]] # dim(results.endpoint) 2, 960, 3
  results.endpoint_displacement <- DATA$results[[4 + SESSION_MODIFIER]] # dim(endpoint.displacement) 960, 3
  results.trajectory <- DATA$results[[5 + SESSION_MODIFIER]] # dim(trajectory) 2, 1008, 960, 3  

  curvature_results = tmp$collated.curvature.results[,,SESSION]
  
  if (SESSION == 20) {
    curvature_results[705:globals$number_of_trials,] = NaN # controller disconnected
  }
  
  outputs <- endpoint_plot_by_condition()
  
  DF[[SESSION]] <- outputs[[1]]
  DF2[[SESSION]] <- outputs[[2]]
  
}


# group_plot --------------------------------------------------------------

group_plot <- function(DF, filename_modifier){
  df <- vector('list', nrow(figure_key))
  
  for (i in seq(1, nrow(figure_key))){
    df[[i]] <- as_tibble(data.frame(matrix(ncol = 3, nrow = 0)))
    names(df[[i]]) <- c('target_position', 'x', 'y')
  }
  
  for (SESSION in seq(1, globals$number_of_sessions)){
    for (i in seq(1, nrow(figure_key))){
      df[[i]] <- rbind(df[[i]], DF[[SESSION]][[i]])  
    }
  }
  
  subplots = list('vector', nrow(figure_key))
  
  for (i in seq(1, nrow(figure_key))){
    plot_title <- paste(figure_key[i,]$CONTROL, figure_key[i,]$VISIBILITY)
    filename <- paste0(output_directory, 'group.', filename_modifer, '.', paste(figure_key[i,]$CONTROL, figure_key[i,]$VISIBILITY), '.png')
    subplots[[i]] <- endpoint_plot(df[[i]], plot_title, filename)
  }
  
  p2 <- plot_summary(subplots, paste0(output_directory, 'group.', filename_modifier, '.summary.png'))
}

ptm <- proc.time()
group_plot(DF, "endpoint")
proc.time() - ptm

ptm <- proc.time()
group_plot(DF2, "trajectory")
proc.time() - ptm