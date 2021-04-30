# prepare ----------------------------------------------------------------

rm(list = ls())
source("common.R")
clean_start()
load_libraries()
globals = get_globals()
output_directory = set_output_directory("Figure7/")


# load and organise -------------------------------------------------------

relevance_levels = c("Target", "Distractor")

file = "..\\EEG_spatial_attention\\spatialAttentionGroup\\spatialAttention.txt"
tmp <- read.delim(file, header = TRUE, sep = "\t", dec = ".")

df <- (data.frame(subject_id = rep(seq(1, globals$number_of_participants), 4)))

df$subject_id <- as.factor(df$subject_id)
df$Control <- as.factor(c(rep("Solo",globals$number_of_sessions*4),rep("Joint",globals$number_of_sessions*4)))
df$Control <- factor(df$Control, levels = globals$control_levels2)
df$Relevance <- as.factor(c(rep("Target",globals$number_of_sessions*2), rep("Distractor",globals$number_of_sessions*2), rep("Target",globals$number_of_sessions*2), rep("Distractor",globals$number_of_sessions*2)))
df$Relevance <- factor(df$Relevance, levels = relevance_levels)
df$DV <- c(tmp$soloT, tmp$soloD, tmp$jointT, tmp$jointD)

# plot -----------------------------------------------------------------------

ylabel <- expression(paste("SSVEP Amplitude (", italic(mu), "V)"))
df_summary <- summarySE(df, measurevar = "DV", groupvars=c("Control", "Relevance"))

p <- ggplot(df, aes(x = Control, y = DV, fill = Relevance)) +
  geom_flat_violin(aes(fill = Relevance), position = position_nudge(x = .1, y = 0), adjust = 1.5, trim = FALSE, alpha = .5, colour=NA, width=.75)+
  geom_boxplot(aes(x = Control, y = DV, fill = Relevance), outlier.shape = NA, width = .1, colour = "black")+
  geom_point(aes(x = as.numeric(Control)-.15, y = DV, colour = Relevance), position = position_jitter(width = .05), size = 3, shape = 20, alpha=.5)+
  
  geom_line(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, group = Relevance, colour = Relevance), linetype = 3, size = 1)+
  geom_point(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, group = Relevance, colour = Relevance), shape = 18, size = 1) +
  geom_errorbar(data = df_summary, aes(x = as.numeric(Control)+.1, y = DV_mean, group = Relevance, colour = Relevance, ymin = DV_mean-se, ymax = DV_mean+se), width = .05, size = 1)+
  
  theme_cowplot()+
  scale_color_aaas() +
  scale_fill_aaas()+
  theme(plot.margin=grid::unit(c(1, 1, 1, 1), "mm"),
        legend.position = c(.25,.95),
        legend.justification = .5,
        legend.title = element_text(size=11),
        legend.text = element_text(size=11),
        axis.title = element_text(size=11),
        axis.text = element_text(size=11),
        plot.title = element_text(size=12, hjust = .5, face='plain'),
        axis.line = element_line(colour = 'black', size = 1),
        axis.ticks = element_line(colour = "black", size = 1))+
  ylim(-.35, 2.5)+
  
  ylab(ylabel)+
  ggtitle("")

print(p)

ggsave(plot=p, paste0(output_directory, "Figure7.png"), width = 3, height = 3, dpi = 900)



# anova -------------------------------------------------------------------





control_relevance_anova <- function(df){
  
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
    
    anova_results$ANOVA = format_anova(anova_results)
    
    # anova_results$`Sphericity Corrections` = anova_results$`Sphericity Corrections`[c('Effect', 'DF[GG]', 'p[GG]', 'p[GG]<.05')]
    # anova_results$`Sphericity Corrections`$'p[GG]<.05' = clean_p_strings(anova_results$`Sphericity Corrections`$'p[GG]<.05', anova_results$`Sphericity Corrections`$'p[GG]')
    # anova_results$`Sphericity Corrections`$p.round <- as.numeric(specify_decimal(anova_results$`Sphericity Corrections`$'p[GG]', 3))
    # 
    cat("ANOVA results:\n")
    print(anova_results)
    cat('\n') 
    
  }
  
  cat('----------------')
  cat('All')
  cat('\n\n')  
  # anova_results = 
  pretty_anova(anova_test(data = df, dv = DV, wid = subject_id, within = c(Control, Relevance), effect.size="pes"))
  
  for(RELEVANCE in relevance_levels){
    cat('----------------')
    cat(RELEVANCE)
    cat('\n\n')
    pretty_anova(anova_test(data = df[df$Relevance == RELEVANCE,], dv = DV, wid = subject_id, within = Control, effect.size="pes"))  
  }
  
  pwc <- df %>%
    group_by(Control) %>%
    pairwise_t_test(
      DV ~ Relevance, paired = TRUE,
      p.adjust.method = "bonferroni"
    )
  
  my_pwc(pwc)
  cat('\n')
  
  pwc <- df %>%
    group_by(Relevance) %>%
    pairwise_t_test(
      DV ~ Control, paired = TRUE,
      p.adjust.method = "bonferroni"
    )
  
  my_pwc(pwc)
  cat('\n') 
  
  
  cat("cell means:\n")
  
  for (i in seq(1,3)) {
    
    switch(i, 
           { grouping_variables=c("Control", "Relevance") },
           { grouping_variables=c("Control") },
           { grouping_variables=c("Relevance") },  
    )
    
    my_summary(df, grouping_variables)
    cat('\n')
  }
  
}


control_relevance_anova(df)