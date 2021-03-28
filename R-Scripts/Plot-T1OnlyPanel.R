library(rjson)
library(dplyr)
library(RColorBrewer)
library(ggplot2)
library(facetscales)



setwd("/Users/pipp8/Universita/Src/IdeaProjects/PowerStatistics/data/results/dataset5-1000")
	
alphaValues = c("010", "050", "100")
gammaValues = c(0.01, 0.05, 0.10)	
kValues = c(4, 6, 8, 10)

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
	
	dfAll$measure <- as.factor(dfAll$measure)
	dfAll$k <- factor( dfAll$k, levels = c( 4, 6, 8, 10))
	dfAll$alfa <- factor( dfAll$alfa, levels = c( "1%", "5%", "10%"))
		
	# modifica i fattori di scala per ciascuna riga del pannello
	scales_y <- list(
    	`1%` = scale_y_continuous(limits = c(0, 0.10), breaks = seq(0, 0.10, 0.02)),
    	`5%` = scale_y_continuous(limits = c(0, 0.20), breaks = seq(0, 0.20, 0.04)),
    	`10%` = scale_y_continuous(limits = c(0, 0.30), breaks = seq(0, 0.30, 0.06)))

#	facet_bounds <- read.table(header=TRUE,
#		text=                           
# "alpha ymin ymax breaks
# 0.01		0	0.10    5
# 0.05		0	0.20    5
# 0.10		0	0.30    5",
# stringsAsFactors=FALSE)

	cat(sprintf("Data Frame loaded. %d rows\n", nrow(dfAll)))
		
    # title = sprintf("T1 Error Check (alpha = %d%%)", dfAll$alpha[1]*100)

	# sp2 <-	ggplot(dfAll, aes(x = measure, y = T1, fill = k)) +
	#		ggtitle( title) + labs( x = "") +
	#		theme_light() + theme(legend.position = "bottom") + theme(axis.text.x = element_text(angle = 45, vjust = 0.95, hjust=1)) +
			# theme(axis.text.x = element_blank()) + # axis.ticks.x = element_blank()) +
			# scale_colour_brewer(palette="Dark2") +
	#		scale_fill_manual(values = c("#1C8F63", "#CE4907", "#6159A3", "#DD0077", "#535353")) +
	#		scale_y_continuous(name = "T1 Error", limits = c(0, 0.30)) +
	#		geom_boxplot(lwd = 0.2, alpha = 0.9) #outlier.shape = 20, width=15

	sp <- ggplot( dfAll, aes(x = measure, y = T1, fill = k)) + 
	 	geom_boxplot( aes(color = k), outlier.size = 0.25) +
	 	# facet_grid(rows = vars( alpha), scales = "free") + # scale_y_continuous(name = "T1 Value", limits = c(0, 0.30)) +
	 	facet_grid_sc(rows = vars( alfa), scales = list( y = scales_y)) +
	 	theme_bw() + theme( axis.text.x = element_text(size = 8, angle = 45, hjust = 1)) +
	 	labs(y = "T1 Value", x = "") # theme(legend.position = "none") 
	 	# ggtitle("Pannello risultati T1-Check") 
	
	# dev.new(width = 10, height = 5)
    outfname <- sprintf( "%s/T1Box-Panel.png", dirname)
    ggsave( outfname, device = png(), dpi = 300) 
    print( sp)
    # readline(prompt="Press [enter] to continue")
    # dev.off() #only 129kb in size
    