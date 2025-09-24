function process_solver_logs(logFile, outputFile)
% process_solver_logs A MATLAB script to extract solver performance data.
% This script reads a log file, finds 'Reciprocal Condition Number' and
% 'FGMRES iteration' values for each system ID, and writes them to a CSV file.
%
% Inputs:
%   logFile: The path to the input log file.
%   outputFile: The path to the output CSV file.

% Open the log file for reading
fid_log = fopen(logFile, 'r');
if fid_log == -1
    error('Could not open log file: %s', logFile);
end

% Open the output CSV file for writing
fid_csv = fopen(outputFile, 'w');
if fid_csv == -1
    error('Could not create output file: %s', outputFile);
end

% Write the new header to the CSV file
fprintf(fid_csv, 'System_ID,Reciprocal_Condition_Number,FGMRES_Iterations\n');

% Initialize a map to store the results for each system ID
% The key is the system ID, and the value is a struct with the performance data
resultsMap = containers.Map('KeyType', 'double', 'ValueType', 'any');

% Read the log file line by line
currentSystemID = -1;
line = fgetl(fid_log);
while ischar(line)
    
    % Find System ID to group data
    systemID_match = regexp(line, 'Processing System (\d+)', 'tokens', 'once');
    if ~isempty(systemID_match)
        currentSystemID = str2double(systemID_match{1});
        % Initialize the map entry for the current system ID
        if ~isKey(resultsMap, currentSystemID)
            resultsMap(currentSystemID) = struct('rcond', 'N/A', 'iter', 'N/A');
        end
    end
    
    % Find the Reciprocal Condition Number
    rcond_match = regexp(line, 'Reciprocal Condition Number of System:\s*([-+]?[\d.]+(?:[eE][-+]?\d+)?)', 'tokens', 'once');
    if ~isempty(rcond_match) && currentSystemID ~= -1
        currentResult = resultsMap(currentSystemID);
        currentResult.rcond = rcond_match{1};
        resultsMap(currentSystemID) = currentResult;
    end
    
    % Find the FGMRES Iteration count
    iter_match = regexp(line, 'FGMRES:.*iter:\s*(\d+)', 'tokens', 'once');
    if ~isempty(iter_match) && currentSystemID ~= -1
        currentResult = resultsMap(currentSystemID);
        currentResult.iter = iter_match{1};
        resultsMap(currentSystemID) = currentResult;
    end
    
    line = fgetl(fid_log);
end

% Close the log file
fclose(fid_log);

% Iterate through all System IDs and write the results to the CSV file
% The loop range is fixed from 0 to 14 as per the original script.
for i = 0:51
    rcond_val = 'N/A';
    iter_val = 'N/A';
    
    if isKey(resultsMap, i)
        foundResult = resultsMap(i);
        rcond_val = foundResult.rcond;
        iter_val = foundResult.iter;
    end
    
    % Write the final line to the CSV file
    fprintf(fid_csv, '%d,%s,%s\n', i, rcond_val, iter_val);
end

% Close the output CSV file
fclose(fid_csv);

end
