## Command-line interface for documentation synchronization.
##
## This module provides a binary tool for synchronizing documentation between
## the main `/docs` directory and the Jekyll documentation in `/.jekyll/_docs`.

import std/[parseopt, strutils]
import sync

proc showHelp() =
  echo """
docsync - Documentation synchronization tool

Usage:
  docsync [options] <source_dir> <target_dir>

Options:
  -h, --help            Show this help message
  -d, --dry-run        Show what would be done without making changes
  -v, --verbose        Show detailed progress
  -n, --no-recursive   Don't process subdirectories
"""
  quit(0)

proc main() =
  var
    sourceDir = ""
    targetDir = ""
    dryRun = false
    verbose = false
    recursive = true
    p = initOptParser()

  # Parse command line options
  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      if sourceDir == "":
        sourceDir = key
      elif targetDir == "":
        targetDir = key
      else:
        echo "Error: Too many arguments"
        showHelp()
    of cmdLongOption, cmdShortOption:
      case key.toLowerAscii()
      of "help", "h": showHelp()
      of "dry-run", "d": dryRun = true
      of "verbose", "v": verbose = true
      of "no-recursive", "n": recursive = false
      else:
        echo "Unknown option: ", key
        showHelp()
    of cmdEnd: break

  # Validate arguments
  if sourceDir == "" or targetDir == "":
    echo "Error: Source and target directories are required"
    showHelp()

  # Create sync controller and run
  let syncer = newDocSync(
    sourceDir = sourceDir,
    targetDir = targetDir,
    dryRun = dryRun,
    recursive = recursive,
    verbose = verbose
  )

  try:
    if not syncer.sync():
      quit(1)
  except DocSyncError:
    echo getCurrentExceptionMsg()
    quit(1)

when isMainModule:
  main()
