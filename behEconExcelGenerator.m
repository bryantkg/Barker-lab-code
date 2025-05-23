%%Excel sheet generator for Behavioral Economics R code - KGB updated
%%4/25/25
% This is to extract binned lever presses from the "I" array and then
% export them with the first column being the number 1-10 and the second
% column being the corresponding values in the I array. It also titles
% these with Bin and Lever_press to be readable by the R code generated by
% Shanna Samels in the Espana lab

% All you should need to update each run is the day number at the bottom
% (if relevant). It will automatically populate the excel name with the
% subject number

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
    
    % Write to excel file and include Bin and Lever_press labels at the top
    writecell([{"Bin", "Lever_press"}; num2cell(binsI)], sprintf('day1_%d.xlsx', subNum));%%EDIT TO CHANGE DAY NUMBER

end