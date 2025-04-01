## Tests for documentation synchronization
##
## These tests verify the functionality of the documentation sync tool.

import std/[unittest, os, strutils]
import ../src/doctools/sync

suite "Documentation Sync":
  let
    currentDir = getCurrentDir()
    testDir = normalizedPath(currentDir / "tests" / "fixtures" / "docs")
    targetDir = normalizedPath(currentDir / "tests" / "fixtures" / "jekyll_docs")
    testFile = normalizedPath(testDir / "test.md")
    subDirFile = normalizedPath(testDir / "subdir" / "nested.md")
    targetFile = normalizedPath(targetDir / "test.md")
    targetNestedFile = normalizedPath(targetDir / "subdir" / "nested.md")

  proc cleanupDirs() =
    try:
      # Ensure we can clean up by restoring permissions
      when defined(posix):
        if dirExists(testDir):
          setFilePermissions(testDir, {fpUserRead, fpUserWrite, fpUserExec})
          if dirExists(testDir / "subdir"):
            setFilePermissions(testDir / "subdir", {fpUserRead, fpUserWrite, fpUserExec})
          if fileExists(testFile):
            setFilePermissions(testFile, {fpUserRead, fpUserWrite})
          if fileExists(subDirFile):
            setFilePermissions(subDirFile, {fpUserRead, fpUserWrite})

      # Clean up test directories
      removeDir(testDir)
      removeDir(targetDir)
    except OSError:
      echo "Warning: Failed to clean up test directories"

  setup:
    # Clean up any existing test directories
    cleanupDirs()

    # Create test directories with proper permissions
    createDir(testDir)
    createDir(testDir / "subdir")

    # Create test files with proper permissions
    writeFile(testFile, "# Test Document\n\nThis is a test.")
    writeFile(subDirFile, "# Nested Document\n\nThis is nested.")

    # Ensure proper permissions
    when defined(posix):
      setFilePermissions(testDir, {fpUserRead, fpUserWrite, fpUserExec})
      setFilePermissions(testDir / "subdir", {fpUserRead, fpUserWrite, fpUserExec})
      setFilePermissions(testFile, {fpUserRead, fpUserWrite})
      setFilePermissions(subDirFile, {fpUserRead, fpUserWrite})

  teardown:
    cleanupDirs()

  test "Basic sync works":
    let syncer = newDocSync(testDir, targetDir, verbose = true)
    check syncer.sync()
    check fileExists(targetFile)
    check fileExists(targetNestedFile)

    let content = readFile(targetFile)
    check content.contains("layout: docs")
    check content.contains("title: Test")
    check content.contains("# Test Document")

  test "Dry run doesn't create files":
    removeDir(targetDir) # Ensure target doesn't exist
    let syncer = newDocSync(testDir, targetDir, dryRun = true)
    check syncer.sync()
    check not dirExists(targetDir)

  test "Non-recursive sync skips subdirectories":
    let syncer = newDocSync(testDir, targetDir, recursive = false)
    check syncer.sync()
    check fileExists(targetFile)
    check not fileExists(targetNestedFile)

  test "Preserves existing front matter":
    let frontMatter = """---
layout: custom
title: Custom Title
permalink: /custom/
---

# Content
"""
    writeFile(testFile, frontMatter)
    let syncer = newDocSync(testDir, targetDir)
    check syncer.sync()
    let content = readFile(targetFile)
    check content == frontMatter

  test "Handles missing source directory":
    let nonexistentDir = currentDir / "nonexistent"
    let syncer = newDocSync(nonexistentDir, targetDir)
    expect DocSyncError:
      discard syncer.sync()

  test "Cleans up orphaned files":
    # Create an orphaned file
    createDir(targetDir)
    let orphanedFile = normalizedPath(targetDir / "orphaned.md")
    writeFile(orphanedFile, "# Orphaned")
    when defined(posix):
      setFilePermissions(orphanedFile, {fpUserRead, fpUserWrite})

    let syncer = newDocSync(testDir, targetDir, verbose = true)
    check syncer.sync()
    check not fileExists(orphanedFile)

  test "Reports errors for unreadable files":
    when defined(posix):
      # Make test file unreadable
      writeFile(testFile, "# Test")
      setFilePermissions(testFile, {}) # Remove all permissions

      let syncer = newDocSync(testDir, targetDir)
      check not syncer.sync()

      # Restore permissions for cleanup
      setFilePermissions(testFile, {fpUserRead, fpUserWrite})
