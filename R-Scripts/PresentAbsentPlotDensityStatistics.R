library(DescTools)
library(dplyr)
library(ggplot2)
library(hrbrthemes)



###### DESCRIPTION

# compute Power Statistics and T1 error from raw data produced by PresenAbsent3.py script
# in CSV format


###### OPTIONS

# Sets the path of the directory containing the output of FADE
setwd("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent")

bs <- "uniform"

similarities = c('D2')

# Defines the name of the file containing a copy of the dataframe created by this script
# dfFilename <- "PresentAbsent-Power+T1.RDS"
# csvFilename <- 'PresentAbsentData-all.csv'
# nullModel <- 'Uniform'

dfFilename <- sprintf( "%s,32/PresentAbsentEC-Power+T1-%s,32.RDS", bs, bs)
dirname <- sprintf("%s,32/PlotDensity", bs)
if (!dir.exists(dirname)) {
  dir.create(dirname)
}


nullModel <- 'Uniform'
# nullModel <- 'ShuffledEColi'
T1Model <- paste( sep='', nullModel, '-T1')

###### CODE

# 'data.frame':	15120 obs. of  13 variables:
# $ Measure  : chr  "Anderberg" "Anderberg" "Anderberg" "Anderberg" ...
# $ Model    : Factor w/ 2 levels "MotifRepl-U",..: 1 2 1 2 1 2 1 2 1 2 ...
# $ len      : num  1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 ...
# $ gamma    : num  0.01 0.01 0.01 0.01 0.01 0.01 0.05 0.05 0.05 0.05 ...
# $ k        : num  4 4 4 4 4 4 4 4 4 4 ...
# $ alpha    : num  0.01 0.01 0.05 0.05 0.1 0.1 0.01 0.01 0.05 0.05 ...
# $ threshold: num  0.337 0.337 0.411 0.411 0.461 ...
# $ power    : num  0 0.018 0.028 0.113 0.168 0.199 0 0.216 0.069 0.473 ...
# $ T1       : num  0.006 0.006 0.039 0.039 0.097 0.097 0.006 0.006 0.039 0.039 ...
# $ nmDensity: num  0.96 0.96 0.96 0.96 0.96 ...
# $ nmSD     : num  0.0129 0.0129 0.0129 0.0129 0.0129 ...
# $ amDensity: num  0.912 0.96 0.912 0.96 0.912 ...
# $ amSD     : num  0.0289 0.013 0.0289 0.013 0.0289 ...


df <-readRDS( file = dfFilename)
cat(sprintf("Dataset %s loaded. (%d rows).\n", dfFilename, nrow(df)))

# escludiamo le misure: euclidean norm, anderberg, gowel , phi e yule. 15120 -> 10800 observations
df <- filter( df, Measure != "Anderberg" & Measure != "Gower" & Measure != "Phi" & Measure != "Yule" &
  Measure != "Euclid_norm" & Measure != "Mash.Distance.1000." & Measure != "Mash.Distance.100000.")

cat(sprintf("Filtered measures: Anderberg, Gower, Phi, Yule, Euclid_norm, Mash.Distance.1000, Mash.Distance.100000. (%d rows).\n",nrow(df)))

df$Model = factor(df$Model)
df$kv = factor(df$k)
df$len = factor(df$len)
df$class = "unkmown"

kValues = levels(factor(df$k))
lengths = levels(factor(df$len))
measures <- levels(factor(df$Measure))
altModels = levels(df$Model)[1:2]
classes <- c("scarso", "saturo", "resto")

# fissati alpha, gamma e Model (variabili indipendenti)
dfScarsi = filter( df, nmDensity <= 0.05 & gamma == 0.05 & Model == "MotifRepl-U")
dfSaturi = filter( df, nmDensity >= 0.95 & gamma == 0.05 & Model == "MotifRepl-U")
dfResto =  filter( df, nmDensity > 0.05 & nmDensity < 0.95 & gamma == 0.05 & Model == "MotifRepl-U")

nmdf <- data.frame(lengths)
for( kk in kValues ) {
  l <- c()
  for( ll in lengths) {
    tdf <- filter( df, k == kk & len == ll & Measure == "Jaccard" & alpha == 0.05 & gamma == 0.05 & Model == "MotifRepl-U")
    l <- append(l, tdf$nmDensity)
  }
  nmdf[kk] <- l
}

