## Documentation synchronization tools for darwinmetrics.
##
## This module provides tools to synchronize documentation between the main `/docs`
## directory and the Jekyll documentation in `/.jekyll/_docs`.
##
## Example:
##
## ```nim
## import doctools/sync
##
## let syncer = newDocSync(
##   sourceDir = "docs",
##   targetDir = ".jekyll/_docs"
## )
## syncer.sync()
## ```

import std/[os, strutils, strformat, sets]

type
  DocSyncError* = object of CatchableError
    ## Represents errors that can occur during documentation synchronization.

  DocSyncConfig* = object
    ## Configuration for documentation synchronization.
    sourceDir*: string ## Source documentation directory
    targetDir*: string ## Target Jekyll documentation directory
    dryRun*: bool      ## If true, only show what would be done
    recursive*: bool   ## If true, process subdirectories
    verbose*: bool     ## If true, show detailed progress

  DocSync* = ref object
    ## Documentation synchronization controller.
    config: DocSyncConfig
    processedFiles: HashSet[string]
    hasErrors: bool

const DefaultFrontMatter = """---
layout: docs
title: $1
permalink: /docs/$2/
---

"""

proc ensureDir(dir: string): bool =
  ## Creates directory and all parent directories if they don't exist.
  ## Returns true if successful, false otherwise.
  try:
    createDir(dir)
    result = true
  except OSError:
    result = false

proc generateTitle(filename: string): string =
  ## Generates a Jekyll-friendly title from filename.
  result = filename.splitFile.name
    .replace('_', ' ')
    .capitalizeAscii()

proc generatePermalink(filename: string): string =
  ## Generates a Jekyll-friendly permalink from filename.
  result = filename.splitFile.name.toLowerAscii()

proc addFrontMatter(content, filename: string): string =
  ## Adds Jekyll front matter to content if not present.
  if content.startsWith("---"):
    return content

  let
    title = generateTitle(filename)
    permalink = generatePermalink(filename)
  result = DefaultFrontMatter % [title, permalink]
  result.add(content)

proc canReadFile(path: string): bool =
  ## Checks if a file exists and is readable.
  try:
    discard readFile(path)
    result = true
  except IOError:
    result = false

proc syncFile(self: DocSync, src, dest: string): bool =
  ## Syncs a single file from source to destination.
  ##
  ## Returns true if successful, false otherwise.
  if self.config.dryRun:
    if self.config.verbose:
      echo fmt"[DRY RUN] Would sync: {src} -> {dest}"
    self.processedFiles.incl(dest)
    return true

  # Check source file
  if not fileExists(src):
    if self.config.verbose:
      echo fmt"Source file not found: {src}"
    self.hasErrors = true
    return false

  # Check if we can read the source file
  if not canReadFile(src):
    if self.config.verbose:
      echo fmt"Cannot read source file: {src}"
    self.hasErrors = true
    return false

  # Read source content
  var content: string
  try:
    content = readFile(src)
  except IOError:
    if self.config.verbose:
      echo fmt"Failed to read source file: {src}"
    self.hasErrors = true
    return false

  # Process content
  content = addFrontMatter(content, src.extractFilename)

  # Ensure target directory exists
  let targetDir = dest.parentDir
  if not ensureDir(targetDir):
    if self.config.verbose:
      echo fmt"Failed to create directory: {targetDir}"
    self.hasErrors = true
    return false

  # Write the file
  try:
    writeFile(dest, content)
    if self.config.verbose:
      echo fmt"Synced: {src} -> {dest}"
    self.processedFiles.incl(dest)
    result = true
  except IOError:
    if self.config.verbose:
      echo fmt"Failed to write file: {dest}"
    self.hasErrors = true
    result = false

proc newDocSync*(sourceDir, targetDir: string,
                dryRun = false,
                recursive = true,
                verbose = false): DocSync =
  ## Creates a new documentation synchronization controller.
  ##
  ## Args:
  ##   sourceDir: Source documentation directory
  ##   targetDir: Target Jekyll documentation directory
  ##   dryRun: If true, only show what would be done
  ##   recursive: If true, process subdirectories
  ##   verbose: If true, show detailed progress
  result = DocSync(
    config: DocSyncConfig(
      sourceDir: normalizedPath(sourceDir),
      targetDir: normalizedPath(targetDir),
      dryRun: dryRun,
      recursive: recursive,
      verbose: verbose
    ),
    processedFiles: initHashSet[string](),
    hasErrors: false
  )

proc sync*(self: DocSync): bool =
  ## Synchronizes documentation from source to target directory.
  ## Only syncs files that exist in the source directory, preserving other files
  ## in the target directory.
  ##
  ## Returns true if all files were synced successfully.
  self.processedFiles.clear()
  self.hasErrors = false

  # Validate source directory
  if not dirExists(self.config.sourceDir):
    raise newException(DocSyncError,
      fmt"Source directory not found: {self.config.sourceDir}")

  # Create target directory if not in dry run mode
  if not self.config.dryRun and not ensureDir(self.config.targetDir):
    echo fmt"Failed to create target directory: {self.config.targetDir}"
    return false

  # First pass: sync files
  for file in walkDirRec(self.config.sourceDir):
    # Skip if not a markdown file
    if not file.endsWith(".md"):
      continue

    # Skip if not recursive and file is in subdirectory
    if not self.config.recursive and file.parentDir != self.config.sourceDir:
      continue

    let
      relPath = relativePath(file, self.config.sourceDir)
      destFile = self.config.targetDir / relPath

    if not self.syncFile(file, destFile):
      self.hasErrors = true

  # Second pass: cleanup orphaned files if not in dry run mode
  if not self.config.dryRun and dirExists(self.config.targetDir):
    for file in walkDirRec(self.config.targetDir):
      # Skip if not a markdown file
      if not file.endsWith(".md"):
        continue

      # Skip if not recursive and file is in subdirectory
      if not self.config.recursive and file.parentDir != self.config.targetDir:
        continue

      if file notin self.processedFiles:
        try:
          if self.config.verbose:
            echo fmt"Removing orphaned file: {file}"
          removeFile(file)
        except OSError:
          if self.config.verbose:
            echo fmt"Error removing orphaned file: {file}"
          self.hasErrors = true

  if self.config.verbose:
    if not self.hasErrors:
      echo "Documentation sync complete! 🐹"
    else:
      echo "Documentation sync completed with errors! 🐹"

  result = not self.hasErrors
