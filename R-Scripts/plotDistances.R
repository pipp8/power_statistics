library(DescTools)
library(ggplot2)
library(facetscales)
library(dplyr)

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/results/dataset5-1000")
# produce una pannello (nel supplementary: separation ....)
# AFMeasureDistances-All-k=4-allMeasures.png
# Fissato k e per n = 5.000.000 per ciascuna misura valuta la distanza al variare del modello
# sulle ascisse i valori dei 2 AM per i 3 gamma + NM Uniform

nPairs = 1000
lengths = c(200000, 5000000)
lengths = seq(200000, 10000000, 200000)
kValues = c(4, 6, 8, 10)

# measures = c( 'canberra', 'chebyshev', 'chisquare', 'd2', 'd2s', 'd2star', 'd2z', 'euclidean', 'harmonicmean', 'intersection', 'jeffrey', 'jensenshannon', 'kulczynski2', 'manhattan', 'squaredchord') # no jaccard e mash
# misure ordinate per famiglia
sortedMeasures <- c('chebyshev', 'euclidean', 'manhattan',
                    'chisquare',
                    'canberra',
                    'd2', 'd2s', 'd2star', 'd2z',
                    'intersection', 'kulczynski2',
                    'harmonicmean', 'squaredchord',
                    'jeffrey', 'jensenshannon')

dfFilename <- "AFMeasureDistances-All.df"			

# modifica i fattori di scala per ciascuna riga del pannello
# N.B. l'etichetta del pannello deve essere stringa NON numero
scales_y <- list(
    'chebyshev' = scale_y_continuous(limits = c(400, 1300)),
    'd2z' = scale_y_continuous(limits = c(135.80, 136)))

if (file.exists(dfFilename)) {
	cat( sprintf("Data file exists. Loading %s\n", dfFilename))			
	# carica il dataframe dal file
	df <- readRDS(file = dfFilename)
} else {

	df <- data.frame( Distance = double(), Measure = character(), Model = character(), k = numeric(), len = numeric(), stringsAsFactors=FALSE)

	for( len in lengths)	{

		for( k in kValues) {

			model = 'Uniform' # dist-k=4_Uniform-1000.8600000
			f1 <- sprintf("k=%d/dist-k=%d_%s-%d.%d%s.csv", k, k, model, nPairs, len, '')
			
			tmp <- read.csv( file = f1)

			for(mes in sortedMeasures) {
				
				df2 <- data.frame(get( mes, tmp))
				names(df2) <- 'Distance'
				df2$Measure <- mes
				df2$Model <- 'NM'
				df2$k <- k
				df2$len <- len	
			
				df <- rbind(df, df2)
				
				cat( '.')
			}
			cat( sprintf("%s.  done.\n", 'Uniform'))
					
			for( model in c('MotifRepl-U', 'PatTransf-U')) {
				
				for( g in c(0.01, 0.05, 0.10)) {
			
					gVal <- sprintf(".G=%.3f", g)
					mdl <- sprintf("%s%s", if (model == 'MotifRepl-U') 'MR' else 'PT', gVal)
					f1 <- sprintf("k=%d/dist-k=%d_%s-%d.%d%s.csv", k, k, model, nPairs, len, gVal)
			
					tmp <- read.csv( file = f1)
			
					for(mes in sortedMeasures) {
						
						df2 <- data.frame(get( mes, tmp))
						names(df2) <- 'Distance'
						df2$Measure <- mes
						df2$Model <- mdl
						df2$k <- k
						df2$len <- len	
						
						df <- rbind(df, df2)
						
						cat( '.')
					}
					cat( sprintf("%s ok\n", f1))	
				} # for all gamma
			} # for all models
			cat( sprintf("k = %d.  done.\n", k))
		} # for all k
		cat( sprintf("length = %d.  done.\n\n", len))
	} # for all lenngth
	
	df$Measure <- factor(df$Measure, levels = sortedMeasures)
	df$Model <- factor(df$Model, levels = c('NM', "MR.G=0.010", "MR.G=0.050", "MR.G=0.100", "PT.G=0.010", "PT.G=0.050", "PT.G=0.100"))
	df$k <- factor( df$k, kValues)
	df$len <- factor( df$len, lengths)
	saveRDS( df, file = dfFilename)
}

cat('Starting plotting.\n')

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

for(kv in kValues) {

	dff <- filter(df, df$len == 5000000 & df$k == kv) # tutte le misure per uno specifico valore di k

	sp <- ggplot( dff, aes(x = Model, y = Distance, fill = Model, alpha=0.7)) + 
	 	geom_boxplot( aes(color = Model), outlier.size = 0.3) +
	 	facet_grid(cols = vars( len), rows = vars( Measure), scales = "free", labeller = plot_labeller) +
	 	# facet_grid_sc(cols = vars( len), rows = vars( Measure), scales = list( y = scales_y)) +
	 	# scale_y_continuous(name = "Distance", limits = c(0, 1)) +
	 	theme_bw() + theme( axis.text.x = element_text(size = 10, angle = 45, hjust = 1), axis.text.y = element_blank()) +
	 	theme(legend.position = "none") + labs(x ="") + labs(y = "") # Canberra Distances") 
	 	# ggtitle(sprintf("Distances for k = %d", kv)) 
	
	
	# dev.new(width = 4, height = 12)
	outfname <- sprintf("%s-k=%d-allMeasures.png", tools::file_path_sans_ext(dfFilename), kv)
	ggsave( outfname, device = png(), width = 6, height = 12, dpi = 300)
	# ggsave( outfname, device = png(), dpi = 300)
	cat(sprintf("%s processed\n", outfname))
	# readline(prompt="Press [enter] to continue")
	dev.off() #only 129kb in size
}