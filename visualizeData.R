library(ggplot2)
library(plyr)
library(lme4)
library(gridExtra)
source('lmerCellMeans.R')

# read in ROI names
roi.lables<-read.table('txt/labels_bb244_coordinate',sep="\t")
names(roi.lables) <- c('num','x','y','z','atlas','r','name','prob','segnum')

if(! file.exists('imgs')) { dir.create('imgs') }

### SUBJ INFO
# subject info, like
# 10152	female	19930510	20100514	17.0106278777989
subjectInfo <- read.table('txt/IDSexDOBVisitAge.txt')
names(subjectInfo) <- c('ID','sex','DOB','ScanDate','age')
# break down by group
subjectInfo$group <- ifelse(subjectInfo$age<14,'Child','Teen')
subjectInfo$group[subjectInfo$age>=18]<-'Adult'
subjectInfo$group <- as.factor(subjectInfo$group)
#TODO relevel
ddply(subjectInfo,.(group),summary)

##### BIG LIST
# read in giant table of cor for each ROIROI for each person for each pipeline
roirois.long <- read.csv('txt/ROIROIcorAgeSubjPipe.csv')
names(roirois.long) <- c('ROI1','ROI2','value','Age','Pipeline','ID')
roirois.long$ID   <-  as.factor(roirois.long$ID )
roirois.long$ROI1 <-  as.factor(roirois.long$ROI1 )
roirois.long$ROI2 <-  as.factor(roirois.long$ROI2 )
roirois.long$Pipeline <-  as.factor(roirois.long$Pipeline )
roirois.long$AgeInverseCentered <- 1/(roirois.long$Age) -  mean(1/(roirois.long$Age),na.rm=T  )
roirois.long$AgeCentered <- roirois.long$Age -  mean(roirois.long$Age,na.rm=T  )
# by group
roirois.long$group <- ifelse(roirois.long$Age<14,'Child','Teen')
roirois.long$group[roirois.long$Age>=18]<-'Adult'
roirois.long$group <- as.factor(roirois.long$group)

#group avg
coravg <- aggregate(value ~ ROI1+ROI2+Pipeline+group,roirois.long, mean,na.rm=T)

mats.plot <- ggplot(coravg,aes(x=ROI1,y=ROI2,fill=value))+theme_bw()+
  geom_tile() + 
  scale_fill_gradient2(low = "blue", mid="white", high = "red", limits=c(-1,1))+
  facet_grid(Pipeline~group)

ggsave(file='imgs/groupCorMats.svg',mats.plot)

# density plot
rrdiff.density <- ggplot(coravg,aes(x=value,fill=Pipeline),alpha=I(.5))+geom_density()+facet_wrap(~group) + theme_bw()+ggtitle('value of all roi-roi correlations')
ggsave(file='imgs/group-roiroi-density.svg',rrdiff.density)


coravg.wide = reshape(coravg,idvar=c('ROI1', 'ROI2','group'),timevar='Pipeline',direction='wide')
coravg.wide$value.diff <-  coravg.wide$value.physio - coravg.wide$value.nophysio 

rrdiff.plot <- ggplot(coravg.wide,aes(x=value.nophysio,y=value.physio,color=group)) 
rrdiff.plot.together <- rrdiff.plot + geom_point(alpha=I(.2))+theme_bw()+geom_abline(intercept=0,slop=1)
rrdiff.plot.facet   <- rrdiff.plot.together+facet_wrap(~group)
#ggsave(file="group-roiroi-diff.png",rrdiff.plot)
svg("imgs/group-roiroi-diff.svg")
print(grid.arrange(rrdiff.plot.together,rrdiff.plot.facet) )
dev.off()
#coravg.wide$roi1 <- roi.labels[



################## general subj plots
# histogram: age
summary(subjectInfo$age)
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#   10.11   13.05   15.63   15.45   18.33   20.33
hist.age <- ggplot(subjectInfo)+geom_histogram(aes(x=age),color=I('grey75'),fill=I('grey55'),binwidth=1)+geom_histogram(aes(x=age,fill=sex,color=sex),position='dodge',binwidth=1) + theme_bw() + ggtitle('Age of participants') + geom_vline(x=c(14,18))+scale_x_continuous(limits=c(10,21),breaks=c(10:21))
ggsave(hist.age,file="imgs/hist-age.svg")

### BELOW done by visualizeSubset.R
# so we can skip
quit() # press c 

################## Inv
# linear age models, roirois.lm is a list of lm models
load('Rdata/lmer-perROI-out-invage.Rdata')

# easy access to correlation 
ageeff.ageXphys <- read.csv('txt/ageeffAgeXphys-invage.csv')

showplotatindex <- function(i) {
	ggplot(lmerCellMeans(roirois.lm[[i]]$invAge),aes(x=AgeInverseCentered,y=value,color=Pipeline))+
	geom_line()+
	geom_smooth(aes(ymin=plo,ymax=phi),stat='identity')+
	theme_bw()+
	geom_point(data=roirois.lm[[i]]$invAge@frame,alpha=I(.5)) +
       	geom_point(data=roirois.lm[[i]]$invAge@frame,aes(label=ID)) + #,x=AgeInverseCentered,y=value)+
	ggtitle(as.character(ageeff.ageXphys[i,'rtitle']))
	#ggtitle(paste(as.character(ageeff.ageXphys[i,]),collapse=" - "))
}
# put high t-values up for roi-roi where age is signfig
o <- rev(order(abs(ageeff.ageXphys$ageXphysio.tval)*as.numeric(abs(ageeff.ageXphys$age.tval)>2.569) )   ) 
for(i in o[1:30]) { print(i); print(ageeff.ageXphys[i,]);
  svg(sprintf('imgs/lm/ageinv/%s.svg',ageeff.ageXphys[i,'rtitle']));
  print(showplotatindex(i) );
  dev.off()
}


################## LINEAR 
# linear age models, roirois.lm is a list of lm models
load('Rdata/lmer-perROI-out-agec.Rdata')

# easy acces to correlation moles
roirois.ageeff <- read.csv('txt/ageeffAgeXphys-agec.csv')
