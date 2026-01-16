#!/bin/bash

LOG="debug-1.log"

echo "# Complete Bug Trace - Train-Station Desynchronization"
echo ""
echo "## Key Entities"
echo "- **Test Train 1** (ID: 4b5f0e0e) - physically stopped at aa4feb96"
echo "- **Test Train 3** (ID: 4471ce2f) - the train incorrectly reserved at aa4feb96"
echo "- **Station aa4feb96** (Loader 1) - where Train 1 is stopped, but points to Train 3"
echo "- **Station e1e37bfd** (Loader 1) - where Train 3 actually was/went"
echo ""

echo "## Section 1: When did Train 3 (4471ce2f) first reserve station aa4feb96?"
echo ""
grep -n "4471ce2f" "$LOG" | grep "aa4feb96" | grep -E "(reserveFor|reservation)" | head -20

echo ""
echo "## Section 2: Train 3 Movement to Loader 1 stations"
echo ""
grep -n "4471ce2f" "$LOG" | grep -E "(arriveAt|leaveStation|setCurrentStation)" | grep -A1 -B1 "Loader"

echo ""
echo "## Section 3: When Train 3 departed e1e37bfd (the correct Loader 1)"
echo ""
grep -n "4471ce2f.*e1e37bfd" "$LOG" | grep -E "(leaveStation|trainDeparted|cancelReservation)"

echo ""
echo "## Section 4: What happened to station aa4feb96 after Train 3 left e1e37bfd?"
echo ""
grep -n "aa4feb96" "$LOG" | grep -A2 -B2 "07:59:15"

