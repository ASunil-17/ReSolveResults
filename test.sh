#!/bin/bash

# Define the name of the log file and the output CSV file
LOG_FILE="hybrid_solver_output_test.txt"
OUTPUT_CSV="test_metrics.csv"

# Clear any previous content from the output CSV file and add the header
echo "System_ID, 2-norm of error #1, 2-norm of error #2" > "$OUTPUT_CSV"

# Call the MATLAB script to process the log file.
# The `matlab -batch` command runs the function non-interactively.
# -nodisplay -nosplash are used to run MATLAB in headless mode.
matlab -nodisplay -nosplash -r "process_solver_logs_test('$LOG_FILE', '$OUTPUT_CSV'); exit;"

echo "Processing complete. Check $OUTPUT_CSV for results."
