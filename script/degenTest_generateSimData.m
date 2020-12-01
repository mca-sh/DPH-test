function degenTest_generateSimData(pname)
% degenTest_generateSimData(pname)
%
% Controls MASH-FRET's interface to generate synthetic time traces from preset files stored in folder `pname`
% Simulated trace files are exported in a subfolder named after the preset file
% /!\ MASH-FRET must be open and the corresponding figure must be the last one selected!
% /!\ All simulation parameters that are not defined by presets must be set prior running the script
%
% example:
% degenTest_generateSimData('C:\Users\mimi\Documents\MyDataFolder\degenerated_test\testdata');

if pname(end)~=filesep
    pname = [pname,filesep];
end

% get handle to MASH-FRET's figure
h_fig = gcf;
h = guidata(h_fig);
prev_mute = h.mute_actions;
h.mute_actions = true;
guidata(h_fig,h);

% list all preset files
flist = dir([pname,'*.mat']);
F = size(flist,1);
nb = 0;
titer = [];
td = 0;
for f = 1:F
    tid = tic;
    if td>0
        tleft = (F-f+1)*td;
        hrs = fix(tleft/3600);
        mns = fix((tleft-hrs*3600)/60);
        sec = round(tleft-hrs*3600-mns*60);
        nb = dispProgress(sprintf(['Simulate data. Process file %i/%i: %s',...
            '\nremaining time: %i:%i:%i'],f,F,flist(f,1).name,hrs,mns,sec),...
            nb);
    else
        nb = dispProgress(sprintf(['Simulate data. Process file %i/%i: %s',...
            '\nremaining time: estimating..'],f,F,flist(f,1).name),nb);
    end
    
    % remove previous preset file
    if strcmp(h.pushbutton_simRemPrm.Enable,'on')
        pushbutton_simRemPrm_Callback(h.pushbutton_simRemPrm,[],h_fig);
    end
    
    % import presets
    pushbutton_simImpPrm_Callback({pname,flist(f,1).name},[],h_fig);
    
    % generate and export data
    [~,name,~] = fileparts(flist(f,1).name);
    pname_out = [pname,name,filesep];
    if ~exist(pname_out,'dir')
        mkdir(pname_out);
    end
    pushbutton_startSim_Callback(h.pushbutton_startSim,[],h_fig);
    pushbutton_exportSim_Callback({pname_out,name},[],h_fig);
    
    titer = cat(2,titer,toc(tid));
    td = mean(titer);
end

h = guidata(h_fig);
h.mute_actions = prev_mute;
guidata(h_fig,h);

disp('Routine completed!');
