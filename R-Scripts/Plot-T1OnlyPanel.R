library(rjson)
library(dplyr)
library(RColorBrewer)
library(ggplot2)
library(facetscales)



setwd("/Users/pipp8/Universita/Src/IdeaProjects/PowerStatistics/data/results/dataset5-1000")
	
alphaValues = c("010", "050", "100")
gammaValues = c(0.01, 0.05, 0.10)	
kValues = c(4, 6, 8, 10)

# misure ordinate per famiglia
sortedMeasures <- c('chebyshev', 'euclidean', 'manhattan',
                    'chisquare',
                    'canberra',
                    'd2', 'd2s', 'd2star', 'd2z',
                    'intersection', 'kulczynski2',
                    'harmonicmean', 'squaredchord',
                    'jeffrey', 'jensenshannon')

dfAll <- data.frame()

for(alpha in alphaValues) {

    jsonDir <- sprintf( "json-%s", alpha)

    files <- list.files(jsonDir, "*.json")

    print( sprintf("Processing %d files from: %s/%s", length(files), getwd(), jsonDir))

    dirname <- "T1BoxPlot"
    if (!dir.exists(dirname)) {
    	dir.create(dirname)
    }

    seqLengths <- 50 # 1000, 10000, 100000, 1.000.000 = # numero di risultati per ciascun plot
    nAlpha <- 1
    nGamma <- length(gammaValues) # cambiare in 3
    nK <- length(kValues)
    nPlot <- nAlpha * nK + 1 # nGamma * nAlpha * nK + 1
    nCol <- 6
    nCol2 <- 6
	colors <- rainbow(nK + 1)

	tblMeasures <- c()
	ndx = 1
	
    for (file in files) {

        if (grepl( "jaccard|mash", file, ignore.case = TRUE)) {
            cat(sprintf("skipping file: %s\n", file))
            next
        }
        cat( sprintf("Processing: %s, Alpha: 0.%s ... ", file, alpha))

        exp <- fromJSON(file = paste(jsonDir, file, sep="/"))
        
        if (exp$header$alternateModel == "PatternTransfer") {
			cat(sprintf("%s skipped.\n", file))
			next
		}
        values <-exp[['values']]
		
        df <- lapply( values, function( p) { data.frame(matrix(unlist(p), ncol=nCol, byrow=T))})
        df <- do.call(rbind, df)
        colnames(df)[1:nCol] <- c("len", "alpha", "k", "power", "T1", "gamma")

		measureName <- gsub( "[dD]istance", "", exp$header$distanceName)
		tblMeasures[ndx] = measureName

		# aggiunge una colonna con il nome della misura in ogni riga
		# df["measure"] = ndx
		df["measure"] = measureName
		df["alfa"] = sprintf("%d%%", df$alpha * 100) # fattore alpha alfanumerico

		# aggiunge al dataframe finale i valori per un solo gamma N.B. T1 check gv <- 0.010
		dfAll <- rbind(dfAll, filter( df, gamma == 0.010))
		
		ndx <- ndx + 1
		cat("done.\n")
	}
	cat(sprintf("alpha=%s done.\n", alpha))
	# dfAll 3.000 righe per ciascun modello / Alpha
} # foreach alpha
	# dfAll 9.000 righe
	
	dfAll$measure <- factor(dfAll$measure, levels = sortedMeasures)
	dfAll$k <- factor( dfAll$k, levels = c( 4, 6, 8, 10))
	dfAll$alfa2 <- factor( dfAll$alfa, levels = c( "1%", "5%", "10%"))
		
	# modifica i fattori di scala per ciascuna riga del pannello
	scales_y <- list(
    	`1%` = scale_y_continuous(limits = c(0, 0.10), breaks = seq(0, 0.10, 0.02)),
    	`5%` = scale_y_continuous(limits = c(0, 0.20), breaks = seq(0, 0.20, 0.04)),
    	`10%` = scale_y_continuous(limits = c(0, 0.30), breaks = seq(0, 0.30, 0.06)))


	cat(sprintf("Data Frame loaded. %d rows\n", nrow(dfAll)))

# 	stop("break")

for( a in c( 0.01, 0.05, 0.10)) { 
  
  MaxT1 <- switch( sprintf("%.2f", a), "0.01" = 0.050, "0.05" = 0.150, "0.10" = 0.3) # fattore di amplificazione del valore di T1
  cat(sprintf("%.3f - %.3f\n", a, MaxT1))

	dff <- filter(dfAll, dfAll$alpha == a)

	sp <- ggplot( dff, aes(x = measure, y = T1)) + 
	 	geom_boxplot( aes(color = k, fill = k), alpha=0.7, outlier.size = 0.25) +
	 	# facet_grid(rows = vars( alpha), scales = "free") +
	  scale_y_continuous(name = "T1 Value", limits = c(0, MaxT1)) +
	 	# facet_grid_sc(rows = vars( alfa2), scales = list( y = scales_y)) +
	  geom_hline(yintercept = dff$alpha[1], linetype="dashed", color = "black") +
	 	theme_bw() + theme( axis.text.x = element_text(size = 9, angle = 45, hjust = 1)) +
	 	labs(x = "") # theme(legend.position = "none") 
	 	# ggtitle("Pannello risultati T1-Check") 
	
	# dev.new(width = 10, height = 5)
    outfname <- sprintf( "%s/T1Box-alpha=%.2f.png", dirname, a)
    ggsave( outfname, width = 9, height = 6, device = png(), dpi = 300) 
    # print( sp)
    # readline(prompt="Press [enter] to continue")
    # dev.off() #only 129kb in size
}