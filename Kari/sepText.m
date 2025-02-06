%% sepText.m
% Updated 10/2/2024 by KGB
% This separates out individual subject data when its all smushed into one
% file by MEDPC. Goes from one "Start Date" to another "Start Date" and
% deletes any comments that may be present because my med matlab importer
% cant read comments and i dont have time to fix that right now. Saves each
% .txt file named as Subject and then whatever is in the Subject field for
% that subject
clear all
close all

% Find the correct file in the current directory
% Currently assumes the file has GONAD in the title. IF it doesn't, updated
% as needed with whatever starts the filename in the line below
files = dir('GONAD*'); % UPDATE FROM GONAD IF NEEDED
if isempty(files)
    error('Not found in directory');
end

% Open the GONAD file
inputFile = fullfile(files(1).folder, files(1).name);
fid = fopen(inputFile, 'r');

% Initialize variables
currentSubjectData = {};
subjectName = '';
isNewSubject = false;

% Read the file line by line
while ~feof(fid)
    line = fgetl(fid);
    
    % Skip lines starting with "File:"
    if startsWith(line, 'File:')
        continue; 
    end
    
    % Check for new subject by looking for "Start Date" in the file
    if contains(line, 'Start Date')
        % If there is already subject data, save it to a file
        if ~isempty(currentSubjectData)
            % Remove comments and write to a file
            currentSubjectData = regexprep(currentSubjectData, '/.*', ''); % Remove comments
            subjectFileName = regexprep(subjectName, '[\\/:*?"<>|]', ''); % Clean the subject name for the filename
            subjectFilePath = fullfile(files(1).folder, [subjectFileName '.txt']);
            fidSubject = fopen(subjectFilePath, 'w');
            fprintf(fidSubject, '%s\n', currentSubjectData{:});
            fclose(fidSubject);
        end
        % Reset for new subject
        currentSubjectData = {};
        subjectName = ''; % Reset subject name
        isNewSubject = true; 
        continue;
    end
    % Capture the Subject line
    if startsWith(line, 'Subject:')
        subjectName = line; 
    end
    % Store the current line if it is not a comment
    if ~startsWith(line, '\')
        currentSubjectData{end+1} = line; 
    end
end

% Save the last subject if it exists
if ~isempty(currentSubjectData)
    currentSubjectData = regexprep(currentSubjectData, '/.*', ''); % Remove comments
    subjectFileName = regexprep(subjectName, '[\\/:*?"<>|]', ''); % Clean the subject name for the file
    subjectFilePath = fullfile(files(1).folder, [subjectFileName '.txt']);
    fidSubject = fopen(subjectFilePath, 'w');
    fprintf(fidSubject, '%s\n', currentSubjectData{:});
    fclose(fidSubject);
end

fclose(fid);

