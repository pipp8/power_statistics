library(plyr)
library(tidyr)
library(dplyr)


###### DESCRIPTION

# Produces an heatmap of the delta values obtained as the difference between the average
# of the distribution of AF values computed with NM and one of AM and PT,
# for different combinations of n, k and gamma.
# The output is a PNG image with name clustering.png

# Note: this script must be executed after RawDistances-CSV2RDS

###### OPTIONS

# Sets the path of the directory containing the input dataframe
setwd("~/Universita/Src/IdeaProjects/power_statistics/data/results/dataset5-1000")


# Sets the name of the file containing the input dataframe

dfFilename <- "AFMeasureDistances-All.df"


###### CODE


dati<-readRDS(dfFilename)

allMeasures <- levels(dati$Measure)

similarityMeasures <- c('d2', 'd2s', 'd2star', 'd2z', 'harmonicmean', 'intersection', 'jaccard', 'kulczynski2')

##### CARICO I TIPI DI AF 
tipo<-read.csv("Measures.csv",sep=";",header = FALSE)
segno<-rep(1,nrow(tipo))
segno[tipo$V2=="Similarity"]<- -1
tipo<-data.frame(tipo,segno)
row.names(tipo)<-tipo[,1]

# segno <- c()
# for(m in allMeasures) {
#   segno <- c(segno, if (m %in% similarityMeasures) -1 else 1)
# }
# tipo<-data.frame(allMeasures, segno)

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
  # sel sono tutti gli AM per i vari gamma e target e' il NM
  # in caso di distanza dovrebbe decrescere quindi target - sel
  # in caso di similarità dovrebbe crescere quindi (target - sel) * -1
  l<-apply(sel,1,function(e) ((target-e)*tipo$segno)/target)
  df[[i]] <- ldply(l, data.frame)
}


df.fin <- ldply(df, data.frame)
row.names(df.fin)<-df.fin[,1]
df.fin<-df.fin[,-1]


#SCALO E NORMALIZZO PER FINI GRAFICI 


df.color<-df.fin
df.color<-scale(df.color, center = FALSE)
#df.color<-df.color-min(df.color)
#df.color[df.color>3]<-3
#pheatmap::pheatmap(df.color)

l<-strsplit(row.names(df.color),split = "\\.")
ann<-ldply(l,data.frame)
n<-rep(c(1:5),length(l))
n2<-rep(1:48,each=5)
ann<-data.frame(n,n2,ann)
ann<-pivot_wider(ann,names_from = n,values_from = X..i..)
colnames(ann)<-c("tmp","Model","tmp","Gamma","k","length")
ann<-ann[,c(2,4:6)]
ann$k<-as.numeric(ann$k)
ann$length<-as.numeric(ann$length)
ann<-data.frame(ann)
ann$Gamma<-as.numeric(ann$Gamma)/1000
row.names(ann)<-row.names(df.color)
df.color<-df.color[order(ann$Model,ann$length,ann$k),]
library(RColorBrewer)
pheatmap::pheatmap(df.color,cluster_rows = FALSE,
                   annotation_names_row=TRUE,annotation_row=ann,
                   show_rownames = FALSE,gaps_row = 24,
                   color = colorRampPalette(rev(brewer.pal(n = 7, name =
                                                             "RdYlBu")))(1000)
                  )

flag<-grepl("MR",row.names(df.color),fixed = TRUE)
pheatmap::pheatmap(df.color[flag,],cluster_rows = FALSE,annotation_names_row=TRUE,annotation_row=ann,show_rownames = FALSE)
flag<-grepl("PT",row.names(df.color),fixed = TRUE)
pheatmap::pheatmap(annotation_row = ann,df.color[flag,],cluster_rows = FALSE,annotation_names_row=TRUE,annotation_row=ann,show_rownames = FALSE)

