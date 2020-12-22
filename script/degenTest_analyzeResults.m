function degenTest_analyzeResults(pname)
% degenTest_analyzeResults(pname)
%
% Read results of analysis and evaluate the performance by comparing to the ground truth.
% Ground truth files are stored in `pname` and results in subfolders named after the preset files.
%
% example: 
% degenTest_analyzeResults('C:\Users\mimi\Documents\MyDataFolder\degenerated_test\testdata');

% default
rgb_red = [255,120,120];
rgb_orange = [255,213,111];
rgb_green = [162,255,162];

if pname(end)~=filesep
    pname = [pname,filesep];
end

% get all subfolders
dlist = dir(pname);
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
pathids = zeros(1,D);
k0 = cell(1,D);
k = k0;
FRET0 = k0;
FRET = k0;
simdat = k0;
pop0 = k0;
for d = 1:D
    if ~exist([pname,dlist(d,1).name,filesep,dlist(d,1).name,'_res.mat'],'file')
        continue
    end
    
    % collect ground truth
    GT = load([pname,dlist(d,1).name,'_eff.mat'],'-mat');
    k0{d} = GT.trans_rates(:,:,1);
    pop0{d} = GT.pop;
    clear('GT');
    GT = load([pname,dlist(d,1).name,'.mat'],'-mat');
    FRET0{d} = GT.FRET(:,1,1)';
    clear('GT');
    
    % collect analysis results
    res = load([pname,dlist(d,1).name,filesep,dlist(d,1).name,'_res.mat'],...
        '-mat');
    FRET{d} = sort(res.FRET,'ascend');
    res.trans_rates(~~eye(size(res.trans_rates))) = 0;
    res.trans_rates_err(~~repmat(eye(size(res.trans_rates)),[1,1,2])) = 0;
    k{d} = cat(3,res.trans_rates,res.trans_rates_err);
    simdat{d} = res.simdat;
    clear('res');
    
    % sort according to FRET value
    [FRET0{d},ord0] = sort(FRET0{d});
    k0_ord = k0{d};
    for j1 = 1:numel(FRET0{d}) 
        for j2 = 1:numel(FRET0{d})
            k0_ord(j1,j2) = k0{d}(ord0(j1),ord0(j2));
        end
    end
    pop0{d} = pop0{d}(ord0);
    k0{d} = k0_ord;
    [FRET{d},ord] = sort(FRET{d});
    
    k_ord = k{d};
    for j1 = 1:numel(FRET{d})
        for j2 = 1:numel(FRET{d})
            k_ord(j1,j2,:) = k{d}(ord(j1),ord(j2),:);
        end
    end
    k{d} = k_ord;
    dt_ord = simdat{d}.dt;
    for j = 1:numel(FRET{d})
        dt_ord(simdat{d}.dt(:,3)==ord(j),3) = j;
        dt_ord(simdat{d}.dt(:,4)==ord(j),4) = j;
    end
    simdat{d}.dt = dt_ord;
    
    % sort according to lifetime
    r0 = sum(k0{d},2)';
    [r0,ord0] = sort(r0);
    for j1 = 1:numel(r0) 
        for j2 = 1:numel(r0)
            k0_ord(j1,j2) = k0{d}(ord0(j1),ord0(j2));
        end
    end
    k0{d} = k0_ord;
    pop0{d} = pop0{d}(ord0);
    FRET0{d} = FRET0{d}(ord0);
    
    r = sum(k{d}(:,:,1),2)';
    [r,ord] = sort(r);
    for j1 = 1:numel(r)
        for j2 = 1:numel(r)
            k_ord(j1,j2,:) = k{d}(ord(j1),ord(j2),:);
        end
    end
    k{d} = k_ord;
    FRET{d} = FRET{d}(ord);
    dt_ord = simdat{d}.dt;
    for j = 1:numel(FRET{d})
        dt_ord(simdat{d}.dt(:,3)==ord(j),3) = j;
        dt_ord(simdat{d}.dt(:,4)==ord(j),4) = j;
    end
    simdat{d}.dt = dt_ord;
    
    % store state degeneracy
    vals = unique(FRET0{d});
    nDegen0(d,:) = [numel(find(FRET0{d}==vals(1))),...
        numel(find(FRET0{d}==vals(2)))];
    vals = unique(FRET{d});
    nDegen(d,:) = [numel(find(FRET{d}==vals(1))),...
        numel(find(FRET{d}==vals(2)))];
    
    % store transition path index
    lbl = dlist(d,1).name((length('presets_1-1-')+1):end);
    pathids(d) = str2num(strrep(lbl,'-','.'));
