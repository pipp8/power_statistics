library(rjson)
library(ggplot2)
library(stringr)
library(dplyr)
library(RColorBrewer)




###### DESCRIPTION

# Produces two panels reporting the power trend, respectively for the PT and MR alternative models.
# In each panel, for each AF and gamma is reported the power level obtained across different
# values of n. It is also colored according to the value of k.
# The output is a set PNG images with name PanelPowerAnalysis-<AM>-A=0.10.png
# where <AM> reflects the alternative model being considered

# Note: this script must be executed after Power+T1-Json2RDS.R


###### OPTIONS

# Sets the path of the directory containing the input dataframe

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent")

# Sets the name of the file containing the input dataframe
dfFilename <- "PresentAbsent-RawData.RDS"
csvFilename <- 'PresentAbsentECData.csv'
# nullModel <- 'ShuffledEColi'
nullModel <- 'Uniform'
T1Model <- paste( sep='', nullModel, '-T1')

# Sets the output path for the images to be generated

setwd("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent")

bs <- "uniform"

# Sets the name of the file containing the input dataframe
dfFilename <- sprintf( "%s,32/%s", bs, dfFilename)

# Sets the output path for the images to be generated
dirname <- sprintf("%s,32/T1+Power-Plots", bs)

if (!dir.exists(dirname)) {
  dir.create(dirname)
}

###### CODE

# misure di riferimento
l1 <- c("D2")
# misure analizzate
l2 <- c("Antidice", "Dice", "Jaccard", "Kulczynski", "Ochiai", "Russel")
# misure dominate da A e D (B e C diventano irrilevanti)
l3 <- c("Hamman", "Hamming", "Matching", "Sneath", "Tanimoto")
# misure escluse dal calcolo
l4 <- c("Anderberg", "Gower", "Yule", "Mash.distance.1000.", "Mash.distance.10000.", "Mash.distance.100000.", "Euclidean")

# riordina la lista delle misure
sortedMeasures = c(l1, l2, l3)
#measureNanesDF <- data.frame( ref = l1, g1 = l2, alt = l3, no = l4, stringsAsFactors = FALSE)


scales_y <- list(
  '0.01' = scale_y_continuous(limits = c(0, 1e-10)),
  '0.05' = scale_y_continuous(limits = c(0, 136)),
  '0.10' = scale_y_continuous(limits = c(0, 136)))

if (!file.exists(dfFilename)) {
  # converte il file CSV in dataframe
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

} else {
  # carica il dataframe esistente
  dati <- readRDS(file = dfFilename)
}

###### CODE
altModels = levels(dati$model)[1:2]

alphaValues <- c( 0.01, 0.05, 0.10)

dati$kf = factor(dati$k)
dati$lf = factor(dati$seqLen)

NM <- filter(dati, dati$model == nullModel) # tutte le misure per uno specifico AM e valore di alpha
dff <- filter(dati, dati$model != T1Model & dati$model != nullModel) # tutte le misure per uno specifico AM e valore di alpha

NM$gamma <- 0.01
dff <- rbind( dff, NM)
NM$gamma <- 0.05
dff <- rbind( dff, NM)
NM$gamma <- 0.10
dff <- rbind( dff, NM)

md = levels(dff$model)
dff$model <- factor(dff$model, levels = c( md[3], md[1], md[2])) # riordina le labels
dff$k = factor(dff$k)
dff$AD = (dff$A+dff$D) / dff$N

# crea un nuovo dataframe per 3 misure

nmDist <- data.frame( seqLen = numeric(), pairId = numeric(), k = numeric(), distance = double(),
                      model = character(), Measure = character(), stringsAsFactors=FALSE)

pltMeasures = c("D2", "Jaccard", "Hamman")

# solo per gamma = 0
tt <- filter(dati, dati$model == nullModel & dati$gamma == 0 ) # tutte le misure per il solo NM  
for (mes in pltMeasures) { # per tutte le misure previste
  df1 = data.frame( tt$seqLen, tt$pairId, tt$k, tt[[mes]])
  colnames(df1)[1] = "seqLen"
  colnames(df1)[2] = "pairId"
  colnames(df1)[3] = "k"
  colnames(df1)[4] = "distance"
  
  df1$model = nullModel
  df1$Measure = mes
  
  nmDist = rbind(nmDist, df1)
}

nmDist$lf = factor(nmDist$seqLen)
nmDist$k = factor(nmDist$k)


sp <- ggplot( dff, aes(x = lf, y = A/N, alpha=0.8)) +
      geom_boxplot( aes( color = model), alpha = 0.7, outlier.size = 0.3) +
      facet_grid(cols = vars(gamma), rows = vars(k)) +
      # facet_grid_sc(rows = vars( gamma), scales = 'free') +
      scale_y_continuous(name = "A/N") +
      scale_x_discrete(name = NULL, #breaks=c(1000, 10000, 100000, 1000000, 10000000),
                            labels=c("10E3", "10E4", "10E5", "10E6", "10E7")) +
      # scale_x_log10(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
      #          labels=c("10E3", "10E4", "10E5", "10E6", "10E7"), limits = c(1000, 10000000)) +
      theme_light() + theme(strip.text.x = element_text( size = 8),
                            axis.text.x = element_text( size = rel( 0.8)),
                            axis.text.y = element_text( size = rel( 0.8)),
                            panel.spacing=unit(0.1, "lines")) +
      guides(colour = guide_legend(override.aes = list(size=1)))
      # ggtitle( am)

# dev.new(width = 9, height = 6)
# print(sp)
outfname <- sprintf( "%s/PanelAN.pdf", dirname)
ggsave( outfname, device = pdf(), width = 9, height = 6, units = "in", dpi = 300)
dev.off() #only 129kb in size

