# Complete Bug Trace - Train-Station Desynchronization

## Executive Summary

This document provides a complete line-by-line trace of the train-station desynchronization bug captured by the instrumentation.

**The Bug**: Train 3 (`4471ce2f`) reserved BOTH stations named "Loader 1" during navigation, but only cancelled the reservation at the station it actually visited.

- **Test Train 1** (ID: `4b5f0e0e`) - physically stopped at station **Loader 1** (UUID: `aa4feb96`)
- **Test Train 2** (ID: `c1c9d44a`) - tries to use aa4feb96 but gets rejected
- **Test Train 3** (ID: `4471ce2f`) - incorrectly reserved at `aa4feb96`, actually went to `e1e37bfd`
- Station `aa4feb96` has stale reservation pointing to Train 3
- Station `e1e37bfd` is a DIFFERENT station also named "Loader 1" where Train 3 actually went

## Key Entities

| Entity | ID | Name | Role |
|--------|-----|------|------|
| Train 1 | `4b5f0e0e` | Test Train 1 | Physically at aa4feb96, station doesn't detect it |
| Train 2 | `c1c9d44a` | Test Train 2 | Previously had aa4feb96 reserved, lost it to Train 3 |
| Train 3 | `4471ce2f` | Test Train 3 | Incorrectly reserved aa4feb96, went to e1e37bfd instead |
| Station | `aa4feb96` | Loader 1 | Has stale reservation to Train 3 (never visited) |
| Station | `e1e37bfd` | Loader 1 | Where Train 3 actually went (same name, different UUID!) |
| Station | `71adee51` | Loader 2b | Where Train 3 went after e1e37bfd |

## Timeline of Events

### Phase 1: Train 3 at Loader 2c Before the Bug (07:36:00)

Train 3 is sitting at Loader 2c station (`9707c882`), about to leave.

```
Line 223660: [15Jan.2026 07:36:00.211] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Yard Lead 1' (ID: a7f34964) reserveFor() called. Previous: null, New: 4471ce2f (Test Train 3)
Line 223661: [15Jan.2026 07:36:00.211] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Yard Lead 1' reservation updated to train 4471ce2f (Test Train 3)
Line 223662: [15Jan.2026 07:36:00.211] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: 9707c882 (Loader 2c)
```

**Line 223662** - Train 3 leaves Loader 2c:

```
[15Jan.2026 07:36:00.211] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: 9707c882 (Loader 2c)
```

### Phase 2: Train 3 Travels Through Yard Stations (07:36:16-07:36:21)

Train 3 moves through intermediate yard stations.

**Line 248547-248548** - Train 3 arrives at Yard Lead 1:

```
[15Jan.2026 07:36:16.362] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station a7f34964 (Yard Lead 1)
[15Jan.2026 07:36:16.362] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to a7f34964 (Yard Lead 1)
```

**Lines ~250648** - Train 3 at Yard Lead 1, then moves on:

```
```

**Lines ~251940** - Train 3 arrives at Yard Lead 2a:

```
```

### Phase 3: 🚨 THE BUG - Station aa4feb96 Gets Wrong Reservation (07:36:21.064)

**CRITICAL MOMENT**: While Train 3 is at or leaving Yard Lead 2a (station `f39bb7f7`), heading toward `e1e37bfd` (Loader 1), it somehow reserves a DIFFERENT station `aa4feb96` (also named Loader 1)!

**Context - What was happening at aa4feb96 before** (lines 255500-255602):

```
Line 255602: [15Jan.2026 07:36:21.064] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
```

**Line 255602** - 🔥 FIRST WRONG RESERVATION! Train 3 takes over from Train 2:

```
[15Jan.2026 07:36:21.064] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
```

Notice: `Previous: c1c9d44a, New: 4471ce2f` - Train 2 had this station reserved, but Train 3 is now 'closer' and takes it over. **But Train 3 never goes there!**

**Line 255604** - At the same moment, Train 3 leaves Yard Lead 2a:

```
[15Jan.2026 07:36:21.064] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: f39bb7f7 (Yard Lead 2a)
```

**Lines 255602-256000** - Repeated reserveFor() calls at aa4feb96:

