library(DescTools)
library(dplyr)
library(parallel)
library(filelock)




###### DESCRIPTION

# compute Power Statistics and T1 error from raw data produced by PresenAbsent3.py script
# in CSV format


###### OPTIONS

# Sets the path of the directory containing the output of FADE
setwd("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent")

bs <- 1

similarities = c('D2')

# Defines the name of the file containing a copy of the dataframe created by this script
# dfFilename <- "PresentAbsent-Power+T1.RDS"
# csvFilename <- 'PresentAbsentData-all.csv'
# nullModel <- 'Uniform'

dfFilename <- sprintf( "%d,32/PresentAbsentEC-Power+T1-%d,32.RDS", bs, bs)
csvFilename <- sprintf("%d,32/PresentAbsentECData-%d-32.csv", bs, bs)
trsh <- sprintf("%d,32/Thresholds.csv", bs)

# nullModel <- 'Uniform'
nullModel <- 'ShuffledEColi'
T1Model <- paste( sep='', nullModel, '-T1')

###### CODE

if (file.exists(dfFilename)) {
  cat( sprintf("Data file %s exists. Do you want to overwrite (Y/N) ?\n", dfFilename))
  res <- readline()
  if (res != "Y") {
    quit(save="ask")
  }
}


getPower <- function( am, mes, threshold, similarityP)
{
  # se distanza (dissimilarità) conta il numero di risultati migliori (<) della soglia threshold
  # return (sum(am <= threshold) / length(am)) # è un data.frame non un vector
  tot <- 0
  for(v in am[[mes]]) {
    if (similarityP) {
      # strettamente maggiore (similarità) am non è ordinato risultato migliore per questo valore di gamma
      tot <- tot + if (v > threshold) 1 else 0
    } else {
      # strettamente minore (distanza) risultato migliore per questo valore di gamma
      tot <- tot + if (v < threshold) 1 else 0
    }
  }
  return (tot / nrow(am))
}


getT1error <- function( nm, threshold, similarityP)
{
  if (similarityP) {
    # se similarità conta il numero di risultati migliori (>) della soglia threshold
    return (sum(nm > threshold) / length(nm))
  }
  else {
    # se distanza (dissimilarità) conta il numero di risultati migliori (<) della soglia threshold
    return (sum(nm < threshold) / length(nm))
  }
}


T1Power <- function( len) {
  
  resultsDF <- data.frame( Measure = character(),  Model = character(), len = numeric(), gamma = double(),
                           k = numeric(), alpha=double(), threshold = double(),
                           power = double(), T1 = double(), stringsAsFactors=FALSE)
  
  cat(sprintf("len = %d\n", len))
  for(kv in kValues)  {
    cat(sprintf("\tk = %d\n", kv))
    # Collect the Null-Model results
    nm <- filter( df, df$model == nullModel & df$seqLen == len & df$k == kv)
    if (nrow(nm) == 0) {
      cat(sprintf("Wrong nullModel: %s no row found\n", nullModel))
      stop("bad data")
    }
    for( mes in measures) {
      similarityP <- mes %in% similarities 
      cat(sprintf("\t\t%s (%s): ", mes, if (similarityP) 'similarity' else 'distance'))
      nmDistances <- sort(nm[[mes]], decreasing = similarityP) # distances are sorted in ascending order, similarities in descending  
      for( g in gValues) { # salta gamma == 0
        for(alpha in alphaValues) {
          ndx <- round(length(nmDistances) * alpha)
          threshold <- nmDistances[ndx]
          # if (threshold == 1) {
          lck = lock( trsh, exclusive = TRUE, timeout = Inf)
          if (!is.null(lck)) {
            logLine <- sprintf("%d, %d, %s, %.3f, %.3f, %.3f", len, kv, mes, g, alpha, threshold)
            write( logLine, file = trsh, append = TRUE)
            unlock(lck)
          }
          for(altMod in altModels ) {  # 2 alternative models "MotifRepl-U" "PatTransf-U"
            am <- filter( df, df$model == altMod & df$gamma == g & df$seqLen == len & df$k == kv)
            power = getPower(am, mes, threshold, similarityP)
            #            cat(sprintf("AM: %s, power = %f  -  ", altMod, power))
            cat('.')
            if(altMod == altModels[1]) {
              # calcola solo una volta T1 una per ciascun AM
              nmT1 <- filter( df, df$model == T1Model & df$seqLen == len & df$k == kv)
              T1 <- getT1error(nmT1[[mes]], threshold, similarityP)
              #              cat(sprintf("T1-error = %f  -  ", T1))
            }
            resultsDF[nrow( resultsDF)+1,] <- list(mes, altMod, len, g, kv, alpha, threshold, power, T1)
          }
        }
      }
      cat('\n')
    }
  }
  return( resultsDF)
}



columnClasses = c(
      # 1  model	   2 gamma	  3 seqLen	 4 pairId	   5 k
      "character", "numeric", "integer", "integer", "integer",
      # 6  A	        B	         C	        D	        N
      "numeric", "numeric", "numeric", "numeric", "numeric",
      # 15 x misure present absent
      # 11 Anderberg	Antidice	 Dice	     Gower	    Hamman	  Hamming	   Jaccard	  Kulczynski
      "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",
      # Matching	 Ochiai	     Phi	     Russel	   Sneath    	Tanimoto	  Yule
      "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",
      # 26 mash 4 x 3 (P value, Mash distance, A, N)
      "numeric", "numeric", "numeric", "numeric",
      "numeric", "numeric", "numeric", "numeric",
      "numeric", "numeric", "numeric", "numeric",
      # 38 D2, Euclidean, NormalizedEuclidean
      "numeric", "numeric", "numeric",
      #  dati entropia 5 x seq x 2 (A-B)
      # sequence-A
      # 41 NKeysA 2*totalCntA deltaA	   HkA	      errorA
      "numeric", "numeric", "numeric", "numeric", "numeric",
      # sequence-B
      # 46 NKeysB	2*totalCntB deltaB	   HkB	      errorB
      "numeric", "numeric", "numeric", "numeric", "numeric")


df <-read.csv( file = csvFilename, colClasses = columnClasses)
df$model = factor(df$model)
# df$gamma = factor(df$gamma)
# df$k = factor(df$k)
# df$seqLen = factor(df$seqLen)


ll = levels(factor(df$gamma))
gValues = as.double(ll[2:length(ll)])
kValues = as.integer(levels(factor(df$k)))
lengths = as.integer(levels(factor(df$seqLen)))
col <- colnames(df)
measures <- c(col[11:25], col[27], col[31], col[35], col[38:40])
altModels = levels(df$model)[1:2]

alphaValues <- c( 0.01, 0.05, 0.10)

write( "Len, K, Measure, Gamma, Alpha, Threshold\n", file = trsh, append = FALSE)


# r <- lapply(lengths, T1Power) # sequential
r <- mclapply( lengths, T1Power, mc.cores = 6) # concurrent

resultsDF <- r[[1]]
for( i in 2:length(r)) { 
  resultsDF <- rbind( resultsDF, r[[i]])
}

saveRDS( resultsDF, file = dfFilename)

cat(sprintf("Dataset %s %d rows saved.", dfFilename, nrow(resultsDF)))

