library(DescTools)
library(ggplot2)
library(facetscales)
library(dplyr)

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/results/dataset5-1000")

nPairs = 1000
lengths = c(200000, 5000000)
kValues = c(4, 6, 8, 10)

measures = c('camberra', 'chebyshev', 'd2', 'd2z', 'manhattan')
mespos = c(3, 4, 6, 9, 17)

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

			for(i in 1:length(measures)) {
				
				df2 <- data.frame(tmp[, mespos[i]])
				names(df2) <- 'Distance'
				df2$Measure <- measures[i]
				df2$Model <- 'NM'
				df2$k <- k
				df2$len <- len	
			
				df <- rbind(df, df2)
			}
			cat( sprintf("%s.  done.\n", 'Uniform'))
					
			for( model in c('MotifRepl-U', 'PatTransf-U')) {
				
				for( g in c(0.01, 0.05, 0.10)) {
			
					gVal <- sprintf(".G=%.3f", g)
					mdl <- sprintf("%s%s", if (model == 'MotifRepl-U') 'MR' else 'PT', gVal)
					f1 <- sprintf("k=%d/dist-k=%d_%s-%d.%d%s.csv", k, k, model, nPairs, len, gVal)
			
					tmp <- read.csv( file = f1)
			
					for(i in 1:length(measures)) {
						
						df2 <- data.frame(tmp[, mespos[i]])
						names(df2) <- 'Distance'
						df2$Measure <- measures[i]
						df2$Model <- mdl
						df2$k <- k
						df2$len <- len	
						
						df <- rbind(df, df2)
					}
					cat( sprintf("%s ok\n", f1))	
				} # for all gamma
				cat( sprintf("%s.  done.\n\n", model))
			} # for all models
		} # for all k
	} # for all lenngth
	
	df$Measure <- factor(df$Measure, levels = measures)
	df$Model <- factor(df$Model, levels = c('NM', "MR.G=0.010", "MR.G=0.050", "MR.G=0.100", "PT.G=0.010", "PT.G=0.050", "PT.G=0.100"))
	df$k <- factor( df$k, kValues)
	df$len <- factor( df$len, lengths)
	saveRDS( df, file = dfFilename)
}

levels(df$len) <- c("n = 200 000", "n = 5 000 000")


# for(k in kValues) {
	k <- 6
	dff <- filter(df, df$len == 'n = 5 000 000' & df$k == 6 & ( df$Measure == 'd2z' | df$Measure == 'chebyshev'))
	
	sp <- ggplot( dff, aes(x = Model, y = Distance, fill = Model, alpha=0.7)) + 
	 	geom_boxplot( aes(color = Model), outlier.size = 0.3) +
	 	facet_grid(cols = vars( len), rows = vars( Measure), scales = "free") +
	 	# facet_grid_sc(cols = vars( len), rows = vars( Measure), scales = list( y = scales_y)) +
	 	# scale_y_continuous(name = "Hamming Distance", limits = c(0, 1)) +
	 	theme_bw() + theme( axis.text.x = element_text(size = 10, angle = 45, hjust =1)) +
	 	theme(legend.position = "none") + labs(x ="") +
	 	ggtitle(sprintf("Distances for k = %d", k)) + labs(y = "")
	
	
	# dev.new(width = 9, height = 6)
	outfname <- sprintf("%s-k=%d.png", tools::file_path_sans_ext(dfFilename), k)
	# ggsave( outfname, device = png(), width = 9, height = 4, dpi = 300)
	ggsave( outfname, device = png(), dpi = 300)
	#print( sp)
	# stop("break")
	# readline(prompt="Press [enter] to continue")
	#			dev.off() #only 129kb in size
#}