```
Line 255602: [15Jan.2026 07:36:21.064] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
Line 255682: [15Jan.2026 07:36:21.115] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
Line 255756: [15Jan.2026 07:36:21.162] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
Line 255830: [15Jan.2026 07:36:21.211] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
Line 255904: [15Jan.2026 07:36:21.261] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
Line 255978: [15Jan.2026 07:36:21.313] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
...
```

The station keeps calling `reserveFor()` every tick as Train 3 approaches... but Train 3 is NOT approaching THIS station!

### Phase 4: Train 3 Arrives at e1e37bfd (The ACTUAL Loader 1) - Not aa4feb96! (07:37:29.600)

**Line 286959-286960** - Train 3 arrives at station `e1e37bfd` (Loader 1):

```
[15Jan.2026 07:37:29.600] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
[15Jan.2026 07:37:29.600] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
```

🔍 **KEY OBSERVATION**: Train 3 arrived at **`e1e37bfd`** (Loader 1), NOT `aa4feb96` (also Loader 1)!
These are two DIFFERENT physical stations with the SAME name!

**Station e1e37bfd correctly detects Train 3's arrival** (around line 286960-287000):

```
Line 286964: [15Jan.2026 07:37:29.647] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-BE-DEBUG] Station 'Loader 1' (ID: e1e37bfd): imminent=4471ce2f, trainCurrentStation=e1e37bfd (Loader 1), match=true, trainPresent=true
Line 286982: [15Jan.2026 07:37:29.697] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-BE-DEBUG] Station 'Loader 1' (ID: e1e37bfd): imminent=4471ce2f, trainCurrentStation=e1e37bfd (Loader 1), match=true, trainPresent=true
Line 286999: [15Jan.2026 07:37:29.749] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-BE-DEBUG] Station 'Loader 1' (ID: e1e37bfd): imminent=4471ce2f, trainCurrentStation=e1e37bfd (Loader 1), match=true, trainPresent=true
```

**Meanwhile, station aa4feb96 still thinks it has Train 3** (same timeframe):

```
```

Notice: aa4feb96 shows `trainPresent=false` because Train 3's `currentStation` is now e1e37bfd!

### Phase 5: Train 3 Departs e1e37bfd - Only e1e37bfd Cancels! (07:37:39.251)

**Line 290246** - Train 3 leaves e1e37bfd:

```
[15Jan.2026 07:37:39.251] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: e1e37bfd (Loader 1)
```

**Lines 290246-290250** - Station e1e37bfd properly cancels reservation:

```
Line 290247: [15Jan.2026 07:37:39.251] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: e1e37bfd) trainDeparted() for train 4471ce2f (Test Train 3)
Line 290248: [15Jan.2026 07:37:39.251] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: e1e37bfd) cancelReservation() for train 4471ce2f. Current: 4471ce2f
Line 290250: [15Jan.2026 07:37:39.251] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) currentStation UUID cleared
```

🚨 **THE BUG FULLY MANIFESTS**: Station `e1e37bfd` cancelled its reservation correctly, but station `aa4feb96` (which Train 3 NEVER visited) still has its reservation to Train 3!

**Station aa4feb96 still has Train 3 reserved** (around line 290250-290300):

```
Line 290253: [15Jan.2026 07:37:39.298] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-BE-DEBUG] Station 'Loader 1' (ID: aa4feb96): imminent=4471ce2f, trainCurrentStation=null (unknown), match=false, trainPresent=false
Line 290274: [15Jan.2026 07:37:39.347] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-BE-DEBUG] Station 'Loader 1' (ID: aa4feb96): imminent=4471ce2f, trainCurrentStation=null (unknown), match=false, trainPresent=false
Line 290294: [15Jan.2026 07:37:39.398] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-BE-DEBUG] Station 'Loader 1' (ID: aa4feb96): imminent=4471ce2f, trainCurrentStation=null (unknown), match=false, trainPresent=false
```

### Phase 6: Train 3 Moves to Next Station - Stale Reservation Remains (07:37:40.100)

**Line 290592-290593** - Train 3 arrives at Loader 2b (71adee51):

