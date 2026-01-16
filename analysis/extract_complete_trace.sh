#!/bin/bash

# Extract complete trace from debug-4.log.gz (the log with the bug)
echo "Extracting comprehensive bug trace..."

zcat debug-4.log.gz | awk '
BEGIN {
    print "# Complete Train-Station Desynchronization Bug Trace"
    print "# Analyzed from debug-4.log.gz (718,239 lines)"
    print ""
}

# Track key entities
/4b5f0ef9|aa4feb96|4471ce2f|e1e37bfd/ {
    line_num = NR
    
    # Extract timestamp
    if (match($0, /\[([0-9]+[A-Za-z.]+[0-9]+\s+[0-9:]+\.[0-9]+)\]/, ts)) {
        timestamp = ts[1]
    }
    
    # Store critical events
    if ($0 ~ /4471ce2f.*arriveAt.*e1e37bfd/) {
        print "\n## CRITICAL: Train 3 arrives at e1e37bfd (NOT aa4feb96)"
        print "Line " line_num ": [" timestamp "]"
        print $0
        train3_arrived = 1
    }
    
    if ($0 ~ /4471ce2f.*leaveStation.*e1e37bfd/ || $0 ~ /4471ce2f.*trainDeparted.*e1e37bfd/) {
        print "\n## CRITICAL: Train 3 departs e1e37bfd"
        print "Line " line_num ": [" timestamp "]"
        print $0
    }
    
    if ($0 ~ /e1e37bfd.*cancelReservation/) {
        print "\n## CRITICAL: e1e37bfd cancels reservation"
        print "Line " line_num ": [" timestamp "]"
        print $0
    }
    
    if ($0 ~ /aa4feb96.*cancelReservation.*4471ce/) {
        print "\n## NOTICE: aa4feb96 cancels Train 3 reservation (should happen but doesn'"'"'t!)"
        print "Line " line_num ": [" timestamp "]"
        print $0
        aa4feb_cancelled = 1
    }
    
    if ($0 ~ /aa4feb96.*reserveFor.*4471ce/ && $0 ~ /Previous: null/) {
        print "\n## INITIAL RESERVATION: aa4feb96 first reserves Train 3"
        print "Line " line_num ": [" timestamp "]"
        print $0
        first_reserve = line_num
    }
    
    if ($0 ~ /4b5f0ef9.*arriveAt.*aa4feb96/) {
        print "\n## VICTIM TRAIN: Train 1 arrives at aa4feb96"
        print "Line " line_num ": [" timestamp "]"
        print $0
    }
    
    if ($0 ~ /4b5f0ef9.*reserveFor.*aa4feb96/ && $0 ~ /Previous: null/) {
        print "\n## VICTIM: Train 1 first tries to reserve aa4feb96"
        print "Line " line_num ": [" timestamp "]"
        print $0
    }
}

END {
    print "\n\n## Analysis Summary"
    if (first_reserve > 0) {
        print "- First reservation of aa4feb96 to Train 3 at line: " first_reserve
    }
    if (train3_arrived) {
        print "- Train 3 arrived at e1e37bfd (different station!)"
    }
    if (!aa4feb_cancelled) {
        print "- ** BUG CONFIRMED **: aa4feb96 NEVER cancelled Train 3 reservation!"
    }
}
' | head -1000
