library(rjson)
library(ggplot2)
library(stringr)
library(dplyr)
library(RColorBrewer)
library(facetscales)



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
csvFilename <- 'PresentAbsentData-all.csv'

# Sets the output path for the images to be generated

dirname <- "PlotAN"
if (!dir.exists(dirname)) {
  dir.create(dirname)
}

###### CODE

scales_y <- list(
  '0.01' = scale_y_continuous(limits = c(0, 1e-10)),
  '0.05' = scale_y_continuous(limits = c(0, 136)),
  '0.10' = scale_y_continuous(limits = c(0, 136)))

if (!file.exists(dfFilename)) {
  # converte il file CSV in datafgrame
  columnClasses = c( "character", "numeric", "integer", "integer", "integer",
                   "numeric", "numeric", "numeric", "numeric", "numeric",
                   "numeric", "numeric", "numeric", "numeric", "numeric",
                   "numeric", "numeric", "numeric", "numeric", "numeric",
                   "numeric", "numeric", "numeric", "numeric", "numeric",
                   "numeric", "numeric", "numeric", "character", "numeric",
                   "numeric", "numeric", "numeric", "numeric")
  dati <-read.csv(file = csvFilename, colClasses = columnClasses)
  dati$model = factor(dati$model)
  # dati$gamma = factor(dati$gamma)
  # dati$k = factor(dati$k)


  ll = levels(factor(dati$gamma))
  gValues = as.double(ll[2:length(ll)])
  kValues = as.integer(levels(factor(dati$k)))
  lengths = as.integer(levels(factor(dati$seqLen)))
  col <- colnames(dati)
  measures <- c(col[11:26], col[28])

  saveRDS(dati, file = dfFilename)
  cat(sprintf("Dataset %s %d rows saved.", dfFilename, nrow(dati)))

} else {
  # carica il dataframe esistente
  dati <- readRDS(file = dfFilename)
}

###### CODE
altModels = levels(dati$model)[1:2]

alphaValues <- c( 0.01, 0.05, 0.10)

# carica il dataframe dal file
dati$kf = factor(dati$k)
dati$lf = factor(dati$seqLen)

for (kvf in levels(factor(dati$k))) {
    kv = as.integer( kvf)
	# solo per alpha = 0.10
    NM <- filter(dati, dati$k == kv & dati$model == 'Uniform') # tutte le misure per uno specifico AM e valore di alpha
    dff <- filter(dati, dati$k == kv & dati$model != 'Uniform-T1' & dati$model != 'Uniform') # tutte le misure per uno specifico AM e valore di alpha

    NM$gamma <- 0.01
    dff <- rbind( dff, NM)
    NM$gamma <- 0.05
    dff <- rbind( dff, NM)
    NM$gamma <- 0.10
    dff <- rbind( dff, NM)

    dff$model <- factor(dff$model, levels = c('Uniform', 'MotifRepl-U', 'PatTransf-U'))

    cat(nrow(dff))

    sp <- ggplot( dff, aes(x = lf, y = A/N, alpha=0.8)) +
          geom_boxplot( aes( color = model), alpha = 0.7, outlier.size = 0.3) +
          # facet_grid(rows = vars(gamma)) +
          facet_grid_sc(rows = vars( gamma), scales = 'free') +
          # scale_x_continuous(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
          #                   labels=c("", "1e+4", "", "1e+6", ""), limits = c(1000, 10000000), trans='log10') +
          scale_y_continuous(name = "A/N") +
          theme_light() + theme(strip.text.x = element_text( size = 8, angle = 70),
                       axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                       panel.spacing=unit(0.1, "lines")) +
          guides(colour = guide_legend(override.aes = list(size=3)))
          # ggtitle( am)
    
	# dev.new(width = 9, height = 6)
	# print(sp)
	# stop("break")
	outfname <- sprintf( "%s/PanelAN-k=%d.pdf", dirname, kv)
	ggsave( outfname, device = pdf(), width = 9, height = 6, units = "in", dpi = 300)
	dev.off() #only 129kb in size
}
