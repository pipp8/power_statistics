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

wd <- "~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent/RealGenomes"
setwd(wd)

dirname <- "ReportSyntheticsV4"

similarities <- c('D2')
df1Filename <- sprintf("%s/distanceAll.RDS", dirname )

similarities <- c('D2')
# misure di riferimento
PAMeasures <- c("Antidice", "Dice", "Jaccard", "Kulczynski", "Ochiai", "Russel",
                "Hamman", "Hamming", "Matching", "Sneath", "Tanimoto") # solo alcune misure Present/Absent senza le count based
pltMeasures <- c("D2", "Euclidean", "Antidice", "Dice", "Jaccard", "Kulczynski", "Ochiai", "Russel",
                 "Hamman", "Hamming", "Matching", "Sneath", "Tanimoto")
mainMeasures <- c("Jaccard", "Russel", "Hamman")

xWidth <- 2.5 # larghezza di una singola colonna del pannello
yHeight <- 12 # altezza di tutti i grafici
deltaWidth <- 0.8 # incremento width x misura per eventuali y-axis header

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
#             3.340.225.228  3.217.480.608 3.154.078.448    2.762.331.583 101.526.309 12.223.592
genomes <- c( "HomoSapiens", "Chimpazee",  "MacacaMulatta", "HouseMouse", "CElegans", "Yeast")

sortedGenomes <- c( "HomoSapiens", "Chimpazee", "MacacaMulatta", "HouseMouse", "CElegans", "Yeast")
restrictedGenomes <- c("HomoSapiens")
restrictedGenomes2<- c("Yeast", "CElegans", "HomoSapiens")
# ordinati per lunghezza crescente
restrictedGenomes3 <- c( "Yeast", "CElegans", "HouseMouse", "MacacaMulatta", "Chimpazee", "HomoSapiens")



                         types <- c("1:3", "4:6", "7:9", "9:11", "4:11", "all")
elements <- c("1:3", "4:6", "7:9", "9:11", "4:11", "1:11")

tgtDF <- data.frame( Genome = character(), Measure = character(), Theta = integer(), k = integer(),
                     A = numeric(), B = numeric(), C = numeric(), D = numeric(), N = numeric(), density = numeric(),
                     distance=double(), stringsAsFactors=FALSE)

# Theta1 = 14 (0.005, 0.01 - 0.10, 0.20, 0.30)
# Theta2 = 11 (0.05, 0.10 - 0.90, 0.95)
# Thetat = totale 25
# K = 8

nObs <- 160 # 20 Theta x 8 k
nRowXObs <- length(pltMeasures)
dfSize <- nObs * nRowXObs


