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

import std/[os, strutils, strformat, options, sets]

type
  DocSyncError* = object of CatchableError
    ## Represents errors that can occur during documentation synchronization.

  DocSyncConfig* = object
    ## Configuration for documentation synchronization.
    sourceDir*: string        ## Source documentation directory
    targetDir*: string       ## Target Jekyll documentation directory
    dryRun*: bool           ## If true, only show what would be done
    recursive*: bool        ## If true, process subdirectories
    verbose*: bool         ## If true, show detailed progress

  DocSync* = ref object
    ## Documentation synchronization controller.
    config: DocSyncConfig
    processedFiles: HashSet[string]

const DefaultFrontMatter = """---
layout: docs
title: {title}
permalink: /docs/{permalink}/
---

"""

proc ensureDir(dir: string) =
  ## Creates directory and all parent directories if they don't exist.
  if not dirExists(dir):
    try:
      createDir(dir)
    except OSError as e:
      raise newException(DocSyncError, fmt"Failed to create directory {dir}: {e.msg}")

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
      sourceDir: sourceDir.absolutePath(),
      targetDir: targetDir.absolutePath(),
      dryRun: dryRun,
      recursive: recursive,
      verbose: verbose
    ),
    processedFiles: initHashSet[string]()
  )

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
  result = DefaultFrontMatter % ["title", title, "permalink", permalink]
  result.add(content)

proc syncFile(self: DocSync, src, dest: string): bool =
  ## Syncs a single file from source to destination.
  ##
  ## Returns true if successful, false otherwise.
  try:
    if not fileExists(src):
      raise newException(DocSyncError, fmt"Source file not found: {src}")

    var content = readFile(src)
    content = addFrontMatter(content, src.extractFilename)

    if self.config.dryRun:
      if self.config.verbose:
        echo fmt"[DRY RUN] Would sync: {src} -> {dest}"
      return true

    # Ensure target directory exists
    let targetDir = dest.parentDir
    ensureDir(targetDir)

    # Check if file has changed before writing
    var shouldWrite = true
    if fileExists(dest):
      let existingContent = readFile(dest)
      if existingContent == content:
        shouldWrite = false
        if self.config.verbose:
          echo fmt"Skipped (unchanged): {src}"

    if shouldWrite:
      writeFile(dest, content)
      if self.config.verbose:
        echo fmt"Synced: {src} -> {dest}"

    self.processedFiles.incl(dest)
    result = true

  except:
    let e = getCurrentException()
    if self.config.verbose:
      echo fmt"Error syncing {src}: {e.msg}"
    result = false

proc sync*(self: DocSync): bool =
  ## Synchronizes documentation from source to target directory.
  ## Only syncs files that exist in the source directory, preserving other files
  ## in the target directory.
  ##
  ## Returns true if all files were synced successfully.
  result = true
  self.processedFiles.clear()

  # Validate and create directories
  try:
    if not dirExists(self.config.sourceDir):
      raise newException(DocSyncError,
        fmt"Source directory not found: {self.config.sourceDir}")

    if not self.config.dryRun:
      ensureDir(self.config.targetDir)
  except DocSyncError as e:
    echo e.msg
    return false

  # Process files
  var pattern = self.config.sourceDir
  if self.config.recursive:
    pattern = pattern / "**" / "*.md"
  else:
    pattern = pattern / "*.md"

  for file in walkPattern(pattern):
    let
      relPath = relativePath(file, self.config.sourceDir)
      destFile = self.config.targetDir / relPath

    if not self.syncFile(file, destFile):
      result = false

  if self.config.verbose:
    if result:
      echo "Documentation sync complete! 🐹"
    else:
      echo "Documentation sync completed with errors! 🐹"
