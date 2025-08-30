#!/bin/bash

# Define the log file and output CSV file paths
LOG_FILE="./hybrid_solver_output.txt"
OUTPUT_CSV="./solver_metrics.csv"

# Remove the old CSV file to start with a clean slate
rm -f "$OUTPUT_CSV"

# Create the CSV file with the header
echo "System_ID,FGMRES_init_nrm,FGMRES_final_nrm,FGMRES_error_nrm,Effective_Stability,Relative_residual" > "$OUTPUT_CSV"

# Run the MATLAB script to process the log file and append the data to the CSV
matlab -batch "process_solver_logs('$LOG_FILE', '$OUTPUT_CSV')"
