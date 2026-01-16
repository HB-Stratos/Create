#!/bin/bash
# Extract and merge timeline events from all log files
# Focus on Test Train 1 (4b5f0e), Train 2, Train 3 (4471ce2f)
# And the problematic station aa4feb96 (Loader 1 left)

cd /home/runner/work/Create/Create/analysis

echo "Creating comprehensive timeline from all log files..."
echo "This will take several minutes..."

# Create temp directory
mkdir -p temp_timeline

# Function to extract train events from a log file
extract_train_events() {
    local logfile=$1
    local output=$2
    
    echo "Processing $logfile..."
    
    if [[ $logfile == *.gz ]]; then
        zcat "$logfile" 2>/dev/null | grep -E "\[TRAIN-DEBUG\]|\[STATION-DEBUG\]|\[STATION-BE-DEBUG\]" | \
        grep -E "4b5f0e|4471ce2f|aa4feb96|Test Train|reserveFor|leaveStation|arriveAt|setCurrentStation|getCurrentStation|trainDeparted" | \
        sed "s/^/[$logfile] /" >> "$output"
    else
        cat "$logfile" | grep -E "\[TRAIN-DEBUG\]|\[STATION-DEBUG\]|\[STATION-BE-DEBUG\]" | \
        grep -E "4b5f0e|4471ce2f|aa4feb96|Test Train|reserveFor|leaveStation|arriveAt|setCurrentStation|getCurrentStation|trainDeparted" | \
        sed "s/^/[$logfile] /" >> "$output"
    fi
}

# Extract from all files
for logfile in debug-1.log.gz debug-2.log.gz debug-3.log.gz debug-4.log.gz debug-5.log.gz debug_filtered_brokenstationoccurred.log; do
    if [ -f "$logfile" ]; then
        extract_train_events "$logfile" "temp_timeline/all_events_unsorted.txt"
    fi
done

echo "Sorting events by timestamp..."

# Sort by timestamp (column 2-3 after filename)
sort -t']' -k2,3 temp_timeline/all_events_unsorted.txt > temp_timeline/all_events_sorted.txt

# Create organized timeline
echo "Creating organized timeline..."
cat > COMPREHENSIVE_TIMELINE.md << 'EOF'
# Comprehensive Timeline - All Three Test Trains

This timeline shows all events for Test Train 1 (4b5f0e), Test Train 2, and Test Train 3 (4471ce2f),
with special focus on station aa4feb96 (Loader 1 left track - the broken station).

## Key IDs
- **Train 1**: 4b5f0e (victim train stuck at broken station)
- **Train 3**: 4471ce2f (train with stale reservation)
- **Station aa4feb96**: "Loader 1" (left track, west yard - BROKEN)
- **Bug manifests**: 08:12:47.613

## Timeline

EOF

# Add sorted events
cat temp_timeline/all_events_sorted.txt >> COMPREHENSIVE_TIMELINE.md

echo ""
echo "Timeline created: COMPREHENSIVE_TIMELINE.md"
echo "Event count: $(wc -l < temp_timeline/all_events_sorted.txt)"

# Create summary focusing on key moments
echo ""
echo "Creating focused summary around bug manifestation (08:12:47.613)..."

cat > FOCUSED_BUG_TIMELINE.md << 'EOF'
# Focused Timeline - Around Bug Manifestation

Focus period: 08:10:00 to 08:15:00 (5 minutes around bug manifestation at 08:12:47.613)

## Events

EOF

# Extract events around the bug time (08:10 to 08:15)
grep -E "08:1[0-5]:" temp_timeline/all_events_sorted.txt | \
grep -E "4b5f0e|4471ce2f|aa4feb96|Test Train" >> FOCUSED_BUG_TIMELINE.md 2>/dev/null || echo "No events found in this timeframe"

echo "Focused timeline created: FOCUSED_BUG_TIMELINE.md"
echo ""
echo "Creating Train 3 complete journey..."

# Track Train 3's complete journey
cat > TRAIN3_COMPLETE_JOURNEY.md << 'EOF'
# Train 3 (4471ce2f) - Complete Journey

All events involving Train 3 from all log files.

## Events

EOF

grep "4471ce2f" temp_timeline/all_events_sorted.txt >> TRAIN3_COMPLETE_JOURNEY.md 2>/dev/null || echo "No Train 3 events found"

echo "Train 3 journey created: TRAIN3_COMPLETE_JOURNEY.md"
echo ""
echo "Creating Station aa4feb96 complete history..."

# Track station aa4feb96's complete history
cat > STATION_AA4FEB96_HISTORY.md << 'EOF'
# Station aa4feb96 (Loader 1 left) - Complete History

All reservation events for the broken station.

## Events

EOF

grep "aa4feb96" temp_timeline/all_events_sorted.txt >> STATION_AA4FEB96_HISTORY.md 2>/dev/null || echo "No station events found"

echo "Station history created: STATION_AA4FEB96_HISTORY.md"

# Cleanup
# rm -rf temp_timeline

echo ""
echo "All timelines created successfully!"
echo ""
echo "Files created:"
echo "  - COMPREHENSIVE_TIMELINE.md (all events)"
echo "  - FOCUSED_BUG_TIMELINE.md (08:10-08:15)"
echo "  - TRAIN3_COMPLETE_JOURNEY.md (Train 3 only)"
echo "  - STATION_AA4FEB96_HISTORY.md (station only)"
