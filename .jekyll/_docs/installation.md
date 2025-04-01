---
layout: doc
title: 📥 Installation Guide
permalink: /docs/installation/
---


## Prerequisites

* Nim 2.2.2 or higher
* macOS 12.0+ (Monterey or higher)
* Nimble package manager

## Installing Dependencies

1. Install Xcode Command Line Tools:

```bash
xcode-select --install
```

2. Install Nim (if not already installed):

```bash
brew install nim
```

## Installing darwinmetrics

1. Using Nimble:

```bash
nimble install darwinmetrics
```

2. From source:

```bash
git clone https://github.com/sm-moshi/darwinmetrics
cd darwinmetrics
nimble install
```

## Verifying Installation

Create a test file `test.nim`:

```nim
import darwinmetrics

echo "CPU Info:"
echo getCpuInfo()
```

Run it:

```bash
nim c -r test.nim
```

## Next Steps

* Check out our [Quick Start Guide]({% link _docs/examples.md %})
* Read the [API Reference]({% link _docs/api.md %})
* Learn about [Configuration]({% link _docs/configuration.md %})
