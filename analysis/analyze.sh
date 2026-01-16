#!/bin/bash

echo "=== ANALYSIS OF TRAIN-STATION DESYNCHRONIZATION BUG ==="
echo ""
echo "Key Facts from User:"
echo "- Test Train 1 (4b5f0e) is stopped at station Loader 1 (aa4feb96)"
echo "- Train 1 knows this (train.currentStation = aa4feb96)"
echo "- But station aa4feb96 has nearestTrain pointing at 4471ce2f (Test Train 3)"
echo "- Train 4471ce2f is actually at station e1e37b (also named Loader 1)"
echo ""

echo "=== Finding Test Train 1 (4b5f0e) ==="
grep -n "Test Train 1" debug_filtered_brokenstationoccurred.log | head -20

echo ""
echo "=== Finding when station aa4feb96 first got train 4471ce2f ==="
grep -n "aa4feb96" debug_filtered_brokenstationoccurred.log | grep "4471ce2f" | grep "Previous: null" | head -5

echo ""
echo "=== Finding when station aa4feb96 first got train 4471ce2f (alternative) ==="
grep -n "aa4feb96" debug_filtered_brokenstationoccurred.log | grep "4471ce2f" | grep "reservation updated" | head -5

echo ""
echo "=== Finding all trains that arrived at aa4feb96 ==="
grep -n "arriveAt.*aa4feb96\|setCurrentStation.*aa4feb96" debug_filtered_brokenstationoccurred.log | head -20

echo ""
echo "=== Finding when Train 4471ce2f left station e1e37bfd ==="
grep -n "4471ce2f.*leaveStation\|4471ce2f.*trainDeparted" debug_filtered_brokenstationoccurred.log | grep -A2 -B2 "e1e37bfd"

echo ""
echo "=== Train 4471ce2f movement timeline ==="
grep -n "4471ce2f" debug_filtered_brokenstationoccurred.log | grep -E "(arriveAt|setCurrentStation|leaveStation)" | head -20

