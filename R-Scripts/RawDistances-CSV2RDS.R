library(DescTools)
library(dplyr)

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/results/dataset5-1000")

# Converte tutti i file CSV prodotti da fade  in un unico dataframe con il seguente numero di righe
# 50 lunghezze x 4 valori di k x 15 misure x (2 NM + 2 AM x 3 Gamma) x 1000 coppie = 24.000.000

nPairs = 1000
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


dfFilename <- "RawDistances-All.RDS"			

if (file.exists(dfFilename)) {
  cat( sprintf("Data file %s exists. Do you want to overwrite (Y/N) ?\n", dfFilename))
  res <- readline()
  if (res != "Y") {
    quit(save="ask")
  }
}

df <- data.frame( Distance = double(), Measure = character(), Model = character(), k = numeric(), len = numeric(), stringsAsFactors=FALSE)

for( len in lengths)	{ # 50 lunghezze

	for( k in kValues) {  # 4 valori di k

		model = 'Uniform' # dist-k=4_Uniform-1000.8600000
		f1 <- sprintf("k=%d/dist-k=%d_%s-%d.%d%s.csv", k, k, model, nPairs, len, '')
		
		tmp <- read.csv( file = f1)

		for(mes in sortedMeasures) { # 15 misure
			
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
				
		for( model in c('MotifRepl-U', 'PatTransf-U')) { # 2 AM
			
			for( g in c(0.01, 0.05, 0.10)) {               # 3 valori di gamma
		
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
} # for all length

df$Measure <- factor(df$Measure, levels = sortedMeasures)
df$Model <- factor(df$Model, levels = c('NM', "MR.G=0.010", "MR.G=0.050", "MR.G=0.100", "PT.G=0.010", "PT.G=0.050", "PT.G=0.100"))
df$k <- factor( df$k, kValues)
df$len <- factor( df$len, lengths)
saveRDS( df, file = dfFilename)

cat(sprintf("Dataset %s %d rows saved.", dfFilename, nrow(df)))
