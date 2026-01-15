#!/bin/bash

# The user said: Train 1 (4b5f0e) is at aa4feb96, but aa4feb96 points to Train 3 (4471ce2f)
# Train 3 is NOT at aa4feb96, it's at e1e37bfd (also called "Loader 1")

# Step 1: Find when aa4feb96 first got Train 3 reservation
echo "=== STEP 1: When did aa4feb96 FIRST get Train 3 (4471ce2f) reservation? ===" > COMPLETE_STORY.md
echo "" >> COMPLETE_STORY.md

for logfile in debug-*.log.gz; do
    echo "Checking $logfile..."
    FIRST=$(zcat "$logfile" 2>/dev/null | nl -nln | grep '\[STATION-DEBUG\].*aa4feb96.*reserveFor' | grep '4471ce2f' | head -1)
    if [ -n "$FIRST" ]; then
        echo "### Found in $logfile:" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "$FIRST" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "" >> COMPLETE_STORY.md
    fi
done

# Step 2: Did Train 3 ever arrive at aa4feb96?
echo "=== STEP 2: Did Train 3 ever ARRIVE at aa4feb96? ===" >> COMPLETE_STORY.md
echo "" >> COMPLETE_STORY.md

for logfile in debug-*.log.gz; do
    ARRIVE=$(zcat "$logfile" 2>/dev/null | nl -nln | grep '\[TRAIN-DEBUG\].*4471ce2f.*arriveAt\|setCurrentStation' | grep 'aa4feb96' | head -5)
    if [ -n "$ARRIVE" ]; then
        echo "### Found in $logfile:" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "$ARRIVE" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "" >> COMPLETE_STORY.md
    fi
done

# Step 3: Did Train 3 ever LEAVE aa4feb96?
echo "=== STEP 3: Did Train 3 ever LEAVE aa4feb96? ===" >> COMPLETE_STORY.md
echo "" >> COMPLETE_STORY.md

for logfile in debug-*.log.gz; do
    LEAVE=$(zcat "$logfile" 2>/dev/null | nl -nln | grep '\[TRAIN-DEBUG\].*4471ce2f.*leaveStation\|trainDeparted' | grep 'aa4feb96' | head -5)
    if [ -n "$LEAVE" ]; then
        echo "### Found in $logfile:" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "$LEAVE" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "" >> COMPLETE_STORY.md
    fi
done

# Step 4: Did aa4feb96 ever cancel Train 3 reservation?
echo "=== STEP 4: Did aa4feb96 ever CANCEL Train 3 reservation? ===" >> COMPLETE_STORY.md
echo "" >> COMPLETE_STORY.md

for logfile in debug-*.log.gz; do
    CANCEL=$(zcat "$logfile" 2>/dev/null | nl -nln | grep '\[STATION-DEBUG\].*aa4feb96.*cancelReservation' | grep '4471ce2f' | head -5)
    if [ -n "$CANCEL" ]; then
        echo "### Found in $logfile:" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "$CANCEL" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "" >> COMPLETE_STORY.md
    fi
done

# Step 5: When did Train 3 go to e1e37bfd instead?
echo "=== STEP 5: When did Train 3 go to e1e37bfd (the OTHER 'Loader 1')? ===" >> COMPLETE_STORY.md
echo "" >> COMPLETE_STORY.md

for logfile in debug-*.log.gz; do
    OTHER=$(zcat "$logfile" 2>/dev/null | nl -nln | grep '\[TRAIN-DEBUG\].*4471ce2f.*arriveAt\|setCurrentStation' | grep 'e1e37b' | head -5)
    if [ -n "$OTHER" ]; then
        echo "### Found in $logfile:" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "$OTHER" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "" >> COMPLETE_STORY.md
    fi
done

# Step 6: When did Train 1 (4b5f0e) arrive at aa4feb96?
echo "=== STEP 6: When did Train 1 (4b5f0e) arrive at aa4feb96? ===" >> COMPLETE_STORY.md
echo "" >> COMPLETE_STORY.md

for logfile in debug-*.log.gz; do
    TRAIN1=$(zcat "$logfile" 2>/dev/null | nl -nln | grep '\[TRAIN-DEBUG\].*4b5f0e.*arriveAt\|setCurrentStation' | grep 'aa4feb96' | head -5)
    if [ -n "$TRAIN1" ]; then
        echo "### Found in $logfile:" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "$TRAIN1" >> COMPLETE_STORY.md
        echo "\`\`\`" >> COMPLETE_STORY.md
        echo "" >> COMPLETE_STORY.md
    fi
done

echo "Story compiled to COMPLETE_STORY.md"
wc -l COMPLETE_STORY.md
