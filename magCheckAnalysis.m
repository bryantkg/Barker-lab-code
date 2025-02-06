%% magCheckAnalysis
% Updated 9/9/24 by KGB
% Pulled from Binay's original code and my (KGB) rewrite to further reduce 
% the need to explicitly enter any information, including subject number
% TO RUN THE CODE:
%   1. Save this .m file in a folder with the text files you wish to run.
%      Currently, this does not include the ability to pull date information
%      So do NOT include overlapping animal subjects. It will still run, but
%      you won't be able to discern what days are which.
%   2. Update the filename for your CSV on line 105 (where endFilename is)
%   3. Hit Run
% This will give you a .csv file with you subject numbers in the first
% column and the percent Mag Checking in the second column



% Clear and close out old stuff open in matlab
clear all
close all
%% 
%import and organize every file within a selcted folder  
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
all_out{i} = out;%variable all_out contains structure of every subject's data 
end
clearvars -except all_out

%% Initialize result storage for subject numbers and percentages
percentMagCheck = [];

for i = 1:length(all_out)
    % Extract current animal data
    currentStruct = all_out{i};
    
    % Remove zeros and pull relevant stamps (most of the arrays have a 0 at the beginning and a bunch at the end)
    % UPDATED 9/9/24 for Mark's programs
    % C = lever press
    % K = magazine entry
    % E = reinforcer delivery
    % subNum = subject number assumed to be in 'Subjet' field in the txt
    % file
    timestamps_C = currentStruct.C(currentStruct.C ~= 0);
    timestamps_K = currentStruct.K(currentStruct.K ~= 0);
    timestamps_E = currentStruct.E(currentStruct.E ~= 0);
    subNum = currentStruct.Subject;
    
    % Initialize counters
    levFollowedByMag = 0;
    levFollowedByLev = 0;
    
    for j = 1:length(timestamps_C)
        % Find the first Mag or Lev timestamp that comes after the current
        % Lev press
        nextMag = find(timestamps_K > timestamps_C(j), 1, 'first');
        nextLev = find(timestamps_C > timestamps_C(j), 1, 'first');
        
        % Compare the timing of the next event (either Mag or Lev)
        if ~isempty(nextMag) && (isempty(nextLev) || timestamps_K(nextMag) < timestamps_C(nextLev))
            % Mag comes next
            levFollowedByMag = levFollowedByMag + 1;
        elseif ~isempty(nextLev)
            % Lev comes next
            levFollowedByLev = levFollowedByLev + 1;
        end
    end
    
    % Calculate percentage of lever presses followed by magazine entries
    totalLevs = levFollowedByMag + levFollowedByLev;
    if totalLevs > 0
        percentLevFollowedByMag = (levFollowedByMag / totalLevs) * 100;
    else
        percentLevFollowedByMag = 0;
    end
    
    % Store the subject number and percentage in the percentMagCheck array
    percentMagCheck = [percentMagCheck; subNum, percentLevFollowedByMag];
end

%% Write the results to a CSV file which can be opened in Excel
endFilename = 'CHANGEFILENAMEHERE.csv';  % Replace with a filename of your choice

data = num2cell(percentMagCheck);
header = {'Animal ID', 'Percent Mag Checking'};
writecell([header; data], endFilename);

disp(['Results saved to ', endFilename]);