clear
clc
%% import and organize every txt file within a selcted folder  
datapath=uigetdir([],'Select Data Directory'); 
d=dir(fullfile(datapath,'*.txt'));
for i=1:numel(d)
  txt_file = fullfile(datapath,d(i).name);
    [fid,msg] = fopen(txt_file,'rt');
    assert(fid>=3,msg)
    out = struct();
    while ~feof(fid)
	pos = ftell(fid);
	str = strtrim(fgetl(fid));
	if numel(str)
		spl = regexp(str,':','once','split');
		spl = strtrim(spl);
		if isnan(str2double(spl{1}))
			fnm = strrep(spl{1},' ','');
			val = str2double(spl{2});
			if isnan(val)
				out.(fnm) = spl{2};
			else
				out.(fnm) = val;
			end
		else
			fseek(fid,pos,'bof');
			vec = fscanf(fid,'%*d:%f%f%f%f%f',[1,Inf]);
			out.(fnm) = vec;
            end
        end
    end
fclose(fid);
allOut{i} = out;%variable allOut contains structure of every subject's data 
end
clearvars -except allOut

%% Calculate latencies and probabilities
latencies = [];
probabilities_1_followed_by_1 = [];
probabilities_2_followed_by_2 = [];
probabilities_2_followed_by_1 = []; % Updated to store probabilities for low followed by high
subjectNumbers = [];
blockProbabilities_1_followed_by_1 = []; % Initialize array to store block-wise probabilities for 1 followed by 1
blockProbabilities_2_followed_by_2 = []; % Initialize array to store block-wise probabilities for 2 followed by 2
blockProbabilities_2_followed_by_1 = []; % Updated to store block-wise probabilities for low followed by high
blockLabels = []; % Initialize array to store block labels