if (!file.exists(df1Filename)) {
  # calcola il dataframe
  cnt <- 0
  for( sequenceName in genomes) {

    csvFilename <- sprintf("%s/%s.csv", dirname, sequenceName)
    tgtDir <- sprintf("%s/%s", dirname, sequenceName)
    if (!dir.exists( tgtDir)) {
      dir.create(tgtDir)
    }

    # carica il CSV dell'esperimento
    columnClasses <- c(
      #   sequenceA  sequenceB  start.time  real.time    Theta        k
      "character", "character", "numeric", "numeric", "numeric", "integer",
      #   A	        B	      C	         D	        N         A/N
      "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",
      # 15 x misure present absent
      # Anderberg	Antidice	 Dice	     Gower	    Hamman	  Hamming	   Jaccard	  Kulczynski
      "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",
      # Matching	 Ochiai	     Phi	     Russel	   Sneath    	Tanimoto	  Yule
      "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",
      # mash 4 x 1 (P value, Mash distance, A, N size = 10.000)
      "numeric", "numeric", "numeric", "numeric",
      # D2     Euclidean    Euclid_norm
      "numeric", "numeric", "numeric",
      # NKeysA   totalCntA   deltaA       HkA      errorA
      "numeric", "numeric", "numeric", "numeric","numeric",
      # NKeysB   totalCntB   deltaB       HkB      errorB
      "numeric", "numeric", "numeric", "numeric","numeric")

      df <-read.csv( file = csvFilename, sep = ",", dec = ".", colClasses = columnClasses)
      cat(sprintf("Dataset %s loaded %d rows read.\n", csvFilename, nrow(df)))

      # 'data.frame':	48 obs. of  44 variables:
      # $ sequenceA           : Factor w/ 1 level "GCF_003339765.1_Mmul_1.0": 1 1 1 1 1 1 1 1 1 1 ...
      # $ sequenceB           : Factor w/ 6 levels "GCF_003339765.1_Mmul_1.0-10",..: 3 1 2 4 5 6 3 1 2 4 ...
      # $ start.time          : int  1702206937 1702236286 1702268144 1702300312 1702338382 1702370789 1702207380 1702236826 1702268569 1702300989 ...
      # $ real.time           : Factor w/ 48 levels "222,4092066",..: 17 23 14 30 38 29 4 12 5 21 ...
      # $ Theta               : int  5 10 20 80 90 95 5 10 20 80 ...
      # $ k                   : int  4 4 4 4 4 4 8 8 8 8 ...
      # $ A                   : Factor w/ 33 levels "0","103","108.466.454",..: 13 13 13 13 13 13 25 25 25 25 ...
      # $ B                   : Factor w/ 31 levels "0","1.390.399.430",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ C                   : Factor w/ 33 levels "0","1.039.140.839",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ D                   : Factor w/ 29 levels "0","1.094.310.351.548",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ N                   : Factor w/ 8 levels "1.099.511.627.776",..: 4 4 4 4 4 4 7 7 7 7 ...
      # $ A.N                 : Factor w/ 32 levels "0","0,000324535",..: 13 13 13 13 13 13 13 13 13 13 ...
      # $ Anderberg           : Factor w/ 30 levels "0,213759018",..: 30 30 30 30 30 30 30 30 30 30 ...
      # $ Antidice            : Factor w/ 32 levels "0","0,016613598",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Dice                : Factor w/ 32 levels "0","0,004205805",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Gower               : Factor w/ 31 levels "-0,3132203","-0,962032841",..: 31 31 31 31 31 31 31 31 31 31 ...
      # $ Hamman              : Factor w/ 27 levels "0","0,010904372",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Hamming             : Factor w/ 27 levels "0","0,002733565",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Jaccard             : Factor w/ 32 levels "0","0,00837638",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Kulczynski          : Factor w/ 32 levels "0","0,004189791",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Matching            : Factor w/ 27 levels "0","0,002733565",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Ochiai              : Factor w/ 32 levels "0","0,004197798",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Phi                 : Factor w/ 30 levels "-1,03E+33","-1,42E+35",..: 30 30 30 30 30 30 30 30 30 30 ...
      # $ Russel              : Factor w/ 22 levels "0","0,008593202",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Sneath              : Factor w/ 27 levels "0","0,001368653",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Tanimoto            : Factor w/ 28 levels "0","0,005452227",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Yule                : Factor w/ 31 levels "0","0,000340283",..: 24 24 24 24 24 24 24 24 24 24 ...
      # $ Mash.Pv..10000.     : Factor w/ 25 levels "0","0,0148949",..: 1 1 1 1 1 1 1 1 1 1 ...
      # $ Mash.Distance.10000.: Factor w/ 16 levels "0","0,0348505",..: 7 7 7 7 7 7 6 6 6 6 ...
      # $ A..10000.           : int  136 136 136 136 136 136 10000 10000 10000 10000 ...
      # $ N..10000.           : int  136 136 136 136 136 136 10000 10000 10000 10000 ...
      # $ D2                  : Factor w/ 46 levels "0","1,00952E+12",..: 34 33 31 26 25 24 23 19 17 8 ...
      # $ Euclidean           : Factor w/ 42 levels "1.832.067,52",..: 7 24 36 4 5 6 30 38 42 8 ...
      # $ EuclideanZ          : int  0 0 0 0 0 0 0 0 0 0 ...
      # $ NKeysA              : num  256 256 256 256 256 ...
      # $ X2.totalCntA        : num  5.87e+09 5.87e+09 5.87e+09 5.87e+09 5.87e+09 ...
      # $ deltaA              : Factor w/ 8 levels "0,002831776",..: 8 8 8 8 8 8 7 7 7 7 ...
      # $ HkA                 : Factor w/ 8 levels "-15,28220155",..: 8 8 8 8 8 8 1 1 1 1 ...
      # $ errorA              : Factor w/ 8 levels "-0,000127184",..: 7 7 7 7 7 7 8 8 8 8 ...
      # $ NKeysB              : num  256 256 256 256 256 ...
      # $ X2.totalCntB        : num  5.87e+09 5.87e+09 5.87e+09 5.87e+09 5.87e+09 ...
      # $ deltaB              : Factor w/ 32 levels "0,002854579",..: 32 32 32 32 32 32 31 31 31 31 ...
      # $ HkB                 : Factor w/ 47 levels "-15,47734591",..: 42 43 44 47 46 45 1 2 3 6 ...
      # $ errorB              : Factor w/ 42 levels "-0,00011904",..: 37 36 35 34 34 34 42 41 40 38 ...

    df$kf <- factor(df$k)
    df$tf <- factor(df$Theta)

    measures <- colnames(df)[13:27]
    # extras = c("Mash.Distance.10000.", "D2", "Euclidean")
    extras <- c("Mash.Distance.10000.", "D2", "Euclidean")
    measures <- append(measures, extras)

    # calcola la trasposta ... un rigo per ogni misura
    for(i in seq_len(nrow(df))) {
      r <- df[i,]
      for(m in measures) {
        MesName <- if (m == "Mash.Distance.10000.") "Mash" else m
        nr <- c( sequenceName, MesName, r[5:12], df[i, m])
        tgtDF[nrow(tgtDF)+1,] <- nr
      }
    }

    # escludiamo le misure: euclidean norm, anderberg, gowel , phi e yule. 2880 -> 2080 observations
    tgtDF <- filter(tgtDF, Measure %in% pltMeasures)
    # tgtDF <- filter( tgtDF, Measure != "Euclid_norm" & Measure != "Mash.Distance.1000." & Measure != "Mash.Distance.100000.")

    cat(sprintf("Filtered measures: Anderberg, Gower, Phi, Yule, EuclideanZ, Mash.Distance.1000, Mash.Distance.10000, Mash.Distance.100000. (%d rows).\n",nrow(df)))

    tgtDF$k <- factor(tgtDF$k)
    # tgtDF$Theta = factor(tgtDF$Theta)

    kValues <- levels(tgtDF$k)
    measures <- levels(factor(tgtDF$Measure))

    cat(sprintf("Data Frame %s filtered (%d observations).\n", sequenceName, nrow(tgtDF) - cnt * dfSize))

    cnt <- cnt + 1
    if (nrow(tgtDF) != cnt * dfSize)   {
      stop("errore nel calcolo di tgtDF per il calcolo delle distanze relative")
    }
  } # per ogni genoma
  # salva il df finale

  saveRDS( tgtDF, df1Filename)
  cat(sprintf("%d genomes loaded. Data Frame %s -> %d observations.\n", cnt, df1Filename, nrow(tgtDF)))

  # ordina i genomi per lunghezza crescente
  # cvDF$Genome <- factor(cvDF$Genome, levels = sortedGenomes)
  # cvDF$Measure <- factor(cvDF$Measure, levels = PAMeasures)
  # cvDF$k <-factor(cvDF$k,levels(factor(cvDF$k)))
  # cvDF$type <-factor(cvDF$type)
  # salva il datafrme con i coefficienti di variazione
  # saveRDS( cvDF, df2Filename)
  # for( mes in measures) {
  #  df <- filter( cvDF, Measure == mes)
  #  cat(sprintf("%s -> min: %f, max: %f\n", mes, min(df$cv, na.rm = TRUE), max(df$cv,na.rm = TRUE)))
  #}
}
# i due dataframe già esistono N.B. cancellare per ricolacolare i valori
tgtDF <-readRDS( file = df1Filename)

