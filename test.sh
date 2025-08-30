#!/bin/bash

# Define the name of the log file and the output CSV file
LOG_FILE="hybrid_solver_output.txt"
OUTPUT_CSV="solver_metrics.csv"

# Clear any previous content from the output CSV file and add the header
echo "System_ID,FGMRES_init_nrm,FGMRES_final_nrm,FGMRES_error_nrm,Effective_Stability,Relative_residual" > "$OUTPUT_CSV"

# Call the MATLAB script to process the log file.
# The `matlab -batch` command runs the function non-interactively.
# -nodisplay -nosplash are used to run MATLAB in headless mode.
matlab -nodisplay -nosplash -r "process_solver_logs('$LOG_FILE', '$OUTPUT_CSV'); exit;"

echo "Processing complete. Check $OUTPUT_CSV for results."
