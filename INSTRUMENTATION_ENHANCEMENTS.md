# Enhanced Instrumentation Plan

## Critical Missing Instrumentation Identified

Based on the 65-second gap analysis, we need to capture:

1. **Stack Traces for State Changes**: Log stack traces when `nearestTrain` WeakReference changes
2. **Distance Calculation Logging**: Log when/how `distanceToDestination` is calculated and updated
3. **Direct Assignment Detection**: Ensure NO code path bypasses `reserveFor()`
4. **Navigation State Logging**: Log complete navigation state when reserving stations
5. **Train Lifecycle Events**: Log train invalidation, destruction, route changes

## Files to Enhance

### GlobalStation.java
- Add stack trace to `reserveFor()` when reservation changes
- Add stack trace to `cancelReservation()`
- Log complete train navigation state in `reserveFor()`
- Add assertions to detect direct `nearestTrain` assignments

### Navigation.java
- Log stack trace when calling `destination.reserveFor()`
- Log `distanceToDestination` value and calculation
- Log when destination changes
- Log when navigation is cancelled

### Train.java
- Add stack trace to `arriveAt()` and `leaveStation()`
- Log when train becomes invalid
- Log when train is destroyed
- Log complete state in critical operations

### StationBlockEntity.java
- Enhanced logging in tick() with more context
- Log complete station state when desync detected

## Stack Trace Strategy

Only log stack traces for:
- Actual state changes (not queries)
- When reservation changes owner
- When train arrives/departs
- When navigation target changes

This keeps logs manageable while capturing all critical code paths.
