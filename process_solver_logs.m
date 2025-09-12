function process_solver_logs(log_filepath, output_filepath)
% PROCESS_SOLVER_LOGS Reads a structured log file line-by-line,
% extracts key metrics, and saves them to a CSV.
% This version is more resilient to inconsistent formatting.

    % Open the log file for reading.
    fid = fopen(log_filepath, 'r');
    if fid == -1
        fprintf(2, 'Error: Could not open log file: %s\n', log_filepath);
        return;
    end

    % Define keywords for each metric.
    keywords = {
        'ID: '
        'FGMRES: init nrm:'
        'FGMRES: final nrm:'
        'FGMRES norm of error:'
        'FGMRES error estimation:'
        'FGMRES Effective Stability:'
        'Relative residual after error update:'
    };

    % Initialize a cell array to store the extracted data.
    all_data = cell(0, 6);
    current_system_data = cell(1, 6);
    current_system_ID = '';

    line = fgetl(fid);
    while ischar(line)
        % Trim leading/trailing whitespace and replace non-standard spaces
        line = strtrim(line);
        line = regexprep(line, char(160), ' ');

        % Look for the start of a new system block.
        if contains(line, 'Processing System')
            % If we have collected data for a system, store it.
            if ~isempty(current_system_ID)
                all_data(end+1, :) = current_system_data;
            end
            % Reset for the new system.
            current_system_data = {NaN, NaN, NaN, NaN, NaN, NaN};
            % Extract the System ID.
            id_match = regexp(line, 'ID: (\d+)', 'tokens', 'once');
            if ~isempty(id_match)
                current_system_ID = id_match{1};
            end
        end

        % Look for the FGMRES initial and final norms.
        if contains(line, 'FGMRES: init nrm:')
            nrm_match = regexp(line, 'FGMRES: init nrm: ([\d.eE+-]+)\s+final nrm: ([\d.eE+-]+)', 'tokens', 'once');
            if ~isempty(nrm_match)
                current_system_data{2} = str2double(nrm_match{1});
                current_system_data{3} = str2double(nrm_match{2});
            end
        end

        % Look for the FGMRES error norm, handling both formats.
        if contains(line, 'FGMRES norm of error:')
            error_match = regexp(line, 'FGMRES norm of error: ([\d.eE+-]+)', 'tokens', 'once');
            if ~isempty(error_match)
                current_system_data{4} = str2double(error_match{1});
            end
        elseif contains(line, 'FGMRES error estimation:')
            error_match = regexp(line, 'FGMRES error estimation: ([\d.eE+-]+)', 'tokens', 'once');
            if ~isempty(error_match)
                current_system_data{4} = str2double(error_match{1});
            end
        end

        % Look for Effective Stability.
        if contains(line, 'FGMRES Effective Stability:')
            stability_match = regexp(line, 'FGMRES Effective Stability: ([\d.eE+-]+)', 'tokens', 'once');
            if ~isempty(stability_match)
                current_system_data{5} = str2double(stability_match{1});
            end
        end

        % Look for Relative Residual.
        if contains(line, 'Relative residual after error update:')
            res_match = regexp(line, 'Relative residual after error update: ([\d.eE+-]+)', 'tokens', 'once');
            if ~isempty(res_match)
                current_system_data{6} = str2double(res_match{1});
            end
        end

        line = fgetl(fid);
    end

    % Store the last system's data.
    if ~isempty(current_system_ID)
        all_data(end+1, :) = current_system_data;
    end

    fclose(fid);

    % Add System IDs to the collected data.
    system_ids = (1:size(all_data, 1))';
    all_data(:, 1) = num2cell(system_ids);

    % Create a table from the data.
    metrics = cell2table(all_data, ...
        'VariableNames', {'System_ID', 'FGMRES_init_nrm', 'FGMRES_final_nrm', ...
        'FGMRES_error_nrm', 'Effective_Stability', 'Relative_residual'});

    % Write the results to the CSV file.
    try
        writetable(metrics, output_filepath);
        fprintf('Successfully wrote data for %d systems to %s\n', size(metrics, 1), output_filepath);
    catch
        fprintf(2, 'Error: Could not write to file: %s\n', output_filepath);
    end
end
