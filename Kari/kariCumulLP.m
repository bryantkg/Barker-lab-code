%% kariCumulLP
% Updated 10/2/24 by KGB
% Pulled from Binay's original code and my (KGB) rewrite to further reduce 
% the need to explicitly enter any information, including subject number
% TO RUN THE CODE:
%   1. Save this .m file in a folder with the text files you wish to run.
%      Currently, this does not include the ability to pull date information
%      So do NOT include overlapping animal subjects. It will still run, but
%      you won't be able to discern what days are which.
%   2. Update the filename for your CSV on line 120ish (where outputFileName is)
%   3. Hit Run
% This will give you a .csv file with you subject numbers in the first
% column, latencies in the second, and cumulLP from 3rd column on

% Clear and close out old stuff open in matlab
clear all
close all

% Run the file which makes them into separate txt files
% sepText.m;

% Import and organize every file within a selcted folder  
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
all_out{i} = out; % Variable all_out contains structure of every subject's data 
end
clearvars -except all_out
%% Calculate latency and cumulative responding and export as a .csv
% Currently just gets the presses from the first 20 minutes (1200s) and in
% 20s bins. Change either of these as needed in the next 2 lines - just be
% sure to keep it in seconds and not minutes
durationInSeconds = 1200; % 20 minutes in seconds
binSize = 20; % 20-second intervals
numBins = durationInSeconds / binSize; % Number of bins
cumulResponding = zeros(length(all_out), numBins); 
latencyToFirstPress = cell(length(all_out), 1); 
latencyResults = {}; 

% Iterate through each subject
for i = 1:length(all_out)
    currentStruct = all_out{i}; % Extract current animal data
    
    % Check if the structure has a 'Subject' field
    % Sometimes sepText creates random bits of text as txt files (like the
    % file name)
    % Updated for Kari's behavior 10/2/2024
    % E = lever press timestamp array
    % Note: Time stamps here are as a soft CR, so they need to be added to
    % get 'actual' time stamps
    if isfield(currentStruct, 'Subject')
        % Extract lever press timestamps and remove zeros
        timestamps_E = currentStruct.E(currentStruct.E ~= 0); 
        subNum = currentStruct.Subject; % Subject number
        
        % Convert subject number to a string (in case it's numeric)
        subNumStr = string(subNum); 
        
        % Latency to first press
        if ~isempty(timestamps_E)
            latencyToFirstPress{i} = timestamps_E(1); % First value in E
            
            % Convert to actual cumulative time: timestamps_E are delays between presses
            actualTimestamps = cumsum(timestamps_E); % Cumulative sum for actual timestamps
            
            % Cumulative responding for each bin based on actual timestamps
            for j = 1:length(actualTimestamps)
                binIndex = ceil(actualTimestamps(j) / binSize); 
                if binIndex <= numBins
                    cumulResponding(i, binIndex) = cumulResponding(i, binIndex) + 1; 
                end
            end
        end
        
        % Cumulative counts across bins
        cumulativeCount = 0; % Initialize cumulative count for this subject
        for j = 1:numBins
            cumulativeCount = cumulativeCount + cumulResponding(i, j); % update 
            cumulResponding(i, j) = cumulativeCount; % store
        end
        latencyResults = [latencyResults; {subNumStr, num2str(latencyToFirstPress{i})}]; 
    end
end

% Remove the first row from cumulResponding because its always empty/full
% of zeros
cumulResponding(1, :) = [];

% Combine into single matrix and label for export
outputData = [latencyResults, num2cell(cumulResponding)];
headers = [{'Subject', 'Latency'}, arrayfun(@(x) sprintf('Bin_%d', x), 1:numBins, 'UniformOutput', false)];

% Export to a .csv file (readable by excel)
outputFileName = 'INSERTNAMEHERE.csv'; % CHANGE THE NAME OF THE .CSV GENERATED HERE
fid = fopen(outputFileName, 'w');
fprintf(fid, '%s,', headers{1:end-1});
fprintf(fid, '%s\n', headers{end});
fclose(fid);

% Write the data 
fid = fopen(outputFileName, 'a'); 
for i = 1:size(outputData, 1)
    fprintf(fid, '%s,%s,', outputData{i, 1}, outputData{i, 2});
    fprintf(fid, '%d,', outputData{i, 3:end-1});
    fprintf(fid, '%d\n', outputData{i, end});
end
fclose(fid);
disp(['Data exported to ', outputFileName]);

%% Plot for funzies/to check everything looks normal
plot(cumulResponding')
xlabel('Time bins (20 minutes)')
ylabel('Cumulative Lever Presses')