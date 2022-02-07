library(DescTools)
library(dplyr)

###### DESCRIPTION

# compute Power Statistics and T1 error from raw data prduced by PresenAbsent.py script
# in CSV format


###### OPTIONS

# Sets the path of the directory containing the output of FADE
setwd("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent")

# Defines the name of the file containing a copy of the dataframe created by this script
dfFilename <- "Power+T1.RDS"
csvFilename <- 'PresentAbsentData-all.csv'
csvFilename <- 'tt.csv'

###### CODE

# if (file.exists(dfFilename)) {
#   cat( sprintf("Data file %s exists. Do you want to overwrite (Y/N) ?\n", dfFilename))
#   res <- readline()
#   if (res != "Y") {
#     quit(save="ask")
#   }
# }


getPower <- function( am, mes, threshold)
{
  # se distanza (dissimilarità) conta il numero di risultati migliori (<=) della soglia threshold
  # return (sum(am <= threshold) / length(am)) # è un data.frame non un vector
  tot <- 0
  for(v in am[[mes]]) {
    tot <- tot + if (v <= threshold) 1 else 0
  }
  return (tot / nrow(am))
}

getT1error <- function( nm, threshold)
{
  # se distanza (dissimilarità) conta il numero di risultati migliori (<=) della soglia threshold
  return (sum(nm <= threshold) / length(nm))
}

columnClasses = c( "character", "numeric", "integer", "integer", "integer",
                   "numeric", "numeric", "numeric", "numeric", "numeric",
                   "numeric", "numeric", "numeric", "numeric", "numeric",
                   "numeric", "numeric", "numeric", "numeric", "numeric",
                   "numeric", "numeric", "numeric", "numeric", "numeric",
                   "numeric", "numeric", "numeric", "character", "numeric",
                   "numeric", "numeric", "numeric", "numeric")
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
measures <- c(col[11:26], col[28])
altModels = levels(df$model)[1:2]

resultsDF <- data.frame( Measure = character(),  Model = character(), len = numeric(), gamma = double(),
                         k = numeric(), threshold = double(), power = double(), T1 = double(), stringsAsFactors=FALSE)

for( len in lengths) {
  for(kv in kValues)  {
    # Collect the Null-Model results
    nm <- filter( df, df$model == 'Uniform' & df$seqLen == len & df$k == kv)
    for( mes in measures) {
      nmDistances <- sort(nm[[mes]])   # sort in ordine crescente sono tutte dissimilarità / distanze
      for( g in gValues) { # salta gamma == 0
        ndx <- round(length(nmDistances) * g)
        threshold <- nmDistances[ndx]
        cat( sprintf("len = %d, k = %d, measure = %s,  gamma = %f, ndx = %d, threshold = %f\n",
                     len, kv, mes, g, ndx, threshold))
        for(altMod in altModels ) {  # 2 alternative models "MotifRepl-U" "PatTransf-U"
          am <- filter( df, df$model == altMod & df$gamma == g & df$seqLen == len & df$k == kv)
          power = getPower(am, mes, threshold)
          cat(sprintf("AM: %s, power = %f\n", altMod, power))
          # calcola 2 volte T1 una per ciascun AM
          nmT1 <- filter( df, df$model == 'Uniform-T1' & df$seqLen == len & df$k == kv)
          T1 <- getT1error(nmT1[[mes]], threshold)
          cat(sprintf("T1: %s, T1-error = %f\n", nmT1$model[1], T1))
          resultsDF[nrow( resultsDF)+1,] <- c(mes, altMod, len, g, kv, threshold, power, T1)
       }
      }
    }
  }
}

saveRDS( resultsDF, file = dfFilename)

cat(sprintf("Dataset %s %d rows saved.", dfFilename, nrow(resultsDF)))

