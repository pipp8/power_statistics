library(DescTools)
library(ggplot2)
library(facetscales)
library(dplyr)

setwd("/Users/pipp8/Universita/Src/IdeaProjects/PowerStatistics/data/results/dataset5-1000")

# produce un pannello con 6 boxplot (3 x 2) le colonne sono i 2 AM le righe i valori di gamma, 
# i boxplot per ciascun grafico riportano i valori della power statistics per ogni misura ed ogni valore di K

sortedMeasures <- c('chebyshev', 'euclidean', 'manhattan',
                    'chisquare',
                    'canberra',
                    'd2', 'd2s', 'd2star', 'd2z',
                    'intersection', 'kulczynski2',
                    'harmonicmean', 'squaredchord',
                    'jeffrey', 'jensenshannon')


plot_labeller <- function(variable,value){
  if (variable=='gamma') {
    # N.B. len e' un factor
    return(sprintf("G = %.2f", value))
  } else {
    return(as.character(value))
  }
}

AMs <- c("MotifReplace", "PatternTransfer")
alphaValues = c("010", "050", "100")

kValues = c(4, 6, 8, 10)

dirname <- "PowerBoxPlot"
if (!dir.exists(dirname)) {
  dir.create(dirname)
}

seqLengths <- 50 # 200.000 - 10.000.0000 step 200.000 # numero di risultati per ciascun plot

gammaValues = c(0.01, 0.05, 0.10)
nGamma <- length(gammaValues) # cambiare in 3
nK <- length(kValues)
nCol <- 6
nCol2 <- 6
colors <- rainbow(nK + 1)

dfFilename = sprintf("AllData.RDS")

if (file.exists(dfFilename)) {
  cat( sprintf("Data file exists. Loading %s\n", dfFilename))			
  # carica il dataframe dal file
  dati <- readRDS(file = dfFilename)
} else {
  
  for(alpha in alphaValues) {
    
    dati <- data.frame() # risultato finale
    
    for (am in AMs) {
      
      jsonDir <- sprintf( "json-%s", alpha)
      files <- list.files(jsonDir, sprintf("*%s*", am))
      print( sprintf("Processing %d files from: %s/%s", length(files), getwd(), jsonDir))
      
      tblMeasures <- c()
      ndx = 1
      md = if (am == 'MotifReplace') 'MR' else 'PT'
      
      for (file in files) {
        
        if (grepl( "jaccard|mash", file, ignore.case = TRUE)) {
          cat(sprintf("skipping file: %s\n", file))
          next
        }
        
        cat( sprintf("Processing: %s, Alpha: 0.%s ... ", file, alpha))
        
        exp <- fromJSON(file = paste(jsonDir, file, sep="/"))
        values <-exp[['values']]
        
        df <- lapply( values, function( p) { data.frame(matrix(unlist(p), ncol=nCol, byrow=T))})
        df <- do.call(rbind, df)
        colnames(df)[1:nCol] <- c("len", "alpha", "k", "power", "T1", "gamma")
        
        measureName <- gsub( "[dD]istance", "", exp$header$distanceName)
        tblMeasures[ndx] = measureName
        
        # aggiunge una colonna con il nome della misura in ogni riga
        df$measure = measureName
        # ed una colonna con l'Alternate Model esteso
        df$model = am
        # ed una colonna con l'Alternate Model x alpha
        df$mds = sprintf("%s.G=%.3f", md, df$alpha[1])
        
        dati <- rbind(dati, df)
        
        ndx <- ndx + 1
        cat("done.\n")
      } # for each file
    } # foreach AM
  } # foreach alpha
  dati$measure <- factor(dati$measure, levels = sortedMeasures)
  dati$model <- factor(dati$model)
  dati$mds <- factor(dati$mds)
  dati$k <- factor( dati$k, levels = c( 4, 6, 8, 10))
  # dati$gamma = factor( dati$gamma, levels = c( "G = 0.01", "G = 0.05", "G = 0.10"))
  saveRDS( dati, file = dfFilename)
}



# solo per alpha = 0.10
dff <- filter(dati, dati$alpha == 0.10) # tutte le misure per uno specifico valore di alpha

levels(dff$model)[levels(dff$model)=="MotifReplace"] <- "Motif Replace"
levels(dff$model)[levels(dff$model)=="PatternTransfer"] <- "Pattern Transfer"

sp <- ggplot(dff, aes(x = measure, y = power, fill = k, alpha = 0.7)) + 
  geom_boxplot( aes( color = k), alpha = 0.7, outlier.size = 0.3) +
  facet_grid(rows = vars(gamma), cols = vars(model), labeller = plot_labeller) +
  theme_bw() + theme(axis.title.x = element_blank(), 
                     axis.text.x = element_text( size = rel(0.8), angle = 45, hjust = 1))

# sp <- ggplot( dff, aes( x = len, y = power, fill = k, alpha=0.8)) +
#   geom_point( aes( color = k), alpha = 0.8, size = 0.08) +
#   scale_x_continuous(name = NULL, breaks=c(200000, 2500000, 5000000, 7500000, 10000000),
#                      labels=c("", "2.5e+6", "", "7.5e+6", ""), limits = c(200000, 10000000)) +
#   scale_y_continuous(name = "Power", limits = c(0, 1)) +
#   facet_grid( rows = vars( gamma), cols = vars( measure),  labeller = plot_labeller) +
#   theme_bw() + theme(strip.text.x = element_text( size = 8, angle = 70),
#                      axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
#                      panel.spacing=unit(0.1, "lines")) +
#   guides(colour = guide_legend(override.aes = list(size=3)))
# ggtitle( am)

dev.new(width = 9, height = 6)
# rint(sp)
outfname <- sprintf( "%s/PanelBoxplotPowerAllMeasures-A=%.2f.png", dirname, dati$alpha[1])
ggsave( outfname, device = png(), width = 9, height = 6, units = "in", dpi = 300)
# dev.off() #only 129kb in size
