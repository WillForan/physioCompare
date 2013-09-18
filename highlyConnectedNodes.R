library(plyr)
library(reshape2)
library(ggplot2)
node.connections.orig <- read.table('txt/nodecounts-ageeffAgeXphys-invage-sigcluster-unbalenced-colorbyclusterID_widthageXphysio.tval-p1.txt')
names(node.connections.orig) <- .(roinum,numcon,x,y,z)
node.connections.orig<-node.connections.orig[rev(order(node.connections.orig$numcon)),]
node.connections <- subset(node.connections.orig, numcon>=5)

roi.lables<-read.table('txt/labels_bb244_coordinate',sep="\t")
names(roi.lables) <- c('num','x','y','z','atlas','r','name','prob','segnum')

ageeff.ageXphys.orig <- read.csv('txt/ageeffAgeXphys-invage.csv')
ageeff.ageXphys <- subset(ageeff.ageXphys.orig, abs(ageXphysio.tval)>2.58)

ageeff.highlyconn <- subset(ageeff.ageXphys,ROI1%in%node.connections$roinum|ROI2 %in% node.connections$roinum,c('ROI1','ROI2','ageXphysio.val','ageXphysio.tval','rtitle'))

ageeff.highlyconn <- reshape(ageeff.highlyconn, direction = "long", varying = c('ROI1','ROI2'), sep = "")
ageeff.highlyconn$ROIname <- gsub(' ?','',as.character(sapply(ageeff.highlyconn$ROI, function(x){ 
   roiidx<-which(roi.lables$num==x)
   xyz <- paste(collapse=" ",sep=" ",roi.lables[roiidx,c('x','y','z')]);
    
   aname<-gsub(' ?','',as.character(roi.lables$name[roiidx] ))
   if(aname=='unknown'){
    aname<-paste(sep="_",collapse="_",roi.lables[roiidx,c('x','y','z')] )
   }
   else {
    aname<-paste(sep="_",aname,xyz)
   }
   as.character(aname)
   })))

## find where half the connections are already explained
ageeff <- ageeff.ageXphys
hubs<-list()
for(i in 1:nrow(node.connections.orig)) {roi=node.connections.orig[i,'roinum']
 numcon=node.connections.orig[i,'numcon']
 osize=nrow(ageeff)
 ageeff<-subset(ageeff,ROI1!=roi&ROI2!=roi)
 nsize=nrow(ageeff)
 idx <- which(roi.lables$num==roi)
 xyz= paste(collapse=" ",sep=" ",roi.lables[idx,c('x','y','z')]);
 name= paste(sep="_",gsub(' ?','',as.character(roi.lables$name[idx])),xyz)
 if((osize-nsize)/numcon<.5 || numcon<5){ next }
 cat(i,roi,numcon,osize-nsize,nrow(ageeff),"\n")
 hubs[[as.character(roi)]] <- c(name,numcon,osize-nsize,(osize-nsize)/numcon, xyz)
}

#ageeff.highlyconn$ROI<-as.factor(ageeff.highlyconn$ROI)
# %in% node.connections$roinum[1:10] vs %in% names(hubs)
toptenhist <- ggplot(subset(ageeff.highlyconn,ROI %in% names(hubs)[1:12] ),aes(x=ageXphysio.val,fill=ROIname))+geom_histogram(stat="bin")+theme_bw()+scale_fill_brewer(type='qual',palette='Spectral')
ggsave(toptenhist, file='imgs/highlyconnected-histogram.svg')