end
excl = pathids==0;
pathids(excl) = [];
nDegen0(excl,:) = [];
nDegen(excl,:) = [];
FRET0(excl) = [];
FRET(excl) = [];
k0(excl) = [];
k(excl) = [];
simdat(excl) = [];
pop0(excl) = [];

% calculate performance
degen = unique(nDegen0,'rows','sorted');
Dgn = size(degen,1);
perf = cell(1,Dgn);
rates = perf;
states = perf;
pthids_dgn = perf;
simdat_dgn = perf;
pop_dgn = perf;
for dgn = 1:Dgn
    pths = find(nDegen0(:,1)==degen(dgn,1) & nDegen0(:,2)==degen(dgn,2))';
    [pthids_dgn{dgn},ord] = sort(pathids(pths),'ascend');
    nPth = numel(pthids_dgn{dgn});
    perf{dgn} = zeros(1,nPth);
    rates{dgn} = cell(2,nPth);
    states{dgn} = cell(2,nPth);
    simdat_dgn{dgn} = cell(1,nPth);
    pop_dgn{dgn} = cell(1,nPth);
    pths = pths(ord);
    for pth = 1:nPth
        if isequal(nDegen0(pths(pth),:),nDegen(pths(pth),:))
            if isequal(~~k0{pths(pth)},~~k{pths(pth)}(:,:,1))
                perf{dgn}(pth) = 2;
            else
                perf{dgn}(pth) = 1;
            end
        end
        rates{dgn}{1,pth} = k0{pths(pth)};
        rates{dgn}{2,pth} = k{pths(pth)};
        states{dgn}{1,pth} = FRET0{pths(pth)};
        states{dgn}{2,pth} = FRET{pths(pth)};
        simdat_dgn{dgn}{pth} = simdat{pths(pth)};
        pop_dgn{dgn}{pth} = pop0{pths(pth)};
    end
end

% build figure and show performance
h_fig2 = buildDegenTestFig(degen);
gd = guidata(h_fig2);
gd.perf = perf;
gd.rates = rates;
gd.states = states;
gd.pthids = pthids_dgn;
gd.simdat = simdat_dgn;
gd.pop0 = pop_dgn;
gd.rgb_red = rgb_red;
gd.rgb_green = rgb_green;
gd.rgb_orange = rgb_orange;
guidata(h_fig2,gd);

% plot left axes
for dgn = 1:Dgn
    nPth = numel(gd.pthids{dgn});
    b = bar(gd.axes_perf(dgn),1,ones(nPth,1),'stacked');
    for pth = 1:nPth
        switch perf{dgn}(pth)
            case 0
                b(pth).FaceColor = rgb_red/255; % red
            case 1
                b(pth).FaceColor = rgb_orange/255; % orange
            case 2
                b(pth).FaceColor = rgb_green/255; % green
        end
    end
    gd.axes_perf(dgn).YLim = [0,nPth];
    gd.axes_perf(dgn).XLim = [0.5,1.5];
    gd.axes_perf(dgn).XTick = 1;
    gd.axes_perf(dgn).XTickLabel = {sprintf('%i%i',degen(dgn,:))};
end

% update listbox
degenTest_popup_degeneracy_Callback(gd.popup_degeneracy,[],h_fig2);

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

% collect model and sort parameters
dgn = gd.popup_degeneracy.Value;
pth = gd.listbox_paths.Value;
k0 = gd.rates{dgn}{1,pth};
k = gd.rates{dgn}{2,pth}(:,:,1);
FRET0 = gd.states{dgn}{1,pth};
FRET = gd.states{dgn}{2,pth};

