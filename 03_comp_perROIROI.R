modelname<-'invage'
#modelname<-'agec'
#also change e.g. roirois.lm's ddply creation, a for  ageeff.inv 

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
 roirois.long<-read.csv(sprintf('txt/ROIROIcorAgeSubjPipe.csv'))
 # why was this modelname before?
 #roirois.long<-read.csv(sprintf('txt/ROIROIcorAgeSubjPipe-%s.csv',modelname))
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
    #i=summary(x$age)
    data.frame(

     ROI1=x['ROI1'],
     ROI2=x['ROI2'],

     intercept    =i@coefs[1,1],
     intcpt.tval  =i@coefs[1,3],

     pipe.slope =i@coefs[2,1],
     pipe.tval  =i@coefs[2,3],

     age.slope  =i@coefs[3,1],
     age.tval   =i@coefs[3,3],

     ageXphysio.val  =i@coefs[4,1],
     ageXphysio.tval =i@coefs[4,3],

     rtitle=paste(collapse=" -  ",
	      roi.lables[c(
	       which(roi.lables$num==x['ROI1']),
	       which(roi.lables$num==x['ROI2']))
            ,'name'])
   )   
 })
write.csv(file=txtfile,ageeff.ageXphys)
#    X ROI1 ROI2 intercept intcpt.tval pipe.slope pipe.tval age.slope  age.tval ageXphysio.val ageXphysio.tval
#21618  130  233  0.270628    11.09827 0.03981486  3.188247  1.661884 0.9453313       1.661884        2.59676

#summary(roirois.lm[[21618]]$invAge)
#   Fixed effects:
#                                     Estimate Std. Error t value
#   (Intercept)                        0.27063    0.02438  11.098
#   Pipelinephysio                     0.03981    0.01249   3.188
#   AgeInverseCentered                 1.66188    1.75799   0.945
#   Pipelinephysio:AgeInverseCentered  2.33790    0.90031   2.597
# 

#o <- rev(order(ageeff.ageXphys$Xtval.inv)) 


### compute p-vals, will take half the day and eat a 10 gigs of ram
# .0109 -- best.lm 113 == t of -2.564929
# .0009 -- best.lm 110 == t of -2.598584
# 
# getpval(113)$pvals$fixed[4,6]
#  [1]  0.0109 
# ageeff$ageXphysio.tval[best.lm.order[113]]
#  [1] -2.564929

# getpval(110)$pvals$fixed[4,6]
#  [1] "0.0099"
# ageeff$ageXphysio.tval[best.lm.order[110]]
#  [1] -2.598584

# load('Rdata/lmer-perROI-out-invage.Rdata')
# ageeff <- read.csv('txt/ageeffAgeXphys-invage.csv')
#library(doMC)
#library(lme4)
#library(languageR)
#library(foreach)
#registerDoMC(5)
#l<-length(roirois.lm)
#l<-10
##for ( i in 1:l ) { pvals[i] <- pvals.fnc(roirois.lm[[i]]$invAge) }
#getpval <- function(i){ s<-Sys.time(); l<-list(i=i,pvals=pvals.fnc(roirois.lm[[i]]$invAge)); cat(i,s, Sys.time(),"\n"); return(l)  }
##eats all the ram
##pvals <- foreach(i=1:l) %dopar% getpval(i) 
#save(list='pvals',file='Rdata/lm-invage-pvals.Rdata')