for(i in 1:nrow(df)) {
  t <- df[i, 'nmDensity']
  if (t < 0.03)      { lbl <- classes[1]}
  else if (t > 0.97) { lbl <- classes[2]}
  else               { lbl <- classes[3]}
  df[i, 'class'] <- lbl
}

write.csv(nmdf, "density-k-len.csv", row.names=FALSE)

for( ss in classes) {

  dfv <- filter( df, class == ss & gamma == 0.05 & Model == "MotifRepl-U")
  cat(sprintf("Dataset %s -> %d rows.\n", ss, nrow(dfv)))

  # plot scarsi divisi in 3 alpha altrimenti illegibile
  for( a in c(0.01, 0.05, 0.10)) {
    df1 = filter( dfv, alpha == a)
    sp1 <- ggplot( df1, aes(x = Measure, y = T1, fill = kv)) +
      geom_bar( position = "dodge", stat = "identity") +
      facet_grid( cols = vars(alpha), rows = vars(len)) +
      # facet_grid_sc(rows = vars( gamma), scales = 'free') +
      # scale_x_continuous(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
      #                   labels=c("", "1e+4", "", "1e+6", ""), limits = c(1000, 10000000), trans='log10') +
      # scale_y_continuous(name = "A/N") +
      theme_light() + theme(strip.text.x = element_text( size = 8, angle = 70),
                            axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                            panel.spacing=unit(0.1, "lines")) +
      labs(y = sprintf("T1 results (A/N %s)", ss)) +
      # scale_x_continuous(trans='log10') +
      guides(colour = guide_legend(override.aes = list(size=1)))
    # ggtitle( am)

      # dev.new(width = 6, height = 6)
      # print(sp1)
      outfname <- sprintf( "%s/PanelT1-%s-A=%.2f.pdf", dirname, ss, a)
      ggsave( outfname, device = pdf(), width = 9, height = 6, units = "in", dpi = 300)
      # dev.off() #only 129kb in size


    sp2 <- ggplot( df1, aes(x = Measure, y = power, fill = kv)) +
      geom_bar( position = "dodge", stat = "identity") +
      facet_grid( cols = vars(alpha), rows = vars(len)) +
      # facet_grid_sc(rows = vars( gamma), scales = 'free') +
      # scale_x_continuous(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
      #                   labels=c("", "1e+4", "", "1e+6", ""), limits = c(1000, 10000000), trans='log10') +
      # scale_y_continuous(name = "A/N") +
      theme_light() + theme(strip.text.x = element_text( size = 8, angle = 70),
                            axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                            panel.spacing=unit(0.1, "lines")) +
      labs(y = sprintf("Power results (A/N %s)", ss)) +
      # scale_x_continuous(trans='log10') +
      guides(colour = guide_legend(override.aes = list(size=1)))
    # ggtitle( am)

    # dev.new(width = 6, height = 6)
    # print(sp1)
    outfname <- sprintf( "%s/PanelPower-%s-A=%.2f.pdf", dirname, ss, a)
    ggsave( outfname, device = pdf(), width = 9, height = 6, units = "in", dpi = 300)
    # dev.off() #only 129kb in size
  }
}

# dfv = filter( df, Measure == "Jaccard" & Model == "MotifRepl-U" & gamma == 0.05 & alpha == 0.05)
#
# sp1 <- ggplot( dfv, aes(x = len, y = kv, fill = nmDensity)) +
#   geom_tile() +
#   # scale_fill_gradient(low="white", high="blue") +
#   # scale_fill_distiller(palette = "RdPu") +
#   labs(title = "A/N Density(k, len)", x = "len", y = "K")
#   # theme_ipsum()
# # dev.new(width = 9, height = 6)
# # print(sp2)
# # stop("break")
# outfname <- sprintf( "%s/Heatmap Density.pdf", dirname)
# ggsave( outfname, device = pdf(), width = 9, height = 6, units = "in", dpi = 300)
# # dev.off() #only 129kb in size
cat(sprintf("%d plot printed", 3))