% draw reference diagramm
drawDiagram(gd.axes_diagramGT,FRET0,k0,0,gd.pop0{dgn}{pth});
gd.axes_diagramGT.Visible = 'on';

% calculate exp. state rel. pop
J = numel(FRET);
pop = zeros(1,J);
dt = gd.simdat{dgn}{pth}.dt;
dtSum = sum(dt(:,1));
for j = 1:J
    pop(j) = sum(dt(dt(:,3)==j,1))/dtSum;
end

% draw experimental diagram
drawDiagram(gd.axes_diagram,FRET,k,0,pop);
gd.axes_diagram.Visible = 'on';


function h_fig = buildDegenTestFig(degen)

% defaults
mg = 5;
mgttl = 20;
hpop = 22;
htxt = 14;
wFig = 800;
str0 = 'degeneracy';
str1 = 'transition paths';
str_lst = {'Transition paths'};

% calculate dimensions
D = size(degen,1);
hFig = round(wFig/3);
wleft = round(wFig/3);
waxes1 = (wleft-mg)/D;
wlst = (wFig-wleft-4*mg)/6;
waxes2 = ((wFig-wleft-4*mg)-wlst)/2;
hlst = (hFig-2*mg)-2*htxt-hpop-mg;
haxes = hFig-2*mg-mgttl;

gd = struct();

% figure
h_fig = figure('units','pixels','position',[0,0,wFig,hFig],'name',...
    'Performance evaluation','numbertitle','off','menubar','none');
gd.figure_testDPH = h_fig;

% left axes
x = mg;
y = mg;
for d = 1:D
    gd.axes_perf(d) = axes('parent',h_fig,'units','pixels','position',...
        [x,y,waxes1,haxes]);
    pos = getRealPosAxes([x,y,waxes1,haxes],...
        get(gd.axes_perf(d),'tightinset'),'traces');
    set(gd.axes_perf(d),'position',pos);
    x = x+waxes1;
end

% popup menu
x = wleft + mg;
y = hFig-mg-htxt;
gd.text_degeneracy = uicontrol('style','text','parent',h_fig,'units',...
    'pixels','position',[x,y,wlst,htxt],'string',str0);

y = y-hpop;
str_pop = cell(1,D);
for d = 1:D
    str_pop{d} = sprintf('%i%i',degen(d,:));
end
gd.popup_degeneracy = uicontrol('style','popup','parent',h_fig,'units',...
    'pixels','position',[x,y,wlst,hpop],'string',str_pop,'callback',...
    {@degenTest_popup_degeneracy_Callback,h_fig});

% list
y = y-mg-htxt;
gd.text_transpath = uicontrol('style','text','parent',h_fig,'units',...
    'pixels','position',[x,y,wlst,htxt],'string',str1);

y = y-hlst;
gd.listbox_paths = uicontrol('style','listbox','parent',h_fig,'units',...
    'pixels','position',[x,y,wlst,hlst],'string',str_lst,'min',0,'max',1,...
    'callback',{@degenTest_listbox_paths_Callback,h_fig});

% right axes
x = x+wlst+mg;
y = mg;
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
    switch perf{dgn}(pth)
        case 0
            rgb_str = sprintf('rgb(%d,%i,%i)',gd.rgb_red);
        case 1
            rgb_str = sprintf('rgb(%i,%i,%i)',gd.rgb_orange);
        case 2
            rgb_str = sprintf('rgb(%i,%i,%i)',gd.rgb_green);
    end
    str_lst{pth} = sprintf(['<html><span style= "background-color: ',...
        rgb_str,';">%.1f</span></html>'],gd.pthids{dgn}(pth));
end
gd.listbox_paths.Value = 1;
gd.listbox_paths.String = str_lst;

% update right axes
ud_degenTestDiagrams(h_fig);


function degenTest_listbox_paths_Callback(obj,evd,h_fig)
gd = guidata(h_fig);
perf = gd.perf;
dgn = gd.popup_degeneracy.Value;
nPth = numel(perf{dgn});

if obj.Value<1
    obj.Value = 1;
end
if obj.Value>nPth
    obj.Value = nPth;
end

% update right axes
ud_degenTestDiagrams(h_fig);

