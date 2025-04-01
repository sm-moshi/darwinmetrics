import std/[os]
from std/strformat import fmt

# Import nimscript functionality
include "system/nimscript"

# Get absolute paths
let
  projectRoot = currentSourcePath().parentDir.absolutePath()
  docsDir = projectRoot / "docs"
  jekyllDocsDir = projectRoot / ".jekyll" / "_docs"

# Ensure directories exist
if not dirExists(docsDir):
  mkDir(docsDir)
if not dirExists(jekyllDocsDir):
  mkDir(jekyllDocsDir)

# Build the docsync tool
exec "nimble build"

# Run the sync tool with absolute paths
let cmd = fmt"bin/docsync --verbose {docsDir} {jekyllDocsDir}"
exec cmd
