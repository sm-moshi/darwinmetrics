## ThreadSanitizer Test
##
## This basic test uses threads to verify ThreadSanitizer detection works properly.

import std/[threadpool]

proc main() =
  ## A simple demonstration of thread usage
  let input = @[1, 2, 3, 4, 5]
  var flowVars: seq[FlowVar[int]] = @[]

  # Create a small job that processes each element
  for i in input:
    # Start parallel job and collect FlowVar result
    flowVars.add spawn (proc (x: int): int =
      # Some "work"
      result = x * 2
    )(i)

  # Wait for all jobs to complete
  sync()

  # Collect results (optional - sync() already waited for completion)
  for fv in flowVars:
    let value = ^fv # Retrieve the value from the FlowVar
    echo "Result: ", value

  echo "ThreadSanitizer test completed successfully"

when isMainModule:
  main()
