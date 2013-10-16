load('Rdata/lmer-perROI-out-invage.Rdata')
ageeff <- read.csv('txt/ageeffAgeXphys-invage.csv')
#best.lm <- roirois.lm[order(ageeff$ageXphysio.tval)[1:300]]
#best.lm.order <- order(ageeff$ageXphysio.tval)[1:300]

# only use significant ROIs
ageeff.sigidx <- which(abs(ageeff$ageXphysio.tval)>2.58)
# grav tvalues at sigindex, order for greatest to least, 
best.lm.order <- ageeff.sigidx[ rev(order(ageeff$ageXphysio.tval[ageeff.sigidx])) ]
best.lm <- roirois.lm[best.lm.order]
save(list=c('best.lm','best.lm.order'),file="Rdata/ageinv-signficantInteraction.Rdata")

develrois<-c(78,100,174,190,213,215,230,232,241) # sort -n develRois.txt|cut -f1 -d' ' |tr '\n' ','
develidx <- which( (ageeff$ROI1 %in% develrois ) & ( ageeff$ROI2 %in% develrois) )
devel.lm <- roirois.lm[develidx]
save(list=c('devel.lm','develidx','develrois'),file="Rdata/devel-invage.Rdata")

