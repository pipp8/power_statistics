library(DescTools)
library(dplyr)
library(ggplot2)





###### DESCRIPTION

# compute Power Statistics and T1 error from raw data produced by PresenAbsent3.py script
# in CSV format


###### OPTIONS

# Sets the path of the directory containing the output of FADE
setwd("~/Universita/Src/IdeaProjects/power_statistics/data/PresentAbsent")

bs <- 1

similarities = c('D2')

# Defines the name of the file containing a copy of the dataframe created by this script
# dfFilename <- "PresentAbsent-Power+T1.RDS"
# csvFilename <- 'PresentAbsentData-all.csv'
# nullModel <- 'Uniform'

dfFilename <- sprintf( "%d,32/PresentAbsentEC-Power+T1-%d,32.RDS", bs, bs)
dirname <- sprintf("%d,32/PlotDensity", bs)

# nullModel <- 'Uniform'
nullModel <- 'ShuffledEColi'
T1Model <- paste( sep='', nullModel, '-T1')

###### CODE


# dataframe structure:
#  Measure = character(),  Model = character(), len = numeric(), gamma = double(),
#  k = numeric(), alpha=double(), threshold = double(),
#  power = double(), T1 = double(),
#  nmAverage = double(), nmStdDev = double(), amAverage = double(), amStdDev = double(), stringsAsFactors=FALSE)
# 'data.frame':	15120 obs. of  13 variables:
# $ Measure  : chr  "Anderberg" "Anderberg" "Anderberg" "Anderberg" ...
# $ Model    : Factor w/ 2 levels "MotifRepl-Sh",..: 1 2 1 2 1 2 1 2 1 2 ...
# $ len      : num  1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 ...
# $ gamma    : num  0.01 0.01 0.01 0.01 0.01 0.01 0.05 0.05 0.05 0.05 ...
# $ k        : num  4 4 4 4 4 4 4 4 4 4 ...
# $ alpha    : num  0.01 0.01 0.05 0.05 0.1 0.1 0.01 0.01 0.05 0.05 ...
# $ threshold: num  0.337 0.337 0.416 0.416 0.444 ...
# $ power    : num  0.003 0.022 0.035 0.133 0.105 0.237 0.001 0.225 0.076 0.51 ...
# $ T1       : num  0.007 0.007 0.055 0.055 0.107 0.107 0.007 0.007 0.055 0.055 ...
# $ nmAverage: num  0.958 0.958 0.958 0.958 0.958 ...
# $ nmStdDev : num  0.013 0.013 0.013 0.013 0.013 ...
# $ amAverage: num  0.912 0.959 0.912 0.959 0.912 ...
# $ amStdDev : num  0.0288 0.0128 0.0288 0.0128 0.0288 ...

df <-readRDS( file = dfFilename)

df$Model = factor(df$Model)

kValues = as.integer(levels(factor(df$k)))
lengths = as.integer(levels(factor(df$len)))
measures <- levels(factor(df$Measure))
altModels = levels(df$Model)[1:2]

cat(sprintf("Dataset %s loaded. (%d rows).", dfFilename, nrow(df)))

fd = filter( df, df$Measure == "Jaccard" & df$alpha == 0.05 & df$gamma == 0.05)

sp1 <- ggplot( fd, aes(x = len, y = nmDensity)) +
  geom_line( ) + geom_point() +
  facet_grid( cols = vars(k)) +
  # facet_grid_sc(rows = vars( gamma), scales = 'free') +
  # scale_x_continuous(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
  #                   labels=c("", "1e+4", "", "1e+6", ""), limits = c(1000, 10000000), trans='log10') +
  # scale_y_continuous(name = "A/N") +
  theme_light() + theme(strip.text.x = element_text( size = 8, angle = 70),
                        axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                        panel.spacing=unit(0.1, "lines")) +
  labs(y = "NM Average Density Teta (A/N)") +
  scale_x_continuous(trans='log10') +
  guides(colour = guide_legend(override.aes = list(size=1)))
# ggtitle( am)

# dev.new(width = 6, height = 6)
# print(sp1)
outfname <- sprintf( "%s/PanelAvgNM.pdf", dirname)
ggsave( outfname, device = pdf(), width = 9, height = 6, units = "in", dpi = 300)
# dev.off() #only 129kb in size

sp2 <- ggplot( fd, aes(x = len, y = amDensity, colour = Model)) +
  geom_line() + geom_point() +
  facet_grid(rows = vars(Model), cols = vars(k)) +
  # facet_grid_sc(rows = vars( gamma), scales = 'free') +
  # scale_x_continuous(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
  #                   labels=c("", "1e+4", "", "1e+6", ""), limits = c(1000, 10000000), trans='log10') +
  # scale_y_continuous(name = "A/N") +
  theme_light() + theme(strip.text.x = element_text( size = 8, angle = 70),
                        axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                        panel.spacing=unit(0.1, "lines")) +
  labs(y = "AMs Average Density Teta (A/N)") +
  scale_x_continuous(trans='log10') +
  guides(colour = guide_legend(override.aes = list(size=1)))

# dev.new(width = 9, height = 6)
# print(sp2)
# stop("break")
outfname <- sprintf( "%s/PanelAvgAM.pdf", dirname)
ggsave( outfname, device = pdf(), width = 9, height = 6, units = "in", dpi = 300)
# dev.off() #only 129kb in size

fd2 = filter( df, df$Measure == "Jaccard" & df$alpha == 0.05 )
fd2$gamma = factor(fd2$gamma)

sp3 <- ggplot( fd2, aes(x = len, y = threshold, colour = gamma)) +
  geom_line() + geom_point() +
  facet_grid(rows = vars(Model), cols = vars(k)) +
  # facet_grid_sc(rows = vars( gamma), scales = 'free') +
  # scale_x_continuous(name = NULL, breaks=c(1000, 10000, 100000, 1000000, 10000000),
  #                   labels=c("", "1e+4", "", "1e+6", ""), limits = c(1000, 10000000), trans='log10') +
  # scale_y_continuous(name = "A/N") +
  theme_light() + theme(strip.text.x = element_text( size = 8, angle = 70),
                        axis.text.x = element_text( size = rel( 0.7), angle = 45, hjust=1),
                        panel.spacing=unit(0.1, "lines")) +
  labs(y = "Threshold values (gamma)") +
  scale_x_continuous(trans='log10') +
  guides(colour = guide_legend(override.aes = list(size=1)))

# dev.new(width = 9, height = 6)
# print(sp2)
# stop("break")
outfname <- sprintf( "%s/PanelThreshold.pdf", dirname)
ggsave( outfname, device = pdf(), width = 9, height = 6, units = "in", dpi = 300)
# dev.off() #only 129kb in size
cat(sprintf("%d plot printed", 3))