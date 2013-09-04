library(plyr)
library(lme4)
library(doMC)
registerDoMC(cores=4)
#library(doParallel)
#library(foreach)
#registerDoParallel(makeCluster(4))


# lmerCellMeans is MH's lmer groking function
# not used here yet
source("lmerCellMeans.R")

# read in ROI names
roi.lables<-read.table('txt/labels_bb244_coordinate',sep="\t")
names(roi.lables) <- c('num','x','y','z','atlas','r','name','prob','segnum')


# only make roirois.long if we have to
# loading the 100s of MB files take a bit of time
if(!exists("roirois.long")) {
 cat('reading in giant csv!\n')
 roirois.long<-read.csv('txt/ROIROIcorAgeSubjPipe.csv')
 names(roirois.long) <- c('ROI1','ROI2','value','Age','Pipeline','ID')

 roirois.long$ID   <-  as.factor(roirois.long$ID )
 roirois.long$ROI1 <-  as.factor(roirois.long$ROI1 )
 roirois.long$ROI2 <-  as.factor(roirois.long$ROI2 )
 roirois.long$Pipeline <-  as.factor(roirois.long$Pipeline )
 roirois.long$AgeInverseCentered <- 1/(roirois.long$Age) -  mean(1/(roirois.long$Age),na.rm=T  )
 roirois.long$AgeCentered <- roirois.long$Age -  mean(roirois.long$Age,na.rm=T  )
} else {
 cat('using roirois.long thats in environment!\n')
}

# mean should be centered, but could be off by rounding error
if(abs(mean(roirois.long$AgeInverseCentered,na.rm=T)) > 10^(-8) ){ 
  warn('the mean inv age is not zero!!')
}
# remove NA (dangerous?), fails otherwise
roirois.long <- roirois.long[!is.nan(roirois.long$value),]

modelname<-'invage'
#also change e.g. roirois.lm's ddply creation, a for  ageeff.inv 
savefile<-sprintf("Rdata/lmer-perROI-out-%s.Rdata",modelname)
txtfile<-sprintf("txt/ageeffAgeXphys-%s.csv",modelname)

if(file.exists(savefile)){
 cat('already have' , savefile, ', loading from src\n')
 load(savefile)
}else{
  roirois.lm <- dlply( roirois.long, .(ROI1,ROI2),.parallel=T, function(roiroi) {
    #library(lme4)  # included because doParallel needs new env
    cat("ROI1: ",roiroi$ROI1[1],"; ROI2: ",roiroi$ROI2[1],"\n")
    list( 
	ROI1=roiroi$ROI1[1],
	ROI2=roiroi$ROI2[1],
	invAge=lmer(value ~ 1 + Pipeline  * AgeInverseCentered + (1 | ID), roiroi, REML=TRUE)
	#age=lmer(value ~ 1 + Pipeline  * AgeCentered + (1 | ID), roiroi, REML=TRUE)
    )
  })
  cat('saving file: ', savefile,'\n')
  save(file=savefile,list=c('roirois.lm'))
  cat('saved\n')
}
# collect all the tvals 
ageeff.ageXphys <-ldply(roirois.lm,.parallel=T, function(x){
    #library(lme4)  # included because doParallel needs new env
    i=summary(x$invAge)
    #a=summary(x$age)
    data.frame(

     ROI1=x['ROI1'],
     ROI2=x['ROI2'],

     intercept    =i@coefs[1,1],
     intcpt.tval  =i@coefs[1,3],

     pipe.slope =i@coefs[2,1],
     pipe.tval  =i@coefs[2,3],

     age.slope  =i@coefs[3,1],
     age.tval   =i@coefs[3,3],

     ageXphysio.val  =i@coefs[3,1],
     ageXphysio.tval =i@coefs[4,3],

     rtitle=paste(collapse=" -  ",
	      roi.lables[c(
	       which(roi.lables$num==x['ROI1']),
	       which(roi.lables$num==x['ROI2']))
            ,'name'])
   )   
 })
write.csv(file=txtfile,ageeff.ageXphys)

#o <- rev(order(ageeff.ageXphys$Xtval.inv)) 

