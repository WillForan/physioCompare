% use brainviwer: http://www.nitrc.org/projects/bnv/
% create endge and node files for display
% settings are from manually playing with displays
%

% surface to use
bvsurface='/home/foranw/src/pkg/brainNetViewer/BrainNetViewer/Data/SurfTemplate/BrainMesh_ICBM152.nv';

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

%% create node file:
%   all nodes
nodefile=sprintf('txt/brainview/nodes-%d_all.node',length(nodes{1}) );
fid=fopen(nodefile, 'w');

k=1;
for i=1:length(nodes_cell{1})

  % rois are numbered from 264 but only use 244
  % -- so write othe original but use size 0
  while(k<nodes_cell{1}(i))
   k=k+1;
   fprintf(fid,'%d\t%d\t%d\t\t%d\t%d\t%s\n',0,0,0,0,0,'-');
  end
  k=k+1;
  % node color and size can be any numeric value to threshold/color/size by
  % maybe go back and make the color or size based on # of connections
  node_color=1;
  node_size=1;
  % label cannot have  spaces
  label=strrep(strtrim(nodes{4}{i}),' ' ,'_');
  fprintf(fid,'%d\t%d\t%d\t\t%d\t%d\t%s\n',nodes{1}(i),nodes{2}(i),nodes{3}(i),node_color,node_size,label);
end
fclose(fid);


%% create first edge file
%  wants a matrix corresponding to the node file
%  .. so we'll reconstruct from R output
%  we only get one value to show so pick which index
%  likely we want either ageXphysio.tval(11) or ageXpysio.val(10)
roi1IDX=2;
roi2IDX=3;
edgeValueIdx=10;
edgeTvalIdx=11;
sigthresh=2.86; % via MCMC in R
[idx,tval]=find(abs(roiroi_invage_cell{edgeTvalIdx})>sigthresh);
%edgesmat2=zeros(length(nodes_cell{1}))
%edgesmat2( roiroi_invage_cell{roi1IDX}(idx),  roiroi_invage_cell{roi2IDX}(idx) ) = roiroi_invage_cell{edgeValueIdx}(idx);
edgesmat=zeros(max(nodes_cell{1}));
for i=[idx']
 roi1=roiroi_invage_cell{2}(i);
 roi2=roiroi_invage_cell{3}(i);
 val=roiroi_invage_cell{edgeValueIdx}(i);
 edgesmat(roi1,roi2) = val;
end

%write out
edgefilename=sprintf('txt/brainview/edges-%d-%.3fsignificant.edge',length(nodes{1}),sigthresh);
dlmwrite(edgefilename,edgesmat,'\t');

%% Draw Brain
% BrainNet_MapCfg(bvsurface)
% blue-red_allnodes.mat is saved from playing by hand
BrainNet_MapCfg(bvsurface,nodefile,edgefilename,'txt/brainview/blue-red_allnodes.mat','imgs/wholebrain/allsignchanges.png')
