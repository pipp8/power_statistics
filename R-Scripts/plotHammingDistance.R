library(DescTools)
library(ggplot2)
library(dplyr)

setwd("/Users/pipp8/Universita/Src/IdeaProjects/power_statistics/data/results/AnalisiAlternativeModel/seqs")

# produce un pannello (HammingDistance-n=5000000) la distanza di hamming
# sulle ascisse i 2 AM x i 3 valori di gamma + uniform.

#
nPairs = 1000
lenghts = c(200000, 5000000)

dfFilename = "HammingDistance-All.df"		

if (file.exists(dfFilename)) {
	cat( sprintf("Data file exists. Loading %s\n", dfFilename))			
	# carica il dataframe dal file
	df <- readRDS(file = dfFilename)
} else {

	df <- data.frame( Name = character(), Dist = double(), len = numeric(), stringsAsFactors=FALSE)

	for( len in lenghts)	{
		model = 'Uniform'
		f1 <- sprintf("%s-%d.%d%s.fasta", model, nPairs, len, '')
		con1 = file(f1, "r")
		
		for( pair in 1:nPairs) {
			
			s1Name = readLines(con1, n = 1)
			s1 = readLines(con1, n = 1)
			s2Name = readLines(con1, n = 1)
			s2 = readLines(con1, n = 1)
		
			d <- StrDist(s1, s2, method = 'hamming')
			df[nrow(df) + 1,] <- list( 'NM', d[1]/len, len)
			
			cat( sprintf("%5d /%5d\r", pair, nPairs))
		}
		close(con1)
		cat( sprintf("%s.  done.\n", 'Uniform'))
	
		for( model in c('MotifRepl-U', 'PatTransf-U')) {
			
			for( g in c(0.01, 0.05, 0.10)) {
		
				gVal <- sprintf(".G=%.3f", g)
				k1 <- sprintf("%s%s", if (model == 'MotifRepl-U') 'MR' else 'PT', gVal)
						
				f2 <- sprintf("%s-%d.%d%s.fasta", model, nPairs, len, gVal)
				con2 = file(f2, "r")
			
				for( pair in 1:nPairs) {
		
					s1AMName = readLines(con2, n = 1)
					s1AM = readLines(con2, n = 1)
					s2AMName = readLines(con2, n = 1)
					s2AM = readLines(con2, n = 1)
				
					d <- StrDist(s1AM, s2AM, method = 'hamming')
					df[ nrow(df) + 1,] <- list( k1, d[1]/len, len)
					
					cat( sprintf("%5d /%5d\r", pair, nPairs))
				} # for all pairs
	
				close(con2)
				cat( sprintf("\n%s ok\n", f2))	
			} # for all gamma
			cat( sprintf("%s.  done.\n", model))
		} # for all models
	} # for all lenngth
	saveRDS( df, file = dfFilename)
}

df$Name = factor(df$Name, levels = c('NM', 'MR.G=0.010','MR.G=0.050','MR.G=0.100', 'PT.G=0.010','PT.G=0.050','PT.G=0.100'))

df$len <- factor(df$len)
levels(df$len) <- c("n = 200 000", "n = 5 000 000")

dff <- filter( df, df$len == 'n = 5 000 000')
sp <- ggplot( dff, aes(x = Name,y = Dist, fill = Name)) + 
 	geom_boxplot( aes(color = Name), outlier.size = 0.3) +
 	facet_grid(cols = vars( len)) +
 	scale_y_continuous(name = "Hamming Distance", limits = c(0, 1)) +
 	theme_bw()+ theme( axis.text.x = element_text(size = 10, angle = 45, hjust =1)) +
 	theme(legend.position = "none") + labs(x ="")

# dev.new(width = 9, height = 6)
outfname <- sprintf( "%s.png",  tools::file_path_sans_ext(dfFilename))
ggsave( outfname, device = png(), width = 9, height = 4, dpi = 300)
# ggsave( outfname, device = png(), dpi = 300)
#			print( sp2)
# stop("break")
# readline(prompt="Press [enter] to continue")
#			dev.off() #only 129kb in size
