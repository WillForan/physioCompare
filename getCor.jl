#!/usr/bin/env julia

# an object to store each subject's visit for each pipeline
type corrMetaInfo
  id
  visit
  pipeline
  age
  existingROIs
end

# rows of time samples, columns of regiions. 
# get the correlation over a sliding window

function rollingcors(in_mat, samplesPerWindow)
    numCorr=size(in_mat,1)-samplesPerWindow
    cors = zeros(size(in_mat, 2), size(in_mat, 2), numCorr)

    # start at 1 and go until the window would exceed the matrix
    for startat = 1:numCorr
       endat = startat+samplesPerWindow
       cors[:, :, startat] = cor(in_mat[startat:endat, :])
    end
    return cors
end

# get median without worrying about NaNs
function nanmedian(A)
    cleanA = A[isfinite(A)]
    if isempty(cleanA)
       NaN
    else
      return median(cleanA)
    end
end

# get all the files we want to work on
basedir = "txt/bb244Stats_mni/"
outdir =  "txt/ROIROI_median"
files = readdir(basedir)
#files=files[1:2] # testing

# allCorMeta has type and

allCorrMeta = Array(corrMetaInfo,size(files,1) )
allCorr =  zeros(264,264,size(files,1) )

for i in 1:length(files)
   f=files[i];
   println(f)
   fileparts = split(f,"_")
  (subj, visit) = fileparts

  # parse out which pipeline the file is coming from
  if ismatch(r"1D",fileparts[4])
    pipeline="physio"
  elseif ismatch(r"abs",fileparts[4])
    continue 
  else
    pipeline=fileparts[4]
  end

  #TODO
  ## get age at visit
  age = 0

  # this is the output of 3dROIStats
  # it's funny
  oned_string = readdlm(joinpath(basedir,f),'	', String,ignore_invalid_chars=true);
  
  # so we read it in as a string, chopped of the first row,
  # and turned it into a float
  oned = float(oned_string[:,2:end])
  
  
  # median of each ROIvROI interaction over a sliding window
  # yeilds 264x264 matrix
  # put in one for each subject
  allCorr[:,:,i] = mapslices(nanmedian,rollingcors(oned,10),3)
  
  
  ## remove missing ROIs
  # count the number of finite numbers in each row (ROI)
  # then find those ROIs that have a count >1
  #   and ROI with all NANs will still correlate with itself at 1
  existingROIs=find(x->x>1,map(x->size(find(isfinite(allCorr[x,:,i])),1), 1:size(allCorr,1)))
  # NOTE this should be 244, but is currently 217
 
  # id visit pipeline corelation age
  allCorrMeta [i] =  corrMetaInfo(subj,visit,pipeline,age,existingROIs)

  # save data from any other program to open
  writedlm(joinpath(outdir,@sprintf("%s_%s_%s_%s.csv",subj,visit,age,pipeline) ), allCorr[:,:,i],',')

end
