function process_solver_logs(logFile, outputFile)
% process_solver_logs A MATLAB script to extract solver performance data.
% This script reads a log file, finds 'FGMRES iteration' and 
% 'The system scalling measure is' values for each system ID, and writes them to a CSV file.
%
% Inputs:
%   logFile: The path to the input log file (e.g., 'hybrid_solver_output.txt').
%   outputFile: The path to the output CSV file.

% Open the log file for reading
fid_log = fopen(logFile, 'r');
if fid_log == -1
    error('Could not open log file: %s', logFile);
end

% Open the output CSV file for writing
fid_csv = fopen(outputFile, 'w');
if fid_csv == -1
    % Close the log file before throwing an error
    fclose(fid_log); 
    error('Could not create output file: %s', outputFile);
end

% === CSV HEADER: Now includes only System ID, FGMRES Iterations, and Scaling Measure ===
fprintf(fid_csv, 'System_ID,FGMRES_Iterations,System_Scaling_Measure\n');

% Initialize a map to store the results for each system ID
% The struct now only stores 'iter' and 'scaling_measure'
resultsMap = containers.Map('KeyType', 'double', 'ValueType', 'any');

% Read the log file line by line
currentSystemID = -1;
line = fgetl(fid_log);
while ischar(line)

    % Find System ID to group data (e.g., Processing System 1 (ID: 02))
    systemID_match = regexp(line, 'Processing System \d+ \(ID:\s*(\d+)\)', 'tokens', 'once');
    if ~isempty(systemID_match)
        currentSystemID = str2double(systemID_match{1});
        % Initialize the map entry for the current system ID
        if ~isKey(resultsMap, currentSystemID)
            % Initialize all fields with 'N/A'
            resultsMap(currentSystemID) = struct('iter', 'N/A', 'scaling_measure', 'N/A');
        end
    end

    % === Find the System Scaling Measure ===
    % Pattern captures the number after "The system scalling measure is "
    scaling_pattern = 'The system scalling measure is\s*([-+]?[\d.]+(?:[eE][-+]?\d+)?)';
    scaling_match = regexp(line, scaling_pattern, 'tokens', 'once');
    
    if ~isempty(scaling_match) && currentSystemID ~= -1
        currentResult = resultsMap(currentSystemID);
        % Store the raw string value (e.g., '5.5649728722494856e+16')
        currentResult.scaling_measure = scaling_match{1};
        resultsMap(currentSystemID) = currentResult;
    end
    
    % Find the FGMRES Iteration count
    % Pattern looks for "iter: X" inside the FGMRES line
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

% Iterate through all possible System IDs (0 to 51, based on your loop range) 
% and write the results to the CSV file
for i = 0:19
    iter_val = 'N/A';
    scaling_val = 'N/A'; 
    
    if isKey(resultsMap, i)
        foundResult = resultsMap(i);
        iter_val = foundResult.iter;
        scaling_val = foundResult.scaling_measure;
    end
    
    % Output format: System_ID, FGMRES_Iterations, System_Scaling_Measure
    fprintf(fid_csv, '%d,%s,%s\n', i, iter_val, scaling_val);
end

% Close the output CSV file
fclose(fid_csv);

end
