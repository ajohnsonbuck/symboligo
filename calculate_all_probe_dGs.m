% Find deltaG for all probes binding to all miRNA targets in a defined list

% NEED TO INCORPORATE MISMATCHES INTO CODE, INCLUDING TERMINAL MISMATCHES

T = 37; % temp in Celsius

mask = '-----------nnnnnnnnnnnnnnnnnnnn'; % only g12-end
% mask = '------------nnnnnnnnnnnnnnnnnnn'; % only g13-end

targets = walter_lab_miRNAs(); % load miRNA sequences into array
targets = targets.applyMask(mask); % apply mask

% probe_targets = {'ATCG','TCAT', 'GGCT', 'TCAA', 'GGAC', 'GAAG', 'CCTC', 'GCAA', 'TGGC', 'ACCG', 'GTTG', 'GTAT', 'GTCC', 'TAGT', 'CTGC', 'TGTA'}; %2025-01-29 98.8% unambiguous
probe_targets = {'UGGC','GUUG','AUCG'};

for n = 1:length(probe_targets)
    probes(n) = NucleicAcid(probe_targets{n}).reverseComplement.toLNA;
end

for m = 1:numel(targets)
    for n = 1:numel(probes)
        dG(m,n) = NucleicAcidPair(targets(m),probes(n)).longestDuplex.estimateDeltaG('temperature',T);
    end
end

% imshow(-dG/max(max(-dG)),'InitialMagnification',2000);

dG = dG/1000;
dG = round(dG,2);

for n = 1:numel(probes)
    column_names{1,n} = probes(n).BareString;
end
for n = 1:numel(targets)
    row_names{n,1} = targets(n).Name;
end
uitable("ColumnName",column_names,"RowName",row_names,"Data",dG,'Units','normalized','Position',[0.05 0.05 0.9 0.9]);