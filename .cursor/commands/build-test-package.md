description: Build and test a specific Swift Package Manager package. Defaults to "Audio Trimmer/App" if no package path is provided.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execution Steps

1. **Determine package path**: 
   - If `$ARGUMENTS` is provided and not empty, use it as the package path (quote it when running commands if it contains spaces)
   - If `$ARGUMENTS` is empty or not provided, default to `Audio Trimmer/App`
   - The package path should correspond to a directory under the workspace root (e.g., `Audio Trimmer/App` points to the Swift package that powers the app)

2. **Build the package**:
   - Run `swift build --package-path "<package-path>"` from the workspace root
   - Execute commands from the workspace root directory (current working directory)
   - If the build fails, **STOP immediately** and report the build failure
   - Do not proceed to testing if the build fails

3. **Test the package** (only if build succeeded):
   - Run `swift test --package-path "<package-path>"` from the workspace root
   - Report test results (success or failure)

4. **Report final status**:
   - If both build and test succeeded: "Build and test completed successfully for package: <package-path>"
   - If build failed: "Build failed for package: <package-path>"
   - If build succeeded but test failed: "Build succeeded but test failed for package: <package-path>"

## Key rules

- Execute commands from the workspace root directory (current working directory)
- Use relative paths: `--package-path <package-path>` where the path is relative to the workspace root
- Stop execution immediately if build fails
- Only run tests if build succeeds
- Provide clear, concise output for each step
