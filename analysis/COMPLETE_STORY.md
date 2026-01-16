=== STEP 1: When did aa4feb96 FIRST get Train 3 (4471ce2f) reservation? ===

### Found in debug-1.log.gz:
```
255602	[15Jan.2026 07:36:21.064] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: c1c9d44a, New: 4471ce2f (Test Train 3)
```

### Found in debug-2.log.gz:
```
496001	[15Jan.2026 07:23:14.059] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: 4471ce2f, New: 4471ce2f (Test Train 3)
```

### Found in debug-3.log.gz:
```
338344	[15Jan.2026 06:56:42.359] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: null, New: 4471ce2f (Test Train 3)
```

### Found in debug-4.log.gz:
```
153665	[15Jan.2026 06:05:47.690] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) reserveFor() called. Previous: null, New: 4471ce2f (Test Train 3)
```

=== STEP 2: Did Train 3 ever ARRIVE at aa4feb96? ===

### Found in debug-3.log.gz:
```
281674	[15Jan.2026 06:50:13.801] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) setCurrentStation() to aa4feb96 (Loader 1)
311592	[15Jan.2026 06:53:58.106] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train c1c9d44a (Test Train 2) setCurrentStation() to aa4feb96 (Loader 1)
340259	[15Jan.2026 06:56:51.512] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station aa4feb96 (Loader 1)
340260	[15Jan.2026 06:56:51.512] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to aa4feb96 (Loader 1)
484881	[15Jan.2026 07:07:44.109] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) setCurrentStation() to aa4feb96 (Loader 1)
```

### Found in debug-4.log.gz:
```
1673  	[15Jan.2026 05:58:17.712] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) setCurrentStation() to aa4feb96 (Loader 1)
120127	[15Jan.2026 06:02:40.486] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) setCurrentStation() to aa4feb96 (Loader 1)
155546	[15Jan.2026 06:05:56.842] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station aa4feb96 (Loader 1)
155547	[15Jan.2026 06:05:56.842] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to aa4feb96 (Loader 1)
473119	[15Jan.2026 06:16:07.440] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train c1c9d44a (Test Train 2) setCurrentStation() to aa4feb96 (Loader 1)
```

=== STEP 3: Did Train 3 ever LEAVE aa4feb96? ===

### Found in debug-3.log.gz:
```
282852	[15Jan.2026 06:50:23.561] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) trainDeparted() for train 4b5f0ef9 (Test Train 1)
312970	[15Jan.2026 06:54:07.855] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) trainDeparted() for train c1c9d44a (Test Train 2)
342020	[15Jan.2026 06:57:01.261] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: aa4feb96 (Loader 1)
342021	[15Jan.2026 06:57:01.261] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) trainDeparted() for train 4471ce2f (Test Train 3)
487440	[15Jan.2026 07:07:53.860] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) trainDeparted() for train 4b5f0ef9 (Test Train 1)
```

### Found in debug-4.log.gz:
```
14694 	[15Jan.2026 05:58:29.953] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) trainDeparted() for train 4b5f0ef9 (Test Train 1)
121716	[15Jan.2026 06:02:50.240] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) trainDeparted() for train 4b5f0ef9 (Test Train 1)
157135	[15Jan.2026 06:06:06.590] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) leaveStation(). Current station: aa4feb96 (Loader 1)
157136	[15Jan.2026 06:06:06.590] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) trainDeparted() for train 4471ce2f (Test Train 3)
485020	[15Jan.2026 06:16:17.192] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) trainDeparted() for train c1c9d44a (Test Train 2)
```

=== STEP 4: Did aa4feb96 ever CANCEL Train 3 reservation? ===

### Found in debug-3.log.gz:
```
342022	[15Jan.2026 06:57:01.261] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) cancelReservation() for train 4471ce2f. Current: 4471ce2f
```

### Found in debug-4.log.gz:
```
157137	[15Jan.2026 06:06:06.590] [Server thread/INFO] [com.simibubi.create.Create/]: [STATION-DEBUG] Station 'Loader 1' (ID: aa4feb96) cancelReservation() for train 4471ce2f. Current: 4471ce2f
```

=== STEP 5: When did Train 3 go to e1e37bfd (the OTHER 'Loader 1')? ===

### Found in debug-1.log.gz:
```
194474	[15Jan.2026 07:35:40.810] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train c1c9d44a (Test Train 2) setCurrentStation() to e1e37bfd (Loader 1)
286959	[15Jan.2026 07:37:29.600] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
286960	[15Jan.2026 07:37:29.600] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
401145	[15Jan.2026 07:42:58.606] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
401146	[15Jan.2026 07:42:58.606] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
```

### Found in debug-2.log.gz:
```
467802	[15Jan.2026 07:22:55.960] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train c1c9d44a (Test Train 2) setCurrentStation() to e1e37bfd (Loader 1)
695861	[15Jan.2026 07:25:32.804] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
695862	[15Jan.2026 07:25:32.804] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
767998	[15Jan.2026 07:28:10.756] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train c1c9d44a (Test Train 2) setCurrentStation() to e1e37bfd (Loader 1)
```

### Found in debug-3.log.gz:
```
11604 	[15Jan.2026 06:34:16.620] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
11605 	[15Jan.2026 06:34:16.620] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
61342 	[15Jan.2026 06:35:27.346] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
61343 	[15Jan.2026 06:35:27.346] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
198506	[15Jan.2026 06:42:23.366] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) setCurrentStation() to e1e37bfd (Loader 1)
```

### Found in debug-4.log.gz:
```
454448	[15Jan.2026 06:15:52.488] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) setCurrentStation() to e1e37bfd (Loader 1)
643235	[15Jan.2026 06:18:29.207] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) arriveAt() station e1e37bfd (Loader 1)
643236	[15Jan.2026 06:18:29.207] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to e1e37bfd (Loader 1)
684424	[15Jan.2026 06:22:56.246] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train c1c9d44a (Test Train 2) setCurrentStation() to e1e37bfd (Loader 1)
```

=== STEP 6: When did Train 1 (4b5f0e) arrive at aa4feb96? ===

### Found in debug-3.log.gz:
```
281673	[15Jan.2026 06:50:13.801] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) arriveAt() station aa4feb96 (Loader 1)
281674	[15Jan.2026 06:50:13.801] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) setCurrentStation() to aa4feb96 (Loader 1)
311592	[15Jan.2026 06:53:58.106] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train c1c9d44a (Test Train 2) setCurrentStation() to aa4feb96 (Loader 1)
340260	[15Jan.2026 06:56:51.512] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to aa4feb96 (Loader 1)
484880	[15Jan.2026 07:07:44.109] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) arriveAt() station aa4feb96 (Loader 1)
```

### Found in debug-4.log.gz:
```
1672  	[15Jan.2026 05:58:17.712] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) arriveAt() station aa4feb96 (Loader 1)
1673  	[15Jan.2026 05:58:17.712] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) setCurrentStation() to aa4feb96 (Loader 1)
120126	[15Jan.2026 06:02:40.486] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) arriveAt() station aa4feb96 (Loader 1)
120127	[15Jan.2026 06:02:40.486] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4b5f0ef9 (Test Train 1) setCurrentStation() to aa4feb96 (Loader 1)
155547	[15Jan.2026 06:05:56.842] [Server thread/INFO] [com.simibubi.create.Create/]: [TRAIN-DEBUG] Train 4471ce2f (Test Train 3) setCurrentStation() to aa4feb96 (Loader 1)
```

