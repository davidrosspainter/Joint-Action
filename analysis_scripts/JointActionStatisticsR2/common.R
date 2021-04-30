clean_start <- function(){
  
  graphics.off()
  
  detachAllPackages <- function() {
    basic.packages <- c("package:stats","package:graphics","package:grDevices","package:utils","package:datasets","package:methods","package:base")
    package.list <- search()[ifelse(unlist(gregexpr("package:",search()))==1,TRUE,FALSE)]
    package.list <- setdiff(package.list,basic.packages)
    if (length(package.list)>0)  for (package in package.list) detach(package, character.only=TRUE)
  }
  
  rm(list=ls())
  
  cat("\014")
}

specify_decimal <- function(x, k){
  return (trimws(format(round(x, k), nsmall=k)))
}

get_plot_limits <- function(plot) {
  gb = ggplot_build(plot)
  xmin = gb$layout$panel_params[[1]]$x.range[1]
  xmax = gb$layout$panel_params[[1]]$x.range[2]
  ymin = gb$layout$panel_params[[1]]$y.range[1]
  ymax = gb$layout$panel_params[[1]]$y.range[2]
  list(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
}

load_libraries <- function(){
  setwd("D:\\JOINT.ACTION\\JointActionRevision\\analysis\\JointActionStatisticsR2\\")
  
  directory_raincloud = paste0(getwd(),"/RainCloudPlots-master/tutorial_R/")
  
  source(paste0(directory_raincloud,"R_rainclouds.R"))
  source(paste0(directory_raincloud,"summarySE.R"))
  #source(paste0(directory_raincloud,"simulateData.R"))
  
  library(rstatix) # anova
  library(ggpubr) # plot
  library(R.matlab)
  library(cowplot)
  library(dplyr)
  library(readr)
  library(gridExtra)
  library(grid)
  library(RColorBrewer)
  library(ggpubr) # significance levels
  library(ggsci)
  library(tidyverse)
}

set_output_directory <- function(output_directory){
  if (!dir.exists(output_directory)){
    dir.create(output_directory)  
  }
  return(output_directory)
}

get_globals <- function(){
  globals <- list(number_of_sessions = 20,
                  number_of_participants = 40,
                  number_of_trials = 960,
                  cursor_levels = c("Visible", "Invisible"),
                  control_levels = c("HP Solo", "LP Solo", "Joint"),
                  control_levels2 = c("Solo", "Joint"),
                  accuracy_levels = c("Correct","Error"))
  return (globals)
}


print_stars <- function(n=50){
  print(strrep('*', n))
}

control_cursor_plot <- function(df, ylabel, filename)
{
  
  df_summary <- summarySE(df, measurevar = "DV", groupvars=c("Control", "Cursor"))
  
  p1 <- ggplot(df, aes(x = Control, y = DV, fill = Cursor)) +
    geom_flat_violin(aes(fill = Cursor), position = position_nudge(x = .1, y = 0), adjust = 1.5, trim = FALSE, alpha = .5, colour=NA, width=.75)+
    geom_boxplot(aes(x = Control, y = DV, fill = Cursor), outlier.shape = NA, width = .1, colour = "black")+
    geom_point(aes(x = as.numeric(Control)-.15, y = DV, colour = Cursor), position = position_jitter(width = .05), size = 3, shape = 20, alpha=.5)+
    
    geom_line(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, group = Cursor, colour = Cursor), linetype = 3, size = 1)+
    geom_point(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, group = Cursor, colour = Cursor), shape = 18, size = 1) +
    geom_errorbar(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, group = Cursor, colour = Cursor, ymin = DV_mean-se, ymax = DV_mean+se), width = .05, size = 1)+
    
    theme_cowplot()+
    scale_color_aaas() +
    scale_fill_aaas()+
    theme(plot.margin=grid::unit(c(1, 1, 1, 1), "mm"),
          legend.position = 'top',
          legend.justification = .5,
          legend.title = element_text(size=13), legend.text = element_text(size=13),
          axis.title = element_text(size=14),
          axis.text = element_text(size=14),
          plot.title=element_text(size=12, hjust = .5, face='plain'),
          axis.line = element_line(colour = 'black', size = 1),
          axis.ticks = element_line(colour = "black", size = 1))+
    ylab(ylabel)+
    ggtitle("")
  
  print(p1)
  
  width = 6; height = 3
  ggsave(plot=p1, filename, width = width, height = height, dpi = 900)
  
  return(p1)
}


