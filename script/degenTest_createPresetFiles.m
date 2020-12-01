function degenTest_createPresetFiles(Dmax,pname)
% degenTest_createPresetFiles(Dmax,pname)
%
% Generate preset files used in paper for 2 states and a maximum degeneracy complexity `Dmax`
% State lifetimes are evenly log-distributed
% Transition probabiltiies are randomly distributed.
% Initial state probabilities are identical for each state.
% Files are exported in folder `pname`
%
% example:
% degenTest_createPresetFiles(4,'C:\Users\mimi\Documents\MyDataFolder\degenerated_test\testdata');

% default
Jmax0 = 4; % maximum number of states (long to compute otherwise)
V = 2; % number of state values
vals = [0.2,0.7]; % state values
N = 250; % number of trajectories
wmin = 0.1; % minimum random

if pname(end)~=filesep
    pname = [pname,filesep];
end

% get all possible transition matrices
Jmax = min([Dmax*V,Jmax0]);
Jmin = V;
trans_mat = cell(1,Jmax);
for J = Jmin:Jmax
    trans_mat{J} = getTransSchemes(J);
end

for d1 = 1:Dmax
    degen{1} = 1:d1;
    for d2 = d1:Dmax
        degen{2} = (d1+1):(d1+d2);
        J = d1+d2;
        if J>Jmax
            continue
        end

        % exclude matrices where states are isolated
        nMat = size(trans_mat{J},3);
        incl = true(1,nMat);
        for m = 1:nMat
            if sum(all(trans_mat{J}(:,:,m)==0,2)' & ...
                    all(trans_mat{J}(:,:,m)==0,1))
                incl(m) = false;
            end
        end
        mat = trans_mat{J}(:,:,incl);
        
        % get FRET states
        FRET = repmat(...
            [repmat([vals(1),0],[d1,1]);repmat([vals(2),0],[d2,1])],[1,1,N]);
        
        % get state lifetimes
        tau = zeros(1,J);
        rd = logspace(-1,3,d1+2);
        tau(degen{1}) = rd(2:end-1);
        rd = logspace(-1,3,d2+2);
        tau(degen{2}) = rd(2:end-1);
        r = (1./tau)';
        
        % get intial probabiltiies
        ini_prob = repmat(ones(1,J)/J,[N,1]);
        
        nMat = size(mat,3);
        for m = 1:nMat
            % get transition rate coefficients
            w = wmin + rand(J);
            w(~mat(:,:,m)) = 0;
            w = w./repmat(sum(w,2),[1,J]);
            w(isnan(w)) = 0;
            trans_rates = repmat(w.*repmat(r,1,J),[1,1,N]);
            
            % save presets to file
            fname = sprintf('presets_%i-%i-%i.mat',d1,d2,m);
            save([pname,fname],'FRET','trans_rates','ini_prob','-mat');
            fprintf(['Presets for [%i,%i] complexity (scheme %i) saved to',...
                ' file: %s\n'],d1,d2,m,fname);
        end
    end
end
disp('process complete!');
