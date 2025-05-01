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

percentMagCheck = [];

% Loop through all subjects in allOut
for i = 1:length(allOut)
    % Extract current animal data
    currentStruct = allOut{i};
    subNum = currentStruct.Subject;

    % Extract lever presses (B), magazine entries (E), and reinforcer delivery (I)
    B = round(currentStruct.B(currentStruct.B ~= 0));  
    E = currentStruct.E(currentStruct.E ~= 0);         
    I = currentStruct.I(currentStruct.I ~= 0);        

    allLev = numel(B);
    PRblock = [];
    cumPress = 0;

    % Construct the PR Blocks completed for this subject
    while true
        blockCount = 1 + 4 * (length(PRblock));
        if cumPress + blockCount > allLev
            break
        end
        PRblock(end+1) = blockCount;
        cumPress = cumPress + blockCount;
    end

    % Assign lever presses to respective blocks they occured in based on
    % lever press number and block number
    indyBlock = cell(1, numel(PRblock));
    startIDX = 1;
    for b = 1:numel(PRblock)
        endIDX = startIDX + PRblock(b) - 1;
        indyBlock{b} = B(startIDX:endIDX);
        startIDX = endIDX + 1;
    end

    % Initialize for subject
    percentLevFollowedByMag = nan(1, numel(indyBlock));

    for block = 1:numel(indyBlock)
        CurBlock = indyBlock{block};

        levFollowedByMag = 0;
        levFollowedByLev = 0;

        for j = 1:length(CurBlock)
            pressTime = CurBlock(j);

            
            nextMag = find(E > pressTime, 1, 'first');
            nextLev = find(B > pressTime, 1, 'first');

            if ~isempty(nextMag) && (isempty(nextLev) || E(nextMag) < B(nextLev))
                levFollowedByMag = levFollowedByMag + 1;
            elseif ~isempty(nextLev)
                levFollowedByLev = levFollowedByLev + 1;
            end
        end

        % Calculate percent magazine checking
        total = levFollowedByMag + levFollowedByLev;
        if total > 0
            percentLevFollowedByMag(block) = (levFollowedByMag / total) * 100;
        else
            percentLevFollowedByMag(block) = NaN;
        end
    end

    % Pad subject with NaNs if needed
    maxCols = max(size(percentMagCheck, 2), numel(percentLevFollowedByMag) + 1);
    subjectRow = nan(1, maxCols);
    subjectRow(1) = subNum;
    subjectRow(2:(numel(percentLevFollowedByMag)+1)) = percentLevFollowedByMag;

    % Pad matrix with NaNs if needed
    if isempty(percentMagCheck)
        percentMagCheck = subjectRow;
    else
        if size(percentMagCheck, 2) < maxCols
            percentMagCheck(:, end+1:maxCols) = NaN;
        end
        if numel(subjectRow) < size(percentMagCheck,2)
            subjectRow(end+1:size(percentMagCheck,2)) = NaN;
        end
        percentMagCheck = [percentMagCheck; subjectRow];
    end
end

%% Write the results to a CSV file which can be opened in Excel
endFilename = 'CHANGEFILENAMEHERE.csv';  % Replace with a filename of your choice

data = num2cell(percentMagCheck);
header = {'Animal ID', 'Percent Mag Checking'};
writecell([header; data], endFilename);

disp(['Results saved to ', endFilename]);
