#!/bin/bash

# Define the name of the log file and the output CSV file
LOG_FILE="hybrid_solver_output.txt"
OUTPUT_CSV="test_metrics.csv"

# Clear any previous content from the output CSV file and add the header.
# NOTE: The MATLAB script itself writes the final header, so we typically omit 
# this line or use it only for initial confirmation. If you want the script 
# to run fully independently of the MATLAB script's internal header, you 
# should remove the header writing from the MATLAB file.
# Since the MATLAB file generates the final header, I'll comment this out 
# to prevent double-headers, but leave the correct header structure here for reference.
# echo "System_ID,FGMRES_Iterations,System_Scaling_Measure" > "$OUTPUT_CSV"

# Call the MATLAB script to process the log file.
# The `matlab -batch` command runs the function non-interactively.
# -nodisplay -nosplash are used to run MATLAB in headless mode.
# --- MODIFIED: Changed function name to process_solver_logs ---
matlab -nodisplay -nosplash -r "process_solver_logs('$LOG_FILE', '$OUTPUT_CSV'); exit;"

echo "Processing complete. Check $OUTPUT_CSV for results."
