#!/bin/bash

# Extract complete timeline from all log files
OUTPUT="COMPLETE_TIMELINE.txt"
echo "Extracting complete timeline from all log files..." > $OUTPUT
echo "=================================================" >> $OUTPUT
echo "" >> $OUTPUT

# Process each log file
for logfile in debug-*.log.gz; do
    echo "Processing $logfile..."
    echo "" >> $OUTPUT
    echo "=== From $logfile ===" >> $OUTPUT
    echo "" >> $OUTPUT
    
    # Extract all lines with train IDs and station IDs mentioned in the bug
    zcat "$logfile" 2>/dev/null | grep -E '\[(STATION-DEBUG|TRAIN-DEBUG|STATION-BE-DEBUG|RAILWAY-MGR-DEBUG)\]' | \
        grep -E '(4b5f0e|4471ce|aa4feb|e1e37b|f39bb7)' >> $OUTPUT || true
done

# Also check uncompressed logs
for logfile in debug*.log; do
    if [ -f "$logfile" ]; then
        echo "Processing $logfile..."
        echo "" >> $OUTPUT
        echo "=== From $logfile ===" >> $OUTPUT
        echo "" >> $OUTPUT
        
        cat "$logfile" | grep -E '\[(STATION-DEBUG|TRAIN-DEBUG|STATION-BE-DEBUG|RAILWAY-MGR-DEBUG)\]' | \
            grep -E '(4b5f0e|4471ce|aa4feb|e1e37b|f39bb7)' >> $OUTPUT || true
    fi
done

echo "Timeline extracted to $OUTPUT"
wc -l $OUTPUT
