#!/bin/bash
# This script is used to move the run folders and metadata.json files from the workspace to the aide_gpt_4o_our_results directory.

# data/home/xiaoyang/repos/batch_ctrl/aideML/workspaces/ep04/runs/2025-03-04T01-11-04-GMT_run-group_aide

BASE_DIR="/data/home/xiaoyang/repos/batch_ctrl/aideML/workspaces"

# mv
for workspace in "$BASE_DIR"/*; do
    # echo "Processing: $workspace"
    if [ -d "$workspace/runs" ]; then
        echo "Processing: $workspace/runs"
        
        for run_folder in "$workspace/runs"/*; do
            if [ -d "$run_folder" ]; then
                echo "$run_folder"
                cp -r "$run_folder" /home/v-yuanteli/aide_gpt_4o_our_results
            fi
        done
    fi
done


# process json
for workspace in "$BASE_DIR"/*; do
    # echo "Processing: $workspace"
    if [ -d "$workspace/runs" ]; then
        echo "Processing: $workspace/runs"
        
        for run_folder in "$workspace/runs"/*; do
            if [ -d "$run_folder" ]; then
                if [ -f "$run_folder/metadata.json" ]; then
                    ws_name=$(basename "$workspace")
                    cp "$run_folder/metadata.json" "/home/v-yuanteli/aide_gpt_4o_our_results/${ws_name}_metadata.json"
                fi
            fi
        done
    fi
done

# merge
merged_file="/home/v-yuanteli/aide_gpt_4o_our_results/merged_metadata.json"
metadata_files=(/home/v-yuanteli/aide_gpt_4o_our_results/*_metadata.json)

if [ ${#metadata_files[@]} -eq 0 ]; then
    echo "No metadata json files found."
    exit 1
fi

jq -s '.[0] as $first |
    {
        run_group: $first.run_group,
        created_at: $first.created_at,
        runs: (reduce .[] as $item ({}; . + $item.runs))
    }' "${metadata_files[@]}" > "$merged_file"

echo "Merged metadata saved to: $merged_file"