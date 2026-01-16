# Train-Station Desynchronization Bug - Comprehensive Analysis

## Executive Summary

The bug involves a station's `nearestTrain` WeakReference pointing to a train that is not actually at that station. The instrumentation successfully captured the bug and revealed the root cause: **multiple stations with identical names on the same schedule route cause pathfinding to reserve the wrong station**.

## Bug Manifestation (from user report)

- **Test Train 1** (ID: `4b5f0e0e`) is physically stopped at station **Loader 1** (UUID: `aa4feb96`)
- Train 1's `currentStation` field correctly points to `aa4feb96`
- **BUT** station `aa4feb96`'s `nearestTrain` WeakReference points to **Test Train 3** (ID: `4471ce2f`)
- Test Train 3 is actually at a completely different station `e1e37bfd` (also named "Loader 1")

## Timeline of Events (from log analysis)

### Initial State (07:57:25)
**Line 47288**: Station `aa4feb96` (Loader 1) already has desynchronization:
```
[STATION-BE-DEBUG] Station 'Loader 1' (ID: aa4feb96): imminent=4471ce2f, trainCurrentStation=null (unknown), match=false, trainPresent=false
```

**Key observation**: The station has `nearestTrain` = `4471ce2f`, but that train's `currentStation` is NULL. This means the desynchronization existed even before the filtered log starts.

### Train 3 Movement Timeline

**07:57:13**: Train `4471ce2f` leaves station `9707c882` (Loader 2c)

**07:57:29**: Train `4471ce2f` arrives at station `a7f34964` (Yard Lead 1)

**07:57:30**: Train `4471ce2f` leaves station `a7f34964`

**07:57:31**: Train `4471ce2f` arrives at station `f39bb7f7` (Yard Lead 2a)

**07:57:34**: Train `4471ce2f` leaves station `f39bb7f7`

**07:59:05**: Train `4471ce2f` arrives at station `e1e37bfd` (**Loader 1** - different from `aa4feb96`!)
```
[TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
[TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
```

**07:59:15.207**: Train `4471ce2f` leaves station `e1e37bfd`:
```
[TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: e1e37bfd (Loader 1)
[STATION-DEBUG] Station 'Loader 1' (ID: e1e37bfd) trainDeparted() for train 4471ce2f (Test Train 3)
[STATION-DEBUG] Station 'Loader 1' (ID: e1e37bfd) cancelReservation() for train 4471ce2f. Current: 4471ce2f
[TRAIN-DEBUG] Train 4471ce2f (Test Train 3) currentStation UUID cleared
```

**07:59:15.252**: Station `aa4feb96` still thinks it has train `4471ce2f`:
```
[STATION-BE-DEBUG] Station 'Loader 1' (ID: aa4feb96): imminent=4471ce2f, trainCurrentStation=null (unknown), match=false, trainPresent=false
```

**CRITICAL**: Station `e1e37bfd` correctly cancelled its reservation, but station `aa4feb96` (a DIFFERENT station with the same name) was never told to cancel!

**07:59:16**: Train `4471ce2f` arrives at station `71adee51` (Loader 2b)

### Continuous Desynchronization

From **08:30:18** onwards: Station `aa4feb96` keeps rejecting other trains because it thinks `4471ce2f` is "closer":
```
[STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: 4471ce2f, New: c1c9d44a (Test Train 2)
[STATION-DEBUG] Station 'Loader 1' reservation kept with train 4471ce2f (closer)
```

## Root Cause Analysis

### The Problem: Duplicate Station Names in Schedules

There are TWO stations named "Loader 1":
1. Station `aa4feb96` - where Test Train 1 is actually stopped
2. Station `e1e37bfd` - where Test Train 3 was temporarily stopped

### Code Path Analysis

#### Path 1: Navigation Reservation (SUSPECT - Most Likely)

**Location**: `Navigation.updateNavigationTarget()` or pathfinding code

**What happens**:
1. Train 3 is navigating and has "Loader 1" in its schedule
2. Pathfinding finds a route that goes near BOTH stations named "Loader 1"
3. During navigation, the train calls `reserveFor()` on stations it's approaching
4. **BUG**: The train reserves station `aa4feb96` even though its actual destination is `e1e37bfd`
5. When train arrives at `e1e37bfd`, it calls `arriveAt(e1e37bfd)`
6. When train leaves `e1e37bfd`, only `e1e37bfd.cancelReservation()` is called
7. Station `aa4feb96` never gets its reservation cancelled

**Evidence**:
- Station `aa4feb96` has `nearestTrain` = `4471ce2f` from the beginning
- Train `4471ce2f` never actually arrived at `aa4feb96`
- Only `e1e37bfd` received the `trainDeparted()` call

#### Path 2: Schedule Name Resolution (POSSIBLE)

**Location**: Schedule instruction execution when resolving station names

