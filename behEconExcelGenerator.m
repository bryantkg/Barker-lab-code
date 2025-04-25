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

% Loop through all subjects in allOut
for i = 1:length(allOut)
    % Extract current animal data
    currentStruct = allOut{i};
    subNum = currentStruct.Subject;
    
    % Extract lever presses per block/bin (I)        
    I = currentStruct.I(currentStruct.I ~= 0);        
    
    % Create matrix with 1-10 in column 1, values of I column 2
    binsI = [(1:10)', I'];
    
    % Write to excel file
    writecell([{"Bin", "Lever_press"}; num2cell(binsI)], sprintf('day1_%d.xlsx', subNum));%%EDIT TO CHANGE DAY NUMBER

end