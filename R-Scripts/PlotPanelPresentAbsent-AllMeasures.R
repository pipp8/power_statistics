library(rjson)
library(ggplot2)
library(stringr)
library(dplyr)
library(RColorBrewer)



###### DESCRIPTION

# Produces two panels reporting the power trend, respectively for the PT and MR alternative models.
# In each panel, for each AF and gamma is reported the power level obtained across different
# values of n. It is also colored according to the value of k.
# The output is a set PNG images with name PanelPowerAnalysis-<AM>-A=0.10.png
# where <AM> reflects the alternative model being considered

# Note: this script must be executed after Power+T1-Json2RDS.R


###### OPTIONS

# Sets the path of the directory containing the input dataframe

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent")

# Sets the name of the file containing the input dataframe
dfFilename <- "PresentAbsent-Power+T1.RDS"

# Sets the output path for the images to be generated

dirname <- "PowerBoxPlot"


###### CODE

# rename in a human readable format the measure names
measure_names <- function( measure) {
  ris <- c()
  for( m in measure) {
    ris <- c(ris , str_to_title( switch( m,
                                         'chisquare' = 'chi square',
                                         'd2star' = 'd2*',
                                         'harmonicmean' = 'harmonic\nmean',
                                         'squaredchord' = 'squared\nchord',
                                         'jensenshannon' = 'jensen\nshannon',
                                         m)))
  }
  return( ris)
}

plot_labeller <- function(variable,value){
  # cat(sprintf("nome: %s, valore: %s\n", variable, as.character(value)))
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

if (!dir.exists(dirname)) {
  dir.create(dirname)
}


if (!file.exists(dfFilename)) {
    cat( sprintf("Input Dataframe (%s) does not exist. Exiting\n", dfFilename))
	quit(save = "ask")
}

# carica il dataframe dal file
dati <- readRDS(file = dfFilename)
alphaTarget = 0.10
dati$kf = factor(dati$k)

for (am in levels(factor(dati$Model))) {

	# solo per alpha = 0.10
    dff <- filter(dati, dati$alpha == alphaTarget & dati$Model == am) # tutte le misure per uno specifico AM e valore di alpha

    sp <- ggplot( dff, aes( x = len, y = power, fill = kf, alpha=0.8)) +
          geom_point( aes( color = kf), alpha = 0.8, size = 1) +
          scale_x_continuous(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
                             labels=c("", "1e+4", "", "1e+6", ""), limits = c(1000, 10000000), trans='log10') +
          scale_y_continuous(name = "Power", limits = c(0, 1)) +
          facet_grid( rows = vars( gamma), cols = vars( Measure),  labeller = plot_labeller) +
          theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 70),
                       axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                       panel.spacing=unit(0.1, "lines")) +
          guides(colour = guide_legend(override.aes = list(size=3)))
          # ggtitle( am)
    
	# dev.new(width = 9, height = 6)
	# print(sp)
	# stop("break")
	outfname <- sprintf( "%s/PanelPowerAnalysis-%s-A=%.2f.pdf", dirname, str_replace(am, " ", ""), alphaTarget)
	ggsave( outfname, device = pdf(), width = 9, height = 6, units = "in", dpi = 300)
	# dev.off() #only 129kb in size
}