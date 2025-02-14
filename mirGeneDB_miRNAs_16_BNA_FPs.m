% Load all mature miRNAs from MirGeneDB fasta file
miRNAs = fasta_read('homo sapiens mature miRNAs mirGeneDB 3_0.fas');
% Create NucleicAcid array containing all miRNA sequences & names; convert to RNA (‘rN’)
seqs = NucleicAcid(miRNAs(:,2),'name',miRNAs(:,1)).toRNA; 
% Mask first 12 nucleotides
seqs = seqs.applyMask('------------nnnnnnnnnnnnnnnnnnnnnnnn'); 

% Specify 16 probe target sequences
probe_targets = {'ATCG';'TCAT';'GGCT';'TCAA';'GGAC';'GAAG';'CCTC';'GCAA';'TGGC';'ACCG';'GTTG';'GTAT';'GTCC';'TAGT';'CTGC';'TGTA'};
% Create NucleicAcid array containing LNA versions of probes complementary to all 16 probe target sequences
probes = NucleicAcid(probe_targets).reverseComplement.toLNA;

% Hybridize 559 miRNAs to 16 probes, creating a 559 x 16 array of NucleicAcidPairs
pairs = seqs*probes;

% Calculate Tms of all target-probe pairs
Tms = pairs.longestDuplex.estimateTm;

% Show interaction of target 200 with probe 9
pairs(200,9).longestDuplex.print

% Plot histogram of all deltaG0s
hist([pairs.longestDuplex.dG0]/1000,-15:0.1:5);

% Show heat map of deltaGs for all probe/target pairs
dG0s = reshape([pairs.longestDuplex.dG0],size(pairs))/(-1000);
imshow(imresize(dG0s',[128,1118],'Nearest'),[0 10]); colormap('hot');
ylabel('Probe'); xlabel('miRNA'); c = colorbar; c.Label.String = '-dG0 (kcal/mol)';