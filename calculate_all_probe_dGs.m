% Find deltaG0 for all probes binding to all miRNA targets in a defined list

% NEED TO INCORPORATE MISMATCHES INTO CODE, INCLUDING TERMINAL MISMATCHES

mask = '-----------nnnnnnnnnnnnnnnnnnnn'; % only g12-end
% mask = '------------nnnnnnnnnnnnnnnnnnn'; % only g13-end

targets = walter_lab_miRNAs(); % load miRNA sequences into array
targets = targets.applyMask(mask); % apply mask

% probe_targets = {'ATCG','TCAT', 'GGCT', 'TCAA', 'GGAC', 'GAAG', 'CCTC', 'GCAA', 'TGGC', 'ACCG', 'GTTG', 'GTAT', 'GTCC', 'TAGT', 'CTGC', 'TGTA'}; %2025-01-29 98.8% unambiguous
probe_targets = {'UGGC'; 'GUUG';'AUCG'};
probe_names = {'BNA_FP1'; 'BNA_FP2'; 'BNA_FP3'};

probes = NucleicAcid(probe_targets,'name',probe_names).reverseComplement('keepName').toLNA; % Generate set of LNA probes, which are reverse complements of the probe_targets sequences

pairs = targets*probes; % Hybridize all targets to all probes to create a pair array
dG = [pairs.longestDuplex.dG0]; % Estimate deltaG of longest duplex for each pair
dG = reshape(dG,size(pairs)); % Reshape output to size of pair array

dG = dG/1000;
dG = round(dG,2);

for n = 1:numel(probes)
    column_names{1,n} = probes(n).bareString;
end
for n = 1:numel(targets)
    row_names{n,1} = targets(n).Name;
end
uitable("ColumnName",column_names,"RowName",row_names,"Data",dG,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);