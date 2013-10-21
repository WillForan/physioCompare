library(plyr)
library(reshape2)
library(ggplot2)
signficiance <- 2.58
# for suma stuffs:
# node.connections.orig <- read.table('txt/nodecounts-ageeffAgeXphys-invage-sigcluster-unbalenced-colorbyclusterID_widthageXphysio.tval-p1.txt')
# names(node.connections.orig) <- .(roinum,numcon,x,y,z)
# using brainnetview output
node.connections.orig <- read.table('txt/brainview/nodes-264_all-withsize.node')
#0	0	0		0.000000	0.000000	none
names(node.connections.orig) <- .(x,y,z,numcon,numcon2,label)
node.connections.orig$roinum <- 1:nrow(node.connections.orig)

node.connections.orig<-node.connections.orig[rev(order(node.connections.orig$numcon)),]
# remove low numbers
#node.connections <- subset(node.connections.orig, numcon>=5)

roi.lables<-read.table('txt/labels_bb244_coordinate',sep="\t")
names(roi.lables) <- c('num','x','y','z','atlas','r','name','prob','segnum')

ageeff.ageXphys.orig <- read.csv('txt/ageeffAgeXphys-invage.csv')
ageeff.ageXphys <- subset(ageeff.ageXphys.orig, abs(ageXphysio.tval)>signficiance )

ageeff.highlyconn <- subset(ageeff.ageXphys,ROI1%in%node.connections$roinum|ROI2 %in% node.connections$roinum,c('ROI1','ROI2','ageXphysio.val','ageXphysio.tval','rtitle'))

ageeff.highlyconn <- reshape(ageeff.highlyconn, direction = "long", varying = c('ROI1','ROI2'), sep = "")
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

ageeff.highlyconn$ROIname <- gsub(' +',' ',as.character(sapply(ageeff.highlyconn$ROI, function(x){ 
   roiidx<-which(roi.lables$num==x)
   roinum<-as.character(x)
   count <- "0"
   if(roinum %in% names(hubs) ) {
   count<- hubs[[roinum]][2] 
   }
   aname<-gsub(' +',' ',as.character(roi.lables$name[roiidx] ))
   if(aname=='unknown'){
    aname<-do.call(sprintf,as.list(c("(%s %s %s)",roi.lables[roiidx,c('x','y','z')])))
   }
   else {
    aname<-do.call(sprintf,as.list(c("%s: %s (%s %s %s)", count,aname,roi.lables[roiidx,c('x','y','z')])))
   }
   as.character(aname)
   })))

#ageeff.highlyconn$ROI<-as.factor(ageeff.highlyconn$ROI)
# %in% node.connections$roinum[1:10] vs %in% names(hubs)
top12 <- subset(ageeff.highlyconn,ROI %in% names(hubs)[1:12] )
# order by count
top12$ROIname <- factor(top12$ROIname, levels=sort(unique(top12$ROIname),decreasing=T) )

toptenhist <- ggplot(top12,aes(x=ageXphysio.val,fill=ROIname))+geom_histogram(stat="bin")+theme_bw()+scale_fill_brewer(type='qual',palette=3) +
              theme(plot.background  = element_rect(fill="transparent",color=NA),
                    panel.background = element_rect(fill="transparent",color=NA),
                    legend.background= element_rect(fill="transparent",color=NA),
                    panel.grid.minor = element_blank(),
                    panel.grid.major = element_blank()
                    ) + ylab(" ") + xlab(" ")
ggsave(toptenhist, file='imgs/highlyconnected-histogram.svg',width=15,bg="transparent")

## FOR BRAINVIEWER
# this is ugly hack on list above :)
bvnodes       <-as.data.frame(t(data.frame(hubs[1:12])))
names(bvnodes)<-.(label,totalconnect,totalnotinabove,ratio,xyz)
bvnodes$ROI   <- gsub('X','',rownames(bvnodes) )
bvnodes[,c('x','y','z')] <- t(as.data.frame(strsplit(as.character(bvnodes$xyz),' ')))
bvnodes$community <- 1:nrow(bvnodes)
bvnodes$label <- gsub('[ _]','',bvnodes$label)
write.table(bvnodes[,c('x','y','z','community','totalconnect','label')],'txt/brainview/nodes-topnodesonly.node',row.names=F,sep="\t", quote=F,col.names=F)
# from matlab
# BrainNet_MapCfg('txt/brainview/nodes-topnodesonly.node','/home/foranw/src/pkg/brainNetViewer/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv','txt/brainview/topnodeModule.mat','imgs/wholebrain/onlytopnodes.png')
