import std/[unittest, os, strutils]
import ../src/doctools/sync

suite "Documentation Sync":
  let
    testDir = "tests/fixtures/docs"
    targetDir = "tests/fixtures/jekyll_docs"
    testFile = testDir / "test.md"
    subDirFile = testDir / "subdir" / "nested.md"
    targetFile = targetDir / "test.md"
    targetNestedFile = targetDir / "subdir" / "nested.md"

  setup:
    # Create test directories and files
    removeDir(testDir)
    removeDir(targetDir)
    createDir(testDir)
    createDir(testDir / "subdir")

    # Create test files
    writeFile(testFile, "# Test Document\n\nThis is a test.")
    writeFile(subDirFile, "# Nested Document\n\nThis is nested.")

  teardown:
    removeDir(testDir)
    removeDir(targetDir)

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
    let syncer = newDocSync("nonexistent", targetDir)
    expect DocSyncError:
      discard syncer.sync()

  test "Cleans up orphaned files":
    # Create an orphaned file
    createDir(targetDir)
    writeFile(targetDir / "orphaned.md", "# Orphaned")

    let syncer = newDocSync(testDir, targetDir, verbose = true)
    check syncer.sync()
    check not fileExists(targetDir / "orphaned.md")

  test "Reports errors for unreadable files":
    when defined(posix):
      # Make test file unreadable
      writeFile(testFile, "# Test")
      chmod(testFile, 0o000)

      let syncer = newDocSync(testDir, targetDir)
      check not syncer.sync()

      # Restore permissions for cleanup
      chmod(testFile, 0o644)