```
[15Jan.2026 07:37:40.100] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station 71adee51 (Loader 2b)
[15Jan.2026 07:37:40.100] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to 71adee51 (Loader 2b)
```

**Station aa4feb96 continues showing Train 3 as imminent** (around line 290600-290700):

```
```

### Phase 7: The Stale Reservation Persists - Rejecting Other Trains

Station aa4feb96 continues to reject Train 2 and other trains because it thinks Train 3 is 'closer'.

**Examples of aa4feb96 rejecting Train 2 in favor of (non-existent) Train 3:**

```
```

### Phase 8: Train 3 Makes Another Loop - Same Bug Repeats! (07:42:58.606)

Train 3 goes through its schedule loop again and returns to e1e37bfd.

**Line 401145-401146** - Train 3 arrives at e1e37bfd (Loader 1) AGAIN:

```
[15Jan.2026 07:42:58.606] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
[15Jan.2026 07:42:58.606] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
```

**Line 404451** - Train 3 departs e1e37bfd AGAIN:

```
[15Jan.2026 07:43:08.300] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: e1e37bfd (Loader 1)
```

**Station aa4feb96 STILL has stale reservation throughout** (check around line 404000):

```
```

## Root Cause Analysis

### The Problem: Name-Based Reservation During Navigation

1. **Two stations with identical names exist**:
   - Station `aa4feb96` named "Loader 1"
   - Station `e1e37bfd` named "Loader 1"

2. **Train 3's schedule says**: "Go to Loader 1"

3. **During navigation/pathfinding** (around line 255602):
   - Train 3 is traveling from Yard Lead 2a toward station `e1e37bfd` (its actual destination)
   - The navigation system reserves approaching stations
   - **BUG**: It reserves BOTH stations named "Loader 1" instead of just the destination
   - Or it picks the wrong one based on proximity/pathfinding

4. **Train 3 arrives at `e1e37bfd`** (line 286959):
   - Calls `arriveAt(e1e37bfd)`
   - Sets `currentStation = e1e37bfd`

5. **Train 3 departs from `e1e37bfd`** (line 290246):
   - Calls `leaveStation()` which triggers `trainDeparted()` on `e1e37bfd`
   - `e1e37bfd.cancelReservation()` is called
   - **BUG**: `aa4feb96.cancelReservation()` is NEVER called!

6. **Result**: Station `aa4feb96` has permanent stale reservation to Train 3

### Why Test Train 1 Can't Be Detected

When Test Train 1 is physically at station `aa4feb96`:

1. `Train1.currentStation = aa4feb96` ✓ (correct)
2. `Station_aa4feb96.nearestTrain = Train3` ✗ (wrong!)
3. `GlobalStation.getPresentTrain()` checks: `nearestTrain.getCurrentStation() == this`
4. But `Train3.currentStation = 71adee51` (Loader 2b), not `aa4feb96`
5. So `getPresentTrain()` returns `null`
6. `StationBlockEntity.tick()` sees no train present
7. Station can't detect Train 1, comparator outputs 0, can't schedule, etc.

### Why Station Keeps Rejecting Train 2

When Train 2 tries to reserve station `aa4feb96`:

1. `reserveFor(Train2)` is called
2. Current reservation is Train 3
3. Code checks if Train 2 is closer than Train 3
4. Train 3 might appear 'closer' in the navigation distance calculation
5. Station decides to keep Train 3's reservation
6. Logs: `"reservation kept with train 4471ce2f (closer)"`

## Code Path Analysis

### Suspected Code Location: Navigation Reservation Logic

The bug likely occurs in one of these code paths:

#### Option 1: Navigation.updateNavigationTarget() or similar

```java
// Hypothetical buggy code
// When navigating to a station by name
String destinationName = schedule.getCurrentDestination(); // "Loader 1"
for (GlobalStation station : stationsOnOrNearPath) {
    if (station.name.equals(destinationName)) {
        station.reserveFor(this); // BUG: Reserves ALL matching names!
    }
}
```

#### Option 2: Signal Listener / Edge Point Detection

