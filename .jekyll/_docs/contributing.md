---
layout: doc
title: 🤝 Contributing
permalink: /docs/contributing/
---

We welcome contributions to darwinmetrics! This guide will help you get started with contributing to the project.

## Development Setup

1. **Fork and Clone**

   ```bash
   git clone https://github.com/sm-moshi/darwinmetrics.git
   cd darwinmetrics
   ```

2. **Install Dependencies**

   ```bash
   nimble install
   ```

3. **Set Up Development Environment**
   - Use a modern IDE with Nim support (VS Code with nim extension recommended)
   - Install development tools:

     ```bash
     nimble install testament # For testing
     nimble install nimlint  # For linting
     ```

## Code Style

We follow the official Nim style guide with these additional rules:

1. Use clear, descriptive names for variables, functions, and types
2. Add comments for complex logic
3. Include docstrings for public APIs
4. Keep functions focused and small
5. Use type inference where it improves readability

Example:

```nim
proc calculateCpuUsage*(samples: seq[float]): float =
  ## Calculates average CPU usage from a sequence of samples
  ##
  ## Parameters:
  ##   samples: Sequence of CPU usage measurements
  ##
  ## Returns:
  ##   Average CPU usage as percentage
  if samples.len == 0:
    return 0.0

  result = samples.sum() / samples.len.float
```

## Testing

1. **Write Tests**
   - Add tests for new features
   - Update tests for modified code
   - Place tests in the `tests/` directory

   ```nim
   # tests/test_cpu.nim
   import unittest
   import darwinmetrics

   test "getCpuInfo returns valid data":
     let info = getCpuInfo()
     check:
       info.cores > 0
       info.usage >= 0.0 and info.usage <= 100.0
   ```

2. **Run Tests**

   ```bash
   nimble test
   ```

## Pull Request Process

1. **Create a Branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Follow code style guidelines
   - Add/update tests
   - Update documentation

3. **Commit Changes**
   - Use clear commit messages
   - Reference issues if applicable

   ```bash
   git commit -m "feat: add CPU temperature monitoring

   Implements #123 by adding CPU temperature monitoring support
   with automatic fan speed adjustment."
   ```

4. **Submit PR**
   - Create PR against main branch
   - Include description of changes
   - Link related issues
   - Ensure CI passes

## Documentation

1. **API Documentation**
   - Add docstrings to all public APIs
   - Include examples where helpful
   - Update API reference docs

2. **User Guide**
   - Update relevant sections
   - Add new features to examples
   - Keep installation guide current

## Release Process

1. **Version Numbers**
   - Follow semantic versioning
   - Update version in `.nimble` file

2. **Changelog**
   - Add significant changes
   - Credit contributors
   - Follow Keep a Changelog format

## Getting Help

- Open an issue for bugs or features
- Join our Discord community
- Check existing documentation

## Code of Conduct

We follow the Contributor Covenant Code of Conduct. Please read [CODE_OF_CONDUCT.md]({% link _docs/code_of_conduct.md %}) before contributing.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
