library(DescTools)
library(ggplot2)
library(facetscales)
library(dplyr)

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/results/dataset5-1000")

# produce un pannello per una distanza e ciascun valore di k (sulle righe)
# Ogni grafico riporta i valori boxplot per ciascun AM x 3 valori di gamma + Uniform

options(echo=FALSE)
args <- commandArgs(trailingOnly = TRUE)

if (length( args) < 1) {
  cat( sprintf("Wrong number of arguments. Usage: %s targetMeasure\n", 'PlotOneMeasureRawDistances-AllK.R'))
  quit(save = "no")
}

targetMeasures <- args

# targetMeasure <- 'ddddd2222'

dfFilename <- "RawDistances-All.RDS"

if (!file.exists(dfFilename)) {
	cat( sprintf("Input Dataframe (%s) does not exist. Exiting\n", dfFilename))
	quit(save = "no")
}

# carica il dataframe dal file
dati <- readRDS(file = dfFilename)

cat('Start plotting.\n')

# modifica i fattori di scala per ciascuna riga del pannello
# N.B. l'etichetta del pannello deve essere stringa NON numero
scales_y <- list(
    'chebyshev' = scale_y_continuous(limits = c(400, 1300)),
    'd2z' = scale_y_continuous(limits = c(135.80, 136)))

# for labels
len_names <- list(
  '2e+05' = "n = 200 000",
  '5e+06' = "n = 5 000 000")

k_names <- list(
  '4' = "k = 4",
  '6' = "k = 6",
  '8' = "k = 8",
  '10' = "k = 10")

plot_labeller <- function(variable,value){
  # cat(sprintf("variable: %s, value: %s\n", variable, as.character(value)))
  if (variable == 'len') {
    # N.B. len e' un factor
    return(len_names[as.character(value)])
  } else if (variable == 'k') {
    return(k_names[as.character(value)])
  } else {
    return(as.character(value))
  }
}


for( target in targetMeasures) {
    dff <- filter(dati, dati$len == 5000000 & dati$Measure == target & dati$Model != 'T1' & (dati$k == 4 | dati$k == 10)) # solo una misura per tutti i k
    
    if (nrow(dff) < 1000) {
      cat( sprintf("Not  enough data (%d) for measure: %s\n", nrow(dff), target))
      quit(save = "no")
    }
    sp <- ggplot( dff, aes(x = Model, y = Distance, fill = Model, alpha=0.7)) +
    	geom_boxplot( aes(color = Model), outlier.size = 0.3) +
    	facet_grid(cols = vars( len), rows = vars( k), scales = "free", labeller = plot_labeller) +
    	# facet_grid_sc(cols = vars( len), rows = vars( Measure), scales = list( y = scales_y)) +
    	theme_bw() + theme( axis.text.x = element_text(size = 10, angle = 45, hjust = 1)) + # axis.text.y = element_blank()) +
    	theme(legend.position = "none") + labs(x ="") + labs(y = sprintf("%s Distances", target)) # Canberra Distances")
    	# ggtitle(sprintf("Distances for k = %d", kv))
    
    
    # dev.new(width = 4, height = 12)
    outfname <- sprintf("%s-AllK.png", target)
    ggsave( outfname, device = png(), width = 6, height = 6, dpi = 300)
    cat(sprintf("%s processed\n", outfname))
    # dev.off() #only 129kb in size
}