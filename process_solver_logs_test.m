function process_solver_logs(logFile, outputFile)
% process_solver_logs A MATLAB script to extract solver error data.
% This script reads a log file, finds '2-norm of error:' values for each
% system ID, and writes them to a CSV file. It implements a specific rule
% for handling the error values.
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

% Write the header to the CSV file
fprintf(fid_csv, 'System_ID,2-norm of error #1,2-norm of error #2\n');

% Initialize a map to store the error values for each system ID
% The key is the system ID, and the value is a cell array of error values
errorsMap = containers.Map('KeyType', 'double', 'ValueType', 'any');

% Read the log file line by line
currentSystemID = -1;
line = fgetl(fid_log);
while ischar(line)
    
    % Find System ID to group errors
    systemID_match = regexp(line, 'Processing System (\d+)', 'tokens', 'once');
    if ~isempty(systemID_match)
        currentSystemID = str2double(systemID_match{1});
        if ~isKey(errorsMap, currentSystemID)
            errorsMap(currentSystemID) = {};
        end
    end
    
    % Find the 2-norm error value
    % This regex captures the floating-point number or scientific notation
    error_match = regexp(line, '2-norm of the error:\s*([-+]?[\d.]+(?:[eE][-+]?\d+)?)', 'tokens', 'once');
    if ~isempty(error_match) && currentSystemID ~= -1
        currentErrors = errorsMap(currentSystemID);
        currentErrors{end+1} = str2double(error_match{1});
        errorsMap(currentSystemID) = currentErrors;
    end
    
    line = fgetl(fid_log);
end

% Close the log file
fclose(fid_log);

% Iterate through all System IDs and write the results to the CSV file
% The range is from 0 to 18 based on the provided log file.
for i = 0:51
    error1 = 'error:';
    error2 = 'error:';

    if isKey(errorsMap, i)
        foundErrors = errorsMap(i);
        
        % Check the number of errors found for the current system ID
        if length(foundErrors) == 2
            % Case: exactly two errors are found
            error1 = num2str(foundErrors{1});
            error2 = num2str(foundErrors{2});
        elseif length(foundErrors) >= 3
            % Case: three or more errors are found, ignore the first one
            error1 = num2str(foundErrors{2});
            error2 = num2str(foundErrors{3});
        elseif length(foundErrors) == 1
            % Case: only one error is found
            error1 = num2str(foundErrors{1});
        end
    end
    
    % Write the final line to the CSV file
    fprintf(fid_csv, '%d,%s,%s\n', i, error1, error2);
end

% Close the output CSV file
fclose(fid_csv);

end