control_plot <- function(data, ylabel, xlabel, my_title, ylimit, filename, plot_intercept=FALSE){
  
  df_summary <- summarySE(data, measurevar = "DV", groupvars=c("Control"))
  
  p <- ggplot(data, aes(x = Control, y = DV))
  
  if(plot_intercept==TRUE){
    p <- p + geom_hline(yintercept=0, linetype='dotted')
  }
  
  p <- p +
    geom_flat_violin(position = position_nudge(x = .1, y = 0), adjust = 1.5, trim = FALSE, alpha = 1, colour='gray', fill='gray', width=.75)+
    geom_boxplot(aes(x = Control, y = DV), outlier.shape = NA, width = .1, colour = "black")+
    geom_point(aes(x = as.numeric(Control)-.15, y = DV), position = position_jitter(width = .05), size = 3, shape = 20, alpha=.5)+
    
    geom_line(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean), linetype = 3, size = 1)+
    geom_point(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean), shape = 18, size = 1) +
    geom_errorbar(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, ymin = DV_mean-se, ymax = DV_mean+se), width = .05, size = 1)+
    
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
          axis.ticks = element_line(colour = "black", size = 1))
  
  if(!is.null(ylimit)){
    p <- p + ylim(ylimit)
  }
  
  ggsave(plot=p, filename, width = 3, height = 3, dpi = 900)
  
  print(p)
  return(p)
}


control_accuracy_plot <- function(data, ylabel, filename, ylimit, legend_position){
  
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
    ggtitle("")

  if(!is.null(ylimit)){
    p <- p + ylim(ylimit)
  }
  
  print(p)  
  ggsave(plot=p, filename, width = 3, height = 3, dpi = 900)
  
  return(p)  
  
}

control_accuracy_anovaXXXXXXXXXXXXXXXXX <- function(df){
  
  results.aov <- anova_test(
    data = df, dv = DV, wid = subject_id,
    within = c(Control, Accuracy), effect.size="pes"
  )
  
  results.aov <- as_tibble(results.aov)
  
  results.aov$F <- as.numeric(specify_decimal(results.aov$F, 2))
  results.aov$p <- as.numeric(specify_decimal(results.aov$p, 3))
  
  results.aov$pes <- as.numeric(specify_decimal(results.aov$pes, 3))
  
  results.aov$`p<.05`[results.aov$p > .05] = 'NS'
  results.aov$`p<.05`[results.aov$p < .05] = '*'
  results.aov$`p<.05`[results.aov$p < .01] = '**'
  results.aov$`p<.05`[results.aov$p < .001] = '***'
  
  print(results.aov)
  
  pwc <- df %>%
    group_by(Control) %>%
    pairwise_t_test(
      DV ~ Accuracy, paired = TRUE,
      p.adjust.method = "bonferroni"
    )
  
  pwc$`p.adj.signif`[pwc$p.adj > .05] = 'NS'
  pwc$`p.adj.signif`[pwc$p.adj < .05] = '*'
  pwc$`p.adj.signif`[pwc$p.adj < .01] = '**'
  pwc$`p.adj.signif`[pwc$p.adj < .001] = '***'
  
  pwc$p <- as.numeric(specify_decimal(pwc$p, 3))
  pwc$p.adj <- as.numeric(specify_decimal(pwc$p, 3))
  
  print(pwc)
  
  for (i in seq(1,3)) {
    
    print(i)
    
    switch(i, 
           { groupvars=c("Control", "Accuracy") },
           { groupvars=c("Control") },
           { groupvars=c("Accuracy") },  
    )
    
    df_summary <- as_tibble(summarySE(df, measurevar = "DV", groupvars=groupvars))
    
    variables = c('DV_mean', 'DV_median', 'sd', 'se', 'ci')
    
    for(variable in variables){
      df_summary[[variable]] = as.numeric(specify_decimal(df_summary[[variable]], 2))  
    }
    
    print(df_summary[,c(groupvars, 'DV_mean', 'sd')])
    
  }
}

