library(ggplot2)
library(lme4)
# subject info, like
# 10152	female	19930510	20100514	17.0106278777989
subjectInfo <- read.table('txt/IDSexDOBVisitAge.txt')
names(subjectInfo) <- c('ID','sex','DOB','ScanDate','age')

# read in giant table of cor for each ROIROI for each person for each pipeline
roirois. <- read.csv('txt/ROIROIcorAgeSubjPipe.csv')
names(roirois.long) <- c('ROI1','ROI2','value','Age','Pipeline','ID')
roirois.long$ID   <-  as.factor(roirois.long$ID )
roirois.long$ROI1 <-  as.factor(roirois.long$ROI1 )
roirois.long$ROI2 <-  as.factor(roirois.long$ROI2 )
roirois.long$Pipeline <-  as.factor(roirois.long$Pipeline )
roirois.long$AgeInverseCentered <- 1/(roirois.long$Age) -  mean(1/(roirois.long$Age),na.rm=T  )
roirois.long$AgeCentered <- roirois.long$Age -  mean(roirois.long$Age,na.rm=T  )

################## general subj plots
# histogram: age
hist.age <- ggplot(subjectInfo)+geom_histogram(aes(x=age),color=I('grey75'),fill=I('grey55'),binsize=2)+geom_histogram(aes(x=age,fill=sex,color=sex),position='dodge',binsize=1) + theme_bw() + ggtitle('Age of participants')

ggsave(hist.age,file="hist-age.png")
################## Inv
# linear age models, roirois.lm is a list of lm models
load('Rdata/lmer-perROI-out-invage.Rdata')

# easy acces to correlation moles

roirois.ageeff <- read.csv('txt/ageeffAgeXphys-invage.csv')


################## LINEAR 
# linear age models, roirois.lm is a list of lm models
load('Rdata/lmer-perROI-out-agec.Rdata')

# easy acces to correlation moles
roirois.ageeff <- read.csv('txt/ageeffAgeXphys-agec.csv')
