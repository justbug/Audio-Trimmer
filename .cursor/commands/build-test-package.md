description: Build and test a specific Swift Package Manager package. Defaults to "Audio Trimmer/App" if no package path is provided. Automatically fixes build and test failures until both pass.
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

2. **Build the package with automatic fix loop**:
   - Run `swift build --package-path "<package-path>"` from the workspace root
   - Execute commands from the workspace root directory (current working directory)
   - **If the build fails:**
     - Analyze the build error output to identify the specific issue(s)
     - Common issues to detect and fix:
       - Syntax errors (missing braces, semicolons, incorrect Swift syntax)
       - Missing imports or undefined symbols
       - Type mismatches and type errors
       - Missing dependencies or unresolved dependencies
       - Access control issues (missing `public`, `internal`, etc.)
       - Missing files or incorrect file paths
       - Package.swift configuration issues
     - Read the relevant source files to understand the context
     - Apply fixes to resolve the identified errors
     - Report what was fixed: "Fixed: <description of fix>"
     - Retry the build
     - Continue this fix-and-retry loop until the build succeeds
   - **Do not proceed to testing until build succeeds**

3. **Test the package with automatic fix loop** (only after build succeeds):
   - Run `swift test --package-path "<package-path>"` from the workspace root
   - **If tests fail:**
     - Analyze the test failure output to identify the specific issue(s)
     - Common issues to detect and fix:
       - Assertion failures (update test expectations or fix logic)
       - Missing test implementations
       - Incorrect test setup or teardown
       - Logic errors in the code being tested
       - Missing test data or fixtures
       - Dependency injection issues
       - Type mismatches in test code
     - Read the relevant test files and source files to understand the context
     - Apply fixes to resolve the identified failures
     - Report what was fixed: "Fixed: <description of fix>"
     - Retry the tests
     - Continue this fix-and-retry loop until all tests pass
   - **Ensure all tests pass before completing**

4. **Report final status**:
   - If both build and test succeeded: "Build and test completed successfully for package: <package-path>"
   - If unable to fix after reasonable attempts (e.g., 5+ iterations without progress), report the remaining issues and seek clarification

## Key rules

- Execute commands from the workspace root directory (current working directory)
- Use relative paths: `--package-path <package-path>` where the path is relative to the workspace root
- **DO NOT stop on build or test failures** - instead, diagnose and fix them automatically
- Continue fixing and retrying until both build and test succeed
- Provide clear, concise output for each step, including what errors were detected and how they were fixed
- Use codebase search tools to understand the codebase structure and conventions before making fixes
- Follow Swift and TCA best practices when applying fixes (see AGENTS.md for conventions)
- Read linter errors using `read_lints` tool to identify compilation issues
- If you encounter errors that seem unfixable or require user input, report them clearly and ask for guidance