% Iterate through each animal/structure in allOut
for i = 1:length(allOut)
    % Extract current animal data
    currentStruct = allOut{i};
    
    % Remove zeros (most of the arrays have a 0 at the beginning and a bunch
    % at the end.
    % C = left lever press
    % D = right lever press
    % G = magazine entry
    timestamps_C = currentStruct.C(currentStruct.C ~= 0);
    timestamps_D = currentStruct.D(currentStruct.D ~= 0);
    timestamps_G = currentStruct.G(currentStruct.G ~= 0);
    combinedTimestamps = sort([timestamps_C timestamps_D]); % combine lever presses together

    structureLatencies = [];
    for j = 1:length(combinedTimestamps)
        % Find the closest mag. ent. prior to current lever press
        closestTimestamp_G = max(timestamps_G(timestamps_G < combinedTimestamps(j)));
        
        % Calculate latency from that mag. ent. to lever press
        latency = combinedTimestamps(j) - closestTimestamp_G;
        
        % Save
        structureLatencies = [structureLatencies latency];
    end
    
    % Calculate average latency for current animal and save with animal #
    avgLatency = mean(structureLatencies);
    subjectNumber = currentStruct.Subject;
    latencies = [latencies; avgLatency];
    subjectNumbers = [subjectNumbers; subjectNumber];
    
    
    % S = high (1) or low (2) choice during free choice trials
    sequenceArray = currentStruct.S(currentStruct.S ~= 0);
    
    % Count # of 1 followed by 1 and 1 followed by 2
    % i.e., high followed by high vs. high followed by low
    count_1_followed_by_1 = sum(sequenceArray(1:end-1) == 1 & sequenceArray(2:end) == 1);
    count_1_followed_by_2 = sum(sequenceArray(1:end-1) == 1 & sequenceArray(2:end) == 2);
    
    % Count # of 2 followed by 2 and 2 followed by 1
    % i.e., low followed by low vs. low followed by high
    count_2_followed_by_2 = sum(sequenceArray(1:end-1) == 2 & sequenceArray(2:end) == 2);
    count_2_followed_by_1 = sum(sequenceArray(1:end-1) == 2 & sequenceArray(2:end) == 1);
    
    % Calculate probabilities for 1 followed by 1 (win-stay)
    if count_1_followed_by_1 + count_1_followed_by_2 > 0
        probability_1_followed_by_1 = count_1_followed_by_1 / (count_1_followed_by_1 + count_1_followed_by_2);
    else
        probability_1_followed_by_1 = NaN;
    end

    % Calculate probabilities for 2 followed by 1 (lose-shift)
    if count_2_followed_by_2 + count_2_followed_by_1 > 0
        probability_2_followed_by_1 = count_2_followed_by_1 / (count_2_followed_by_2 + count_2_followed_by_1);
    else
        probability_2_followed_by_1 = NaN;
    end
    
  % Save
    probabilities_1_followed_by_1 = [probabilities_1_followed_by_1; probability_1_followed_by_1];
    probabilities_2_followed_by_1 = [probabilities_2_followed_by_1; probability_2_followed_by_1];
    
    % Calculate block-wise probabilities for 1 followed by 1
    % and 2 followed by 1 (updated from 2 followed by 2)
    numBlocks = 5; % Assuming 5 blocks of 10 values each
    blockProbabilities_1_followed_by_1 = [blockProbabilities_1_followed_by_1; nan(1, numBlocks)]; % Initialize row for this animal's block probabilities
    blockProbabilities_2_followed_by_1 = [blockProbabilities_2_followed_by_1; nan(1, numBlocks)]; % Initialize row for this animal's block probabilities
    
    blockSize = length(sequenceArray) / numBlocks;
    for k = 1:numBlocks
        startIdx = (k - 1) * blockSize + 1;
        endIdx = k * blockSize;
        blockSeq = sequenceArray(startIdx:endIdx);
        count_1_followed_by_1_block = sum(blockSeq(1:end-1) == 1 & blockSeq(2:end) == 1);
        count_1_followed_by_2_block = sum(blockSeq(1:end-1) == 1 & blockSeq(2:end) == 2);
        count_2_followed_by_2_block = sum(blockSeq(1:end-1) == 2 & blockSeq(2:end) == 2);
        count_2_followed_by_1_block = sum(blockSeq(1:end-1) == 2 & blockSeq(2:end) == 1);
        if count_1_followed_by_1_block + count_1_followed_by_2_block > 0
            blockProbabilities_1_followed_by_1(end, k) = count_1_followed_by_1_block / (count_1_followed_by_1_block + count_1_followed_by_2_block);
        end
        if count_2_followed_by_2_block + count_2_followed_by_1_block > 0
            blockProbabilities_2_followed_by_1(end, k) = count_2_followed_by_1_block / (count_2_followed_by_2_block + count_2_followed_by_1_block); % Adjusted from count_2_followed_by_2_block to count_2_followed_by_1_block
        end
    end
    
    % Save block labels
    blockLabels = [blockLabels; (1:numBlocks)'];
end

% Initialize variables to store cumulative sums
cumulativeSums = []; % Array to store the final cumulative sums for each animal

for i = 1:length(allOut)
    % Extract current animal data
    currentStruct = allOut{i};
    
    % Extract block labels (W) and choice sequences (S)
    blockLabels_W = currentStruct.W(currentStruct.W ~= 0);
    sequenceArray_S = currentStruct.S(currentStruct.S ~= 0);
    
    % Find indices of reversals in W
    reversalIndices = find(diff(blockLabels_W) ~= 0);
    
    % Initialize an array to store cumulative sums for current animal
    animalCumulativeSums = [];
    
    for j = 1:length(reversalIndices)
        if reversalIndices(j) < length(blockLabels_W)
            % Determine the block number after the reversal
            postReversalBlockNumber = blockLabels_W(reversalIndices(j) + 1);
            
            % Determine the start and end indices for the sequence in S
            startIdx = (reversalIndices(j) + 1 - 1) * 10 + 1;
            endIdx = startIdx + 9;
            
            % Extract the relevant sequence from S
            relevantSequence = sequenceArray_S(startIdx:endIdx);
            
            % Compute the cumulative sum for the sequence
            cumulativeSum = cumsum(2 * (relevantSequence == 1) - 1); % 1 becomes +1, 2 becomes -1
            
            % Store the cumulative sum
            animalCumulativeSums = [animalCumulativeSums; cumulativeSum];
        end
    end
    
    % Average cumulative sums if there are multiple reversals for the animal
    if ~isempty(animalCumulativeSums)
        avgCumulativeSum = mean(animalCumulativeSums, 1);
        cumulativeSums = [cumulativeSums; avgCumulativeSum];
    end
end

% Output the cumulative sums
cumulativeSums

% Concatenate into one big array and save as a labelled table
% subjectDataArray = [subjectNumbers, latencies, probabilities_1_followed_by_1, probabilities_2_followed_by_2, probabilities_2_followed_by_1, blockProbabilities_1_followed_by_1, blockProbabilities_2_followed_by_2, blockProbabilities_2_followed_by_1];
% columnLabels = {'Subject #', 'Avg. Latency to Press', 'Probability of High followed by High', 'Probability of Low followed by High', ...
%     'Block 1 (High followed by High)', 'Block 2 (High followed by High)', 'Block 3 (High followed by High)', 'Block 4 (High followed by High)', 'Block 5 (High followed by High)', ...
%     'Block 1 (Low followed by High)', 'Block 2 (Low followed by High)', 'Block 3 (Low followed by High)', 'Block 4 (Low followed by High)', 'Block 5 (Low followed by High)'};
% subjectDataTable = array2table(subjectDataArray, 'VariableNames', columnLabels);

%Export as a .csv (which opens in excel)
%If you don't want to export as a .csv on a run, add a '%' to the front of
%writetable when you run this. Also, you can edit what the file name it
%will be that it exports to within the ' '. I have put subjectLatProbVGB.csv
%as a default to start/placeholder but feel free to update
%writetable(subjectDataTable,'subjectLatProbVGB.csv')

