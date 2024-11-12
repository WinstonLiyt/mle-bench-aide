#!/bin/bash

BASE_DIR="/home/v-yuanteli/mle-bench/show/w_submission_each_loop/2024-11-11T10-58-58-GMT_run-group_aide"
SUBMISSION_DIR="$BASE_DIR/spaceship-titanic_a1fd045a-5212-4b69-b5ce-91e6d77d6f94/submission"
METADATA_JSON="$BASE_DIR/metadata.json"
OUTPUT_FILE="$BASE_DIR/x_score_mapping.txt"

rm -f "$OUTPUT_FILE"

for SUBMISSION_FILE in "$SUBMISSION_DIR"/submission_*.csv; do
    FILENAME=$(basename "$SUBMISSION_FILE")
    X=${FILENAME%.csv}
    X=${X#submission_}

    echo "Processing submission_i.csv, where i=$X"

    cp "$SUBMISSION_FILE" "$SUBMISSION_DIR/submission.csv"

    python experiments/make_submission.py --metadata "$METADATA_JSON" --output "$BASE_DIR/submission_$X.jsonl"

    OUTPUT_DIR="$BASE_DIR/grading_output_$X"
    mkdir -p "$OUTPUT_DIR"
    mlebench grade --submission "$BASE_DIR/submission_$X.jsonl" --output-dir "$OUTPUT_DIR"

    GRADING_REPORT=$(ls -t "$OUTPUT_DIR"/*_grading_report.json | head -1)

    SCORE=$(jq '.competition_reports[0].score' "$GRADING_REPORT")

    echo "x=$X, score=$SCORE"
    echo "$X $SCORE" >> "$OUTPUT_FILE"

done

echo "All scores have been recorded in $OUTPUT_FILE"
