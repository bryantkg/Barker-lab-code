%%Cumulative Lever Press code - KGB updated 1/30/25
% This is to quantify cumulative lever presses and
% should work with any number of subjects

% All you should need to update each run is what your over all session 
% length (line 47), your bin size (line 48, in seconds), and 
% what you want your csv export to be called at the end (line 90)

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
allOut{i} = out;%variable allOut contains structure of every subject's data 
end
clearvars -except allOut

%% Calculate cumulative lever presses
% Things to potentially edit:
durationInSeconds = 7200;  % UPDATE TO LENGTH OF YOUR SESSION
binSize = 60;  % UPDATE TO YOUR BIN SIZE IN SECONDS (60 = 1 MIN, 300 = 5MIN, ETC)

% Things no to edit
numBins = durationInSeconds / binSize; 
cumulLP = {};  

% Loop through all subjects in allOut
for i = 1:length(allOut)
    % Extract current animal data
    currentStruct = allOut{i};
    subNum = currentStruct.Subject;
    
    % Extract lever presses (B), magazine entries (E), and reinforcer delivery (I)
    B = round(currentStruct.B(currentStruct.B ~= 0));  
    E = currentStruct.E(currentStruct.E ~= 0);         
    I = currentStruct.I(currentStruct.I ~= 0);        

    subjectCumulLP = zeros(1, numBins);

    % Calculate lever presses within your time window
    for j = 1:length(B)
        pressTime = B(j);
        binIndex = floor(pressTime / binSize) + 1; % Convert time to bin index
        if binIndex <= numBins
            subjectCumulLP(binIndex) = subjectCumulLP(binIndex) + 1;
        else
            break;
        end
    end

    % Compute cumulative press count for this subject
    cumulativeCount = 0;
    for j = 1:numBins
        cumulativeCount = cumulativeCount + subjectCumulLP(j);
        subjectCumulLP(j) = cumulativeCount;
    end

    % Store the cumulative data in an array with subject info
    cumulLP{end+1;1} = [subNum, subjectCumulLP]; 
end

% Export to a .csv
writematrix(cumulLP, 'CHANGEMETOWHATEVERYOUWANT.csv');% Update this to whatever filename you prefer
