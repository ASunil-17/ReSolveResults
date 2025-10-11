function process_solver_logs(logFile, outputFile)
% process_solver_logs A MATLAB script to extract solver performance data.
% This script reads a log file, finds 'Growth Factor', 'FGMRES iteration', 
% and 'System Ill-Scaling Measure' values for each system ID, and writes them to a CSV file.
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

% === MODIFICATION 1: Update the CSV header to include the new metric ===
fprintf(fid_csv, 'System_ID,Growth_Factor,FGMRES_Iterations,Ill_Scaling_Measure\n');

% Initialize a map to store the results for each system ID
% The struct is updated to store 'scaling_measure'
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
            % Initialize all fields with 'N/A'
            resultsMap(currentSystemID) = struct('gfactor', 'N/A', 'iter', 'N/A', 'scaling_measure', 'N/A');
        end
    end

    % === MODIFICATION 2: Find the System Ill-Scaling Measure ===
    % The pattern captures the value after "The system scalling measure is "
    % It captures a number in scientific notation (e.g., 6.3159996758641396e+12)
    scaling_pattern = 'The system scalling measure is\s*([-+]?[\d.]+(?:[eE][-+]?\d+)?)';
    scaling_match = regexp(line, scaling_pattern, 'tokens', 'once');
    
    if ~isempty(scaling_match) && currentSystemID ~= -1
        currentResult = resultsMap(currentSystemID);
        % Store the raw string value (e.g., '6.3159996758641396e+12')
        currentResult.scaling_measure = scaling_match{1};
        resultsMap(currentSystemID) = currentResult;
    end
    
    % Find the Growth Factor (Handling scientific notation and 'inf')
    gf_pattern = 'The growth factor is computed as\s*([-+]?[\d.]+(?:[eE][-+]?\d+)?|inf)';
    gf_match = regexp(line, gf_pattern, 'tokens', 'once');

    if ~isempty(gf_match) && currentSystemID ~= -1
        currentResult = resultsMap(currentSystemID);
        
        valueStr = gf_match{1};
        
        if strcmpi(valueStr, 'inf')
            currentResult.gfactor = 'inf';
        else
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
% The loop range is fixed from 0 to 14
for i = 0:14
    gfactor_val = 'N/A';
    iter_val = 'N/A';
    scaling_val = 'N/A'; % Initialize the new variable
    
    if isKey(resultsMap, i)
        foundResult = resultsMap(i);
        gfactor_val = foundResult.gfactor;
        iter_val = foundResult.iter;
        % === MODIFICATION 3: Extract the scaling measure value ===
        scaling_val = foundResult.scaling_measure;
    end
    
    % === MODIFICATION 4: Write the new column to the CSV file ===
    % Output format: System_ID, Growth_Factor, FGMRES_Iterations, Ill_Scaling_Measure
    fprintf(fid_csv, '%d,%s,%s,%s\n', i, gfactor_val, iter_val, scaling_val);
end

% Close the output CSV file
fclose(fid_csv);

end
