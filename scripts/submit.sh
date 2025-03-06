#!/bin/bash

ROOT_DIR="/home/xuyang1/mlebench_aide_gpt_4o_ad_res_anlysis"

for BASE_DIR in $ROOT_DIR; do
    for SUB_DIR in "$BASE_DIR"/*/; do
        METADATA_JSON="$SUB_DIR/metadata.json"
        for COMP_DIR in "$SUB_DIR"/*/; do
            COMP_DIR="$COMP_DIR"
            echo "Found directory: $COMP_DIR"
            cp "$METADATA_JSON" "$COMP_DIR"
            COMP_NAME=$(basename "$COMP_DIR")

            IDENTIFIER=$(basename "$COMP_DIR")
            echo "Processing COMP_DIR with identifier: $IDENTIFIER"

            jq --arg identifier "$IDENTIFIER" '
                .runs |= with_entries(select(.key | contains($identifier)))
            ' "$METADATA_JSON" > "$COMP_DIR/metadata.json"

            OUTPUT_FILE="$COMP_DIR/x_score_mapping.csv"
            SUBMISSION_DIR="$COMP_DIR/submission"

            if [ ! -f "$OUTPUT_FILE" ]; then
                echo "x,score,any_medal,gold_medal,silver_medal,bronze_medal,above_median,submission_exists,valid_submission" > "$OUTPUT_FILE"
            fi

            if [ -d "$SUBMISSION_DIR" ] && [ "$(ls -A "$SUBMISSION_DIR")" ]; then
                for SUBMISSION_FILE in "$SUBMISSION_DIR"/submission_*.csv; do
                    FILENAME=$(basename "$SUBMISSION_FILE")
                    X=${FILENAME%.csv}
                    X=${X#submission_}

                    echo "Processing submission_i.csv, where i=$X"

                    cp "$SUBMISSION_FILE" "$SUBMISSION_DIR/submission.csv"
                    echo "$SUBMISSION_DIR/submission.csv"

                    echo "$COMP_DIR/metadata.json"

                    python experiments/make_submission.py --metadata "$COMP_DIR/metadata.json" --output "$COMP_DIR/submission_$X.jsonl"

                    OUTPUT_DIR="$COMP_DIR/grading_output_$X"
                    mkdir -p "$OUTPUT_DIR"
                    mlebench grade --submission "$COMP_DIR/submission_$X.jsonl" --output-dir "$OUTPUT_DIR"

                    GRADING_REPORT=$(ls -t "$OUTPUT_DIR"/*_grading_report.json | head -1)

                    if [ -f "$GRADING_REPORT" ]; then
                        SCORE=$(jq '.competition_reports[0].score' "$GRADING_REPORT")
                        ANY_MEDAL=$(jq '.competition_reports[0].any_medal' "$GRADING_REPORT")
                        GOLD_MEDAL=$(jq '.competition_reports[0].gold_medal' "$GRADING_REPORT")
                        SILVER_MEDAL=$(jq '.competition_reports[0].silver_medal' "$GRADING_REPORT")
                        BRONZE_MEDAL=$(jq '.competition_reports[0].bronze_medal' "$GRADING_REPORT")
                        ABOVE_MEDIAN=$(jq '.competition_reports[0].above_median' "$GRADING_REPORT")
                        SUBMISSION_EXISTS=$(jq '.competition_reports[0].submission_exists' "$GRADING_REPORT")
                        VALID_SUBMISSION=$(jq '.competition_reports[0].valid_submission' "$GRADING_REPORT")

                        echo "x=$X, score=$SCORE, any_medal=$ANY_MEDAL, gold_medal=$GOLD_MEDAL, silver_medal=$SILVER_MEDAL, bronze_medal=$BRONZE_MEDAL, above_median=$ABOVE_MEDIAN, submission_exists=$SUBMISSION_EXISTS, valid_submission=$VALID_SUBMISSION"

                        echo "$X,$SCORE,$ANY_MEDAL,$GOLD_MEDAL,$SILVER_MEDAL,$BRONZE_MEDAL,$ABOVE_MEDIAN,$SUBMISSION_EXISTS,$VALID_SUBMISSION" >> "$OUTPUT_FILE"
                    else
                        echo "Grading report not found for x=$X"
                    fi
                done
            fi
        done
    done
    # break
done