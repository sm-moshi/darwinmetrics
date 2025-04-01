---
layout: home
title: 🐹 darwinmetrics
permalink: /index.html
---

<div class="badges">
<a href="https://github.com/sm-moshi/darwinmetrics">
  <img src="https://img.shields.io/badge/nimble-develop-orange" alt="nimble">
</a>
<a href="https://github.com/sm-moshi/darwinmetrics/actions/workflows/build.yml"><img src="https://github.com/sm-moshi/darwinmetrics/actions/workflows/build.yml/badge.svg?branch=develop" alt="Build Status"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
<a href="#">
  <img src="https://img.shields.io/badge/platform-macOS%20(Darwin)-lightblue.svg" alt="Platform: macOS">
</a>
<a href="docs/CHANGELOG.md">
  <img src="https://img.shields.io/badge/changelog-Keep%20a%20Changelog-%23E05735" alt="Keep a Changelog">
</a>
</div>

## Welcome to darwinmetrics

A pure Nim library for accessing macOS system metrics.

Welcome to the darwinmetrics documentation. Here you'll find comprehensive guides and documentation to help you start working with darwinmetrics as quickly as possible.

## Overview

darwinmetrics provides a comprehensive interface for accessing macOS system metrics. It is a pure Nim implementation, ported from established libraries in Rust and Go.

## Features

- Architecture detection (arm64, x86_64)
- CPU monitoring (usage, load, frequency)
- Memory statistics (RAM and swap)
- Power management (battery status)
- Temperature sensors and fan control
- Network interface statistics
- Process monitoring
- Disk usage tracking

## Quick Start

```nim
import darwinmetrics

echo getCpuInfo()
echo getMemoryInfo()
echo getPowerInfo()
```

## Requirements

- macOS 12.0 or newer (Darwin 21+)
- Nim 2.22+
- Xcode Command Line Tools

## Documentation

{% for doc in site.docs %}

- [{{ doc.title }}]({{ doc.url | relative_url }})
{% endfor %}

### Quick Links
<!-- markdownlint-disable MD037 -->
- [Installation Guide]({% link _docs/installation.md %})
- [API Reference]({% link _docs/api.md %})
- [Examples]({% link _docs/examples.md %})
- [Changelog]({% link _docs/CHANGELOG.md %})
- [Roadmap]({% link _docs/ROADMAP.md %})

## Contributing
<!-- markdownlint-disable MD037 -->
We welcome contributions! Please check our [Contributing Guide]({% link _docs/contributing.md %}) and [Code of Conduct]({% link _docs/code_of_conduct.md %}).

## License

MIT © 2025 [Stuart Meya](https://github.com/sm-moshi)
