library(plyr)
library(tidyr)
library(dplyr)
library(RColorBrewer)
library(pheatmap)


setwd("~/Universita/Src/IdeaProjects/power_statistics/data/results/dataset5-1000")

dati<-readRDS("RawDistances-All.RDS")

# filter only 2 length and results for T1
dati <- filter(dati, Model != "T1" & (len == 200000 | len == 5000000))

dati$k <- factor(dati$k)
dati$len <- factor(dati$len)

allMeasures <- levels(dati$Measure)

tipo <- data.frame( "name" = c("canberra", "chebyshev", "d2", "d2z", "chisquare","d2s", "d2star",
                                "euclidean","harmonicmean", "intersection", "jeffrey",
                                "jensenshannon", "manhattan", "kulczynski2", "squaredchord"),
                     "type" = c("Distance", "Distance", "Similarity", "Similarity", "Distance", "Similarity", "Similarity",
                                "Distance", "Similarity", "Similarity", "Distance",
                                "Distance", "Distance", "Similarity", "Distance"))

##### CARICO I TIPI DI AF 
# tipo<-read.csv("Measures.csv",sep=";",header = FALSE)
sign <- rep(1,nrow(tipo))
sign[tipo$type == "Similarity"] <- -1
tipo <- data.frame(tipo,sign)
row.names(tipo) <- tipo[,1]


#creo tutte le classi sulle quali calcolare la media
p<-dati
n<-paste(p$Measure,p$Model,p$k,p$len,sep = ".")

n2<-rep(1:1000,840)
p<-cbind(p,n2=n2)

pp<- p %>% pivot_wider(names_from = Measure, values_from = Distance)
n<-paste(pp$Model,pp$k,pp$len,sep = ".")

pp2<-data.frame(names=n,pp[,5:ncol(pp)])


#COLLASSO PER MEDIA

pp3<-pp2  %>%
  group_by(names) %>%
  dplyr::summarise(canberra=mean(canberra),
                   chebyshev=mean(chebyshev),
                   d2=mean(d2),
                   d2z=mean(d2z),
                   chisquare=mean(chisquare),
                   d2s=mean(d2s),
                   d2star=mean(d2star),
                   euclidean=mean(euclidean),
                   harmonicmean=mean(harmonicmean),
                   intersection=mean(intersection),
                   jeffrey=mean(jeffrey),
                   jensenshannon=mean(jensenshannon),
                   manhattan=mean(manhattan),
                   kulczynski2=mean(kulczynski2),
                   squaredchord=mean(squaredchord)
  )
pp3<-data.frame(pp3)
row.names(pp3)<-pp3$names
pp3<-pp3[,-1]
pp3<-data.frame(pp3)


#COLLASSO PER COEFFICIENTE DI VARIAZIONE
pp3sd<-pp2  %>%
  group_by(names) %>%
  dplyr::summarise(canberra=var(canberra)/mean(canberra),
                   chebyshev=var(chebyshev)/mean(chebyshev),
                   d2=var(d2)/mean(d2),
                   d2z=var(d2z)/mean(d2z),
                   chisquare=var(chisquare)/mean(chisquare),
                   d2s=var(d2s)/mean(d2s),
                   d2star=var(d2star)/mean(d2star),
                   euclidean=var(euclidean)/mean(euclidean),
                   harmonicmean=var(harmonicmean)/mean(harmonicmean),
                   intersection=var(intersection)/mean(intersection),
                   jeffrey=var(jeffrey)/mean(jeffrey),
                   jensenshannon=var(jensenshannon)/mean(jensenshannon),
                   manhattan=var(manhattan)/mean(manhattan),
                   kulczynski2=var(kulczynski2)/mean(kulczynski2),
                   squaredchord=var(squaredchord)/mean(squaredchord)
  )

#CALCOLO PER OGNI MODELLO LA DIFF TRA AM E NM 

tipo<-tipo[colnames(pp3),]
NM<-row.names(pp3)[grepl("NM.",row.names(pp3))]
df<-list()
for(i in NM){
  flag<-grepl(substr(i,4,11),row.names(pp3),fixed = TRUE)
  sel<-pp3[flag,]
  target<-sel[i,]
  sel<-sel[-which(row.names(sel)%in%i),]
  
  #IL PUNTO E' QUESTO
  
  l<-apply(sel,1,function(e) (tipo$sign*(target-e))/target)
  df[[i]] <- ldply(l, data.frame)
}


df.fin <- ldply(df, data.frame)
row.names(df.fin)<-df.fin[,1]
df.fin<-df.fin[,-1]


#SCALO E NORMALIZZO PER FINI GRAFICI 
df.color<-df.fin
#df.color<-scale(df.color, center = FALSE)
#df.color<-df.color-min(df.color)
df.color[df.color>0.4]<-0.4
df.color[df.color< -0.4]<- -0.4
#pheatmap::pheatmap(df.color)

l<-strsplit(row.names(df.color),split = "\\.")
ann<-ldply(l,data.frame)
n<-rep(c(1:5), length(l))
n2<-rep(1:48,each=5)
ann<-data.frame(n,n2,ann)
ann<-pivot_wider(ann,names_from = n,values_from = X..i..)
colnames(ann)<-c("tmp","Model","tmp","Gamma","k","Length")
ann<-ann[,c(2,4:6)]
ann$k<-as.numeric(ann$k)
ann$Length<-as.numeric(ann$Length)
ann<-data.frame(ann)
ann$Gamma<-as.numeric(ann$Gamma)/1000
row.names(ann)<-row.names(df.color)
df.color<-df.color[order(ann$Model,ann$Length,ann$k),]

x1 <- pheatmap(df.color,cluster_rows = FALSE, annotation_names_row = TRUE, annotation_row = ann,
                   show_rownames = FALSE, gaps_row = seq(3, nrow(df.color), by = 3),
                   fontsize = 15, angle_col = 45,
                   color = colorRampPalette(rev(brewer.pal(n = 7, name = "RdYlBu")))(1000), scale = "none")

filename<-'heatmap-clustering.png'
png(filename, width = 1600, height=900)
grid::grid.newpage()
grid::grid.draw(x1$gtable)
dev.off()

flag<-grepl("MR|PT",row.names(df.color))
x2 <- pheatmap(df.color[flag,], cluster_rows = FALSE, annotation_names_row = TRUE,
                    annotation_row=ann, show_rownames = FALSE,
                    fontsize = 15, angle_col = 90)

filename<-'heatmap-clustering2.png'
png(filename, width = 1600, height=900)
grid::grid.newpage()
grid::grid.draw(x2$gtable)
dev.off()