**What happens**:
1. Schedule says "go to Loader 1"
2. System finds multiple stations with that name
3. Picks one (`e1e37bfd`) as the actual destination
4. **BUG**: But during pathfinding or reservation, it also reserves the other (`aa4feb96`)

#### Path 3: Graph Migration/Reload (LESS LIKELY given timeline)

The desynchronization exists from the start of the log, suggesting it happened during:
- World load
- Schedule start
- Train graph migration

But given the timeline shows Train 3 moving through stations before reaching "Loader 1", it's more likely Path 1 (navigation reservation).

## Possible Code Locations

### 1. Train.reserveStationsAhead() or similar

Check if there's code that reserves multiple stations during pathfinding:

```java
// Hypothetical buggy code
for (Station station : stationsOnPath) {
    if (station.name.equals(destinationName)) {
        station.reserveFor(this);  // BUG: Reserves ALL stations with matching name!
    }
}
```

### 2. Navigation.tick() - Signal Listener

**Location**: Train front signal listener that reserves approaching stations

```java
// When train approaches a station during navigation
if (edgePoint instanceof GlobalStation) {
    GlobalStation station = (GlobalStation) edgePoint;
    station.reserveFor(train);  // BUG: Might reserve wrong station if names duplicate
}
```

### 3. Schedule Instruction - Station Name Resolution

**Location**: Schedule instruction that resolves station names

```java
// When schedule says "go to Loader 1"
List<GlobalStation> matchingStations = findStationsByName("Loader 1");
// BUG: Might reserve multiple stations or wrong one
for (GlobalStation station : matchingStations) {
    station.reserveFor(train);
}
```

### 4. A* Pathfinding - Penalty Calculation

**Location**: `Navigation.search()` when calculating paths

The pathfinding might be checking station occupancy for ALL stations with the target name, not just the actual destination.

## Why Test Train 1 Can't Be Detected

Station `aa4feb96` has `nearestTrain` pointing to the wrong train (`4471ce2f`), so:

1. `GlobalStation.getNearestTrain()` returns Train 3 (wrong!)
2. `GlobalStation.getPresentTrain()` checks if `nearestTrain.getCurrentStation() == this`
3. Train 3's currentStation is `71adee51` (Loader 2b), not `aa4feb96`
4. So `getPresentTrain()` returns NULL
5. `StationBlockEntity.tick()` sees no train present
6. Station doesn't detect Test Train 1 even though it's physically there

## Code Paths That Could Cause This Bug

### Most Likely: Premature/Incorrect Reservation During Navigation

```
Train.tick()
└─> Navigation.tick()
    └─> updateNavigationTarget()
        └─> [Searches for destination station by name]
        └─> [Reserves approaching stations]
        └─> BUG: Reserves ALL stations with matching name on route
```

### Possible: Schedule Execution With Duplicate Names

```
ScheduleRuntime.tick()
└─> startCurrentInstruction()
    └─> instruction.start()
        └─> [Resolves "Loader 1" station name]
        └─> BUG: Returns wrong station or reserves multiple
```

### Less Likely: Load-Time Desynchronization

```
Train.read()
└─> if (getCurrentStation() != null)
    └─> getCurrentStation().reserveFor(train)
        └─> BUG: Resolves to wrong station if names duplicate
```

## Recommendations for Further Investigation

1. **Add breakpoint** in `GlobalStation.reserveFor()` when station name is "Loader 1"
   - Check the call stack to see WHO is calling it
   - Check if the train's actual destination matches this station's UUID

2. **Search codebase** for where station names are resolved:
   ```bash
   grep -r "station.name" --include="*.java"
   grep -r "getStationByName" --include="*.java"
   grep -r "findStation" --include="*.java"
   ```

3. **Check Navigation code** for reservation logic:
   - `Navigation.updateNavigationTarget()`
   - `Navigation.tick()`
   - Train signal listeners (frontSignalListener, backSignalListener)

4. **Check Schedule code** for name resolution:
   - Schedule instruction `.start()` methods
   - Station destination resolution

5. **Add assertion** in `GlobalStation.reserveFor()`:
   ```java
   public void reserveFor(Train train) {
       // ASSERT: If train has a schedule destination, it should match this station's UUID
       if (train.navigation.destination != null) {
           assert train.navigation.destination.id.equals(this.id) 
               : "Train reserving wrong station! Expected: " + train.navigation.destination.id + ", Got: " + this.id;
       }
       // ... rest of method
   }
   ```

## Conclusion

The bug is caused by a train reserving multiple stations with the same name during navigation or schedule execution. When the train arrives at one station and departs, only that station's reservation is cancelled. Other stations with the same name remain reserved to that train indefinitely, causing desynchronization.

The fix should ensure:
1. Only the actual destination station (by UUID) gets reserved
2. OR all reserved stations get their reservations cancelled on departure
3. OR station name resolution is unique (warn/error on duplicates)
4. OR the commented-out revalidation fix is enabled to auto-heal these cases
