description: Compare local git commits with remote main branch, extract commit information and changed files, then update README.md and AGENTS.md accordingly.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execution Steps

1. **Fetch remote main branch**:
   - Run `git fetch origin main` from the workspace root to ensure remote state is current
   - Execute commands from the workspace root directory (current working directory)

2. **Get commit differences**:
   - Check if local branch is ahead of remote main: `git log origin/main..HEAD --oneline`
   - If no commits ahead, report "Local branch is in sync with remote main. No commits to document."
   - If commits exist, proceed to extract commit information

3. **Extract commit information and analyze code changes**:
   - Get commit list: `git log origin/main..HEAD --format="%h|%s|%b" --no-merges`
   - For each commit:
     - Get changed files: `git show --name-status --format="" <commit-hash>`
     - **Analyze actual code changes**: `git show <commit-hash>` or `git diff <commit-hash>^..<commit-hash>`
     - Examine the code diff to understand:
       - What functionality was added, modified, or removed
       - New functions, methods, classes, or features introduced
       - Changes to existing functionality
       - File structure changes (renames, moves, deletions)
       - Dependencies or imports added/removed
     - Analyze commit title and changed files to understand the nature of changes
   - Parse commit messages following Conventional Commits format:
     - `feat:` → Added/New features
     - `refactor:` → Refactoring/Improved
     - `chore:` → Chores/Maintenance
     - `docs:` → Documentation
     - `fix:` → Fixed/Bug fixes
     - `test:` → Tests

4. **Update README.md**:
   - Read current `README.md` file
   - **Update "Recent Changes" section based on commit titles, changed files, and actual code changes**:
     - Find or create a "Recent Changes" section in README.md (typically before "Next Steps" section)
     - For each commit, analyze:
       - Commit title (the main message after the type prefix)
       - Changed files to understand the scope
       - **Actual code changes from the diff** to understand what was really modified:
         - New functions, methods, or classes added
         - Existing functionality modified or enhanced
         - Features removed or deprecated
         - Bug fixes implemented
         - Refactoring that changes behavior
       - Determine the appropriate category (Added, Changed, Fixed, Removed, Chores) based on the actual code changes
     - Convert commit information to clear, user-friendly descriptions:
       - Use the commit title as the base, but verify and enhance with actual code changes
       - Focus on what functionality was changed based on the code diff, not just the commit message
       - Describe the impact of code changes in user-visible terms
       - Remove technical implementation details that aren't relevant to users
     - Merge new changes with existing "Recent Changes" section if it exists:
       - Add new entries at the top (newest first)
       - Avoid duplicates (check if similar entries already exist)
       - Keep descriptions concise and clear, reflecting actual code changes
     - Format: Simple bullet points grouped by type
   - **Update other README sections** based on commits, changed files, and actual code changes:
     - **Repository Layout**: Update file paths if files were added, deleted, or renamed (verify with code changes)
     - **Architecture**: Update feature descriptions based on actual code changes (new reducers, state management, etc.)
     - **Domain Models**: Update extension references if files were renamed or new extensions added (verify methods/functions in code)
     - **SwiftUI Shell**: Update entry point references and UI component descriptions based on actual view code changes
     - **Testing**: Add new test coverage if tests were added (verify test cases from code changes)
     - **Next Steps**: Remove completed items based on actual code implementation, update with current priorities
   - Ensure all file paths and component names match the current codebase structure (verify with actual code)
   - Keep documentation accurate and up-to-date with the actual implementation (cross-reference with code changes)

5. **Update AGENTS.md if needed**:
   - Read current `AGENTS.md` file
   - Analyze commits to determine if they introduce:
     - New technologies or frameworks
     - Significant architectural changes
     - Major dependency updates
   - If such changes are detected:
     - Update the "Recent Changes" section
     - Keep entries concise and focused on technology/architecture impacts
     - Follow the existing format: `- <spec-id>: Description of technology/architecture change`
   - If no technology/architecture changes, skip this step

6. **Report completion**:
   - Summarize what was updated:
     - Number of commits processed
     - Files created/updated
     - Key changes documented

## Key rules

- Execute commands from the workspace root directory (current working directory)
- Always fetch remote main before comparing to ensure accuracy
- Handle empty commit ranges gracefully (when local is in sync with remote)
- Parse Conventional Commits format correctly to categorize commits
- Always analyze actual code changes (git diff/show) to understand what was really modified, not just commit messages
- Always update README.md to reflect current codebase structure and implemented features (verify with actual code)
- Update "Recent Changes" section based on commit titles, changed files, and actual code changes
- Convert commit information to clear, user-friendly descriptions by examining the code diff to understand real changes
- Verify documentation accuracy by cross-referencing with actual code changes
- Only update AGENTS.md "Recent Changes" for technology/architecture impacts
- Include file change context (added, modified, deleted) for better understanding when updating README sections
- Group related commits logically by type in "Recent Changes"
- Keep documentation focused and avoid duplication
- Maintain chronological order (newest first) in "Recent Changes" section

