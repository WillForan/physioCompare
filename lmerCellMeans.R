#helper function to get predictions of model-estimated correlations
lmerCellMeans <- function(lmerObj, divide=NULL, n.divide=3, divide.prefix=TRUE, n.cont=30, fixat0=NULL) { 
  #print cell means for lmer by expanding level combinations and multiplying against fixed effects  
  predNames <- attr(terms(lmerObj), "term.labels")
  whichME <- attr(terms(lmerObj), "order")
  predNames <- predNames[whichME==1]
  
  predData <- list()
  #divide into categorical and continuous predictors, determine which continuous predictors to discretize
  for (f in predNames) {
    if (f %in% fixat0) { predData[[f]] <- 0 #compute model prediction when this term is 0
    } else if (attr(terms(lmerObj), "dataClasses")[f] == "factor") {
      predData[[f]] <- levels(lmerObj@frame[[f]])  
    } else {
      if (f %in% divide) {
        #divide into -1 SD, M, + 1 SD; or -2SD, -1SD, M, +1SD, +2SD
        fsd <- sd(lmerObj@frame[[f]], na.rm=TRUE)
        fm <- mean(lmerObj@frame[[f]], na.rm=TRUE)
        predData[[f]] <- if (n.divide==3) { c(fm-fsd, fm, fm+fsd)
            } else { c(fm-fsd*2, fm-fsd, fm, fm+fsd, fm+fsd*2) }
      } else {
        if (!is.null(names(n.cont))) {
          #Named vector specifying number of points to predict for each IV
          if (is.na(n.cont[f])) stop("Cannot locate number of continuous pred points for: ", f)
          predData[[f]] <- seq(min(lmerObj@frame[[f]], na.rm=TRUE), max(lmerObj@frame[[f]], na.rm=TRUE), length=n.cont[f])          
        } else {
          #treat as truly continuous predictor and compute models estimates across the range of observed values
          predData[[f]] <- seq(min(lmerObj@frame[[f]], na.rm=TRUE), max(lmerObj@frame[[f]], na.rm=TRUE), length=n.cont)
        }
      }
    }
  }
  
  #dependent variable
  dvname <- as.character(terms(lmerObj)[[2]])
  
  #populate the model-predicted estimates with 0s prior to building model matrix
  predData[[dvname]] <- 0
  
  #Develop a grid 
  predData <- do.call(expand.grid, list(predData))
  
  mm <- model.matrix(terms(lmerObj),predData)
  
  
  predData[[dvname]] <- mm %*% fixef(lmerObj)
  
  pvar1 <- diag(mm %*% tcrossprod(vcov(lmerObj),mm))
  tvar1 <- pvar1+VarCorr(lmerObj)[[1]][1] #assumes that the first element in VarCorr is subject
  
  #confidence and prediction intervals
  predData <- data.frame(
      predData, se=sqrt(pvar1),
      plo = predData[[dvname]]-2*sqrt(pvar1),
      phi = predData[[dvname]]+2*sqrt(pvar1),
      tlo = predData[[dvname]]-2*sqrt(tvar1),
      thi = predData[[dvname]]+2*sqrt(tvar1)
  )
  
  for (f in divide) {
    if (n.divide==3) { flevels <- c("-1 SD", "M", "+1 SD")
    } else if (n.divide==5) { flevels <- c("-2SD", "-1 SD", "M", "+1 SD", "+2 SD") }
    if (divide.prefix) flevels <- paste(Hmisc::capitalize(f), flevels, sep=": ")
    predData[[f]] <- factor(predData[[f]], levels=sort(unique(predData[[f]])), labels=flevels)
  }
  
  return(predData)
}