control_cursor_spss_csv <- function(df, filename){
  df2 <- as_tibble(data.frame(id=seq(1, globals$number_of_sessions)))
  
  for (control in globals$control_levels){
    #print(control)
    for(cursor in globals$cursor_levels){
      #print(Cursor)
      index <- df$Control == control & df$Cursor == cursor
      df2[[str_replace(paste0(control, '_', cursor), " ", "_")]] <- df$DV[index]
    }
  }
  write_csv(df2, filename)
}


control_accuracy_spss_csv <- function(df, filename){
  df2 <- as_tibble(data.frame(id=seq(1, globals$number_of_sessions)))
  
  for (control in globals$control_levels2){
    #print(control)
    for(accuracy in globals$accuracy_levels){
      #print(Cursor)
      index <- df$Control == control & df$Accuracy == accuracy
      df2[[str_replace(paste0(control, '_', accuracy), " ", "_")]] <- df$DV[index]
    }
  }
  write_csv(df2, filename)
}

my_pwc <- function(pwc){
  pwc = as.data.frame(pwc)
  
  pwc$`p.adj.signif`[pwc$p.adj > .05] = 'NS'
  pwc$`p.adj.signif`[pwc$p.adj < .05] = '*'
  pwc$`p.adj.signif`[pwc$p.adj < .01] = '**'
  pwc$`p.adj.signif`[pwc$p.adj < .001] = '***'
  
  pwc$statistic <- as.numeric(specify_decimal(pwc$statistic, 2))
  pwc$p.round <- as.numeric(specify_decimal(pwc$p, 3))
  
  cat('pairwise comparisons:\n')
  print(pwc)
  cat('\n')
}

my_summary <- function(df, grouping_variables){
  
  df_summary <- as_tibble(summarySE(df, measurevar = "DV", groupvars=grouping_variables))
  
  variables = c('DV_mean', 'DV_median', 'sd', 'se', 'ci')
  
  for(variable in variables){
    df_summary[[variable]] = as.numeric(specify_decimal(df_summary[[variable]], 2))  
  }
  
  df_summary = as.data.frame(df_summary)
  print(df_summary[, c(grouping_variables, 'DV_mean', 'sd')])
  cat('\n')
  
}

control_cursor_anova <- function(df){
  
  pretty_anova <- function(anova_results){
    
    clean_p_strings <- function(p_strings, p_values){
      p_strings[p_values > .05] = 'NS'
      p_strings[p_values < .05] = '*'
      p_strings[p_values < .01] = '**'
      p_strings[p_values < .001] = '***'
      return (p_strings)
    }
    
    format_anova <- function(anova_results){
      anova_results$p.round <- as.numeric(specify_decimal(anova_results$p, 3))
      anova_results$F <- as.numeric(specify_decimal(anova_results$F, 2))
      anova_results$pes <- as.numeric(specify_decimal(anova_results$pes, 3))
      
      anova_results$`p<.05` = clean_p_strings(anova_results$`p<.05`, anova_results$p)
      return(anova_results)
    }
    
    anova_results$ANOVA = format_anova(anova_results$ANOVA)
    
    anova_results$`Sphericity Corrections` = anova_results$`Sphericity Corrections`[c('Effect', 'DF[GG]', 'p[GG]', 'p[GG]<.05')]
    anova_results$`Sphericity Corrections`$'p[GG]<.05' = clean_p_strings(anova_results$`Sphericity Corrections`$'p[GG]<.05', anova_results$`Sphericity Corrections`$'p[GG]')
    anova_results$`Sphericity Corrections`$p.round <- as.numeric(specify_decimal(anova_results$`Sphericity Corrections`$'p[GG]', 3))
    
    cat("ANOVA results:\n")
    print(anova_results)
    cat('\n') 
    
  }
  
  cat('----------------')
  cat('All')
  cat('\n\n')  
  pretty_anova(anova_test(data = df, dv = DV, wid = subject_id, within = c(Control, Cursor), effect.size="pes"))
  
  for(cursor in globals$cursor_levels){
    cat('----------------')
    cat(cursor)
    cat('\n\n')
    pretty_anova(anova_test(data = df[df$Cursor == cursor,], dv = DV, wid = subject_id, within = Control, effect.size="pes"))  
  }
  
  pwc <- df %>%
    group_by(Control) %>%
    pairwise_t_test(
      DV ~ Cursor, paired = TRUE,
      p.adjust.method = "bonferroni"
    )
  
  my_pwc(pwc)
  cat('\n')
  
  pwc <- df %>%
    group_by(Cursor) %>%
    pairwise_t_test(
      DV ~ Control, paired = TRUE,
      p.adjust.method = "bonferroni"
    )
  
  my_pwc(pwc)
  cat('\n') 
  
  
  cat("cell means:\n")
  
  for (i in seq(1,3)) {

    switch(i, 
           { grouping_variables=c("Control", "Cursor") },
           { grouping_variables=c("Control") },
           { grouping_variables=c("Cursor") },  
    )
    
    my_summary(df, grouping_variables)
    cat('\n')
  }
  
}

