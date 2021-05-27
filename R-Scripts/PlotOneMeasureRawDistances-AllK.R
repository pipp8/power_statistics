library(DescTools)
library(ggplot2)
library(facetscales)
library(dplyr)

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/results/dataset5-1000")
# produce un pannello per una distanza e ciascun valore di k (sulle righe)
# Ogni grafico riporta i valori boxplot per ciascun AM x 3 valori di gamma + Uniform


dfFilename <- "Power+T1-Results.RDS"

if (!file.exists(dfFilename)) {
	cat( sprintf("Input Dataframe (%s) does not exist. Exiting\n", dfFilename))
	quit(save = "ask")
}

# carica il dataframe dal file
dati <- readRDS(file = dfFilename)

cat('Starting plotting.\n')

nPairs = 1000
lengths = c(200000, 5000000)
lengths = seq(200000, 10000000, 200000)
kValues = c(4, 6, 8, 10)


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
  if (variable=='len') {
    # N.B. len e' un factor
    return(len_names[as.character(value)])
  } else if (variable=='k') {
    return(k_names[value])
  } else {
    return(as.character(value))
  }
}

targetMeasure <- 'canberra'

dff <- filter(df, df$len == 5000000 & df$Measure == targetMeasure) # solo una misura per tutti i k

sp <- ggplot( dff, aes(x = Model, y = Distance, fill = Model, alpha=0.7)) +
	geom_boxplot( aes(color = Model), outlier.size = 0.3) +
	facet_grid(cols = vars( len), rows = vars( k), scales = "free", labeller = plot_labeller) +
	# facet_grid_sc(cols = vars( len), rows = vars( Measure), scales = list( y = scales_y)) +
	# scale_y_continuous(name = "Distance", limits = c(0, 1)) +
	theme_bw() + theme( axis.text.x = element_text(size = 10, angle = 45, hjust = 1)) + # axis.text.y = element_blank()) +
	theme(legend.position = "none") + labs(x ="") + labs(y = "Canberra Distances") # Canberra Distances")
	# ggtitle(sprintf("Distances for k = %d", kv))


# dev.new(width = 4, height = 12)
outfname <- sprintf("%s-AllK.png", targetMeasure)
ggsave( outfname, device = png(), width = 6, height = 12, dpi = 300)
# ggsave( outfname, device = png(), dpi = 300)
cat(sprintf("%s processed\n", outfname))
# stop("break")
# readline(prompt="Press [enter] to continue")
dev.off() #only 129kb in size
