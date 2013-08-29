library(plyr)
library(lme4)
library(doMC)


if(!exists("roirois.long")) {
 roirois.long<-read.csv('ROIROIcorAgeSubjPipe.csv')
 names(roirois.long) <- c('ROI1','ROI2','value','Age','Pipeline','ID')

 roirois.long$ID   <-  as.factor(roirois.long$ID )
 roirois.long$ROI1 <-  as.factor(roirois.long$ROI1 )
 roirois.long$ROI2 <-  as.factor(roirois.long$ROI2 )
 roirois.long$Pipeline <-  as.factor(roirois.long$Pipeline )
 roirois.long$AgeInverseCentered <- 1/(roirois.long$Age) -  mean(1/(roirois.long$Age),na.rm=T  )
} else {
 cat('using roirois.long thats in environment!\n')
}

# mean should be centered, but could be off by rounding error
if(abs(mean(roirois.long$AgeInverseCentered)) > 10^-8 ){ 
  warn('the mean inv age is not zero!!')
}
# remove NA (dangerous?), fails otherwise
roirois.long <- roirois.long[!is.nan(roirois.long$value),]

registerDoMC(cores=4)

if(file.exists("lmer-perROI-out.Rdata")){
 cat('already have lmer-perROI-out.Rdata, loading from src\n')
 load("lmer-perROI-out.Rdata")
}else{
  roirois.lm <- dlply( roirois.long, .(ROI1,ROI2),.parallel=T, function(roiroi) {
    cat("ROI1: ",roiroi$ROI1[1],"; ROI2: ",roiroi$ROI2[1],"\n")
    lmer(value ~ 1 + Pipeline  * AgeInverseCentered + (1 | ID), roiroi, REML=TRUE)
  })
  save(file="lmer-perROI-out.Rdata",list=c('roirois.lm'))
}

# lmerCellMeans is MH's lmer groking function
source("lmerCellMeans.R")

