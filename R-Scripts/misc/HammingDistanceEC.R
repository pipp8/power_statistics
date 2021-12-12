library(DescTools)
library(ggplot2)
library(dplyr)


setwd("/home/cattaneo/results/Escherichiacoli")
# setwd('/Users/pipp8/Universita/Progetti/BioInformatica/Present-Absent/Src')

dfFilename = "HammingDistanceEC-All.df"

gammas <- c(0.005, 0.010, 0.050, 0.100, 0.200, 0.300, 0.500)

if (file.exists(dfFilename)) {
	cat( sprintf("Data file exists. Loading %s\n", dfFilename))			
	# carica il dataframe dal file
	df <- readRDS(file = dfFilename)
} else {

	df <- data.frame( Name = character(), Gamma = double(), Dist = double(), len = numeric(), stringsAsFactors=FALSE)

	model = 'EscherichiaColi'

	for( g in gammas)	{
	  f1 <- sprintf("%s.fasta", model)
	  con1 = file(f1, "r")
	  f2 <- sprintf("%s-G=%.3f.fasta", model, g)
		con2 = file(f2, "r")
    d <- 0
    totLen <- 0

    cat( sprintf("Starting for gamma = %.3f\n", g))
		while( TRUE) {

			s1Name = readLines(con1, n = 1)
			s1 = readLines(con1, n = 1)
			s2Name = readLines(con2, n = 1)
			s2 = readLines(con2, n = 1)

			if (length(s1Name) == 0 | length(s2Name) == 0) {
			  break
			}
			if (startsWith(s1, ">") | startsWith(s2, ">")) {
			  stop("Malformed input file")
			}
			
			# compute hamming distance
			d <- d + StrDist(s1, s2, method = 'hamming')
			totLen <- totLen + length(s1)
		}
		close(con1)
		close(con2)
		df[nrow(df) + 1,] <- list( model, g, d[1]/totLen, totLen)
		cat( sprintf("%s. G=%f d = %d. done.\n", model, g, d))
	}
	saveRDS( df, file = dfFilename)
}

stop()

df$Name = factor(df$Name, levels = c('NM', 'MR.G=0.010','MR.G=0.050','MR.G=0.100', 'PT.G=0.010','PT.G=0.050','PT.G=0.100'))


HammingPower <- data.frame( Name = character(), len = numeric(), Power = double(), alpha = double(), threshold = double(), stringsAsFactors=FALSE)

aValues <- c( 0.01, 0.05, 0.10)

for( len in lenghts)	{
	df2 <- filter(df, df$Name == 'NM' & df$len == len)
	NM <- df2[order(df2$Dist),2]
	
	threshold <- NM[length(NM) * aValues[1]]
	threshold <- c(threshold, NM[length(NM) * aValues[2]])
	threshold <- c(threshold, NM[length(NM) * aValues[3]])

	for(i in 1:3) {
		for( model in c('MR', 'PT')) {
			for( g in c(0.01, 0.05, 0.10)) {
				k1 <- sprintf("%s.G=%.3f", model, g)
			
				AM <- filter(df, df$Name == k1 & df$len == len)[,2]
				pwr <- 0
				for(dist in AM) {
					if (dist <= threshold[i])
						pwr <- pwr + 1
				}
				HammingPower[nrow( HammingPower) + 1,] <- list( k1, len, pwr / length(AM), aValues[i], threshold[i])
			}
		}
	}
}

HammingPower$Name <- factor(HammingPower$Name)
HammingPower$len <- factor(HammingPower$len)
levels(HammingPower$len) <- c('n = 200 000', 'n = 5 000 000')
	
sp <- ggplot( HammingPower, aes(x = Name, y = Power)) +
# sp <- ggplot( HammingPower, aes(x = Name, y = Power, fill = Name)) + 
 	# geom_boxplot( aes(color = Name), outlier.size = 0.3) +
 	geom_point( aes(color = Name), shape = 15, size = 4) +
 	facet_grid(cols = vars( len)) +
 	scale_y_continuous(name = "HD Power Statistics", limits = c(0, 1)) +
 	theme_bw() + theme( axis.text.x = element_text(size = 10, angle = 45, hjust =1)) +
 	theme(legend.position = "none") + labs(x = "")
 	# ggtitle("Power Statistics for Hamming Distance") + labs(y = "Power")


# dev.new(width = 6, height = 9)
outfname <- sprintf( "HammingPowerStatistics.png",  tools::file_path_sans_ext(dfFilename))
ggsave( outfname, device = png(), width = 9, height = 4, dpi = 300)
# ggsave( outfname, device = png(), dpi = 300)
print( sp)

# stop("break")
# readline(prompt="Press [enter] to continue")
#			dev.off() #only 129kb in size
