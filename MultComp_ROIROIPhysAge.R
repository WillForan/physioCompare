library(lme4)
library(multcomp)
source('lmerCellMeans.R')


if(!exists('roisrois.long')){
 roirois.long <- read.csv("ROIROIcorAgeSubjPipe.csv")
 names(roirois.long) <- c('ROI1','ROI2','value','Age','Pipeline','ID')
 # remove NA (dangerous?), fails otherwise
 roirois.long <- roirois.long[!is.nan(roirois.long$value),]
 
 # build moddle attributes
 # most things should be catagorical
 roirois.long$ID   <- factor(roirois.long$ID)
 roirois.long$ROI1 <- factor(roirois.long$ROI1)
 roirois.long$ROI2 <- factor(roirois.long$ROI2)
 roirois.long$Pipeline <-  as.factor(roirois.long$Pipeline )
 roirois.long$AgeInverseCentered <- 1/(roirois.long$Age -  mean(roirois.long$Age,na.rm=T) )
} else {
 cat('using roirois.long thats in environment!\n')
}

#looks normal enough to me!
histogram(~value | ROI1 + ROI2 , roirois.long)
#histogram(~X | PFC + Subcortical, rois)


if(file.exists("lmer-alltogether-out.Rdata")) { 
 cat("loading lmer all output from file!\n")
 load("lmer-alltogether-out.Rdata")
}else {
 #mixed correlation model
 corrMixed <- lmer(value ~ 1 + ROI1 * ROI2 * Pipeline * AgeInverseCentered + (1 | ID), roirois.long, REML=TRUE)
 
 fixef(corrMixed)
 save(file="lmer-alltogether-out.Rdata",list=c('CorrMixed'))
}



#compute cmat for each PFC * Subcort combination
cmat <- list(age=list(), pipeline=list(), agexpipe=list())
ROILevels <- levels(roirois.long$ROI1)
# redudant, but keeps aarthi's code changes to a minimum
ROI2Levels <- levels(roirois.long$ROI2)
coefs <- fixef(corrMixed)
ageEff <- "AgeInverseCentered"
comtEff <- "COMT.Genotype"

