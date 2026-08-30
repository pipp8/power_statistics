library(DescTools)
library(dplyr)
library(ggplot2)
library(hrbrthemes)
library(r2r)
library(stringr)


###### DESCRIPTION

# Plot experiment results for real genome sequences compared against one real sequence (Home Sapiens)


###### OPTIONS
###### CODE

bs <- "uniform"
wd <- sprintf("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent/%s,32", bs)
setwd(wd)

dirname <- "ReportRealSequences"

similarities <- c('D2')
dfFilename <- sprintf("%s/realDistanceAll.RDS", dirname )
csvFilename <- sprintf("%s/%s", dirname, "RealSequencesPairs.csv")

genomesDF <- data.frame(
  genome =     c("Chimpanzee", "Bonobo",	"Gorilla",	"Orangutan",	"MacacaMulatta",	"GrayMouseLemur",	"SootyMangabey",	"Pig", "HouseMouse",	"Gallus"),
  divergence = c( 0.0120,       0.0130,    	0.0160,      0.0310,          0.0646,       	    0.0900,             0.0920,	         0.1063,  0.1500,        0.2500),
  mya =	       c( 5.40,	        6.00,	    9.00,   	 14.00,    	      25.00,    	        60.00,  	        10.50,	         88.00,	  75.00,	     320.00)
)

similarities <- c('D2')
# misure di riferimento
PAMeasures <- c("Antidice", "Dice", "Jaccard", "Kulczynski", "Ochiai", "Russel",
                "Hamman", "Hamming", "Matching", "Sneath", "Tanimoto") # solo alcune misure Present/Absent senza le count based
pltMeasures <- c("D2", "Euclidean", "Antidice", "Dice", "Jaccard", "Kulczynski", "Ochiai", "Russel",
                 "Hamman", "Hamming", "Matching", "Sneath", "Tanimoto")
mainMeasures <- c("Jaccard", "Russel", "Hamman")
countMeasures <- c("D2", "Euclidean")

xWidth <- 2.5 # larghezza di una singola colonna del pannello
yHeight <- 12 # altezza di tutti i grafici
deltaWidth <- 0.8 # incremento width x misura per eventuali y-axis header


# Defines the name of the file containing a copy of the dataframe created by this script
#  Yeast, CElegans, HomoSapiens, Schistosoma, Lemur, MacacaMulatta, PiceaAbies
# genomes <- c( "Yeast", "CElegans", "HomoSapiens", "Schistosoma", "Lemur", "MacacaMulatta", "PiceaAbies")
genomes <- c( "Yeast", "CElegans", "HomoSapiens", "PiceaAbies")
sortedGenomes <- c("Yeast", "CElegans", "HomoSapiens", "PiceaAbies")
sortedGenomes <- genomesDF[[1]]
restrictedGenomes <- c("HomoSapiens")
restrictedGenomes2<- c("Yeast", "CElegans", "HomoSapiens")
restrictedGenomes3 <- c("Yeast", "CElegans")


tgtDF <- data.frame( Genome = character(), Measure = character(), Theta = integer(), k = integer(),
                     A = numeric(), B = numeric(), C = numeric(), D = numeric(), N = numeric(), density = numeric(),
                     distance=double(), stringsAsFactors=FALSE)



nObs <- 200 # Thetat x k
nRowXObs <- length(pltMeasures)
dfSize <- nObs * nRowXObs

if (!dir.exists(dirname)) {
  dir.create(dirname)
}

if (!file.exists(dfFilename)) {
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

  tgtDF <- data.frame( ReferenceGenome = character(), Genome = character(),
                       Measure = character(), Theta = integer(), k = integer(),
                       A = numeric(), B = numeric(), C = numeric(), D = numeric(), N = numeric(), density = numeric(),
                       distance=double(), stringsAsFactors=FALSE)

  # data.frame':	612 obs. of  12 variables:
 # $ ReferenceGenome: chr  "HomoSapiens" "HomoSapiens" "HomoSapiens" "HomoSapiens" ...
 # $ Genome         : chr  "Bonobo" "Bonobo" "Bonobo" "Bonobo" ...
 # $ Measure        : chr  "Anderberg" "Antidice" "Dice" "Gower" ...
 # $ Theta          : num  0 0 0 0 0 0 0 0 0 0 ...
 # $ k              : int  4 4 4 4 4 4 4 4 4 4 ...
 # $ A              : num  256 256 256 256 256 256 256 256 256 256 ...
 # $ B              : num  0 0 0 0 0 0 0 0 0 0 ...
 # $ C              : num  0 0 0 0 0 0 0 0 0 0 ...
 # $ D              : num  0 0 0 0 0 0 0 0 0 0 ...
 # $ N              : num  256 256 256 256 256 256 256 256 256 256 ...
 # $ density        : num  1 1 1 1 1 1 1 1 1 1 ...
 # $ distance       : num  1 0 0 1 0 ...

  # calcola la trasposta ... un rigo per ogni misura
  for(i in 1:nrow(df)) {
    r <- df[i,]
    for(m in measures) {
      MesName <- if (m == "Mash.Distance.10000.") "Mash" else m
      nr <- c( r[1:2], MesName, r[5:12], df[i, m])
      tgtDF[nrow(tgtDF)+1,] <- nr
    }
  }

  # escludiamo le misure: euclidean norm, anderberg, gowel , phi e yule. 864 -> 672 observations
  # tgtDF <- filter(tgtDF, Measure %in% pltMeasures)

  # nessun filtro 864 -> 864
  # tgtDF <- filter( tgtDF, Measure != "Euclid_norm" & Measure != "Mash.Distance.1000." & Measure != "Mash.Distance.100000.")

  # cat(sprintf("Filtered measures: Anderberg, Gower, Phi, Yule, EuclideanZ, Mash.Distance.1000, Mash.Distance.10000, Mash.Distance.100000. (%d rows).\n",nrow(tgtDF)))

  tgtDF$k <- factor(tgtDF$k)
  # tgtDF$Theta = factor(tgtDF$Theta)

  kValues <- levels(tgtDF$k)
  measures <- levels(factor(tgtDF$Measure))

  # cat(sprintf("Data Frame %s filtered (%d observations).\n", sequenceName, nrow(tgtDF) - cnt * dfSize))
  # tgtDF$Theta = factor(tgtDF$Theta)

  if (nrow(tgtDF) != nrow(df) * length(measures))   {
    stop("errore nel calcolo di df_total per il calcolo delle distanze relative")
  }
  # salva il df finale
  saveRDS( tgtDF, dfFilename)
  cat(sprintf("Dataset %s %d rows saved.\n", dfFilename, nrow(tgtDF)))

} else {
  # i due dataframe già esistono N.B. cancellare per ricolacolare i valori
  tgtDF <-readRDS( file = dfFilename)
  cat(sprintf("Dataset %s loaded. (%d rows).\n", dfFilename, nrow(tgtDF)))
}


