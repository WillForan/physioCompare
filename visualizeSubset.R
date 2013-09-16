library(lme4)
library(ggplot2)
library(plyr)
source('lmerCellMeans.R')
# TODO: languageR pmpc p test

#to undo 1/age centering we need the mean, so load up subject file
subjectinfo <- read.table('txt/IDSexDOBVisitAge.txt')
names(subjectinfo)<-.(ID,sex,DOB,DOV,age)
meanage <- mean(subjectinfo$age)
# looks like mean age is actually 14.86196 instead of 15.45362!! why?
meanage<-14.86196

plotmodelwithpoints <- function(model, gtitle,modeltype='ageinv', modelgroup='devel') {
        # two data sets
        lmercell <- lmerCellMeans(model) # construct line with point foreach person
        idvpnts  <- model@frame          # actual data used to create the model

	# set actual age
	# TODO: if state that can handle agec -- not neeed right now
	uncenterAge <- function(x){1/(x+1/meanage)}

	lmercell$age    <- uncenterAge(lmercell$AgeInverseCentered)
	idvpnts$age     <- uncenterAge(idvpnts$AgeInverseCentered)
	model@frame$age <- uncenterAge(model@frame)


	# pretty names for legend
	lmercell$Pipeline <- as.factor(lmercell$Pipeline)
	# correct
	#levels(lmercell$Pipeline) <- list('Without Physio'='nophysio', 'Physio Included'='physio')
	# incorrect
	#levels(lmercell$Pipeline) <- list('nophysio'='Without Physio','physio'= 'Physio Included')

	plot.simple <- ggplot(lmercell,aes(x=age,y=value,color=Pipeline,linetype=Pipeline))+
	               geom_line() +
	               theme_bw()+
		       ylim(-.3,.7) +
	               ggtitle(gtitle)+ylab('ROI-ROI correlation')+xlab('Age')
	
	plot.all <- plot.simple +
	           geom_smooth(aes(ymin=plo,ymax=phi),stat='identity')+
	           geom_point(data=idvpnts,aes(x=age,y=value)) 
       	#geom_text(data=idvpnts,aes(label=ID),size=I(2),alpha=I(.5)) + #,x=AgeInverseCentered,y=value)+
	#ggtitle(paste(as.character(ageeff.ageXphys[i,]),collapse=" - "))
        gtitle <- gsub(' ','_',gtitle)
        gtitle <- gsub(':|\\(|\\)','',gtitle,perl=T)
	ggsave(plot.simple,file=sprintf("imgs/lm/%s/%s/%s-simple.png",modeltype,modelgroup,gtitle))
	ggsave(plot.all,file=sprintf("imgs/lm/%s/%s/%s-all.png",modeltype,modelgroup,gtitle))

        #plot.simple
	#plot.all
	gtitle
}

# if we haven't run this in current space
if(!exists('ageeff.ageXphys.orig') || length(ageeff.ageXphys.orig$ROI1xyz)<1) {
  cat('reading coord labels, age effect models, and glueing them together\n')
  # add x y z position
  roiinfo <- read.table('txt/labels_bb244_coordinate',sep='\t'); 
  names(roiinfo)<-.(num,x,y,z,atlas,radius,afniName,p,refnum)
  
  # easy access to correlation 
  ageeff.ageXphys.orig <- read.csv('txt/ageeffAgeXphys-invage.csv')
  
  # add roiinfo to ageeff
  grabxyz   <- function(row){ paste(collapse=" ",sep=" ", roiinfo[which(roiinfo$num==row),c('x','y','z')])}
  ageeff.ageXphys.orig$ROI1xyz   <- sapply(ageeff.ageXphys.orig$ROI1, grabxyz)
  ageeff.ageXphys.orig$ROI2xyz   <- sapply(ageeff.ageXphys.orig$ROI2, grabxyz)
  grabaname <- function(x){  roiinfo$afniName[roiinfo$num==x]}
  ageeff.ageXphys.orig$ROI1aname <- sapply(ageeff.ageXphys.orig$ROI1, grabaname)
  ageeff.ageXphys.orig$ROI2aname <- sapply(ageeff.ageXphys.orig$ROI2, grabaname)
}

##########################################
# data driven
# most significant ROI-ROI interaction
# see truncateLM.R for generation
########################################

if(!exists('best.lm')){
 cat('loading bests.Rdata\n')
 load('Rdata/bests.Rdata')
 # provides best.lm and best.lm.order
}
# truncate ageeff to only get the roi's we need
# -- this gives us ROI names and easy access to the tvalue of the interaction
ageeff.ageXphys <- ageeff.ageXphys.orig[best.lm.order,]

for (i in 1:nrow(ageeff.ageXphys)) {
  model    <- best.lm[[i]]$invAge
  gtitle   <- paste(collapse=" - ",as.character(unlist(ageeff.ageXphys[i,c('ROI1aname','ROI2aname')])))
  gtitle   <- gsub('  *','',gtitle,perl=T) # remove repeated spaces
  gtitle   <- sprintf('%02d %s (t: %f) ',i, gtitle,abs(ageeff.ageXphys$ageXphysio.tval[i]))
  #png(sprintf('imgs/lm/ageinv/%s.png',ageeff.ageXphys[i,'rtitle']));
  print(plotmodelwithpoints(model,gtitle,modelgroup='datadriven') );
  #dev.off()
}

quit()
##########################################
# 9 development ROIs -- hypotheses driven
# see truncateLM.R for generation
########################################
if(!exists('devel.lm')){
 cat('loading devel-invage.Rdata\n')
 load('Rdata/devel-invage.Rdata')
}
# now have:
#  - devel.lm 
#  - develidx
#  - develrois

# limit our list of roi-roi lm's to theones we have
ageeff.ageXphys <- ageeff.ageXphys.orig[develidx,]

# get the roi's names
roinames <- read.table('txt/develRois.txt',sep=' '); names(roinames)<-.(num,name)
ageeff.ageXphys$ROI1name <- sapply(ageeff.ageXphys$ROI1, function(x){ roinames$name[roinames$num==x]})
ageeff.ageXphys$ROI2name <- sapply(ageeff.ageXphys$ROI2, function(x){ roinames$name[roinames$num==x]})

ageeff.ageXphys[rev(order(abs(ageeff.ageXphys$ageXphysio.tval))),]
# put high t-values up for roi-roi where age is signfig
j=1
for(i in rev(order(abs(ageeff.ageXphys$ageXphysio.tval))) ) { 
  print(i);
  print(ageeff.ageXphys[i,]);

  model    <- devel.lm[[i]]$invAge
  gtitle   <- paste(collapse=" - ",as.character(unlist(ageeff.ageXphys[i,c('ROI1name','ROI2name')])))
  gtitle   <- sprintf('%02d %s (t: %f) ',j, gtitle,abs(ageeff.ageXphys$ageXphysio.tval[i]))
  #png(sprintf('imgs/lm/ageinv/%s.png',ageeff.ageXphys[i,'rtitle']));
  print(plotmodelwithpoints(model,gtitle) );
  #dev.off()
  j=j+1
  #readline();
}

