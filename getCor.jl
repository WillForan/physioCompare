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

# settings
basedir = "txt/bb244Stats_mni/"
outdir =  "txt/ROIROI_median"
# where in the file name are bits stored
typebyfilename = { "physio"=> r"mni_AP_redo.1D", "nophysio"=>r"mni_nophysio.1D" }

## read in ages and make dictionary
subjinfo = readdlm("IDSexDOBVisitAge.txt",'	', String,ignore_invalid_chars=true);
subjage = Dict{String,Float64}()
for i=1:size(subjinfo,1)
 subjage[ subjinfo[i,1] ] = float(subjinfo[i,5])
end



## get all the files we want to work on
# only get people who have both
#files = map (x -> "txt/bb244Stats_mni/$x", readdlm("txt/subjINpipelines.txt",'	',String,has_header=true)[1][:,1])

files = readdir(basedir)
# remove files that don't match the filter
filter!(x ->  any(map(r->ismatch(r,x),collect(values(typebyfilename)))), files)

#files=files[1:2] # testing

# allCorMeta has type and

allCorrMeta = Array(corrMetaInfo,size(files,1) )
allCorr =  zeros(264,264,size(files,1) )



for i in 1:length(files)
   f=files[i];
   println(f)
   fileparts = split(f,"_")
  # this visit is wrongly attributed for skynet parts
  (subj, visit) = fileparts

  ## get age at visit, set to zero if we dont know it
  println(" get age")
  #age = subjage[subj]
  age  = getkey(subjage,subj,0)


  # parse out which pipeline the file is coming from
  if ismatch(typebyfilename["nophysio"],f )
    pipeline="physio"
  elseif ismatch(typebyfilename["physio"],f)
    pipeline="nophysio"
  else
    pipeline
  end

  savefile=joinpath(outdir,@sprintf("%s_%s_%s.csv",subj,pipeline,age) )
  if(isfile(savefile))
    println(" reusing saved file")
    allCorr[:,:,i] = readdlm(savefile,',',Float64)
  else
    ## get roistats output, get median with sliding window, save to file
    # this is the output of 3dROIStats
    # it's funny
    oned_string = readdlm(joinpath(basedir,f),'	', String,ignore_invalid_chars=true);
    
    # so we read it in as a string, chopped of the first row,
    # and turned it into a float
    oned = float(oned_string[:,2:end])
    
    
    # median of each ROIvROI interaction over a sliding window
    # yeilds 264x264 matrix
    # put in one for each subject
    println(" get median")
    allCorr[:,:,i] = mapslices(nanmedian,rollingcors(oned,10),3)

    # save data from any other program to open
    println(" save output")
    writedlm(savefile, allCorr[:,:,i],',')
  end
  
  ## remove missing ROIs
  # count the number of finite numbers in each row (ROI)
  # then find those ROIs that have a count >1
  #   and ROI with all NANs will still correlate with itself at 1
  println(" count ROIs")
  existingROIs=find(x->x>1,map(x->size(find(isfinite(allCorr[x,:,i])),1), 1:size(allCorr,1)))
  # NOTE this should be 244, but is currently 217
 
  # id visit pipeline corelation age
  println(" record metainfo")
  allCorrMeta[i] =  corrMetaInfo(subj,visit,pipeline,age,existingROIs)



end

if size(allCor,1) != size(allCor,2) 
 println("ERROR: ROI column and row are not the same size!!!")
end

## long format: ROI1,ROI2,cor,value,age,pipeline,subj
i=1
numROIs=size(allCor,1)
numVisitsAndPipes=size(allCor,3)
longfmt=Array(Any, binomial(numROIs,2) * numVisitsAndPipes , 6)

for p=1:numVisitsAndPipes # each pipeline of each visit
 for r=1:numROIs          # each roi (row)
   for c=(r+1):numROIs    # each roi (column) -- dont want e.g r=1,c=1 and r=10 c=8 will already been hit by r=8 c=10
    longfmt[i,:]= [ r c allCorr[r,c,p] allCorrMeta[p].age allCorrMeta[p].pipeline allCorrMeta[p].id]
    i+=1
   end
 end
end

writedlm("ROIROIcorAgeSubjPipe.csv",longfmt)

