#!/bin/bash

# Define branches
BASE_BRANCH="devA-metadata"
TARGET_BRANCH="KioskBranch"
REPORT_FILE="devA_diff_report_$(date +%F_%H-%M).txt"

# Ensure latest
git fetch origin $BASE_BRANCH
git fetch origin $TARGET_BRANCH

# Checkout target branch (your working branch)
git checkout $TARGET_BRANCH

# Generate diff
git diff origin/$BASE_BRANCH..origin/$TARGET_BRANCH > "$REPORT_FILE"

# Email the diff (requires mailutils or msmtp + mutt setup)
echo "Differences between DevA metadata and your branch are attached." | mail -s "DevA Sync Report" -A "$REPORT_FILE" your.email@example.com

echo "✅ Report generated: $REPORT_FILE"