# cvDF <-readRDS( file = df2Filename)
# ordina i genomi per lunghezza crescente
# cvDF$Genome <- factor(cvDF$Genome, levels = sortedGenomes)
# cvDF$Measure <- factor(cvDF$Measure)
# cvDF$k <-factor(cvDF$k,levels(factor(cvDF$k)))
# cvDF$type <-factor(cvDF$type)

tgtDF$AD <- (tgtDF$A+tgtDF$D) / tgtDF$N

totPrinted <- 0

for( i in 1:3) {

  #  grafico distanze per tutte le misura Present/Absent (Theta sull'asse delle x)
  df <- switch(as.character(i),
               "1" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure %in% PAMeasures & Theta <= 0.3 & (k == 12 | k == 16)),
               "2" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure %in% PAMeasures & Theta > 0.3 & (k == 12 | k == 16)),
               "3" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure %in% PAMeasures & (k == 12 | k == 16))
  )

  ySize <- yHeight / 8 * length(restrictedGenomes3) * 2
  df$Measure <- factor( df$Measure, levels = PAMeasures)
  # df$Genome <- factor( df$Genome, levels = restrictedGenomes3)

  sp1 <- ggplot(df, aes(x = Theta, y = distance, fill = k)) +
    geom_line(aes(color = k)) +
    geom_point(size = 0.8) +
    facet_grid( rows = vars(Genome, k), cols = vars(Measure), labeller = labeller( k = label_both)) + #, scales = "free_y"
    scale_y_continuous(limits = c(0, 1), labels=c("0", "0.5", "1"), breaks = c(0, 0.5, 1)) +
    theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                          axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                          panel.spacing=unit(0.1, "lines"),
                          legend.position = "none",
                          axis.text.y = element_blank(),
                          axis.title.y = element_blank(),
                          axis.title.x = element_blank())

  # dev.new(width = 6, height = 6)
  # print(sp1)
  outfname <- sprintf( "%s/Panelk1216-all-%d.png", dirname, i)
  ggsave( outfname, device = png(), width = length(PAMeasures) * xWidth + deltaWidth, height = ySize, units = "cm", dpi = 300)
  dev.off() # only 129kb in size
  totPrinted <- totPrinted + 1

  # grafico distanze per le 3 misure principali  Present/Absent (Theta sull'asse delle x)
  df <- switch(as.character(i),
               "1" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure %in% mainMeasures & Theta <= 0.3 & (k == 12 | k == 16)),
               "2" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure %in% mainMeasures & Theta > 0.3 & (k == 12 | k == 16)),
               "3" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure %in% mainMeasures & (k == 12 | k == 16))
  )

  df$Measure <- factor( df$Measure, levels = mainMeasures)
  # df$Genome <- factor( df$Genome, levels = restrictedGenomes3)

  sp1 <- ggplot(df, aes(x = Theta, y = distance, fill = k)) +
    geom_line(aes(color = k)) +
    geom_point(size = 0.8) +
    facet_grid( rows = vars(Genome, k), cols = vars(Measure), labeller = labeller( k = label_both)) + #, scales = "free_y"
    scale_y_continuous(limits = c(0, 1), labels=c("0", "0.5", "1"), breaks = c(0, 0.5, 1)) +
    theme_bw() + theme(   strip.text.x = element_text( size = 8, angle = 0),
                          axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                          panel.spacing=unit(0.1, "lines"),
                          legend.position = "none",
                          axis.text.y = element_blank(),
                          axis.title.y = element_blank(),
                          strip.text.y = element_text( size = rel(0.7)),
                          axis.title.x = element_blank())

  # dev.new(width = 6, height = 6)
  # print(sp1)
  outfname <- sprintf( "%s/Panelk1216-main-%d.png", dirname, i)
  ggsave( outfname, device = png(), width = length(mainMeasures) * xWidth + deltaWidth, height = ySize, units = "cm", dpi = 300)
  dev.off() # only 129kb in size
  totPrinted <- totPrinted + 1


  #  grafico distanze per Euclidean (Theta sull'asse delle x)
  df <- switch(as.character(i),
               "1" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure == "Euclidean" & Theta <= 0.3 & (k == 12 | k == 16)),
               "2" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure == "Euclidean" & Theta > 0.3 & (k == 12 | k == 16)),
               "3" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure == "Euclidean" & (k == 12 | k == 16))
  )

  # df$Measure <- factor( df$Measure, levels = mainMeasures)
  # df$Genome <- factor( df$Genome, levels = restrictedGenomes3)

  sp1 <- ggplot(df, aes(x = Theta, y = distance, fill = k)) +
    geom_line(aes(color = k)) +
    geom_point(size = 0.8) +
    facet_grid( rows = vars(Genome, k), cols = vars(Measure), scales = "free_y", labeller = labeller( k = label_both)) + #, scales = "free_y"
    theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                          strip.text.y = element_blank(),
                          axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                          panel.spacing=unit(0.1, "lines"),
                          legend.position = "none",
                          axis.text.y = element_blank(),
                          axis.title.y = element_blank(),
                          axis.title.x = element_blank())

  # dev.new(width = 6, height = 6)
  # print(sp1)
  outfname <- sprintf( "%s/Panelk1216-Euclidean-%d.png", dirname, i)
  ggsave( outfname, device = png(), width = xWidth, height = ySize, units = "cm", dpi = 300)
  dev.off() # only 129kb in size
  totPrinted <- totPrinted + 1


  #  grafico distanze per D2 (Theta sull'asse delle x)
  df <- switch(as.character(i),
               "1" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure == "D2" & Theta <= 0.3 & (k == 12 | k == 16)),
               "2" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure == "D2" & Theta > 0.3 & (k == 12 | k == 16)),
               "3" = filter(tgtDF, Genome %in% restrictedGenomes3 & Measure == "D2" & (k == 12 | k == 16))
  )

  # df$Measure <- factor( df$Measure, levels = mainMeasures)
  # df$Genome <- factor( df$Genome, levels = restrictedGenomes3)

  sp1 <- ggplot(df, aes(x = Theta, y = distance, fill = k)) +
    geom_line(aes(color = k)) +
    geom_point(size = 0.8) +
    facet_grid( rows = vars(Genome, k), cols = vars(Measure), scales = "free_y", labeller = labeller( k = label_both)) + #, scales = "free_y"
    theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                          axis.title.x = element_blank(),
                          axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                          panel.spacing=unit(0.1, "lines"),
                          legend.position = "none",
                          strip.text.y = element_blank(),
                          axis.text.y = element_blank(),
                          axis.title.y = element_text( size = 9)) + labs( y = "Distances")

  # dev.new(width = 6, height = 6)
  # print(sp1)
  outfname <- sprintf( "%s/Panelk1216-D2-%d.png", dirname, i)
  ggsave( outfname, device = png(), width = xWidth + deltaWidth, height = ySize, units = "cm", dpi = 300)
  dev.off() # only 129kb in size
  totPrinted <- totPrinted + 1

}




