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

% list all preset files
flist = dir([pname,'*.mat']);
F = size(flist,1);
for f = 1:F
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
end
