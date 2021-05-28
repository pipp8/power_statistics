library(DescTools)
library(ggplot2)
library(facetscales)
library(dplyr)

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/results/dataset5-1000")

# produce un pannello (nel supplementary: separation ....)
# AFMeasureDistances-All-k=4-allMeasures.png
# Fissato k e per n = 5.000.000 per ciascuna misura valuta la distanza al variare del modello
# sulle ascisse i valori dei 2 AM per i 3 gamma + NM Uniform

dfFilename <- "RawDistances-All.RDS"

if (!file.exists(dfFilename)) {
	cat( sprintf("Input Dataframe (%s) does not exist. Exiting\n", dfFilename))
	quit(save = "ask")
}

# carica il dataframe dal file
dati <- readRDS(file = dfFilename)

cat('Start plotting.\n')

# modifica i fattori di scala per ciascuna riga del pannello
# N.B. l'etichetta del pannello deve essere stringa NON numero
scales_y <- list(
    'chebyshev' = scale_y_continuous(limits = c(400, 1300)),
    'd2z' = scale_y_continuous(limits = c(135.80, 136)))

#for labels
len_names <- list(
  '2e+05' = "n = 200 000",
  '5e+06' = "n = 5 000 000")

k_names <- list(
  '4' = "k = 4",
  '6' = "k = 6",
  '8' = "k = 8",
  '10' = "k = 10")

plot_labeller <- function(variable,value){
  if (variable=='len') {
    # N.B. len e' un factor
    return(len_names[as.character(value)])
  } else if (variable=='k') {
    return(k_names[value])
  } else {
    return(as.character(value))
  }
}

for(kv in unique(dati$k)) {

	dff <- filter(dati, dati$len == 5000000 & dati$k == kv & as.character(dati$Model) != "T1") # tutte le misure per uno specifico valore di k senza T1 check
	if (nrow(dff) < 1000) {
		cat( sprintf("Not  enough data (%d) to plot\n", nrow(dff)))
		quit(save = "no")
	}

	sp <- ggplot( dff, aes(x = Model, y = Distance, fill = Model, alpha=0.7)) + 
	 	geom_boxplot( aes(color = Model), outlier.size = 0.3) +
	 	facet_grid(cols = vars( len), rows = vars( Measure), scales = "free", labeller = plot_labeller) +
	 	# facet_grid_sc(cols = vars( len), rows = vars( Measure), scales = list( y = scales_y)) +
	 	# scale_y_continuous(name = "Distance", limits = c(0, 1)) +
	 	theme_bw() + theme( axis.text.x = element_text(size = 10, angle = 45, hjust = 1), axis.text.y = element_blank()) +
	 	theme(legend.position = "none") + labs(x ="") + labs(y = "") # Canberra Distances") 
	 	# ggtitle(sprintf("Distances for k = %d", kv)) 
	
	
	# dev.new(width = 4, height = 12)
	outfname <- sprintf("%s-k=%d-allMeasures.png", tools::file_path_sans_ext(dfFilename), kv)
	ggsave( outfname, device = png(), width = 6, height = 12, dpi = 300)
	#print(sp)
	cat(sprintf("%s processed\n", outfname))
	# dev.off() #only 129kb in size
}