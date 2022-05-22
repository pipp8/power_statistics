library(rjson)
library(ggplot2)
library(stringr)
library(dplyr)
library(RColorBrewer)
library(facetscales)



###### DESCRIPTION

# read csv data file and save a dataframe in RDS format

###### OPTIONS

# Sets the path of the directory containing the input dataframe

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent")

# Sets the name of the file containing the input dataframe
dfFilename <- "PresentAbsent-RawData.RDS"
dfFilename <- "PresentAbsentEC-RawData.RDS"
csvFilename <- 'PresentAbsentData-all.csv'
nullModel <- 'Uniform'
csvFilename <- 'PresentAbsentECData.csv'
nullModel <- 'ShuffledEColi'
T1Model <- paste( sep='', nullModel, '-T1')


if (file.exists(dfFilename)) {
  cat( sprintf("Data file %s exists. Do you want to overwrite (Y/N) ?\n", dfFilename))
  res <- readline()
  if (res != "Y") {
    quit(save="ask")
  }
}

# otherwise convert the  CSV file to dataframe
columnClasses = c(
              #   model	    gamma	    seqLen	   pairId	       k
              "character", "numeric", "integer", "integer", "integer",
              #   A	        B	         C	        D	        N
              "numeric", "numeric", "numeric", "numeric", "numeric",
              # 15 x misure present absent
              # Anderberg	Antidice	 Dice	     Gower	    Hamman	  Hamming	   Jaccard	  Kulczynski
              "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",
              # Matching	 Ochiai	     Phi	     Russel	   Sneath    	Tanimoto	  Yule
              "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",
              # mash 4 x 3 (P value, Mash distance, A, N)
              "numeric", "numeric", "numeric", "numeric",
              "numeric", "numeric", "numeric", "numeric",
              "numeric", "numeric", "numeric", "numeric",
              # dati entropia 5 x seq x 2 (A-B)
              # sequence-A
              # NKeysA	 2*totalCntA  deltaA	    HkA	       errorA
              "numeric", "numeric", "numeric", "numeric", "numeric",
              # sequence-B
              # NKeysB	 2*totalCntB  deltaB	    HkB	      errorB
              "numeric", "numeric", "numeric", "numeric", "numeric")

dati <-read.csv(file = csvFilename, colClasses = columnClasses)
dati$model = factor(dati$model)
# dati$gamma = factor(dati$gamma)
# dati$k = factor(dati$k)


ll = levels(factor(dati$gamma))
gValues = as.double(ll[2:length(ll)])
kValues = as.integer(levels(factor(dati$k)))
lengths = as.integer(levels(factor(dati$seqLen)))
col <- colnames(dati)
measures <- c(col[11:25], col[27], col[31], col[35])

saveRDS(dati, file = dfFilename)
cat(sprintf("Dataset %s %d rows saved.", dfFilename, nrow(dati)))
