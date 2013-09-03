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

# linear age models, roirois.lm is a list of lm models
load('Rdata/lmer-perROI-out-agec.Rdata')

# easy acces to correlation moles
roirois.ageeff <- read.csv('txt/ageeffAgeXphys-agec.csv')
