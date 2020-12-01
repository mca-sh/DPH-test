function degenTest_analyzeResults(pname)
% degenTest_analyzeResults(pname)
%
% Read results of analysis and evaluate the performance by comparing to the ground truth.
% Ground truth files are stored in `pname` and results in subfolders named after the preset files.


% default
rgb_red = [255, 80, 80]/255;
rgb_orange = [255,153,51]/255;
reg_green = [102, 255, 102]/255;

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
nDegen0 = zeros(D,2);
nDegen = nDegen0;
k0 = cell(1,D);
pathnb = zeros(1,D);
k = k0;
FRET0 = k0;
FRET = k0;
for d = 1:D
    % collect ground truth
    GT = load([pname,dlist(d,1).name,'.mat'],'-mat');
    FRET0{d} = sort(GT.FRET(:,1,1)','ascend');
    k0{d} = GT.trans_rates(:,:,1);
    clear('GT');
    
    % collect analysis results
    res = load([pname,dlist(d,1).name,filsep,dlist(d,1).name,'_res.mat'],...
        '-mat');
    FRET{d} = sort(res.FRET,'ascend');
    k{d} = cat(3,res.trans_rates,res.trans_rates_err);
    clear('res');
    
    % store state degeneracy
    vals = unique(FRET0{d});
    nDegen0(d,:) = [numel(find(FRET0{d}==vals(1))),...
        numel(find(FRET0{d}==vals(2)))];
    vals = unique(FRET{d});
    nDegen(d,:) = [numel(find(FRET{d}==vals(1))),...
        numel(find(FRET{d}==vals(2)))];
    
    % store transition path index
    pathnb(d) = str2num(dlist(d,1).name((length('presets_1-1-')+1):end));
end

% calculate performance
degen = unique(nDegen0,'rows','sorted');
Dgn = size(degen,1);
perf = cell(1,Dgn);
rates = perf;
states = perf;
for dgn = 1:Dgn
    pths = find(nDegen0(:,1)==degen(dgn,1) && nDegen0(:,2)==degen(dgn,2))';
    [~,ord] = sort(pathnb(pths),'ascend');
    nPth = numel(ord);
    perf{dgn} = zeros(1,nPth);
    rates{dgn} = cell(2,nPth);
    states{dgn} = cell(2,nPth);
    for pth = 1:nPth
        if isequal(nDegen0(ord(pth),:),nDegen(ord(pth),:))
            if isequal(~~k0{ord(pth)},~~k{ord(pth)}(:,:,1))
                perf{dgn}(pth) = 2;
            else
                perf{dgn}(pth) = 1;
            end
        end
        rates{dgn}{1,pth} = k0{ord(pth)};
        rates{dgn}{2,pth} = k{ord(pth)};
        states{dgn}{1,pth} = FRET0{ord(pth)};
        states{dgn}{2,pth} = FRET{ord(pth)};
    end
end

% build figure and show performance
h_fig2 = buildDegenTestFig(degen);
gd = guidata(h_fig2);
gd.perf = perf;
gd.rates = rates;
gd.states = states;
guidata(h_fig2,gd);

% plot left axes
for dgn = 1:Dgn
    b = bar(gd.axes_perf(dgn),(1:nPth)','stacked');
    switch perf{dgn}(pth)==0
        case 0
            b(pth).FaceColor = reg_green; % red
        case 1
            b(pth).FaceColor = rgb_orange; % orange
        case 2
            b(pth).FaceColor = rgb_red; % green
    end
end

% update right axes
ud_degenTestDiagrams(h_fig2);


function ud_degenTestDiagrams(h_fig)

gd = guidata(h_fig);

% clear axes
cla(gd.axes_diagramGT);
cla(gd.axes_diagram);

% clear arrows
if ~isempty(gd.axes_diagramGT.UserData)
    delete(gd.axes_diagramGT.UserData);
end
if ~isempty(gd.axes_diagram.UserData)
    delete(gd.axes_diagram.UserData);
end

% set titles
title(gd.axes_diagramGT,'GT');
title(gd.axes_diagram,'Analysis');

% draw new diagram
dgn = gd.popup_degeneracy.Value;
pth = gd.listbox_paths.Value;

k0 = gd.rates{dgn}{1,pth};
k = gd.rates{dgn}{2,pth}(:,:,1);
FRET0 = gd.states{dgn}{1,pth};
FRET = gd.states{dgn}{2,pth};
drawDiagram(gd.axes_diagramGT,FRET0,k0,1E-5);
drawDiagram(gd.axes_diagram,FRET,k,1E-5);


function h_fig = buildDegenTestFig(degen)

% defaults
mg = 5;
hpop = 22;
htxt = 14;
wFig = 800;
str_txt = 'degeneracy';
str_lst = {'Transition paths'};

% calculate dimensions
hFig = round(wFig/3);
waxes1 = round(wFig/3);
wlst = (wFig-waxes1-3*mg)/3;
waxes2 = ((wFig-waxes1-3*mg)-wlst)/2;
hlst = (hFig-2*mg)-htxt-hpop-mg;
haxes = hFig-2*mg;

gd = struct();

% figure
h_fig = figure('units','pixels','position',[0,0,wFig,hFig],'name',...
    'Performance evaluation','numbertitle','off','menubar','none');
gd.figure_testDPH = h_fig;

% left axes
D = size(degen,1);
for d = 1:D
    gd.axes_perf(d) = subplot(1,3*D,d);
end

% popup menu
x = (wFig/2) + mg;
y = hFig-mg-htxt;
gd.text_degeneracy = uicontrol('style','popup','parent',f_fig,'units',...
    'pixels','position',[x,y,wlst,htxt],'string',str_txt);

y = y-hpop;
str_pop = cell(1,D);
for d = 1:D
    str_pop{d} = sprintf('%i%i',degen(d,:));
end
gd.popup_degeneracy = uicontrol('style','popup','parent',f_fig,'units',...
    'pixels','position',[x,y,wlst,hpop],'string',str_pop,'callback',...
    {degenTest_popup_degeneracy_Callback,h_fig});

% list
y = y-mg-hlst;
gd.listbox_paths = uicontrol('style','listbox','parent',f_fig,'units',...
    'pixels','position',[x,y,wlst,hlst],'string',str_lst,'min',0,'max',1,...
    'callback',{degenTest_listbox_paths_Callback,h_fig});

% right axes
x = x+wlst+mg;
gd.axes_diagramGT = axes('parent',h_fig,'units','pixels','position',...
    [x,y,waxes2,haxes],'xtick',[],'ytick',[]);

x = x+waxes2+mg;
gd.axes_diagram = axes('parent',h_fig,'units','pixels','position',...
    [x,y,waxes2,haxes],'xtick',[],'ytick',[]);

guidata(h_fig,gd);

setProp(h_fig,'units','normalized');


function degenTest_popup_degeneracy_Callback(obj,evd,h_fig)
gd = guidata(h_fig);
perf = gd.perf;
dgn = obj.Value;
nPth = numel(perf{dgn});

% update listbox
str_lst = cell(1,nPth);
for pth = 1:nPth
    str_lst{pth} = sprintf('%i',pth);
end
gd.listbox_paths.Value = 1;
gd.listbox_paths.String = str_lst;

% update right axes
ud_degenTestFig(h_fig);


function degenTest_listbox_paths_Callback(obj,evd,h_fig)
gd = guidata(h_fig);
perf = gd.perf;
dgn = obj.Value;
nPth = numel(perf{dgn});

if obj.Value<1
    obj.Value = 1;
end
if obj.Value>nPth
    obj.Value = nPth;
end

% update right axes
ud_degenTestFig(h_fig);





