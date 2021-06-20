library(DescTools)
library(ggplot2)
library(facetscales)
library(dplyr)
library(rjson)

setwd("/Users/pipp8/Universita/Src/IdeaProjects/PowerStatistics/data/results/dataset5-1000")

# Figura 4 nel supplementary
# produce un pannello con 6 boxplot (3 x 2) le colonne sono i 2 AM le righe i valori di gamma, 
# i boxplot per ciascun grafico riportano i valori della power statistics
# Aggregati per len per ogni misura ed ogni valore di K


# rename in a human readable format the measure names
measure_names <- function( measure) {
  ris <- c()
  for( m in measure) {
    ris <- c(ris , str_to_title( switch( m,
                                         'chisquare' = 'chi square',
                                         'd2star' = 'd2*',
                                         'harmonicmean' = 'harmonic mean',
                                         'squaredchord' = 'squared chord',
                                         'jensenshannon' = 'jensen shannon',
                                         m)))
  }
  return( ris)
}

plot_labeller <- function(variable,value){
  # cat(sprintf("nome: %s, valore: %s\n", variable, as.character(value)))
  if (variable=='gamma') {
    # N.B. len e' un factor
    return(sprintf("G = %.2f", value))
  } else if (variable == 'measure') {
    # N.B. Measure e' un factor
    tr <- measure_names(as.character(value))
    # cat(sprintf("pre: %s\npost: %s\n", as.character(value), tr))
    return( tr)
    # return( as.character(value))
  } else {
    return(as.character(value))
  }
}


# output dirname
dirname <- "PowerBoxPlot"
if (!dir.exists(dirname)) {
  dir.create(dirname)
}

dfFilename <- "Power+T1-Results.RDS"

if (!file.exists(dfFilename)) {
  cat( sprintf("Input Dataframe (%s) does not exist. Exiting\n", dfFilename))
  quit(save = "ask")
}

# carica il dataframe dal file
dati <- readRDS(file = dfFilename)
# solo per alpha = 0.10
alphaTarget = 0.10

dff <- filter(dati, dati$alpha == alphaTarget) # tutte le misure per uno specifico valore di alpha
dff$measure2 <- dff$measure
levels(dff$measure2) <- measure_names(levels(dff$measure))

sp <- ggplot(dff, aes(x = measure2, y = power, fill = k, alpha = 0.7)) + 
  geom_boxplot( aes( color = k), alpha = 0.7, outlier.size = 0.3) +
  facet_grid(rows = vars(gamma), cols = vars(model), labeller = plot_labeller) +
  labs(y = 'Power') + theme_bw() + 
  theme(axis.title.x = element_blank(), 
        axis.text.x = element_text( size = rel(0.8), angle = 45, hjust = 1))

# dev.new(width = 9, height = 6)
# print(sp)
outfname <- sprintf( "%s/PanelBoxplotPowerAllMeasures-A=%.2f.png", dirname, alphaTarget)
ggsave( outfname, device = png(), width = 9, height = 6, units = "in", dpi = 300)
# dev.off() #only 129kb in size