# ordina i genomi per distanza crescente
tgtDF$Genome <- factor(tgtDF$Genome, levels = sortedGenomes)
tgtDF$Measure <- factor(tgtDF$Measure)
tgtDF$k <-factor(tgtDF$k,levels(factor(tgtDF$k)))

totPrinted <- 0

# filter(tgtDF, Genome %in% restrictedGenomes3 & Measure %in% PAMeasures & Theta <= 0.3 & (k == 12 | k == 16))
df <- filter(tgtDF, Measure %in% mainMeasures)

#  grafico distanze per le principali misure Present/Absent (Genome sull'asse delle x)
sp1 <- ggplot(df, aes(x = Genome, y = distance, group = 1)) +
  geom_line(data = genomesDF, aes(x = genome, y = divergence), color = "gray") +
  geom_line(aes(color = k)) +
  geom_point(size = 0.8) +
  facet_grid( rows = vars(k), cols = vars(Measure), labeller = labeller( k = label_both)) + #, scales = "free_y"
  scale_y_continuous(limits = c(0, 1), labels=c("0", "0.5", "1"), breaks = c(0, 0.5, 1)) +
  theme_bw() + theme( panel.spacing=unit(0.1, "lines"),
                      strip.text.x = element_text( size = 8, angle = 0),
                      legend.position = "none",
                      # axis.text.y = element_blank(),
                      axis.title.y = element_blank(),
                      axis.text.x = element_text( size = rel( 0.5), angle = 60, hjust=1),
                      axis.title.x = element_blank())

# dev.new(width = 6, height = 6)
# print(sp1)
outfname <- sprintf( "%s/PanelMainPAMeasures.png", dirname)
ggsave( outfname, device = png(), width = length(mainMeasures) * xWidth + deltaWidth, height = yHeight, units = "cm", dpi = 300)

totPrinted <- totPrinted + 1

# ---------------------------------------------------------------

df <- filter(tgtDF, Measure %in% PAMeasures)

sp1 <- ggplot(df, aes(x = Genome, y = distance, group = 2))+
  geom_line(aes(color = k)) +
  geom_point(size = 0.8) +
  facet_grid( rows = vars(k), cols = vars(Measure), labeller = labeller( k = label_both)) + #, scales = "free_y"
  scale_y_continuous(limits = c(0, 1), labels=c("0", "0.5", "1"), breaks = c(0, 0.5, 1)) +
  theme_bw() + theme(panel.spacing=unit(0.1, "lines"),
                     strip.text.x = element_text( size = 8, angle = 0),
                     legend.position = "none",
                     # axis.text.y = element_blank(),
                     axis.title.y = element_blank(),
                     axis.text.x = element_text( size = rel( 0.5), angle = 60, hjust=1),
                     axis.title.x = element_blank())

# dev.new(width = 6, height = 6)
# print(sp1)
outfname <- sprintf( "%s/PanelAllPAMeasures.png", dirname)
ggsave( outfname, device = png(), width = length(PAMeasures) * xWidth + deltaWidth, height = yHeight, units = "cm", dpi = 300)
dev.off() # only 129kb in size
totPrinted <- totPrinted + 1

# ----------------------------------------------------------

for (seq in countMeasures) {

  df <- filter(tgtDF, Measure == seq)

  sp1 <- ggplot(df, aes(x = Genome, y = distance, group = 1)) +
    geom_line(aes(color = k)) +
    geom_point(size = 0.8) +
    facet_grid( rows = vars(k), cols = vars(Measure), labeller = labeller( k = label_both), scales = "free_y") +
    # scale_y_continuous(limits = c(0, 1), labels=c("0", "0.5", "1"), breaks = c(0, 0.5, 1)) +
    theme_bw() + theme(panel.spacing=unit(0.1, "lines"),
                       strip.text.x = element_text( size = 8, angle = 0),
                       legend.position = "none",
                       # axis.text.y = element_blank(),
                       axis.title.y = element_blank(),
                       axis.text.x = element_text( size = rel( 0.5), angle = 60, hjust=1),
                       axis.title.x = element_blank())

  #  dev.new(width = 6, height = 6)
  # print(sp1)
  outfname <- sprintf( "%s/Panel%s.png", dirname, seq)
  ggsave( outfname, device = png(), width = length(mainMeasures) * xWidth + deltaWidth, height = yHeight, units = "cm", dpi = 300)
  dev.off() # only 129kb in size
  totPrinted <- totPrinted + 1
}


cat(sprintf("CV plot Done. %d plot printed\n", totPrinted))
