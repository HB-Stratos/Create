#!/bin/bash

LOG="debug-1.log"
OUT="COMPLETE_BUG_TRACE.md"

cat > "$OUT" << 'HEADER'
# Complete Bug Trace - Train-Station Desynchronization

## Executive Summary

This document provides a complete line-by-line trace of the train-station desynchronization bug captured by the instrumentation. The bug involves:

- **Test Train 1** (ID: `4b5f0e0e`) physically stopped at station **Loader 1** (UUID: `aa4feb96`)
- Station `aa4feb96`'s `nearestTrain` incorrectly points to **Test Train 3** (ID: `4471ce2f`)
- Train 3 is actually at a different station `71adee51` (Loader 2b)
- Train 3 never actually arrived at station `aa4feb96`

## Key Entities

| Entity | ID | Name | Notes |
|--------|-----|------|-------|
| Train 1 | `4b5f0e0e` | Test Train 1 | Physically at aa4feb96, but station doesn't detect it |
| Train 2 | `c1c9d44a` | Test Train 2 | Previously reserved at aa4feb96 |
| Train 3 | `4471ce2f` | Test Train 3 | Incorrectly reserved at aa4feb96 |
| Station | `aa4feb96` | Loader 1 | Has stale reservation to Train 3 |
| Station | `e1e37bfd` | Loader 1 | Where Train 3 actually went (different station, same name!) |
| Station | `71adee51` | Loader 2b | Where Train 3 currently is |
| Station | `a3be73ac` | Loader 1c | Another "Loader" station |
| Station | `9707c882` | Loader 2c | Another "Loader" station |

## Timeline of Events

HEADER

echo "### Phase 1: Train 3 is at Loader 2c (9707c882) - Before Bug Starts" >> "$OUT"
echo "" >> "$OUT"
echo "Train 3 is sitting at Loader 2c, about to leave and head toward the problematic stations." >> "$OUT"
echo "" >> "$OUT"
echo '```' >> "$OUT"
sed -n '223600,223700p' "$LOG" | grep -E "(4471ce2f|9707c882)" | head -10 >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "**Line 223662** - Train 3 leaves Loader 2c:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '223662p' "$LOG" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "### Phase 2: Train 3 Moves Toward Yard Lead Stations" >> "$OUT"
echo "" >> "$OUT"
echo "Train 3 travels through yard stations before reaching any 'Loader 1' station." >> "$OUT"
echo "" >> "$OUT"

echo "**Line 248547** - Train 3 arrives at Yard Lead 1:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '248547,248548p' "$LOG" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "**Around line 248-250k** - Train 3 at Yard Lead 1, then moves to Yard Lead 2a:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '250645,250650p' "$LOG" | grep "4471ce2f" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "### Phase 3: THE BUG - Station aa4feb96 Gets Wrong Reservation (07:36:21)" >> "$OUT"
echo "" >> "$OUT"
echo "🚨 **CRITICAL MOMENT**: While Train 3 is traveling between Yard Lead 2a and the actual destination" >> "$OUT"
echo "(station e1e37bfd), it somehow reserves station aa4feb96 (a DIFFERENT 'Loader 1')!" >> "$OUT"
echo "" >> "$OUT"

echo "**Context before the bug (lines 255550-255602)**:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '255550,255610p' "$LOG" | grep -E "(aa4feb96|4471ce2f|c1c9d44a)" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "**Line 255602** - First wrong reservation! Train 3 steals reservation from Train 2:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '255602p' "$LOG" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "Note: `Previous: c1c9d44a, New: 4471ce2f` means Train 2 (c1c9d44a) had it reserved," >> "$OUT"
echo "but now Train 3 (4471ce2f) is taking over. This happens repeatedly as Train 3 gets closer." >> "$OUT"
echo "" >> "$OUT"

echo "**Lines 255602-255610** - Repeated reserveFor() calls as Train 3 approaches:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '255602,255610p' "$LOG" | grep "aa4feb96.*reserveFor" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "**Line 255604** - Train 3 actually leaves Yard Lead 2a:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '255604p' "$LOG" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "### Phase 4: Train 3 Arrives at e1e37bfd (The CORRECT Loader 1) - Not aa4feb96!" >> "$OUT"
echo "" >> "$OUT"
echo "**Line 286959-286960** - Train 3 arrives at station e1e37bfd (Loader 1):" >> "$OUT"
echo '```' >> "$OUT"
sed -n '286959,286960p' "$LOG" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "🔍 **KEY OBSERVATION**: Train 3 arrived at `e1e37bfd` (Loader 1), NOT `aa4feb96` (also Loader 1)!" >> "$OUT"
echo "These are two different stations with the same name!" >> "$OUT"
echo "" >> "$OUT"

echo "**Station e1e37bfd detecting Train 3's presence (around line 287000)**:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '287000,287050p' "$LOG" | grep "e1e37bfd" | head -10 >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "### Phase 5: Train 3 Departs e1e37bfd - Only e1e37bfd Gets cancelReservation!" >> "$OUT"
echo "" >> "$OUT"
echo "**Line 290246** - Train 3 leaves e1e37bfd:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '290246p' "$LOG" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "**Around line 290246** - Station e1e37bfd cancels its reservation:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '290240,290260p' "$LOG" | grep -E "(e1e37bfd|4471ce2f)" | grep -E "(trainDeparted|cancelReservation)" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "🚨 **THE BUG MANIFESTS**: Station e1e37bfd cancelled its reservation, but station aa4feb96" >> "$OUT"
echo "(which Train 3 NEVER visited) still has Train 3 reserved!" >> "$OUT"
echo "" >> "$OUT"

echo "### Phase 6: Train 3 Moves On - aa4feb96 Keeps Stale Reservation" >> "$OUT"
echo "" >> "$OUT"
echo "**Line 290592-290593** - Train 3 arrives at next station (Loader 2b - 71adee51):" >> "$OUT"
echo '```' >> "$OUT"
sed -n '290592,290593p' "$LOG" >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "**Station aa4feb96 still thinks it has Train 3 (around line 290000-291000)**:" >> "$OUT"
echo '```' >> "$OUT"
sed -n '290000,291000p' "$LOG" | grep "aa4feb96" | grep "4471ce2f" | head -10 >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "### Phase 7: The Stale Reservation Persists - Rejecting Other Trains" >> "$OUT"
echo "" >> "$OUT"
echo "Station aa4feb96 continues to reject other trains because it thinks Train 3 is 'closer'." >> "$OUT"
echo "" >> "$OUT"

echo "**Later examples where aa4feb96 rejects Train 2 (c1c9d44a)**:" >> "$OUT"
echo '```' >> "$OUT"
grep -n "aa4feb96.*reserveFor" "$LOG" | grep "c1c9d44a" | grep "reservation kept with train 4471ce2f" | head -5 >> "$OUT"
echo '```' >> "$OUT"
echo "" >> "$OUT"

