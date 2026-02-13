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

    # Using awk to find the kernel header and pull the invocation count and metrics
    grep -A 35 "$kernel_regex" "$input_file" | awk '
    BEGIN { id = 0; }
    # This line matches the header: "... Device 0, 8 invocations"
    /Device 0,/ { 
        id++; 
        # Extract the number before "invocations"
        for (i=1; i<=NF; i++) {
            if ($i ~ /invocation/) { invok = $(i-1); break; }
        }
    }
    /launch__grid_size/ { g_size=$NF; }
    /sm__cycles_active.avg/ { cycles=$NF; }
    /dram__bytes_read.sum/ { 
        val=$NF; 
        if ($2 == "Mbyte") val *= 1024;
        dram=val; 
    }
    /l1tex__t_requests_pipe_lsu_mem_global_op_ld.sum/ { l1=$NF; }
    /lts__t_requests_srcunit_tex_op_read.sum/ { 
        l2=$NF; 
        # Print the row once the last metric is found
        printf "%d,%d,%s,%s,%s,%s,%s\n", id, invok, g_size, cycles, dram, l1, l2;
    }' >> "$output_csv"
}

# 1. Your 4 source files
files=(
    "kernel_summary_2000_modern_metrics.txt"
    "kernel_summary_2000_tail.txt"
    "kernel_summary_70k_modern_metrics.txt"
    "kernel_summary_70k_tail.txt"
)

# 2. Run extraction for K1 and K2
for f in "${files[@]}"; do
    base=$(basename "$f" .txt)
    echo "Processing $f..."
    extract_trace "k1_hw" "$f" "${base}_k1_trace.csv"
    extract_trace "k2_hw" "$f" "${base}_k2_trace.csv"
done

echo "------------------------------------------------"
echo "Success! 8 Trace files generated."
ls -lh *_trace.csv
