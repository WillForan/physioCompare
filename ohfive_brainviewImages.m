% use brainviwer: http://www.nitrc.org/projects/bnv/
% create endge and node files for display
% settings are from manually playing with displays
%
function brainviews = ohfive_brainviewImages()
  brainviews=struct();
  %%% READ IN DATA
  % surface to use
  bvsurface='/home/foranw/src/pkg/brainNetViewer/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv';
  defaultmat='txt/brainview/blue-red_sizedNodes.mat';
  imgdir='imgs/wholebrain'
  % blue-red_allnodes.mat is saved from playing by hand
  
  %% READ IN ROIS (Nodes)
  %x y z number/name
  % nodes_raw=dlmread('txt/bb244_coordinate');
  % n x y z atlas r label '---' p
  fid=fopen('txt/labels_bb244_coordinate'); 
  nodes_cell=textscan(fid,'%d\t%d\t%d\t%d\t%s\t%f\t%s\t%s\t%d','delimiter', '\t');
  fclose(fid);
  nodes=nodes_cell([2:4,7]); % x y z label
  
  %% READ IN ROI-ROI models (Edges)
  % file is like:
  % "","ROI1","ROI2","intercept","intcpt.tval","pipe.slope","pipe.tval","age.slope","age.tval","ageXphysio.val","ageXphysio.tval","rtitle"
  % "1","3","6",0.15544953468286,5.9359232115814,-0.00180305479347789,-0.132013915003963,3.64779696275745,1.93210207033041,0.926530826760781,0.940960125401634,"Right Superior Orbital Gyrus    "
  %  ....
  
  fid=fopen('txt/ageeffAgeXphys-invage.csv');
  roiroi_invage_cell=textscan(fid,'"%d" "%d" "%d" %f %f %f %f %f %f %f %f %q','HeaderLines',1,'Delimiter',',');
  fclose(fid);
  


  %% Write node file with size and color equal
  nodefile=sprintf('txt/brainview/nodes-%d_all.node',length(nodes{1}) );
  writeNodeFile(nodefile,@(x) 1, @(x) 1);
  
  %%% Settings for brainview: allrois
  brainviews.('allrois').suf=bvsurface;
  brainviews.('allrois').mat='txt/brainview/blue-red_allnodes.mat';
  brainviews.('allrois').nod=nodefile;


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%  Signficant Edges
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %% get and write all signficant edges
  edgeValueIdx=10;
  edgeTvalIdx=11;
  sigthresh=2.58; % via MCMC in R, see 03_comp_perROIROI.R (used in clusterizeSubsets.R, highlyConnectedNodes.R, and truncateLM.R)
  [idx,tval]=find(abs(roiroi_invage_cell{edgeTvalIdx})>sigthresh);
  [edgesmat,roiCount] = getEdges(idx);

  %write out all edges
  edgefilename=sprintf('txt/brainview/edges-%d-%.3fsignificant.edge',length(nodes{1}),sigthresh);
  dlmwrite(edgefilename,edgesmat,'\t');
  
  
  %% Write node file with size and color indicating the number of sig changed connections
  nodeCountFilename=sprintf('txt/brainview/nodes-%d_all-withsize.node',length(nodes{1}) );
  roiCountFunc=@(i) roiCount(i);
  continuousNodes=writeNodeFile(nodeCountFilename,roiCountFunc,roiCountFunc);

  brainviews.('sigconnect').suf=bvsurface;
  brainviews.('sigconnect').mat=defaultmat;
  brainviews.('sigconnect').nod=nodeCountFilename;
  brainviews.('sigconnect').edg=edgefilename;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%  positve and negative signficant edges
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%POS changes: remove edges that are negative:
  %%NEG changes:  remove edges that are positive:
  % -- can do this with edge thresholding!!?
  for thresh=[-1 1]*sigthresh;
    if(thresh>0)
     threshfun=@(x) x>thresh;
     name='sigpos'
    else
     threshfun=@(x) x<thresh;
     name='signeg'
    end
    [idx,tval]=find(threshfun(roiroi_invage_cell{edgeTvalIdx}));
    [edgesmat,roiCount] = getEdges(idx);
    edgefilename=sprintf('txt/brainview/edges-%d_sigonedir%.3f.edge',length(nodes{1}),thresh);
    dlmwrite(edgefilename,edgesmat,'\t');

    nodeCountFilename=sprintf('txt/brainview/nodes-%d_%s-withsize.node',length(nodes{1}),name );
    roiCountFunc=@(i) roiCount(i);
    continuousNodes=writeNodeFile(nodeCountFilename,roiCountFunc,roiCountFunc);

    brainviews.(name).suf=bvsurface;
    brainviews.(name).mat=defaultmat;
    brainviews.(name).nod=nodeCountFilename;
    brainviews.(name).edg=edgefilename;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%% TOP 12 ROIS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  %% also write out edges for only the top nodes
  numberoftop=12;
  topedgesfilename=sprintf('txt/brainview/edges-%.3fsignficant-top%d.edge',sigthresh,numberoftop);
  % order by count
  [roiCount_sorted,rcidx ] =sort(roiCount,'descend');
  % get edges again, but only for connections within the top rois
  idx=find(all(ismember([ roiroi_invage_cell{2} roiroi_invage_cell{3} ], rcidx(1:numberoftop)),2))
  [edgesmat,roiCount] = getEdges(idx);
  dlmwrite(topedgesfilename,edgesmat,'\t');

  
  % change the number of nodes to match the edges 
  % by editing the settings (instead of the node file)
  load(defaultmat);
  EC.nod.draw_threshold=14;
  topmatfile=sprintf('txt/brainview/blue-red_top%d-nodes.mat',numberoftop);
  save(topmatfile,'EC')

  % show what we did
  fprintf('top %d value (roi#%d): %d==%d connections\n',numberoftop,rcidx(numberoftop),roiCount_sorted(numberoftop),roiCount(rcidx(numberoftop)) );
  fprintf('found %d edges that matches\n', length(idx))
  [rcidx(1:numberoftop) roiCount(rcidx(1:numberoftop)) roiCount_sorted(1:numberoftop)]

  %name=sprintf('top-%d', numberoftop);
  name='toprois';
  brainviews.(name).suf=bvsurface;
  brainviews.(name).mat=topmatfile;
  brainviews.(name).edg=topedgesfilename;
  brainviews.(name).nod=nodeCountFilename;




  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%  Devel ROIS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % first need to get devel rois
  develnodefile='txt/brainview/nodes-aprioriDevel.node';
  develedgefile='txt/brainview/edges-aprioriDevel.edge';
  fid=fopen('txt/develRois.txt');
  develRoisCell=textscan(fid,'%d %s');
  develRoisIdx=develRoisCell{1};
  fclose(fid);
  
  % only take indx where both roi1 and roi2 are members of the developmental (apriori) roi list
  idx=find(all(ismember([ roiroi_invage_cell{2} roiroi_invage_cell{3} ], develRoisIdx),2));
  fprintf('found %d edges that matches that\n', length(idx))
  [edgesmat,roiCountDevel] = getEdges(idx);
  % write files
  dlmwrite(develedgefile,edgesmat,'\t');
  %roi t values
  roi_tval=reshape(getfield(cell2mat(cellfun(@double,roiroi_invage_cell([2,3,11]),'UniformOutput',false)), {idx,[1,3,2,3]} )', 2,length(idx)*2)';
  numroi=max(nodes_cell{1})
  roi_tval=[roi_tval;[1:264;repmat(0,1,264) ]' ];
  % get min pval for each node 
  % invert so sig .01 --> 100 and bigger (for thresholding)
  minpval=@(i) arrayfun(@(x) 1/min(1 - tcdf(abs(roi_tval( find(roi_tval(:,1)==x), 2 )),110 )),i);
  % size thresh by existing in develRoisIdx
  writeNodeFile(develnodefile,@(i) any(ismember(i,develRoisIdx)), minpval);
  fprintf('min pvals\n');
  [double(develRoisIdx) 1./minpval(develRoisIdx) ]

  %% change up the display a bit
  load(defaultmat);
  % thresholding
  EC.nod.draw=2;            % use threshold 
  EC.nod.draw_threshold=2;  % DNE->0, pval(0)=.5 -> 1/.5 = 2. Must be bigger than 2
  % color
  EC.nod.color_threshold=99;%  below 100 is colored one way, above another
  %TODO: set either side of the threshold
  % size
  EC.nod.size=1;            % all the same size
  EC.nod.size_size=3;       % all nodes are size 3
  %% label
  EC.lbl=3;
  EC.lbl_threshold=99;
  EC.lbl_threshold_type=2;

  develmatfile='txt/brainview/blue-red_devel.mat';
  save(develmatfile,'EC')
  

  %brainviews.('aproriDevel').mat=develmatfile; % doesn't have colors yet
  brainviews.('aproriDevel').mat='txt/brainview/devel.mat'
  brainviews.('aproriDevel').edg=develedgefile;
  brainviews.('aproriDevel').nod=develnodefile;


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%  Draw results
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%

  for name=fieldnames(brainviews)'
   name=name{1};
   if(~isfield(brainviews.(name),'suf')),brainviews.(name).suf = bvsurface;  end
   if(~isfield(brainviews.(name),'mat')),brainviews.(name).mat = defaultmat; end
   if(~isfield(brainviews.(name),'png')),brainviews.(name).png = sprintf('%s/%s.png',imgdir,name); end
   disp(name)
   %% reset view on all mat files
   load(brainviews.(name).mat)
   EC.lot.view=1;
   EC.lot.view_direction=4; % custom
   EC.lot.view_az=-170;
   EC.lot.view_el=0;
   save(brainviews.(name).mat,'EC')
   %inputcell=getfield( struct2cell(brainviews.(name)), {':'});
   inputcell=struct2cell(brainviews.(name));
   fprintf('BrainNet_MapCfg(');fprintf(' ''%s'', ', inputcell{:});fprintf(')\n');

   %BrainNet_MapCfg( inputcell{:})
  end
  %BrainNet_MapCfg(bvsurface,nodefile,'txt/brainview/blue-red_allnodes.mat','imgs/wholebrain/allnodes.png')
  %BrainNet_MapCfg(bvsurface,nodeCountFilename,edgefilename,defaultmat,'imgs/wholebrain/allsignchanges-nodes.png')
  %BrainNet_MapCfg(bvsurface,nodeCountFilename,topedgesfilename,topmatfile,'imgs/wholebrain/allsignchanges-topnodes.png')
  %BrainNet_MapCfg(bvsurface,develnodefile,develedgefile,develmatfile,'imgs/wholebrain/apriori.png')
  
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%  Functions 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  
  %% create node file function
  % takes name of a file to save as, and functions for writting size and color both use roi# as input
  function continuousNodes = writeNodeFile(nodefile,colorfunction,sizefunction)
    continuousNodes=cell(max(nodes_cell{1}),1);
    outputstring='%d\t%d\t%d\t\t%.6f\t%.6f\t%s\n';
    fid=fopen(nodefile, 'w');
    k=1;
    for i=1:length(nodes_cell{1})
    
      % rois are numbered from 264 but only use 244
      % -- so write othe original but use size 0
      while(k<nodes_cell{1}(i))
       fprintf(fid,outputstring,0,0,0,0,0,'-');
       continuousNodes{k}= { 0,0,0,0,0,'-'};
       k=k+1;
      end
      % node color and size can be any numeric value to threshold/color/size by
      % maybe go back and make the color or size based on # of connections
      node_color=sizefunction(k);
      node_size=colorfunction(k);
      % label cannot have  spaces
      label=strrep(strtrim(nodes{4}{i}),' ' ,'');

      continuousNodes{k}= { nodes{1}(i),nodes{2}(i),nodes{3}(i),node_color,node_size,label };
      %fprintf(fid,'%d\t%d\t%d\t\t%d\t%d\t%s\n',continuousNodes(i));
      fprintf(fid,outputstring, nodes{1}(i),nodes{2}(i),nodes{3}(i),node_color,node_size,label );
      k=k+1;
    end
    fclose(fid);
  end
  
  %% create edge matrix and count rois the edges
  function [edgesmat, roiCount] = getEdges(idx)
    edgesmat=zeros(max(nodes_cell{1}));
    roiCount=zeros(max(nodes_cell{1}),1);
    %  wants a matrix corresponding to the node file
    %  .. so we'll reconstruct from R output
    roi1IDX=2;
    roi2IDX=3;
    
    %  we only get one value to show so pick which index
    %  likely we want either ageXphysio.tval(11) or ageXpysio.val(10)
    % we picked values to show, so only want those that are significant
    % this gives us the index of the columns (edges) that have significant  age by physiopipeline interaction
    for i=idx'
     roi1=roiroi_invage_cell{roi1IDX}(i);
     roi2=roiroi_invage_cell{roi2IDX}(i);
     val=roiroi_invage_cell{edgeValueIdx}(i);

     % increase node/roi counts
     roiCount(roi1)=roiCount(roi1)+1; roiCount(roi2)=roiCount(roi2)+1;
    
     edgesmat(roi1,roi2) = val;
    end
    % faster but broken?
    %edgesmat2=zeros(length(nodes_cell{1}))
    %edgesmat2( roiroi_invage_cell{roi1IDX}(idx),  roiroi_invage_cell{roi2IDX}(idx) ) = roiroi_invage_cell{edgeValueIdx}(idx);
  end
end 
