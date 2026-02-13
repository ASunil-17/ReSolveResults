#!/bin/bash

extract_trace() {
    local kernel_regex=$1
    local input_file=$2
    local output_csv=$3

    if [ ! -f "$input_file" ]; then 
        echo "Warning: $input_file not found. Skipping."
        return
    fi

    echo "launch_id,invocations,grid_size,cycles,dram_kb,l1_req,l2_req" > "$output_csv"

    # Use awk with a more careful state-machine approach
    awk -v target="$kernel_regex" '
    # 1. Detect the start of a Kernel Block
    /void/ && $0 ~ target {
        # If we already have data from a previous block, print it first
        if (found) {
            printf "%d,%d,%s,%s,%s,%s,%s\n", id, invok, g_size, cycles, dram, l1, l2;
        }
        
        # Reset variables for the new block
        id++; found=1;
        invok=0; g_size="0"; cycles="0"; dram="0"; l1="0"; l2="0";
        
        # Extract invocation count from header
        for (i=1; i<=NF; i++) {
            if ($i ~ /invocation/) { invok = $(i-1); break; }
        }
    }

    # 2. Extract metrics ONLY if we are currently inside a target kernel block
    found {
        if ($0 ~ /launch__grid_size/) { g_size=$NF; }
        if ($0 ~ /sm__cycles_active.avg/) { cycles=$NF; }
        if ($0 ~ /dram__bytes_read.sum/) { 
            val=$NF; 
            if ($2 == "Mbyte") val *= 1024;
            dram=val; 
        }
        if ($0 ~ /l1tex__t_requests_pipe_lsu_mem_global_op_ld.sum/) { l1=$NF; }
        if ($0 ~ /lts__t_requests_srcunit_tex_op_read.sum/) { l2=$NF; }
    }

    # 3. Detect the end of the file or start of a DIFFERENT kernel to print the final block
    /void/ && $0 !~ target && found {
        printf "%d,%d,%s,%s,%s,%s,%s\n", id, invok, g_size, cycles, dram, l1, l2;
        found=0;
    }
    
    END {
        if (found) {
            printf "%d,%d,%s,%s,%s,%s,%s\n", id, invok, g_size, cycles, dram, l1, l2;
        }
    }' "$input_file" >> "$output_csv"
}

# Source files
files=(
    "kernel_summary_2000_modern_metrics.txt"
    "kernel_summary_2000_tail.txt"
    "kernel_summary_70k_modern_metrics.txt"
    "kernel_summary_70k_tail.txt"
)

for f in "${files[@]}"; do
    base=$(basename "$f" .txt)
    echo "Processing $f..."
    extract_trace "k1_hw" "$f" "${base}_k1_trace.csv"
    extract_trace "k2_hw" "$f" "${base}_k2_trace.csv"
done

echo "Done! Check your files for corrected alignments."
