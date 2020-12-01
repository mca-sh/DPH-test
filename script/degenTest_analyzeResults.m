function degenTest_analyzeResults(pname)
% degenTest_analyzeResults(pname)
%
% Read results of analysis and evaluate the performance by comparing to the ground truth.
% Ground truth files are stored in `pname` and results in subfolders named after the preset files.

if pname(end)~=filesep
    pname = [pname,filesep];
end

% get all subfolders
dlist = dir([pname,'.txt']);
D = size(dlist,1);
excl = false(1,D);
for d = 1:D
    if ~dlist(d,1).isdir || strcmp(dlist(d,1).name,'.') || ...
            strcmp(dlist(d,1).name,'..')
        excl(d) = true;
    end
end
dlist(excl,:) = [];

D = size(dlist,1);
for d = 1:D
    GT = load([pname,dlist(d,1).name,'.mat'],'-mat');
    res = load([pname,dlist(d,1).name,filsep,dlist(d,1).name,'_res.mat'],...
        '-mat');
    states0 = sort(GT.FRET(:,1,1)','ascend');
    states = sort(res.FRET,'ascend');
end