control_accuracy_anova <- function(df){
  
  results.aov <- anova_test(
    data = df, dv = DV, wid = subject_id,
    within = c(Control, Accuracy), effect.size="pes"
  )
  
  results.aov$p.round <- as.numeric(specify_decimal(results.aov$p, 3))
  
  #results.aov <- as_tibble(results.aov)
  
  results.aov$F <- as.numeric(specify_decimal(results.aov$F, 2))
  #results.aov$p <- as.numeric(specify_decimal(results.aov$p, 3))
  
  results.aov$pes <- as.numeric(specify_decimal(results.aov$pes, 3))
  
  results.aov$`p<.05`[results.aov$p > .05] = 'NS'
  results.aov$`p<.05`[results.aov$p < .05] = '*'
  results.aov$`p<.05`[results.aov$p < .01] = '**'
  results.aov$`p<.05`[results.aov$p < .001] = '***'
  
  cat("ANOVA results:\n")
  print(results.aov)
  cat('\n')
  
  pwc <- df %>%
    group_by(Control) %>%
    pairwise_t_test(
      DV ~ Accuracy, paired = TRUE,
      p.adjust.method = "bonferroni"
    )

  my_pwc(pwc)
  cat('\n')
  
  cat("cell means:\n")
  
  for (i in seq(1,3)) {

    switch(i, 
           { grouping_variables=c("Control", "Accuracy") },
           { grouping_variables=c("Control") },
           { grouping_variables=c("Accuracy") },  
    )
    
    my_summary(df, grouping_variables)
    cat('\n')
  }
  
  # difference scores
  cat("difference scores:\n")
  
  difference_scores = data.frame(subject_id = rep(seq(1,globals$number_of_sessions),2))
  difference_scores$Control = c(rep(globals$control_levels2[1], globals$number_of_sessions),
                                rep(globals$control_levels2[2], globals$number_of_sessions))
  
  for (control in globals$control_levels2){
    index1 = df$Control == control & df$Accuracy == globals$accuracy_levels[1]
    index2 = df$Control == control & df$Accuracy == globals$accuracy_levels[2]
    difference_scores$DV[difference_scores$Control == control] = df$DV[index2] - df$DV[index1]  
  }
  
  my_summary(difference_scores, "Control")
  
  pwc <- difference_scores %>% pairwise_t_test(DV ~ Control,
                                               paired = TRUE,
                                               p.adjust.method = "bonferroni")
  
  my_pwc(pwc)
  
  cat("single-sample t-tests against 0:\n")
  pwc <- df %>%
    group_by(Control, Accuracy) %>%
    t_test(DV ~ 1, mu = 0, p.adjust.method = "bonferroni", alternative = "two.sided")
  
  pwc = as.data.frame(pwc)
  pwc$statistic <- as.numeric(specify_decimal(pwc$statistic, 2))
  pwc$p.round <- as.numeric(specify_decimal(pwc$p, 3))
  
  print(pwc)
  cat('\n')
  
}
