function process_solver_logs(log_filepath, output_filepath)
% PROCESS_SOLVER_LOGS Reads a structured log file, extracts key metrics, and saves them to a CSV.
%
%   Args:
%       log_filepath (char): The full path to the input log file.
%       output_filepath (char): The full path to the output CSV file.

    % Read the entire log file content into a single string.
    try
        log_content = fileread(log_filepath);
    catch
        fprintf(2, 'Error: Could not read log file: %s\n', log_filepath);
        return;
    end

    % --- Define Regular Expressions for Data Extraction ---
    % This pattern matches an entire system block, from 'Processing System'
    % to the next one or the end of the file.
    system_block_pattern = 'Processing System (\d+)(?:.|\n)*?Relative residual after error update: ([\d.eE+-]+)(?:.|\n)*?(?:Processing System|$)';

    % Find all system blocks in the log file
    system_blocks = regexp(log_content, system_block_pattern, 'tokens');

    % Check if any system blocks were found
    if isempty(system_blocks)
        fprintf(2, 'Error: No system blocks found in the log file. Check the log file format.\n');
        return;
    end

    % Initialize a table to store the results
    metrics = table('Size', [length(system_blocks), 6], ...
        'VariableNames', {'System_ID', 'FGMRES_init_nrm', 'FGMRES_final_nrm', 'FGMRES_error_nrm', 'Effective_Stability', 'Relative_residual'}, ...
        'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'double'});

    % Loop through each extracted system block and get the specific data points
    for i = 1:length(system_blocks)
        system_ID_str = system_blocks{i}{1};
        rel_res_str = system_blocks{i}{2};

        % The content to search for individual metrics
        block_content = system_blocks{i}{end};

        % --- Extract each metric individually for robustness ---

        % FGMRES Initial Norm
        init_nrm_matches = regexp(block_content, 'FGMRES: init nrm: ([\d.eE+-]+)', 'tokens', 'once');
        if ~isempty(init_nrm_matches)
            metrics.FGMRES_init_nrm(i) = str2double(init_nrm_matches{1});
        else
            metrics.FGMRES_init_nrm(i) = NaN;
        end

        % FGMRES Final Norm
        final_nrm_matches = regexp(block_content, 'final nrm: ([\d.eE+-]+)', 'tokens', 'once');
        if ~isempty(final_nrm_matches)
            metrics.FGMRES_final_nrm(i) = str2double(final_nrm_matches{1});
        else
            metrics.FGMRES_final_nrm(i) = NaN;
        end

        % FGMRES Error Norm
        error_nrm_matches = regexp(block_content, 'FGMRES norm of error: ([\d.eE+-]+)', 'tokens', 'once');
        if ~isempty(error_nrm_matches)
            metrics.FGMRES_error_nrm(i) = str2double(error_nrm_matches{1});
        else
            metrics.FGMRES_error_nrm(i) = NaN;
        end

        % Effective Stability
        stability_matches = regexp(block_content, 'FGMRES Effective Stability: ([\d.eE+-]+)', 'tokens', 'once');
        if ~isempty(stability_matches)
            metrics.Effective_Stability(i) = str2double(stability_matches{1});
        else
            metrics.Effective_Stability(i) = NaN;
        end

        % Populate the table with the system ID and relative residual
        metrics.System_ID(i) = str2double(system_ID_str);
        metrics.Relative_residual(i) = str2double(rel_res_str);
    end

    % Write the results to the CSV file.
    try
        if exist(output_filepath, 'file') == 2
            % Append to existing file (without header)
            writetable(metrics, output_filepath, 'WriteMode', 'append', 'WriteVariableNames', false);
        else
            % Create a new file (with header)
            writetable(metrics, output_filepath, 'WriteMode', 'overwrite', 'WriteVariableNames', true);
        end
        fprintf('Successfully wrote data for %d systems to %s\n', length(system_blocks), output_filepath);
    catch
        fprintf(2, 'Error: Could not write to file: %s\n', output_filepath);
    end
end
