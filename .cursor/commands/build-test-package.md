---
description: Build and test a specific Swift Package Manager package. Defaults to "App" if no package name is provided.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execution Steps

1. **Determine package name**: 
   - If `$ARGUMENTS` is provided and not empty, use it as the package name
   - If `$ARGUMENTS` is empty or not provided, default to "App"
   - The package name should correspond to a directory under the workspace root (e.g., "App" refers to the `App/` directory)

2. **Build the package**:
   - Run `swift build --package-path <package-name>` from the workspace root
   - Execute commands from the workspace root directory (current working directory)
   - If the build fails, **STOP immediately** and report the build failure
   - Do not proceed to testing if the build fails

3. **Test the package** (only if build succeeded):
   - Run `swift test --package-path <package-name>` from the workspace root
   - Report test results (success or failure)

4. **Report final status**:
   - If both build and test succeeded: "Build and test completed successfully for package: <package-name>"
   - If build failed: "Build failed for package: <package-name>"
   - If build succeeded but test failed: "Build succeeded but test failed for package: <package-name>"

## Key rules

- Execute commands from the workspace root directory (current working directory)
- Use relative paths: `--package-path <package-name>` where package-name is the directory name relative to workspace root
- Stop execution immediately if build fails
- Only run tests if build succeeds
- Provide clear, concise output for each step

