library(DescTools)
library(dplyr)
library(ggplot2)
library(hrbrthemes)
library(r2r)
library(stringr)


###### DESCRIPTION

# Plot experiment results for real genome sequences compared against the same sequence artificially modified


###### OPTIONS
###### CODE

bs <- "uniform"
wd <- sprintf("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent/%s,32", bs)
setwd(wd)

dirname <- "ReportSyntheticsV2"

similarities <- c('D2')
df1Filename <- sprintf("%s/distanceAll.RDS", dirname )
df2Filename <- sprintf("%s/cvAll.RDS", dirname )

similarities <- c('D2')
# misure di riferimento
PAMeasures <- c("Antidice", "Dice", "Jaccard", "Kulczynski", "Ochiai", "Russel",
                "Hamman", "Hamming", "Matching", "Sneath", "Tanimoto") # solo alcune misure Present/Absent senza le count based
pltMeasures <- c("D2", "Euclidean", "Antidice", "Dice", "Jaccard", "Kulczynski", "Ochiai", "Russel",
                 "Hamman", "Hamming", "Matching", "Sneath", "Tanimoto")
mainMeasures <- c("Jaccard", "Hamman")

xWidth <- 2.5 # larghezza di una singola colonna del pannello
yHeight <- 12 # altezza di tutti i grafici
deltaWidth <- 0.5 # incremento width x misura per eventuali y-axis header

# modifica i fattori di scala per ciascuna riga del pannello
TranslationTable  <- hashmap(default = 0)
TranslationTable[["Mash.Distance.1000."]] <- "Mash (sketch=1.000)"
TranslationTable[["Mash.Distance.10000."]] <- "Mash (sketch=10.000)"
TranslationTable[["Mash.Distance.100000."]] <- "Mash (sketch=10.0000)"


TerminologyServer <- function( key) {
  v <- TranslationTable[[key]]
  return( if (v == 0) key else v)
}

MeasureLabeller <- function(keys) {
  values <- c()
  for(k in keys) {
    values <- c(values, TerminologyServer(k))
  }
  return( values)
}

GammaLabeller <- function(keys) {
  values <- c()
  for(k in keys) {
    values <- c(values, sprintf("G:%.2f", as.numeric(k)))
  }
  return( values)
}



zoomLevels <- c(95, 90, 80, 70, 60) # soglia sul valore di theta per avere 1, 2, 3, 4, 5 valori sull'asse delle x
zoom <- 5

# Defines the name of the file containing a copy of the dataframe created by this script
#  Yeast, CElegans, HomoSapiens, Schistosoma, Lemur, MacacaMulatta, PiceaAbies
# genomes <- c( "Yeast", "CElegans", "HomoSapiens", "Schistosoma", "Lemur", "MacacaMulatta", "PiceaAbies")
genomes <- c( "Yeast", "CElegans", "HomoSapiens", "PiceaAbies")
sortedGenomes <- c("Yeast", "CElegans", "HomoSapiens", "PiceaAbies")
restrictedGenomes <- c("HomoSapiens")

types <- c("1:3", "4:6", "7:9", "9:11", "4:11", "all")
elements <- c("1:3", "4:6", "7:9", "9:11", "4:11", "1:11")
cvDF <- data.frame( Genome = character(), Measure = character(), k = integer(),
                    type = character(), cv = double(), stringsAsFactors=FALSE)

tgtDF <- data.frame( Genome = character(), Measure = character(), Theta = integer(), k = integer(),
                     A = numeric(), B = numeric(), C = numeric(), D = numeric(), N = numeric(), density = numeric(),
                     distance=double(), stringsAsFactors=FALSE)

# Theta1 = 14 (0.005, 0.01 - 0.10, 0.15, 0.20, 0.30)
# Theta2 = 11 (0.05, 0.10 - 0.90, 0.95
# Thetat = totale 25
# K = 8

nObs <- 200 # Thetat x k
nRowXObs <- length(pltMeasures)
dfSize <- nObs * nRowXObs


if (!file.exists(df1Filename) || !file.exists(df2Filename) ) {
  stop(sprintf("i due dataset %s e %d devonoessere già creati, altrimenti usa lo script %s per crearli", df1Filename, df2Filename, "PlotPASemiSyntheticsStatistics.R"))
}


# i due dataframe già esistono N.B. cancellare per ricolacolare i valori
tgtDF <-readRDS( file = df1Filename)
cvDF <-readRDS( file = df2Filename)
# ordina i genomi per lunghezza crescente
cvDF$Genome <- factor(cvDF$Genome, levels = sortedGenomes)
cvDF$Measure <- factor(cvDF$Measure)
# cvDF$k <-factor(cvDF$k,levels(factor(cvDF$k)))
cvDF$type <-factor(cvDF$type)

tgtDF$k <- as.numeric(as.character(tgtDF$k))
tgtDF$AD <- (tgtDF$A+tgtDF$D) / tgtDF$N

for( sequenceName in genomes) {

  totPrinted <- 0

  for( i in 1:3) {

    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure %in% PAMeasures & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure %in% PAMeasures & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure %in% PAMeasures)
      )

    df$Measure <- factor( df$Measure, levels = PAMeasures)


    # Pannello della density x k *******************************************************************
    # grafico delle densità A/N
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure == "Jaccard" & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure == "Jaccard" & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure == "Jaccard")
    )


    #           0.0001%    0.01% 1%     95%   97%   99%
    beta <- c( 1e-40, 1e-20, 1e-10, 1e-5, 1e-3, 0.01, 0.1, 0.7, 0.9, 0.95, 0.96, 0.97, 0.98, 0.99, 1)
    df2 <- select(df, k, Theta, density)               # seleziona le 3 colonne
    df2 <- df2 %>% distinct(k, Theta, .keep_all = TRUE)   # rimuove i duplicati tra diversi esperimenti
    df2 <- df2[order(df2$Theta), ]                        # ordina per Theta
    df2$color <- as.numeric(cut( df2$density, breaks = beta, include.lowest = TRUE, right = TRUE))
    df2$density <- NULL
    mat <- pivot_wider(df2, names_from = Theta, values_from = color)
    k_labels <- mat$k
    mat$k <- NULL
    mat <- as.matrix(mat)
    rownames(mat) <- k_labels


    # create heatmap using pheatmap
    x1 <- pheatmap(mat, cluster_rows = FALSE,cluster_cols = FALSE)
    outfname <- sprintf( "%s/%s/HeatmapDensities-%s-%d.png", dirname, sequenceName, sequenceName, i)
    png(outfname, width = 1600, height=900)
    grid::grid.newpage()
    grid::grid.draw(x1$gtable)
    dev.off()
    totPrinted <- totPrinted + 1
  }
}


cat(sprintf("CV plot Done. %d plot printed\n", totPrinted))