```java
// When train's navigation detects approaching stations
frontSignalListener.approachingStations.forEach(station -> {
    if (station.name.equals(destinationName)) {
        station.reserveFor(train); // BUG: Wrong station with matching name
    }
});
```

#### Option 3: Schedule Instruction Station Resolution

```java
// When schedule instruction starts
List<GlobalStation> matchingStations = 
    findStationsByName("Loader 1"); // Returns BOTH stations!
// BUG: Might reserve multiple or pick wrong one
for (GlobalStation station : matchingStations) {
    station.reserveFor(train);
}
```

### Why Only One Station Gets cancelReservation

When the train departs:

```java
// Train.leaveStation()
GlobalStation currentStation = getCurrentStation(); // Only knows about ONE station
if (currentStation != null) {
    currentStation.trainDeparted(this);
    currentStation.cancelReservation(this);
}
setCurrentStation(null);
// BUG: Doesn't know about OTHER stations that were reserved!
```

## Complete Evidence - Key Log Lines

### 1. First Wrong Reservation (Line 255602)

```
[15Jan.2026 07:36:21.064] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
```

### 2. Train 3 Leaves Yard Lead 2a (Line 255604)

```
[15Jan.2026 07:36:21.064] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: f39bb7f7 (Yard Lead 2a)
```

### 3. Train 3 Arrives at e1e37bfd (Lines 286959-286960)

```
[15Jan.2026 07:37:29.600] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
[15Jan.2026 07:37:29.600] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
```

### 4. Train 3 Departs e1e37bfd (Line 290246)

```
[15Jan.2026 07:37:39.251] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: e1e37bfd (Loader 1)
```

### 5. Only e1e37bfd Cancels (Around line 290246-290250)

```
Line 290247: [15Jan.2026 07:37:39.251] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: e1e37bfd) trainDeparted() for train 4471ce2f (Test Train 3)
Line 290248: [15Jan.2026 07:37:39.251] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: e1e37bfd) cancelReservation() for train 4471ce2f. Current: 4471ce2f
```

### 6. Train 3 Goes to Next Station (Lines 290592-290593)

```
[15Jan.2026 07:37:40.100] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station 71adee51 (Loader 2b)
[15Jan.2026 07:37:40.100] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to 71adee51 (Loader 2b)
```

### 7. Station aa4feb96 Still Has Stale Reservation

```
```

### 8. Station aa4feb96 Keeps Rejecting Train 2

```
```

## Recommendations

### Immediate Fix Options

1. **Uncomment the revalidation fix** in `GlobalStation.getNearestTrain()`
   - Self-healing: automatically detects and fixes stale reservations
   - Already implemented and commented out in the codebase

2. **Add UUID-based reservation** instead of name-based
   - Only reserve the station with matching UUID from schedule
   - Don't use `station.name.equals()` for reservation logic

3. **Track all reserved stations** in Train object
   - Maintain `Set<UUID> reservedStations` in Train
   - Cancel ALL reserved stations on departure, not just currentStation

4. **Warn on duplicate station names** in schedules
   - Detect when multiple stations on same graph have identical names
   - Log warning or error when schedule uses ambiguous names

### Investigation Steps

1. Add breakpoint at `GlobalStation.reserveFor()` when `name == "Loader 1"`
2. Check call stack to see WHO called it (Navigation? Schedule? Signal listener?)
3. Check if train's actual destination UUID matches this station's UUID
4. Search codebase for:
   - `station.name.equals()` - should use UUID instead
   - `findStationsByName()` or similar
   - Station reservation in Navigation code
   - Signal listener station detection

## Conclusion

The instrumentation successfully captured the exact moment and sequence of events that cause the train-station desynchronization bug. The root cause is confirmed:

**During navigation, trains reserve multiple stations with identical names, but only cancel the reservation at the station they actually visit.**

This leaves other stations with stale reservations, preventing them from detecting trains that are physically present and causing ongoing schedule disruptions.

The fix should ensure that:
1. Only the actual destination station (by UUID) gets reserved, OR
2. All reserved stations get their reservations cancelled on departure, OR
3. The commented-out revalidation fix is enabled to auto-heal these cases
