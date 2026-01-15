#!/bin/bash

# Train 1: 4b5f0e9f (victim - can't be detected)
# Train 3: 4471ce2f (wrongly reserved)
# Station aa4feb96 (Loader 1 - broken)
# Station e1e37bfd (Loader 1 - other one)
# Station f39bb7f7 (may be relevant)

OUTPUT="FOCUSED_TIMELINE.md"
echo "# Complete Timeline Analysis" > $OUTPUT
echo "" >> $OUTPUT
echo "## Key Entities" >> $OUTPUT
echo "- Train 1: \`4b5f0e9f\` (victim)" >> $OUTPUT
echo "- Train 3: \`4471ce2f\` (wrongly reserved)" >> $OUTPUT
echo "- Station \`aa4feb96\` (Loader 1 - broken)" >> $OUTPUT
echo "- Station \`e1e37bfd\` (Loader 1 - other one)" >> $OUTPUT
echo "" >> $OUTPUT

# Check which log file has the issue
echo "## Log File Analysis" >> $OUTPUT
echo "" >> $OUTPUT

for logfile in debug-*.log.gz; do
    echo "Checking $logfile for bug condition..."
    # Look for the moment when aa4feb96 has 4471ce2f reserved
    MATCH=$(zcat "$logfile" 2>/dev/null | grep -E 'aa4feb96.*4471ce2f|4471ce2f.*aa4feb96' | wc -l)
    echo "- $logfile: $MATCH matches" >> $OUTPUT
done

echo "" >> $OUTPUT
echo "## Extracting Timeline from debug-4.log.gz (primary log)" >> $OUTPUT
echo "" >> $OUTPUT

# Extract with timestamps and line numbers
zcat debug-4.log.gz | nl -nln | grep -E '\[(STATION-DEBUG|TRAIN-DEBUG|STATION-BE-DEBUG|RAILWAY-MGR-DEBUG)\]' | \
    grep -E '(4b5f0e|4471ce|aa4feb|e1e37b)' > temp_timeline.txt

# Now organize by timestamp
echo "### Train 3 (4471ce2f) Events" >> $OUTPUT
echo "\`\`\`" >> $OUTPUT
cat temp_timeline.txt | grep '4471ce2f' | head -200 >> $OUTPUT
echo "\`\`\`" >> $OUTPUT

echo "" >> $OUTPUT
echo "### Station aa4feb96 Events" >> $OUTPUT
echo "\`\`\`" >> $OUTPUT
cat temp_timeline.txt | grep 'aa4feb96' | head -200 >> $OUTPUT
echo "\`\`\`" >> $OUTPUT

echo "" >> $OUTPUT
echo "### Train 1 (4b5f0e) Events" >> $OUTPUT
echo "\`\`\`" >> $OUTPUT
cat temp_timeline.txt | grep '4b5f0e' | head -100 >> $OUTPUT
echo "\`\`\`" >> $OUTPUT

rm temp_timeline.txt

echo "Timeline extracted to $OUTPUT"
wc -l $OUTPUT