NM$k = factor(NM$k)

# boxplot A/N solo per il null model
sp <- ggplot( NM, aes(x = lf, y = A/N, alpha=0.8)) +
  geom_boxplot( aes( color = k), alpha = 0.7, outlier.size = 0.3, width=0.4) +
  facet_grid(rows = vars(k)) +
  scale_y_continuous(name = "Null Model A/N values") +
  scale_x_discrete(name = NULL, #breaks=c(1000, 10000, 100000, 1000000, 10000000),
                   labels=c("10E3", "10E4", "10E5", "10E6", "10E7")) +
  # scale_x_log10(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
  #          labels=c("10E3", "10E4", "10E5", "10E6", "10E7"), limits = c(1000, 10000000)) +
  theme_light() + theme(strip.text.x = element_text( size = 8),
                        axis.text.x = element_text( size = rel( 0.8)),
                        axis.text.y = element_text( size = rel( 0.8)),
                        panel.spacing=unit(0.1, "lines")) +
  guides(colour = guide_legend(override.aes = list(size=1)))
# ggtitle( am)

# dev.new(width = 9, height = 6)
# print(sp)
outfname <- sprintf( "%s/PanelANNM.pdf", dirname)
ggsave( outfname, device = pdf(), width = 6, height = 6, units = "in", dpi = 300)
dev.off() #only 129kb in size

# boxplot solo per il null model (A+D)/N
sp <- ggplot( NM, aes(x = lf, y = (A+D)/N, alpha=0.8)) +
  geom_boxplot( aes( color = k), alpha = 0.7, outlier.size = 0.3, width=0.4) +
  facet_grid(rows = vars(k)) +
  scale_y_continuous(name = "Null Model (A+D)/N values") +
  scale_x_discrete(name = NULL, #breaks=c(1000, 10000, 100000, 1000000, 10000000),
                   labels=c("10E3", "10E4", "10E5", "10E6", "10E7")) +
  # scale_x_log10(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
  #          labels=c("10E3", "10E4", "10E5", "10E6", "10E7"), limits = c(1000, 10000000)) +
  theme_light() + theme(strip.text.x = element_text( size = 8),
                        axis.text.x = element_text( size = rel( 0.8)),
                        axis.text.y = element_text( size = rel( 0.8)),
                        panel.spacing=unit(0.1, "lines")) +
  guides(colour = guide_legend(override.aes = list(size=1)))
# ggtitle( am)

# dev.new(width = 9, height = 6)
# print(sp)
outfname <- sprintf( "%s/PanelADNM.pdf", dirname)
ggsave( outfname, device = pdf(), width = 6, height = 6, units = "in", dpi = 300)
dev.off() #only 129kb in size

tt <- filter(nmDist, nmDist$Measure != "D2") # tutte le misure Present / Absent 

# boxplot con le distanze per il null model
sp <- ggplot( tt, aes(x = lf, y = distance, alpha=0.8)) +
  geom_boxplot( aes( color = k), alpha = 0.7, outlier.size = 0.3, width=0.4) +
  facet_grid(cols = vars(Measure), rows = vars(k)) +
  scale_y_continuous(name = "Null Model Distance values") +
  scale_x_discrete(name = NULL, #breaks=c(1000, 10000, 100000, 1000000, 10000000),
                   labels=c("10E3", "10E4", "10E5", "10E6", "10E7")) +
  # scale_x_log10(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
  #          labels=c("10E3", "10E4", "10E5", "10E6", "10E7"), limits = c(1000, 10000000)) +
  theme_light() + theme(strip.text.x = element_text( size = 8),
                        axis.text.x = element_text( size = rel( 0.8)),
                        axis.text.y = element_text( size = rel( 0.8)),
                        axis.title.y = element_blank(),
                        panel.spacing=unit(0.1, "lines")) +
  guides(colour = guide_legend(override.aes = list(size=1)))
# ggtitle( am)

# dev.new(width = 9, height = 6)
# print(sp)
outfname <- sprintf( "%s/PanelAllDistancesNM.pdf", dirname)
ggsave( outfname, device = pdf(), width = 6, height = 6, units = "in", dpi = 300)
dev.off() #only 129kb in size

tt <- filter(nmDist, nmDist$Measure == "D2") # solo la misura D2 

# boxplot con le distanze per il null model
sp <- ggplot( tt, aes(x = lf, y = distance, alpha=0.8)) +
  geom_boxplot( aes( color = k), alpha = 0.7, outlier.size = 0.3, width=0.4) +
  facet_grid(cols = vars(Measure), rows = vars(k), scales = "free_y") +
  scale_y_continuous(name = "Null Model Distance values") +
  scale_x_discrete(name = NULL, #breaks=c(1000, 10000, 100000, 1000000, 10000000),
                   labels=c("10E3", "10E4", "10E5", "10E6", "10E7")) +
  # scale_x_log10(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
  #          labels=c("10E3", "10E4", "10E5", "10E6", "10E7"), limits = c(1000, 10000000)) +
  theme_light() + theme(strip.text.x = element_text( size = 8),
                        axis.text.x = element_text( size = rel( 0.8)),
                        axis.text.y = element_text( size = rel( 0.8)),
                        legend.position = "none",  
                        panel.spacing=unit(0.1, "lines")) +
  guides(colour = guide_legend(override.aes = list(size=1)))
# ggtitle( am)

# dev.new(width = 9, height = 6)
# print(sp)
outfname <- sprintf( "%s/PanelD2DistancesNM.pdf", dirname)
ggsave( outfname, device = pdf(), width = 3, height = 6, units = "in", dpi = 300)
dev.off() #only 129kb in size

