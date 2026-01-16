# Create Mod - Train System Architecture Documentation

**Version**: 1.0  
**Date**: 2026-01-14  
**Purpose**: Comprehensive documentation of the train system for debugging train-station desynchronization issues

---

## Table of Contents
1. [System Overview](#system-overview)
2. [Train Lifecycle](#train-lifecycle)
3. [Navigation System](#navigation-system)
4. [Station System](#station-system)
5. [Schedule System](#schedule-system)
6. [State Management](#state-management)
7. [Track Graph](#track-graph)
8. [Synchronization](#synchronization)
9. [Signal System](#signal-system)
10. [Critical Code Paths](#critical-code-paths)
11. [Known Issues](#known-issues)

---

## System Overview

The Create mod's train system is a sophisticated rail network simulation operating at three core levels:

- **Entities**: `Train` and `Carriage` objects representing physical trains
- **Infrastructure**: `TrackGraph` and `GlobalStation` managing rail networks
- **Management**: `GlobalRailwayManager` coordinating all trains and networks

### Key Design Patterns

1. **WeakReference Caching**: `GlobalStation.nearestTrain` uses WeakReference to prevent memory leaks
2. **Penalty-based Routing**: Navigation uses cost penalties instead of hardcoded paths
3. **State Machine Architecture**: Schedules and navigation use explicit state machines
4. **Event-driven Sync**: Client-server uses event packets, not polling
5. **NBT Persistence**: Full train state serialization for world saves

---

## Train Lifecycle

### 1. Train Creation (Assembly)

**Entry Point**: `StationBlockEntity.assemble()` (lines 668-900)

**Process Flow**:
```
1. Player initiates assembly at station
2. Scan track for bogey blocks in assembly direction
3. Validate bogey spacing (minimum 3 blocks apart)
4. Create CarriageContraption for each bogey pair
5. Extract blocks into contraption
6. Instantiate Train with UUID, owner, graph, carriages
7. Initialize Navigation and ScheduleRuntime
8. Set currentStation via setCurrentStation(station)
9. Register with GlobalRailwayManager.trains
10. Broadcast AddTrainPacket to clients
```

**Key Validation Rules**:
- Frontmost bogey must be at station position
- Bogeys must be 3+ blocks apart
- Must have at least one forward-facing control carriage
- Bogeys must be in sequential order along track

**Code Location**: `StationBlockEntity.java:668-900`

### 2. Train Persistence

**Serialization**: `Train.write()` (lines 1158-1205)
**Deserialization**: `Train.read()` (lines 1207-1253)

**Persisted State**:
```java
{
  Id: UUID                          // Train unique identifier
  Owner: UUID                       // Player who assembled
  Graph: UUID                       // Current track graph
  Carriages: List<Carriage>         // All train cars
  CarriageSpacing: int[]            // Distance between cars
  Speed: double                     // Current speed
  TargetSpeed: double               // Desired speed
  Throttle: double                  // Speed multiplier
  Station: UUID                     // Current station (KEY FOR BUG)
  Navigation: CompoundTag           // Path and destination
  Runtime: CompoundTag              // Schedule state
  SignalBlocks: Map<UUID, UUID>     // Occupied signals
  ReservedSignalBlocks: Set<UUID>   // Reserved signals
  Derailed: boolean                 // Derailment state
  MigratingPoints: List             // For graph transitions
}
```

**Critical Load-time Code** (lines 1248-1250):
```java
if (train.getCurrentStation() != null)
    train.getCurrentStation().reserveFor(train);
```

This re-establishes the bidirectional train↔station relationship after deserialization.

### 3. Train Destruction

**Entry Point**: `Train.disassemble()` (lines 757-809)

**Process Flow**:
```
1. Validate canDisassemble() conditions
2. Return contraption blocks to inventory
3. Preserve bogey data for re-assembly
4. Update station with train name/color
5. Remove from GlobalRailwayManager.trains
6. Broadcast RemoveTrainPacket
```

---

## Navigation System

### 1. Pathfinding Algorithm

**Implementation**: `Navigation.search()` (lines 595-801)
**Algorithm**: A* with penalty-based cost function

**Cost Calculation**:
```
total_cost = distance + penalty + heuristic_remaining
```

**Penalty Types** (defined in Train class):
```java
RED_SIGNAL = 25              // Occupied signal passage
REDSTONE_RED_SIGNAL = 400    // Forced red (redstone controlled)
STATION = 50                 // Station occupancy
STATION_WITH_TRAIN = 300     // Other train at station
MANUAL_TRAIN = 200           // Manual mode trains
IDLE_TRAIN = 700             // Trains without schedule
ARRIVING_TRAIN = 50          // Trains near destination
WAITING_TRAIN = 50+          // Trains waiting for signals
```

**Key Features**:
- Signal-aware: checks SignalEdgeGroup occupancy
- Redstone-aware: checks SignalBoundary forced red state
- Penalty accumulation: avoids occupied segments
- Bidirectional: evaluates forward and backward for double-ended trains

### 2. Navigation Execution

**Tick Loop**: `Navigation.tick()` (lines 73-290)

**Speed Control Logic**:
```java
brakingDistance = speed² / (2 × acceleration)

if (distanceToDestination < brakingDistance) {
    // Braking phase
    speed = maxApproachSpeed × (distanceToDestination / 10)
} else if (distanceToDestination < 10) {
    // Final approach
    speed = topSpeed × speedMod
} else {
    // Normal travel
    speed = targetSpeed
}
```

**Signal Handling** (lines 107-233):
1. **Signal Scout**: Separate TravellingPoint scans ahead
2. **Cross-Signal Chains**: Track multi-segment red signals
3. **Reservation**: Mark groups as reserved if clear
4. **Waiting**: Set waitingForSignal if blocked
5. **Resolution**: Clear wait when signal green

### 3. Path Following

**Method**: `Navigation.control()` (lines 347-373)

**Modes**:
- **Manual**: Uses `manualSteer` from conductor input
- **Automated**: Follows pre-calculated `currentPath`

**Path Consumption**:
```java
// Match next edge in path list
// Consume matched edge from path
// If path empty, use default first option
```

---

## Station System

### 1. GlobalStation Structure

**File**: `GlobalStation.java`

**Fields**:
```java
String name                                    // Station display name
WeakReference<Train> nearestTrain             // Reserved train (CRITICAL!)
boolean assembling                            // Assembly mode active
Map<BlockPos, GlobalPackagePort> connectedPorts  // Mail system
```

**Critical Methods**:

| Method | Purpose | Lines |
|--------|---------|-------|
| `reserveFor(Train)` | Mark train as approaching | 123-128 |
| `cancelReservation(Train)` | Clear reservation | 130-133 |
| `trainDeparted(Train)` | Handle train departure | 135-137 |
| `getPresentTrain()` | Get train if at station | 139-145 |
| `getImminentTrain()` | Get approaching train | 147-159 |
| `getNearestTrain()` | Get reserved train | 161-164 |

**BUG LOCATION - WeakReference Reset**:

In `GlobalStation.read()` (line 66):
```java
nearestTrain = new WeakReference<>(null);
```

This resets the WeakReference during deserialization. If the station is reloaded after trains are loaded, the bidirectional relationship breaks.

### 2. StationBlockEntity Integration

**File**: `StationBlockEntity.java`

**Tracked State** (lines 114-122):
```java
UUID imminentTrain              // Approaching train ID
boolean trainPresent            // Train at station
boolean trainBackwards          // Train direction
boolean trainCanDisassemble     // Disassembly ready
boolean trainHasSchedule        // Has schedule
boolean trainHasAutoSchedule    // Auto-schedule active
```

**Tick Logic** (lines 271-322):
```java
1. Query: GlobalStation.getImminentTrain()
2. Check: imminentTrain.getCurrentStation() == station
3. Update: trainPresent = (imminent && at station)
4. Sync: Notify client if state changed
5. Events: Fire ComputerCraft events (IMMINENT/ARRIVAL/DEPARTURE)
6. Schedule: Apply auto-schedule if newly arrived
```

**Critical Line** (line 276):
```java
boolean trainPresent = imminentTrain != null && imminentTrain.getCurrentStation() == station;
```

This is where the desynchronization manifests. If `getImminentTrain()` returns null (because WeakReference is null), but the train's `currentStation` still points here, the bug occurs.

### 3. Train Arrival/Departure

**Arrival** (`Train.arriveAt()`, lines 953-959):
```java
1. setCurrentStation(station)          // Store station UUID
2. reservedSignalBlocks.clear()        // Release signals
3. runtime.destinationReached()        // Notify schedule
4. station.runMailTransfer()           // Handle mail
5. ticksSinceLastMailTransfer = 0
```

**Departure** (`Train.leaveStation()`, lines 946-951):
```java
1. currentStation.trainDeparted(this)  // Cancel reservation
2. this.currentStation = null           // Clear reference
```

---

## Schedule System

### 1. Schedule Runtime State Machine

**File**: `ScheduleRuntime.java`

**States**:
```
PRE_TRANSIT  → [startCurrentInstruction] → IN_TRANSIT
     ↑                                          ↓
     └── [destinationReached] ← POST_TRANSIT ──┘
                                   ↓
                          [tickConditions]
```

**State Transitions**:
1. **PRE_TRANSIT**: Ready to start next instruction
   - Calls `instruction.start()` to get path
   - Calls `navigation.startNavigation(path)`
   - Transitions to IN_TRANSIT
   
2. **IN_TRANSIT**: Train is moving
   - Navigation controls movement
   - No schedule updates
   - Transitions to POST_TRANSIT on arrival
   
3. **POST_TRANSIT**: At destination, checking conditions
   - Calls `tickConditions()` each tick
   - Waits for all conditions to complete
   - Transitions to PRE_TRANSIT when done

### 2. Condition Handling

**Location**: `tickConditions()` (lines 155-190)

**Process**:
```java
For each condition group in current entry:
  Get condition at progress index
  Call condition.tickCompletion(level, train, context)
  If true: increment progress, clear context
  If all groups complete: advance entry, state = PRE_TRANSIT
```

**Cyclic Behavior** (lines 143-153):
```java
if (currentEntry >= schedule.entries.size()) {
    currentEntry = 0
    if (!schedule.cyclic) {
        paused = true
        completed = true
    }
}
```

---

## State Management & Persistence

### 1. NBT Serialization

**Top Level**: `RailwaySavedData` (world save)
- All TrackGraph instances
- All Train instances  
- SignalEdgeGroup mappings

**Train NBT Structure**:
```
Train {
  Id, Owner, Graph                    // Identity
  Carriages, CarriageSpacing          // Physical structure
  Speed, Throttle, TargetSpeed        // Motion state
  Station, Backwards                  // Position state
  Navigation {...}                    // Path & destination
  Runtime {...}                       // Schedule state
  SignalBlocks, ReservedSignalBlocks  // Signal state
  Derailed, MigratingPoints           // Special states
}
```

### 2. Load-time Reattachment

**Critical Code** (`Train.read()`, lines 1248-1250):
```java
if (train.getCurrentStation() != null)
    train.getCurrentStation().reserveFor(train);
```

**Purpose**: Re-establish the train→station WeakReference after deserialization

**BUG SCENARIO**:
1. Trains are loaded first → call `reserveFor()`
2. Station is loaded → WeakReference set correctly
3. Station is reloaded (track graph modification) → WeakReference reset
4. Train's `currentStation` UUID still valid → desynchronization!

### 3. Graph Migration

**Purpose**: Handle trains when track graphs split/merge

**Process** (`Train.reattachToTracks()`, lines 883-928):
```
1. Store train's travelling points as migrations
2. Try relocating in each track graph
3. If found: assign graph, migrate points
4. If not: set cooldown, retry later
```

---

## Track Graph

### 1. Graph Structure

**File**: `TrackGraph.java`

**Core Collections**:
```java
Map<TrackNodeLocation, TrackNode> nodes
Map<Integer, TrackNode> nodesById
Map<TrackNode, Map<TrackNode, TrackEdge>> connectionsByNode
EdgePointStorage edgePoints
Map<ResourceKey<Level>, TrackGraphBounds> bounds
```

**Node**:
```java
TrackNodeLocation location      // Position + dimension
int netId                       // Network ID for sync
Vec3 normal                     // Track surface normal
```

**Edge**:
```java
TrackNode node1, node2
TrackMaterial material
BezierConnection turn           // For curves
EdgeData edgeData               // Points & intersections
```

### 2. Edge Points

**Types**: Stations, Signals, Observers

**Storage**: `EdgePointStorage` in graph

**Lifecycle**:
- Added via `TrackGraph.addPoint()`
- Removed via `TrackGraph.removePoint()`
- Queried via `TrackGraph.getPoint(type, uuid)`

**Station Edge Point** (`GlobalStation extends SingleBlockEntityEdgePoint extends TrackEdgePoint`):
- Has UUID `id` field
- Has `blockEntityPos` and `blockEntityDimension`
- Stored in graph's edge point storage

---

## Synchronization

### 1. Train Sync

**Packet**: `AddTrainPacket` / `RemoveTrainPacket`

**Stream Codec** (Train.STREAM_CODEC, lines 87-97):
```java
id, owner, carriages, spacing, doubleEnded, 
name, icon, mapColorIndex
```

**Update Frequency**: On train creation/removal only
**Position Updates**: Via carriage entity sync

### 2. Graph Sync

**Manager**: `TrackGraphSync`

**Events**:
- Node added/removed
- Edge added/removed/changed
- Point added/removed
- Signal group created/removed

**Full Sync**: On player login, sends entire graph

### 3. Dirty Marking

**Method**: `GlobalRailwayManager.markTracksDirty()`

**Triggers**:
- Node/edge modifications
- Point additions/removals
- Train creation/removal
- Graph split/merge

---

## Signal System

### 1. Signal Edge Groups

**Purpose**: Logical track segments for occupancy

**Structure**:
```java
UUID id
Set<Train> trains               // Currently occupying
SignalBoundary reserved         // Reserved by approaching
Map<UUID, UUID> intersections   // Cross-graph groups
Color color
```

**Occupancy Check**:
```java
signalEdgeGroup.isOccupiedUnless(train)
// Returns true if any OTHER train occupies
```

### 2. Signal Boundaries

**Types**:
- Entry Signal: One-way control
- Cross Signal: Multi-segment control

**Redstone Control**:
```java
signal.isForcedRed(TrackNode side)
// Checks redstone power state
```

### 3. Signal Listening

**Front Listener** (Train, lines 462-506):
```java
Called when leading point reaches edge point:
  GlobalStation → arriveAt() if proper approach
  SignalBoundary → occupy group, wait if red
  TrackObserver → track observation
```

**Back Listener** (Train, lines 530-544):
```java
Called when trailing point leaves edge point:
  Remove occupancy from signal groups
```

---

## Critical Code Paths

### Path 1: Train Movement Loop

```
GlobalRailwayManager.tick()
├─ For each train: earlyTick(level)
│  └─ addToSignalGroups(occupiedSignalBlocks)
├─ For each train: tick(level)
│  ├─ runtime.tick(level)
│  ├─ navigation.tick(level)
│  ├─ carriage.travel()
│  │  ├─ Move travelling points
│  │  ├─ Check collisions
│  │  └─ Call signal listeners
│  └─ updateNavigationTarget()
└─ addToSignalGroups(reservedSignalBlocks)
```

### Path 2: Train Arrival

```
Travelling point reaches GlobalStation:
├─ frontSignalListener() triggered
├─ Station.canApproachFrom() check
├─ Train.arriveAt(station)
│  ├─ setCurrentStation(station)      // Sets UUID
│  ├─ reservedSignalBlocks.clear()
│  ├─ runtime.destinationReached()
│  └─ station.runMailTransfer()
├─ navigation.destination = null
└─ Next tick: runtime.tickConditions()
```

### Path 3: Station Tick

```
StationBlockEntity.tick():
├─ Query: station = getStation()
├─ Query: imminentTrain = station.getImminentTrain()
│  └─ getNearestTrain()
│     └─ return nearestTrain.get()   // BUG: May return null!
├─ Check: trainPresent = imminent && imminent.getCurrentStation() == station
├─ If changed: notifyUpdate()
└─ If newly arrived: applyAutoSchedule()
```

### Path 4: Schedule Progression

```
ScheduleRuntime.tick():
├─ If state == PRE_TRANSIT:
│  ├─ startCurrentInstruction()
│  │  └─ instruction.start(runtime, level)
│  │     └─ Navigation.findPathTo(destination)
│  ├─ navigation.startNavigation(path)
│  └─ state = IN_TRANSIT
├─ If state == IN_TRANSIT:
│  └─ Wait for navigation
├─ If state == POST_TRANSIT:
│  └─ tickConditions()
└─ If conditions complete:
   ├─ currentEntry++
   └─ state = PRE_TRANSIT
```

### Path 5: Station Deserialization (BUG PATH)

```
GlobalStation.read(CompoundTag):
├─ Parse name, assembling, connectedPorts
└─ nearestTrain = new WeakReference<>(null)  // RESET!

Later, Train.read(CompoundTag):
├─ Parse all train state including currentStation UUID
└─ if (getCurrentStation() != null)
   └─ getCurrentStation().reserveFor(train)  // Tries to fix
```

**BUG CONDITION**: If station is reloaded AFTER this line executes, the WeakReference is reset again, breaking the relationship.

---

## Known Issues

### Issue 1: Train-Station Desynchronization

**Symptoms**:
- Train shows "Waiting at: Station" in `/create trains`
- Station doesn't detect train
- Comparator outputs 0
- Can't schedule train
- Station allows creating new train

**Root Cause**:
1. Train's `currentStation` UUID persists across reloads
2. Station's `nearestTrain` WeakReference resets during deserialization
3. If station reloads after train load-time reattachment, WeakReference stays null
4. Station can't find train, even though train references station

**Affected Code**:
- `GlobalStation.read()` line 66
- `GlobalStation.getNearestTrain()` line 162-164
- `StationBlockEntity.tick()` line 276

**Temporary Workaround**: Server restart

**Conditions**:
- Rare: requires specific load ordering
- Independent of chunk loading/unloading
- May occur during track graph modifications

---

## Debugging Guide

### Logging Points for Desynchronization Bug

1. **Train Load** (`Train.read()`):
   - Log train ID, currentStation UUID
   - Log if reserveFor() is called

2. **Station Load** (`GlobalStation.read()`):
   - Log station ID, name
   - Log nearestTrain state before/after reset

3. **Station Tick** (`StationBlockEntity.tick()`):
   - Log station name, imminentTrain ID
   - Log getNearestTrain() result
   - Log trainPresent calculation

4. **Train Tick** (`Train.tick()`):
   - Log train ID, currentStation
   - Log getCurrentStation() result

5. **Reservation** (`GlobalStation.reserveFor()`):
   - Log station ID, train ID
   - Log previous nearestTrain state

### Diagnostic Commands

```
/create trains          // List all trains and their states
/data get entity        // Get train entity NBT
/data get block         // Get station block NBT
```

### Expected Log Patterns

**Normal Operation**:
```
[Train Load] Train abc123 currentStation=def456
[Train Load] Calling reserveFor() on station def456
[Station Tick] Station "Storage" imminent=abc123 present=true
```

**Bug Condition**:
```
[Station Reload] Station "Storage" def456 nearestTrain reset
[Station Tick] Station "Storage" getNearestTrain()=null
[Station Tick] Station "Storage" imminent=null present=false
[Train Tick] Train abc123 currentStation=def456 getCurrentStation()=def456
```

---

## Revision History

- **1.0** (2026-01-14): Initial comprehensive documentation
- Purpose: Support debugging of train-station desynchronization issue