df <- filter(tgtDF, Genome == "HomoSapiens" & Measure == "Jaccard")
# riporta k in numeric anzichè factor
df$k <- as.numeric(levels(df$k))

cat(sprintf( " k\tmin\t\t\tmax\n"))
for( kk in levels(factor(df$k))) {
  d1 <- filter(df, k == as.numeric(kk))
  d1 <- d1[order(d1$Theta),,drop=FALSE]
  cat(sprintf( "%s\t%f\t%f\n", kk, min(d1$density), max(d1$density)))
}


for( sequenceName in genomes) {

  df <- filter(tgtDF, Genome == sequenceName & Measure == "Jaccard")
  # riporta k in numeric anzichè factor
  df$k <- as.numeric(levels(df$k))

  cat(sprintf( " sequence: %s\nk\tmin\t\t\tmax\n", sequenceName))
  for( kk in levels(factor(df$k))) {
    d1 <- filter(df, k == as.numeric(kk))
    d1 <- d1[order(d1$Theta),,drop=FALSE]
    cat(sprintf( "%s\t%f\t%f\n", kk, min(d1$density), max(d1$density)))
  }

  totPrinted <- 0

  for( i in 1:3) {

    # pannello con solo le principali misure
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure %in% mainMeasures & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure %in% mainMeasures & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure %in% mainMeasures)
    )

    df$Measure <- factor( df$Measure, levels = mainMeasures)

    #  grafico distanze per le principali misure Present/Absent (Theta sull'asse delle x)
    sp1 <- ggplot(df, aes(x = Theta, y = distance, fill = k)) +
      geom_line(aes(color = k)) +
      geom_point(size = 0.8) +
      facet_grid( rows = vars(k), cols = vars(Measure), labeller = labeller( k = label_both)) + #, scales = "free_y"
      theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                            axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                            panel.spacing=unit(0.1, "lines"),
                            legend.position = "none",
                            axis.text.y = element_blank(),
                            axis.title.y = element_blank(),
                            axis.title.x = element_blank())

    # dev.new(width = 6, height = 6)
    # print(sp1)
    outfname <- sprintf( "%s/%s/PanelDistancesMain-%s-%d.png", dirname, sequenceName, sequenceName, i)
    ggsave( outfname, device = png(), width = length(mainMeasures) * xWidth + deltaWidth, height = yHeight, units = "cm", dpi = 300)
    dev.off() # only 129kb in size
    totPrinted <- totPrinted + 1


    # panel per tutte le misure Present/Absent
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure %in% PAMeasures & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure %in% PAMeasures & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure %in% PAMeasures)
      )

    df$Measure <- factor( df$Measure, levels = PAMeasures)

    #  grafico distanze per tutte le misura Present/Absent (Theta sull'asse delle x)
    sp1 <- ggplot(df, aes(x = Theta, y = distance, fill = k)) +
        geom_line(aes(color = k)) +
        geom_point(size = 0.8) +
        facet_grid( rows = vars(k), cols = vars(Measure), labeller = labeller( k = label_both)) + #, scales = "free_y"
        theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                               axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                               panel.spacing=unit(0.1, "lines"),
                               legend.position = "none",
                               axis.text.y = element_blank(),
                               axis.title.y = element_blank(),
                               axis.title.x = element_blank())

    # dev.new(width = 6, height = 6)
    # print(sp1)
    outfname <- sprintf( "%s/%s/PanelDistances-%s-%d.png", dirname, sequenceName, sequenceName, i)
    ggsave( outfname, device = png(), width = length(PAMeasures) * xWidth + deltaWidth, height = yHeight, units = "cm", dpi = 300)
    dev.off() # only 129kb in size
    totPrinted <- totPrinted + 1



    # Secondo grafico di riferimento per simmilarità D2 (e leggenda distance)
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure == "D2" & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure == "D2" & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure == "D2")
    )

    sp1 <- ggplot(df, aes(x = Theta, y = distance)) +
      geom_line(aes(color = k)) +
      geom_point(size = 0.8) +
      facet_grid( rows = vars(k), cols = vars(Measure), scales = "free_y", labeller = labeller( k = label_both)) +
      theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                            axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                            axis.title.x = element_blank(),
                            panel.spacing=unit(0.1, "lines"),
                            legend.position = "none",
                            axis.text.y = element_blank(),
                            strip.text.y = element_blank(),
                            axis.title.y = element_text( size = 9)) + labs( y = "Distances")

    # guides(colour = guide_legend(override.aes = list(size=1)))

    # dev.new(width = 6, height = 9)
    # print(sp1)
    outfname <- sprintf( "%s/%s/PanelD2-%s-%d.png", dirname, sequenceName, sequenceName, i)
    ggsave( outfname, device = png(), width = xWidth + deltaWidth, height = yHeight, units = "cm", dpi = 300)
    dev.off() # only 129kb in size
    totPrinted <- totPrinted + 1

    # Terzo grafico di riferimento per Euclide (no Y-Axis no strip)
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure == "Euclidean" & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure == "Euclidean" & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure == "Euclidean")
    )


    sp1 <- ggplot(df, aes(x = Theta, y = distance)) +
      geom_line(aes(color = k)) +
      geom_point(size = 0.8) +
      facet_grid( rows = vars(k), cols = vars(Measure), scales = "free_y", labeller = labeller( k = label_both)) +
      theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                            axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                            panel.spacing=unit(0.1, "lines"),
                            legend.position = "none",
                            axis.title.y = element_blank(),
                            axis.text.y = element_blank(),
                            strip.text.y = element_blank(),
                            axis.title.x = element_blank())

    # dev.new(width = 6, height = 9)
    # print(sp1)
    outfname <- sprintf( "%s/%s/PanelEuclid-%s-%d.png", dirname, sequenceName, sequenceName, i)
    ggsave( outfname, device = png(), width = xWidth, height = yHeight, units = "cm", dpi = 300)
    dev.off() # only 129kb in size
    totPrinted <- totPrinted + 1


    # quarto grafico di riferimento solo Jaccard (no Y-Axis no strip)
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure == "Jaccard" & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure == "Jaccard" & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure == "Jaccard")
    )


    sp1 <- ggplot(df, aes(x = Theta, y = distance)) +
      geom_line(aes(color = k)) +
      geom_point(size = 0.8) +
      facet_grid( rows = vars(k), cols = vars(Measure), scales = "free_y", labeller = labeller( k = label_both)) +
      scale_y_continuous(limits = c(0, 1), labels=c("0", "0.5", "1"), breaks = c(0, 0.5, 1)) +
      theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                            axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                            panel.spacing=unit(0.1, "lines"),
                            legend.position = "none",
                            axis.title.y = element_blank(),
                            axis.text.y = element_blank(),
                            strip.text.y = element_blank(),
                            axis.title.x = element_blank())

    # dev.new(width = 6, height = 9)
    # print(sp1)
    outfname <- sprintf( "%s/%s/PanelJaccard-%s-%d.png", dirname, sequenceName, sequenceName, i)
    ggsave( outfname, device = png(), width = xWidth, height = yHeight, units = "cm", dpi = 300)
    dev.off() # only 129kb in size
    totPrinted <- totPrinted + 1

    # quinto grafico di riferimento solo Russel (no Y-Axis no strip)
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure == "Russel" & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure == "Russel" & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure == "Russel")
    )


    sp1 <- ggplot(df, aes(x = Theta, y = distance)) +
      geom_line(aes(color = k)) +
      geom_point(size = 0.8) +
      facet_grid( rows = vars(k), cols = vars(Measure), scales = "free_y", labeller = labeller( k = label_both)) +
      scale_y_continuous(limits = c(0, 1), labels=c("0", "0.5", "1"), breaks = c(0, 0.5, 1)) +
      theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                            axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                            panel.spacing=unit(0.1, "lines"),
                            legend.position = "none",
                            axis.title.y = element_blank(),
                            axis.text.y = element_blank(),
                            strip.text.y = element_blank(),
                            axis.title.x = element_blank())

    # dev.new(width = 6, height = 9)
    # print(sp1)
    outfname <- sprintf( "%s/%s/PanelRussel-%s-%d.png", dirname, sequenceName, sequenceName, i)
    ggsave( outfname, device = png(), width = xWidth, height = yHeight, units = "cm", dpi = 300)
    dev.off() # only 129kb in size
    totPrinted <- totPrinted + 1

    # sesto grafico di riferimento solo Hamman (e valori di k sulla destra)
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure == "Hamman" & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure == "Hamman" & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure == "Hamman")
    )


    sp1 <- ggplot(df, aes(x = Theta, y = distance)) +
      geom_line(aes(color = k)) +
      geom_point(size = 0.8) +
      facet_grid( rows = vars(k), cols = vars(Measure), scales = "free_y", labeller = labeller( k = label_both)) +
      scale_y_continuous(limits = c(0, 1), labels=c("0", "0.5", "1"), breaks = c(0, 0.5, 1)) +
      theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 0),
                            axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                            panel.spacing=unit(0.1, "lines"),
                            legend.position = "none",
                            axis.title.y = element_blank(),
                            axis.text.y = element_blank(),
                            axis.title.x = element_blank())

    # dev.new(width = 6, height = 9)
    # print(sp1)
    outfname <- sprintf( "%s/%s/PanelHamman-%s-%d.png", dirname, sequenceName, sequenceName, i)
    ggsave( outfname, device = png(), width = xWidth + deltaWidth, height = yHeight, units = "cm", dpi = 300)
    dev.off() # only 129kb in size
    totPrinted <- totPrinted + 1


    # Pannello della density x k *******************************************************************
    # grafico delle densità A/N
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == sequenceName & Measure == "Jaccard" & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == sequenceName & Measure == "Jaccard" & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == sequenceName & Measure == "Jaccard")
    )

    sp1 <- ggplot(data=df, aes(x=Theta, y=density, label=density)) +
      geom_line(aes(color = k)) +
      geom_point(size = 0.8) +
      facet_grid( rows = vars(k), labeller = labeller( k = label_both)) +
      scale_y_continuous(name = "A/N",
                         breaks=c(0, 0.5, 1),
                         labels=c("0", "0.5", "1")) +
      theme_bw() + theme( panel.spacing=unit(0.2, "lines"),
                             legend.position = "none",
                             strip.text.x = element_text( size = 8, angle = 0),
                             axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                             axis.title.x = element_blank())
    #                         axis.text.x=element_blank())

    outfname <- sprintf( "%s/%s/PanelDensities-%s-%d.png", dirname, sequenceName, sequenceName, i)
    ggsave( outfname, device = png(), width = 2 * xWidth, height = yHeight, units = "cm", dpi = 300)
    dev.off()
    totPrinted <- totPrinted + 1
  }
}


