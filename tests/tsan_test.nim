## ThreadSanitizer Test
##
## This basic test uses Nim's built-in threading to verify ThreadSanitizer detection.

import std/[locks, atomics, os]

type SharedData = object
  lock: Lock
  counter: Atomic[int]

proc workerThread(data: ptr SharedData) {.thread.} =
  ## Worker thread that increments the counter
  for i in 1 .. 5:
    # Atomic increment without lock (safe)
    discard data.counter.fetchAdd(1)

    # Intentionally add a small delay
    sleep(10)

    # Use lock for demonstration (though not strictly needed here)
    withLock data.lock:
      echo "Thread increment: ", data.counter.load

proc main() =
  var data: SharedData
  data.counter.store(0)
  initLock(data.lock)

  # Create and start threads
  var threads: array[2, Thread[ptr SharedData]]
  for i in 0 .. threads.high:
    createThread(threads[i], workerThread, addr data)

  # Wait for threads to complete
  joinThreads(threads)

  # Clean up
  deinitLock(data.lock)

  echo "Final counter value: ", data.counter.load
  echo "ThreadSanitizer test completed successfully"

when isMainModule:
  main()
