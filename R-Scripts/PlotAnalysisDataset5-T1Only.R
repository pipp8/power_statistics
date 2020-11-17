library(rjson)
library(ggplot2)
library(dplyr)

setwd("/Users/pipp8/Universita/Src/IdeaProjects/PowerStatistics/data/results/syntheticAllK")

varKDataPath <- "/Users/pipp8/Universita/Src/IdeaProjects/PowerStatistics/data/results/dataset4-1000"


alphaValues = c("010", "050", "100")
# alphaValues = c("050")
gammaValues = c(0.01, 0.05, 0.10)

kValues = c(4, 6, 8, 10)

for(alpha in alphaValues) {

    jsonDir <- sprintf( "json-%s", alpha)

    files <- list.files(jsonDir, "*.json")

    print( sprintf("Processing %d files from: %s/%s", length(files), getwd(), jsonDir))

    dirname <- sprintf( "T1img-a=%s", alpha)
    if (!dir.exists(dirname)) {
    	dir.create(dirname)
    }

    seqLengths <- 17 # 1000, 10000, 100000, 1.000.000 = # numero di risultati per ciascun plot
    nAlpha <- 1
    nGamma <- length(gammaValues) # cambiare in 3
    nK <- length(kValues)
    nPlot <- nAlpha * nK + 1 # nGamma * nAlpha * nK + 1
    nCol <- 6
    nCol2 <- 6
	colors <- rainbow(nK + 1)

    for (file in files) {


        cat( sprintf("Processing: %s, Alpha: 0.%s ... ", file, alpha))

        exp <- fromJSON(file = paste(jsonDir, file, sep="/"))
        values <-exp[['values']]
		
        df <- lapply( values, function( p) { data.frame(matrix(unlist(p), ncol=nCol, byrow=T))})
        df <- do.call(rbind, df)
        colnames(df)[1:nCol] <- c("len", "alpha", "k", "power", "T1", "gamma")

		if (exp$header$alternateModel == "PatternTransfer")
				next

		varKFile <- sprintf("%s/json-%s/%s", varKDataPath, alpha, file)
        expVarK <- fromJSON(file = varKFile)
        valuesVarK <-expVarK[['values']]
        dfVarK <- lapply( valuesVarK, function( p) { data.frame(matrix(unlist(p), ncol=nCol2, byrow=T))})
        dfVarK <- do.call(rbind, dfVarK)
        colnames(dfVarK)[1:nCol2] <- c("len", "alpha", "k", "power", "T1", "gamma")
		
		MaxT1 <- switch(alpha, "010" = 0.030, "050" = 0.150, "100" = 0.3) # fattore di amplificazione del valore di T1

        title = sprintf("T1 Error Check for: %s-%s", gsub( "[dD]istance", "", exp$header$distanceName), exp$header$nullModel)

		T1lbl <- "T1 k var"
		x <- c()
		gv <- 0.010
		
		k4 <- filter(df, k == 4, gamma == gv)
		shp <- c(1)
		
		# un solo grafico con i valori di T!-check per ogni valore di k
		# sp2 <- ggplot( subset(df, gamma == gv)) +
		#	geom_line( aes( x = len, y = power, colour = k)) 
		sp2 <- ggplot( k4, aes(x=len)) + ggtitle( title) +  
			scale_y_continuous(name = "T1 Error Check", limits = c(0, MaxT1)) +
			scale_x_continuous("Sequence Len", limits = c(1000, 10000000), trans='log10') +
#				scale_shape_manual(values=1:nK+1) +

			geom_hline(yintercept = df$alpha[1], linetype="dashed", color = "gray25") +
			annotate(geom="text", x = 3000000, y = df$alpha[1] + 0.002,
				label=paste0("Alpha = ", df$alpha[1]), color="gray25") +
		
			geom_line( aes( x = dfVarK$len[1:17], y = dfVarK$T1[1:17], colour = T1lbl))  # N.B. non dipende da gamma
			# geom_point(aes(x = len, y = T1*t, colour = T1lbl))

		sp2 <- sp2 + geom_line( aes( y = T1, colour = "T1 k = 4")) # + geom_point(aes(y = power))
		sp2 <- sp2 + geom_line( aes( y = filter(df, k == 6, gamma == gv)$T1, colour = "T1 k = 6"))
		# + geom_point(aes(y = filter(df, k == 6, gamma == gv)$power, colour = "k=6"))
		sp2 <- sp2 + geom_line( aes( y = filter(df, k == 8, gamma == gv)$T1, colour = "T1 k = 8"))
		sp2 <- sp2 + geom_line( aes( y = filter(df, k == 10, gamma == gv)$T1, colour = "T1 k = 10"))

		lbls <- c(T1lbl)
		for( kv in kValues) {				
			lbl = sprintf("T1 k = %d", kv)
			lbls <- append(lbls, lbl)
		}
		sp2 <- sp2 + scale_colour_manual(breaks = lbls, values = colors, name = "k-len")

		dev.new(width = 6, height = 4)
        outfname <- sprintf( "%s/%sT1.png", dirname, tools::file_path_sans_ext(file), gv)
        ggsave( outfname, device = png(), width = 15, height = 10, units = "cm", dpi = 300)
        # readline(prompt="Press [enter] to continue")
        dev.off() #only 129kb in size
	    
        print( " done")
    } # for each file
} # for each alpha