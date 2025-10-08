function process_solver_logs(logFile, outputFile)
% process_solver_logs A MATLAB script to extract solver performance data.
% This script reads a log file, finds 'Growth Factor' and
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

% === CHANGE 1: Update the CSV header ===
fprintf(fid_csv, 'System_ID,Growth_Factor,FGMRES_Iterations\n');

% Initialize a map to store the results for each system ID
% The struct is updated to store 'gfactor' instead of 'rcond'
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
            % Initialize with 'N/A' for Growth Factor and Iterations
            resultsMap(currentSystemID) = struct('gfactor', 'N/A', 'iter', 'N/A');
        end
    end

    % === CHANGE 2: Find the Growth Factor (Handling scientific notation and 'inf') ===
    % The pattern captures the value after "The growth factor is computed as "
    % It captures either scientific notation (with optional sign) or 'inf'
    gf_pattern = 'The growth factor is computed as\s*([-+]?[\d.]+(?:[eE][-+]?\d+)?|inf)';
    gf_match = regexp(line, gf_pattern, 'tokens', 'once');

    if ~isempty(gf_match) && currentSystemID ~= -1
        currentResult = resultsMap(currentSystemID);
        
        % The extracted string value
        valueStr = gf_match{1};
        
        % Check for 'inf' and store the string representation
        if strcmpi(valueStr, 'inf')
            currentResult.gfactor = 'inf';
        else
            % Store the raw string value (e.g., '1.2345678901234567e+00')
            currentResult.gfactor = valueStr;
        end
        
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
% The loop range is fixed from 0 to 18 (19 systems total)
for i = 0:18
    gfactor_val = 'N/A';
    iter_val = 'N/A';
    
    if isKey(resultsMap, i)
        foundResult = resultsMap(i);
        % === CHANGE 3: Extract gfactor_val instead of rcond_val ===
        gfactor_val = foundResult.gfactor;
        iter_val = foundResult.iter;
    end
    
    % Write the final line to the CSV file (System_ID, Growth_Factor, FGMRES_Iterations)
    fprintf(fid_csv, '%d,%s,%s\n', i, gfactor_val, iter_val);
end

% Close the output CSV file
fclose(fid_csv);

end
