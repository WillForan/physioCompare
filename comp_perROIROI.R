library(plyr)
library(lme4)
library(doMC)
registerDoMC(cores=5)

# lmerCellMeans is MH's lmer groking function
# not used here yet
source("lmerCellMeans.R")


if(!exists("roirois.long")) {
 cat('reading in giant csv!\n')
 roirois.long<-read.csv('ROIROIcorAgeSubjPipe.csv')
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
if(abs(mean(roirois.long$AgeInverseCentered)) > 10^-8 ){ 
  warn('the mean inv age is not zero!!')
}
# remove NA (dangerous?), fails otherwise
roirois.long <- roirois.long[!is.nan(roirois.long$value),]


if(file.exists("lmer-perROI-out.Rdata")){
 cat('already have lmer-perROI-out.Rdata, loading from src\n')
 load("lmer-perROI-out.Rdata")
}else{
  roirois.lm <- dlply( roirois.long, .(ROI1,ROI2),.parallel=T, function(roiroi) {
    cat("ROI1: ",roiroi$ROI1[1],"; ROI2: ",roiroi$ROI2[1],"\n")
    list( 
	ROI1=roiroi$ROI1[1],
	ROI2=roiroi$ROI2[1],
	invAge=lmer(value ~ 1 + Pipeline  * AgeInverseCentered + (1 | ID), roiroi, REML=TRUE),
	age=lmer(value ~ 1 + Pipeline  * AgeCentered + (1 | ID), roiroi, REML=TRUE)
    )
  })
  cat('saving file: lmer-perROI-out.Rdata\n')
  save(file="lmer-perROI-out.Rdata",list=c('roirois.lm'))
  cat('saved\n')
}

# collect all the tvals 
tvals<-ldply(roirois.lm,.parallel=T, function(x){c(ROI1=x['ROI1'], ROI2=x['ROI2'], tval=summary(x)@coefs[4,3])})

