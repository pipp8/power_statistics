library(ggplot2)
library(facetscales)

setwd("/Users/pipp8/Universita/Src/IdeaProjects/power_statistics/data/results/Kolmogorov")

dfFilename <- 'AllKolmogorov.df'
ris <- readRDS(file = dfFilename)

# redefinisce l'ordine delle colonne della griglia
ris$len <- factor(ris$len,levels=c("200,000","2,000,000"))


# modifica i fattori di scala per ciascuna riga del pannello
# N.B. l'etichetta del pannello deve essere alfanumerica non numerica
scales_y <- list(
    '4' = scale_y_continuous(limits = c(0, 0.15)),
    '6' = scale_y_continuous(limits = c(0, 0.05)),
    '8' = scale_y_continuous(limits = c(0, 0.01)),  
    '10' = scale_y_continuous(limits = c(0, 0.003)))

sp <- ggplot( ris, aes(x = Name,y = D, fill = Name, alpha=0.7)) + 
 	geom_boxplot( aes(color = Name), outlier.size = 0.3) +
 	facet_grid_sc(rows = vars( K), cols = vars( len), scales = list( y = scales_y)) +
 	theme_bw()+ theme( axis.text.x = element_text(size = 8, angle = 45, hjust =1)) +
 	theme(legend.position = "none") + labs(y = "KS", x ="")
 	# ggtitle("Pannello risultati test di Kolmogorv-Smirnov") + labs(y= "D Value")


print( sp)
outfname <- 'AllKolmogorov.png'
ggsave( outfname, device = png(), dpi = 300)