for (l in 1:length(ROILevels)) {
  for (m in 1:length(ROI2Levels)) {
    
    #setup empty contrast
    cont <- rep(0, length(coefs))
    names(cont) <- names(coefs)
    
    #setup possible effects of interest
    meSubcort <- paste("ROI1", ROILevels[l], sep="")
    mePFC <- paste("ROI2", ROI2Levels[m], sep="")
    
    #interactions must follow order of model specification above
    #two-way interactions (6 of them)
    pfc_subcort <- paste(mePFC, meSubcort, sep=":")
    pfc_comt <- paste(mePFC, comtEff, sep=":")
    pfc_age <- paste(mePFC, ageEff, sep=":")
    subcort_comt <- paste(meSubcort, comtEff, sep=":")
    subcort_age <- paste(meSubcort, ageEff, sep=":") 
    comt_age <- paste(comtEff, ageEff, sep=":")
    
    #three-way interactions (4 of them)
    pfc_subcort_comt <- paste(mePFC, meSubcort, comtEff, sep=":")
    pfc_subcort_age <- paste(mePFC, meSubcort, ageEff, sep=":")
    pfc_comt_age <- paste(mePFC, comtEff, ageEff, sep=":")
    subcort_comt_age <- paste(meSubcort, comtEff, ageEff, sep=":")
    
    #four-way interaction
    fourway <- paste(mePFC, meSubcort, comtEff, ageEff, sep=":")
    
    #####
    #age contrast
    #Generally: age + subcort:age + pfc:age + subcort:pfc:age
    age.cont <- cont
    age.cont[ageEff] <- 1 #always include main effect of age for age tests
    
    #two-way age x brain region interactions
    if (pfc_age %in% names(coefs)) age.cont[pfc_age] <- 1
    if (subcort_age %in% names(coefs)) age.cont[subcort_age] <- 1
    
    #three-way age x subcort x pfc
    if (pfc_subcort_age %in% names(coefs)) age.cont[pfc_subcort_age] <- 1
    
    conName <- paste(ROILevels[l], ROI2Levels[m], "Age", sep=" X ")
    cmat$age[[conName]] <- age.cont
    
    #####
    #pipeline contrast
    #Generally: comt + subcort:comt + pfc:comt + subcort:pfc:comt
    pipeline.cont <- cont
    pipeline.cont[comtEff] <- 1 #always include main effect of pipeline for pipeline tests
    
    #two-way pipeline x brain region interactions
    if (pfc_comt %in% names(coefs)) pipeline.cont[pfc_comt] <- 1
    if (subcort_comt %in% names(coefs)) pipeline.cont[subcort_comt] <- 1
    
    #three-way pipeline x subcort x pfc
    if (pfc_subcort_comt %in% names(coefs)) pipeline.cont[pfc_subcort_comt] <- 1
    
    conName <- paste(ROILevels[l], ROI2Levels[m], "COMT", sep=" X ")
    cmat$pipeline[[conName]] <- pipeline.cont
    
    #####
    #age x pipeline
    #Contrasts test how the age x comt interaction deviates for this PFC x Subcort pair
    #Generally: age:comt + subcort:age:comt + pfc:age:comt + subcort:pfc:age:comt
    agexpipe.cont <- cont
    agexpipe.cont[comt_age] <- 1 #always include pipeline x age interaction, which is the reference
    
    #three-way interactions that include age x comt
    if (pfc_comt_age %in% names(coefs)) agexpipe.cont[pfc_comt_age] <- 1
    if (subcort_comt_age %in% names(coefs)) agexpipe.cont[subcort_comt_age] <- 1
    
    #four-way interaction
    if (fourway %in% names(coefs)) agexpipe.cont[fourway] <- 1
    
    conName <- paste(ROILevels[l], ROI2Levels[m], "Age", "COMT", sep=" x ")
    cmat$agexpipe[[conName]] <- agexpipe.cont
    
    
  }
}

#check pipeline contrast problem:


#print out contrast estimates for a couple of models.
for (i in 1:2) {
  cat("Age cont: ", names(cmat$age)[i], "\n")
  print(sum(coefs[which(cmat$age[[i]] > 0)]))
  
  cat("Comt cont: ", names(cmat$comt)[i], "\n")
  print(sum(coefs[which(cmat$pipeline[[i]] > 0)]))
  
  cat("Age x pipe cont: ", names(cmat$agexpipe)[i], "\n")
  print(sum(coefs[which(cmat$agexpipe[[i]] > 0)]))
}

#spot check three models 
###  laccum_acc <- subset(rois, Subcortical=="L_Accum" & PFC=="ACC")
###  summary(m1 <- lm(X ~ AgeInverseCentered * COMT.Genotype, data=laccum_acc))
###  coefs[which(cmat$agexpipe[["L_Accum x ACC x Age x COMT"]] > 0)]
###  
###  lm(X ~ AgeInverseCentered, data=laccum_acc)
###  lm(X ~ COMT.Genotype, data=laccum_acc)
###  
###  m1c <- coef(m1)
###  
###  pred.low <- m1c["(Intercept)"] + m1c["COMT.Genotype"]
###  
###  laccum_dacc <- subset(rois, Subcortical=="L_Accum" & PFC=="DACC")
###  summary(lm(X ~ AgeInverseCentered * COMT.Genotype, data=laccum_dacc))
###  coefs[which(cmat$agexpipe[["L_Accum x DACC x Age x COMT"]] > 0)]
###  
###  lcaudate_rsfg <- subset(rois, Subcortical=="L_Caudate" & PFC=="RightSFG")
###  summary(lm(X ~ AgeInverseCentered * COMT.Genotype, data=lcaudate_rsfg))
###  coefs[which(cmat$agexpipe[["L_Caudate x RightSFG x Age x COMT"]] > 0)]
###  sum(coefs[which(cmat$agexpipe[["L_Caudate x RightSFG x Age x COMT"]] > 0)])
###  
###  #get model-estimated correlations for each combination (useful for graphs)
###  cm <- lmerCellMeans(corrMixed, divide=c("AgeInverseCentered", "COMT.Genotype"))

