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

% default
t_exp = 0.2; % bin time (0.2,0.1)
Lmax = 2000; % maximum trace length (2000, 4000)
t_bleach = 56; % bleaching time constant (56, none)

if pname(end)~=filesep
    pname = [pname,filesep];
end

% get handle to MASH-FRET's figure
h_fig = gcf;
h = guidata(h_fig);
prev_mute = h.mute_actions;
h.mute_actions = true;
guidata(h_fig,h);

% set up main parameters
h.edit_length.String = num2str(Lmax);
edit_length_Callback(h.edit_length,[],h_fig);
h.edit_simRate.String = num2str(1/t_exp);
edit_simRate_Callback(h.edit_simRate,[],h_fig);
h.checkbox_simBleach.Value = t_bleach>0;
checkbox_simBleach_Callback(h.checkbox_simBleach,[],h_fig);
h.edit_simBleach.String = num2str(t_bleach);
edit_simBleach_Callback(h.edit_simBleach,[],h_fig);

% list all preset files
flist = dir([pname,'*.mat']);
F = size(flist,1);
titer = [];
td = 0;
for f = 1:F
    tid = tic;
    if td>0
        tleft = (F-f+1)*td;
        hrs = fix(tleft/3600);
        mns = fix((tleft-hrs*3600)/60);
        sec = round(tleft-hrs*3600-mns*60);
        fprintf(['Simulate data. Process file %i/%i: %s\nremaining time: ',...
            '%i:%i:%i\n'],f,F,flist(f,1).name,hrs,mns,sec);
    else
        fprintf(['Simulate data. Process file %i/%i: %s\nremaining time: ',...
            'estimating..'],f,F,flist(f,1).name);
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
    
    % save effective model parameters
    h = guidata(h_fig);
    expT = 1/h.param.sim.rate;
    discr = h.results.sim.dat_id{5};
    J = h.param.sim.nbStates;
    N = numel(discr);
    ini_prob = zeros(1,J);
    Ntrs = zeros(J);
    pop = zeros(J,1);
    for n = 1:N
        dt = getDtFromDiscr(discr{n},expT);
        ini_prob(dt(1,2)) = ini_prob(dt(1,2))+1;
        for j1 = 1:J
            pop(j1) = pop(j1) + sum(dt(dt(:,2)==j1,1)); % seconds
            for j2 = 1:J
                if j1==j2
                    continue
                end
                Ntrs(j1,j2) = Ntrs(j1,j2) + ...
                    sum(dt(:,2)==j1 & dt(:,3)==j2);
            end
        end
    end
    trans_rates = Ntrs./repmat(pop,1,J);
    pop = (pop/sum(pop))';
    ini_prob = ini_prob/sum(ini_prob);
    save([pname,name,'_eff.mat'],'trans_rates','ini_prob','pop','-mat');
    
    titer = cat(2,titer,toc(tid));
    td = mean(titer);
end

h = guidata(h_fig);
h.mute_actions = prev_mute;
guidata(h_fig,h);

disp('Routine completed!');