for( i in 1:3) {

  df <- switch(as.character(i),
               "1" = filter(tgtDF, Genome %in% restrictedGenomes2, Measure == "Jaccard" & Theta <= 0.3),
               "2" = filter(tgtDF, Genome %in% restrictedGenomes2, Measure == "Jaccard" & Theta > 0.3),
               "3" = filter(tgtDF, Genome %in% restrictedGenomes2, Measure == "Jaccard")
  )
  # grafico delle densità A/N x tutti i genomi
  df$Genome <- factor(df$Genome, levels = restrictedGenomes2)

  sp1 <- ggplot(data=df, aes(x=Theta, y=density, label=density)) +
    geom_line(aes(color = k)) +
    geom_point(size = 0.8) +
    facet_grid( rows = vars(k), cols = vars( Genome), labeller = labeller( k = label_both)) +
    scale_y_continuous(name = "Genome A/N Values",
                       breaks=c(0, 0.5, 1),
                       labels=c("0", "0.5", "1")) +
    theme_bw() + theme( panel.spacing=unit(0.2, "lines"),
                           legend.position = "none",
                           strip.text.x = element_text( size = 8, angle = 0),
                           axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                           axis.title.x = element_blank())
  #                         axis.text.x=element_blank())

  outfname <- sprintf( "%s/PanelDensities-all-%d.png", dirname,i)
  ggsave( outfname, device = png(),  width = length(restrictedGenomes2) * xWidth + 2 * deltaWidth, height = yHeight, units = "cm", dpi = 300)
  dev.off()
  totPrinted <- totPrinted + 1

  df <- switch(as.character(i),
               "1" = filter(tgtDF, Genome %in% restrictedGenomes2, Measure == "Jaccard" & Theta <= 0.3),
               "2" = filter(tgtDF, Genome %in% restrictedGenomes2, Measure == "Jaccard" & Theta > 0.3),
               "3" = filter(tgtDF, Genome %in% restrictedGenomes2, Measure == "Jaccard")
  )
  df$Genome <- factor(df$Genome, levels = restrictedGenomes2)

  # grafico delle densità (A+D)/N x tutti i genomi
  sp1 <- ggplot(data=df, aes(x=Theta, y=AD, label=density)) +
    geom_line(aes(color = k)) +
    geom_point(size = 0.8) +
    facet_grid( rows = vars(k), cols = vars( Genome), labeller = labeller( k = label_both)) +
    scale_y_continuous(name = "Genome (A+D)/N Values",
                       breaks=c(0, 0.5, 1),
                       labels=c("0", "0.5", "1")) +
    theme_bw() + theme( panel.spacing=unit(0.2, "lines"),
                           legend.position = "none",
                           strip.text.x = element_text( size = 8, angle = 0),
                           axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                           axis.title.x = element_blank())
  #                         axis.text.x=element_blank())

  outfname <- sprintf( "%s/PanelRari-all-%d.png", dirname, i)
  ggsave( outfname, device = png(), width = length(restrictedGenomes2) * xWidth + 2 * deltaWidth, height = yHeight, units = "cm", dpi = 300)
  dev.off()
  totPrinted <- totPrinted + 1


  # grafico delle distanze di euclide x tutti i genomi
  for( gen in sortedGenomes) {
    df <- switch(as.character(i),
                 "1" = filter(tgtDF, Genome == gen, Measure == "Euclidean" & Theta <= 0.3),
                 "2" = filter(tgtDF, Genome == gen, Measure == "Euclidean" & Theta > 0.3),
                 "3" = filter(tgtDF, Genome == gen, Measure == "Euclidean")
    )

    df$Genome <- factor(df$Genome, levels = sortedGenomes)

    sp1 <- ggplot(data=df, aes(x=Theta, y=distance)) +
      geom_line(aes(color = k)) +
      geom_point() +
      facet_grid( rows = vars(k), cols = vars( Genome), labeller = labeller( k = label_both), scales = "free_y") +
      # scale_y_continuous(name = "Distance") +
      theme_bw() + theme( panel.spacing = unit(0.2, "lines"),
                             legend.position = "none",
                             strip.text.x = element_text( size = 8, angle = 0),
                             axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                             axis.title.x = element_blank(),
                             axis.title.y = element_blank(),
                             axis.text.y = element_blank(),
                             strip.text.y = if (gen == "PiceaAbies") element_text( size = 8, angle = -90) else element_blank())

    outfname <- sprintf( "%s/PanelDistancesEuclidean-%s-%d.png", dirname, gen, i)
    ggsave( outfname, device = png(), width = xWidth * length(sortedGenomes) + deltaWidth, height = yHeight, units = "cm", dpi = 300)
    dev.off()
    totPrinted <- totPrinted + 1
  }
}

cat(sprintf("Plotting Experiment with Real Genomes. %d plot printed\n", totPrinted))
