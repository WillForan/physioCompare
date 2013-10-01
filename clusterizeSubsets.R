library(mclust)
library(lme4)

# load model values
ageeff.ageXphys.orig <- read.csv('txt/ageeffAgeXphys-invage.csv')

# t>2.580 is approx p=.01 (see 03_comp_perROIROI.R)
ageeff.ageXphys <- subset(ageeff.ageXphys.orig, abs(ageXphysio.tval)>2.596)
#ageeff.ageXphys.orig[21618,1:11]
#    X ROI1 ROI2 intercept intcpt.tval pipe.slope pipe.tval age.slope  age.tval ageXphysio.val ageXphysio.tval
#21618  130  233  0.270628    11.09827 0.03981486  3.188247  1.661884 0.9453313       2.33790          2.59676

#summary(roirois.lm[[21618]]$invAge)
#   Linear mixed model fit by REML
#   Formula: value ~ 1 + Pipeline * AgeInverseCentered + (1 | ID)
#   Fixed effects:
#                                     Estimate Std. Error t value
#   (Intercept)                        0.27063    0.02438  11.098
#   Pipelinephysio                     0.03981    0.01249   3.188
#   AgeInverseCentered                 1.66188    1.75799   0.945
#   Pipelinephysio:AgeInverseCentered  2.33790    0.90031   2.597
# 

# grab only the bits to cluster on
#coeffsToCluster <- ageeff.ageXphys[,c('pipe.slope','ageXphysio.val')]
coeffsToCluster <- ageeff.ageXphys[,c('age.slope','ageXphysio.val')]
plot(coeffsToCluster)

## clusterize
clusters     <- mclustBIC(coeffsToCluster)
clustsummary <- summary(clusters,coeffsToCluster)
clusterIDs   <- apply(clustsummary$z,1,which.max)
ageeff.ageXphys$clusterID <- clusterIDs
write.csv(ageeff.ageXphys, file="txt/ageeffAgeXphys-invage-sigcluster.csv")

## see it
plot(clusters,legendArgs=list(x="bottomleft",horiz=TRUE ,cex=0.75))
svg('imgs/clusterplot')
mclust2Dplot(coeffsToCluster, classification=clustsummary$classification, parameterse=clustsummary$parameters)


mcM<-mclustModel(coeffsToCluster,clusters)
clustmean <- mcM$parameters$mean
clustmean <- as.data.frame( rbind('nophysio'=clustmean[1,],'physio'=apply(clustmean,2,sum) ) )
names(clustmean) <- gsub('^V','Cluster ',names(clustmean))
ages=10:20
d <- foreach(slope = rownames(clustmean), .combine=rbind) %do% {
 foreach(cluster = names(clustmean),.combine=rbind) %do%
    data.frame(
         age=ages,
         Correlation=sapply(ages, function(x){1/15 + 1/x * clustmean[slope,cluster]}),
         cluster=cluster,
         slope=slope) 
}
clusterSlopes<-ggplot(d,aes(x=age,y=Correlation,color=slope))+geom_line()+facet_grid(cluster~.)+theme_bw()
ggsave(clusterSlopes,file='imgs/cluster-slopes.svg')
# load the top 1% of the model
#load('Rdata/bests.Rdata') # bests.lm.order
#ageeff.ageXphys <- ageeff.ageXphys.orig[,]
