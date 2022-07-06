library(ggplot2)
library(dplyr)




setwd("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent")

# Sets the name of the file containing the input dataframe
dfFilename1 <- "PresentAbsent-RawData.RDS"
nullModel1 <- 'Uniform'
T1Model1 <- paste( sep='', nullModel1, '-T1')


dfFilename2 <- "PresentAbsentEC-RawData.RDS"
nullModel2 <- 'ShuffledEColi'
T1Model2 <- paste( sep='', nullModel2, '-T1')

dati1 <- readRDS(file = dfFilename1)
dati2 <- readRDS(file = dfFilename2)

altModels1 = levels(dati1$model)[1:2]
altModels2 = levels(dati2$model)[1:2]

alphaValues <- c( 0.01, 0.05, 0.10)

for (kv in 1:8 * 4) {
  # solo per alpha = 0.10
  NM1 <- filter(dati1, dati1$k == kv & dati1$model == nullModel1) # tutte le misure per lo specifico NM del vecchio generative model

  NM2 <- filter(dati2, dati2$k == kv & dati2$model == nullModel2) # tutte le misure per lo specifico NM del nuovo generative model

  AM1 <- filter(dati2, dati2$k == kv & dati2$model == altModels2[1]) # tutte le misure per uno specifico AM1
  AM2 <- filter(dati2, dati2$k == kv & dati2$model == altModels2[2]) # tutte le misure per uno specifico AM2
  
  # NM$gamma <- 0.01
  # dff <- rbind( dff, NM)
  # NM$gamma <- 0.05
  # dff <- rbind( dff, NM)
  # NM$gamma <- 0.10
  # dff <- rbind( dff, NM)
  
  # md = levels(dff$model)

    
  cat(sprintf("NullModel = %12.12s, k = %2d, rows = %d, min = %.3f, max = %.3f, mean = %.5f\n",
              nullModel1, kv, nrow(NM1), min(NM1$Jaccard), max(NM1$Jaccard), mean(NM1$Jaccard)))
  cat(sprintf("NullModel = %12.12s, k = %2d, rows = %d, min = %.3f, max = %.3f, mean = %.5f\n",
              nullModel2, kv, nrow(NM2), min(NM2$Jaccard), max(NM2$Jaccard), mean(NM2$Jaccard)))
  # Alternative model 1
  g = 0.01
  dff <- filter( AM1, AM1$gamma == g) # tutte le misure per uno specifico AM e valore di alpha
  cat(sprintf("AltModel  = %12.12s, k = %2d, rows = %d, min = %.3f, max = %.3f, mean = %.5f, gamma = %.2f\n",
              altModels2[1], kv, nrow(dff), min(dff$Jaccard), max(dff$Jaccard), mean(dff$Jaccard), g))

  g = 0.05
  dff <- filter( AM1, AM1$gamma == g) # tutte le misure per uno specifico AM e valore di alpha
  cat(sprintf("AltModel  = %12.12s, k = %2d, rows = %d, min = %.3f, max = %.3f, mean = %.5f, gamma = %.2f\n",
              altModels2[1], kv, nrow(dff), min(dff$Jaccard), max(dff$Jaccard), mean(dff$Jaccard), g))
  g = 0.1
  dff <- filter( AM1, AM1$gamma == g) # tutte le misure per uno specifico AM e valore di alpha
  cat(sprintf("AltModel  = %12.12s, k = %2d, rows = %d, min = %.3f, max = %.3f, mean = %.5f, gamma = %.2f\n\n",
              altModels2[1], kv, nrow(dff), min(dff$Jaccard), max(dff$Jaccard), mean(dff$Jaccard), g))

  # Alternative model 2
  g = 0.01
  dff <- filter( AM2, AM2$gamma == g) # tutte le misure per uno specifico AM e valore di alpha
  cat(sprintf("AltModel  = %12.12s, k = %2d, rows = %d, min = %.3f, max = %.3f, mean = %.5f, gamma = %.2f\n",
              altModels2[2], kv, nrow(dff), min(dff$Jaccard), max(dff$Jaccard), mean(dff$Jaccard), g))
  
  g = 0.05
  dff <- filter( AM2, AM2$gamma == g) # tutte le misure per uno specifico AM e valore di alpha
  cat(sprintf("AltModel  = %12.12s, k = %2d, rows = %d, min = %.3f, max = %.3f, mean = %.5f, gamma = %.2f\n",
              altModels2[2], kv, nrow(dff), min(dff$Jaccard), max(dff$Jaccard), mean(dff$Jaccard), g))
  g = 0.1
  dff <- filter( AM2, AM2$gamma == g) # tutte le misure per uno specifico AM e valore di alpha
  cat(sprintf("AltModel  = %12.12s, k = %2d, rows = %d, min = %.3f, max = %.3f, mean = %.5f, gamma = %.2f\n\n",
              altModels2[2], kv, nrow(dff), min(dff$Jaccard), max(dff$Jaccard), mean(dff$Jaccard), g))
}