####SIMULTANEOUS TESTS
#combine into a matrix
#this combines into all contrasts
cmat.mat <- do.call(rbind, lapply(cmat, function(el) do.call(rbind, el)))

#separated by age, pipeline, and interaction
cmat.matSeparate <- lapply(cmat, function(el) do.call(rbind, el))


#no correction (per effect). Adapt below accordingly
lapply(cmat.matSeparate, function(effect) {
      print(summary(glht(corrMixed, linfct=effect), test=adjusted("none")))
    })

###
(nocorrect <- summary(glht(corrMixed, linfct=cmat.mat), test=adjusted("none")))
#print only significant effects
nocorrect$test$coefficients[which(summary(glht(corrMixed, linfct=cmat.mat), test=adjusted("none"))$test$pvalues < .05)]

#if you did the crazy bonferroni
summary(glht(corrMixed, linfct=cmat.mat), test=adjusted("bonferroni"))

#holm is no better
summary(glht(corrMixed, linfct=cmat.mat), test=adjusted("holm"))

#liberal FDR correction
summary(glht(corrMixed, linfct=cmat.mat), test=adjusted("fdr"))

#single-step correction (the Hothorn paper, and multcomp's default
summary(glht(corrMixed, linfct=cmat.mat), test=adjusted("single-step"))

#free combinations of parameters (Westfall 1999)
summary(glht(corrMixed, linfct=cmat.mat), test=adjusted("free"))

#logical constraint adjustments
summary(glht(corrMixed, linfct=cmat.mat), test=adjusted("Westfall"))

#logical constraint adjustments
summary(glht(corrMixed, linfct=cmat.mat), test=adjusted("Shaffer"))



###


## TODO: change me, COMT.Genotype should be physio or nophysio?
## cm <- lmerCellMeans(corrMixed, n.cont=c(AgeInverseCentered=30), fixat0="COMT.Genotype")


ggplot(cm, aes(x=AgeInverseCentered, y=X, color=factor(COMT.Genotype))) +
    facet_grid(PFC ~ Subcortical) + geom_line()



#leftovers -- junk
#    agexpipe.cont[comtEff] <- 1
#    agexpipe.cont[ageEff] <- 1

#two-way (should include all)

#three-way (should include all)
#    if (pfc_subcort_age %in% names(coefs)) agexpipe.cont[pfc_subcort_age] <- 1
#    if (pfc_subcort_comt %in% names(coefs)) agexpipe.cont[pfc_subcort_comt] <- 1

#before including age and pipeline, check for subcort and pfc me and two-way (will exist except for ref levels) 
#if ME subcort is a term, then include it
#    if (meSubcort %in% names(coefs)) cont[meSubcort] <- 1
#    if (mePFC %in% names(coefs)) cont[mePFC] <- 1
#    if (pfc_subcort %in% names(coefs)) cont[pfc_subcort] <- 1


#allSubcort <- grep(paste("Subcortical", ROILevels[l], sep=""), names(coefs), value=TRUE)
#allPFC <- grep(paste("PFC", ROI2Levels[m], sep=""), names(coefs), value=TRUE)

#    if (pfc_age %in% names(coefs)) agexpipe.cont[pfc_age] <- 1
#    if (subcort_age %in% names(coefs)) agexpipe.cont[subcort_age] <- 1
#    if (pfc_comt %in% names(coefs)) agexpipe.cont[pfc_comt] <- 1
#    if (subcort_comt %in% names(coefs)) agexpipe.cont[subcort_comt] <- 1

