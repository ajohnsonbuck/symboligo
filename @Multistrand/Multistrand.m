classdef Multistrand
    properties
        Sequences = {Strand(); Strand()}; % Cell array of two Strand objects
        Duplexes = {}; % Cell array of Duplex objects describing one or more duplexes formed by the pair. By default, the first is the longest.
    end
    methods
        function objArray = Multistrand(varargin) % Constructor
            args = varargin;
            if length(args) == 1
                if isa(args{1},'Strand')
                    objArray(1,numel(args{1})) = Multistrand();
                    for n = 1:numel(args{1})
                        objArray(n).Sequences{1} = args{1}(n);
                    end
                elseif isa(args{1},'string') || isa(args{1},'char') || isa(args{1},'cell')
                    objArray(1).Sequences{1} = Strand(args{1});
                else
                    error('Input must be one or two Strand objects, chars, strings, or sequences');
                end
                for n = 1:numel(objArray)
                    objArray(n).Sequences{2} = objArray(n).Sequences{1}.reverseComplement; % Create reverse complement
                    if ~isempty(objArray(n).Sequences{1}.Name)
                        objArray(n).Sequences{2}.Name = [objArray(n).Sequences{1}.Name,'_reverseComplement'];
                    end
                end
            elseif length(args) == 2
                for n = 1:2
                    if isa(args{n},'Strand')
                        for p = 1:numel(args{1})
                            objArray(p).Sequences{n} = args{n}(p);
                        end
                    elseif isa(args{n},'string') || isa(args{n},'char') || isa(args{n},'cell')
                        objArray(1).Sequences{n} = Strand(args{n});
                    else
                        error('Input must be one or two Strand objects, chars, strings, or sequences');
                    end
                end
            end
            if numel(objArray) > 100
                wb1 = waitbar(0,'Creating multi-strand objects and calculating duplexes...');
            end
            for n = 1:numel(objArray)
                if numel(objArray) > 100 && mod(n,100)==0
                waitbar(n/numel(objArray),wb1,['Created multi-strand object ',num2str(n),' of ',num2str(numel(objArray))]);
                end
                if sum(contains(objArray(n).Sequences{2}.Sequence,'r'))<sum(contains(objArray(n).Sequences{1}.Sequence,'r'))
                    objArray(n).Sequences = flipud(objArray(n).Sequences); % If either sequence has RNA, ensure Sequence 2 has more RNA residues
                end
                if sum(contains(objArray(n).Sequences{2}.Sequence,'+'))>sum(contains(objArray(n).Sequences{1}.Sequence,'+'))
                    objArray(n).Sequences = flipud(objArray(n).Sequences); % If either sequence has LNA, ensure Sequence 1 has more LNA residues
                end
                if sum(contains(objArray(n).Sequences{2}.Sequence,'b'))>sum(contains(objArray(n).Sequences{1}.Sequence,'b'))
                    objArray(n).Sequences = flipud(objArray(n).Sequences); % If either sequence has BNA, ensure Sequence 1 has more BNA residues
                end
                if ~isempty(objArray(n).Sequences{1}.String)
                    objArray(n) = findLongestDuplex(objArray(n));
                end
            end
        end
        function a = findLongestDuplex(a) % Find duplex with largest number of base pairs
            objArray = a;
            for m = 1:numel(objArray)
                objArray(m) = applyMask(objArray(m));
                % Create schema with padding (empty cells) for all possible registers
                schema = cell(2,objArray(m).Sequences{2}.len + (objArray(m).Sequences{1}.len-1)*2);
                % schema(2,objArray(m).Sequences{1}.len:objArray(m).Sequences{1}.len+objArray(m).Sequences{2}.len-1) = objArray(m).Sequences{2}.reverse.bareSequence; % Reverse of bare version of first sequence
                encodedSchema = schema; encodedSchema(:)={1}; % Initialize with 1 (code for empty position)
                encodedSchema(2,objArray(m).Sequences{1}.len:objArray(m).Sequences{1}.len+objArray(m).Sequences{2}.len-1) = Multistrand.encodeSequence(objArray(m).Sequences{2}.reverse.bareSequence); % Encoded bare version of first sequence
                seq1 = Multistrand.encodeSequence(objArray(m).Sequences{1}.bareSequence); % encoded first sequence to be slid across second sequence and compared
                nbest = objArray(m).Sequences{1}.len;
                score_best = 0; % highest complementarity score
                % Determine register of schema with most base pairs
                for n=1:size(schema,2)-objArray(m).Sequences{1}.len+1
                    encodedSchema(1,:) = {1}; % Empty first row
                    encodedSchema(1,n:n+objArray(m).Sequences{1}.len-1) = seq1; % place encoded Sequence{1} into first row of encodedSchema at position n
                    score = Multistrand.scoreBasePairs(encodedSchema); % score base pairs of encodedSchema
                    if score > score_best
                        score_best = score;
                        nbest = n;
                    end
                end
                % Reconstruct schema with largest number of base pairs
                schema = cell(2,objArray(m).Sequences{2}.len + (objArray(m).Sequences{1}.len-1)*2);
                schema(2,objArray(m).Sequences{1}.len:objArray(m).Sequences{1}.len+objArray(m).Sequences{2}.len-1) = objArray(m).Sequences{2}.reverse().Sequence;
                schema(1,nbest:nbest+objArray(m).Sequences{1}.len-1) = objArray(m).Sequences{1}.Sequence;
                % Trim schema of any padding
                ind = any(~cellfun(@isempty,schema),1);
                startpos = find(ind,1,'first');
                endpos = find(ind,1,'last');
                schema = schema(:, startpos:endpos); % trim
                schema(cellfun(@isempty,schema))={''}; % Replace empty cell elements with empty char
                % Create duplex object and place in original Multistrand array
                a(m).Duplexes{1} = Duplex(schema,'Sequences',objArray(m).Sequences);
            end
        end
        function duplex = longestDuplex(objArray)
            for n = 1:numel(objArray) 
                duplex(n) = objArray(n).Duplexes{1};
            end
        end
        function list(obj) % List nucleic acid sequences in pair as strings
            for n = 1:2
                fprintf(1,'Sequence %d: %s\n',n,obj.Sequences{n}.String);
            end
        end
        function Tm = estimateTm(objArray,varargin)
            args = varargin;
            Tm = zeros(numel(objArray),1);
            for n = 1:numel(objArray)
                duplex = objArray(n).longestDuplex();
                if ~isempty(varargin)
                    Tm(n) = duplex.estimateTm(args{:});
                else
                    Tm(n) = duplex.estimateTm();
                end
            end
        end
        function objArray = applyMask(objArray)
            for m = 1:numel(objArray)
                for n = 1:numel(objArray(m).Sequences)
                    mask = objArray(m).Sequences{n}.Mask;
                    if isempty(mask)
                        mask = repmat('n',1,objArray(m).Sequences{n}.len);
                    end
                    str1 = objArray(m).Sequences{n}.String;
                    for p = 1:objArray(m).Sequences{n}.len
                        if strcmp(mask(p),'-')
                            objArray(m).Sequences{n}.Sequence{p}='-';
                        end
                    end
                    objArray(m).Sequences{n} = objArray(m).Sequences{n}.fromSequence;
                    objArray(m).Sequences{n}.UnmaskedString = str1;
                end
            end
        end
        function print(objArray)
            for m = 1:numel(objArray)
                for n = 1:numel(objArray(m).Sequences)
                    fprintf(1,'\n Sequence %d: %s',n,objArray(m).Sequences{n}.Name)
                    fprintf(1,[char("\n5'-"),objArray(m).Sequences{n}.String,char("-3'\n")]);
                end
            end
            fprintf(1,'\n');
        end
    end
    methods (Static)
        function score = scoreBasePairs(encodedSchema) 
            persistent scoreMat
            if isempty(scoreMat)
                scoreMat = [0,	0,	0,	0,	0,	0;... % Rows and cols are: (empty), A, C, G, T, U; Score: G-C = 6, A-U/T = 4, G-U = 3, G-T = 2
                            0,	0,	0,	0,	4,	4;...
                            0,	0,	0,	6,	0,	0;...
                            0,	0,	6,	0,	2,	3;...
                            0,	4,	0,	2,	0,	0;...
                            0,	4,	0,	3,	0,	0];
                scoreMat = single(scoreMat);
            end
            score = 0;
            for n = 1:width(encodedSchema)
                try
                score = score + scoreMat(encodedSchema{1,n},encodedSchema{2,n});
                catch
                    pause;
                end
            end
        end
        function seq = encodeSequence(seq)
            seq(cellfun(@isempty,seq))={1}; % Mark all empty cells as 1
            seq(strcmp(seq,'-'))={1}; % Mark all masked positions as 1
            % Encode other positions
            seq(strcmp(seq,'A'))={2};
            seq(strcmp(seq,'C'))={3};
            seq(strcmp(seq,'G'))={4};
            seq(strcmp(seq,'T'))={5};
            seq(strcmp(seq,'U'))={6};
        end
    end
end