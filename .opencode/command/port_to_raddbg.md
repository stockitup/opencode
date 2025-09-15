---
description: Port functionality to raddbg with deep style analysis and quality checks
agent: build
---

# Parse the arguments from $ARGUMENTS

# Expected format: <source_folder> <instructions>

# First argument is source folder, rest is instructions

echo "Parsing port_to_raddbg arguments: $ARGUMENTS"

# Split on first space - source folder is first word, instructions are the rest

SOURCE_FOLDER=$(echo "$ARGUMENTS" | cut -d' ' -f1)
INSTRUCTIONS=$(echo "$ARGUMENTS" | cut -d' ' -f2-)

# Validate we have both parts

if [ -z "$SOURCE_FOLDER" ] || [ -z "$INSTRUCTIONS" ] || [ "$SOURCE_FOLDER" = "$INSTRUCTIONS" ]; then
echo "❌ Error: Missing required arguments"
echo "Usage: /port_to_raddbg <source_folder> <instructions>"
echo "Example: /port_to_raddbg src/renderer 'Port the rendering system to raddbg style'"
exit 1
fi

DESTINATION_FOLDER="src/raddbg"

echo "📂 Source: $SOURCE_FOLDER"
echo "📂 Destination: $DESTINATION_FOLDER"
echo "📋 Instructions: $INSTRUCTIONS"

# Check if we're already on a specialized branch, create one if not

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" || "$CURRENT_BRANCH" == "develop" ]]; then
BRANCH_NAME="port-to-raddbg-$(basename "$SOURCE_FOLDER")-$(date +%Y%m%d)"
  echo "Creating branch: $BRANCH_NAME"
  git checkout -b "$BRANCH_NAME"
else
echo "Already on specialized branch: $CURRENT_BRANCH"
fi

# Initial setup and planning phase

# CRITICAL: Create and maintain a comprehensive todolist throughout!

Use researcher agent to analyze both source and raddbg to create initial todolist:

1. Research source project structure and identify components for: $INSTRUCTIONS
2. Research raddbg current state and integration points
3. Deep dive into raddbg coding patterns and conventions
4. MANDATORY: Create detailed todolist with TodoWrite tool following the 6-step pattern
   - The todolist is your PRIMARY tracking mechanism
   - Keep it updated CONSTANTLY throughout the porting process

# Execute the porting process with 6-step cycles

# Each cycle handles one specific porting task with thorough style compliance

⚠️ STRICT CYCLE DISCIPLINE ⚠️

- ALWAYS complete all 6 steps in order
- NEVER jump ahead to execution without research
- After Step 6, ALWAYS return to Step 1 for the next task
- No "quick fixes" outside the cycle - everything goes through all 6 steps
- Even trivial-seeming tasks need the full cycle to maintain raddbg consistency

For each porting task, follow this 6-step sequence:

Step 1 - Research Source for Task:
Use researcher to understand what needs to be ported

- Mark current research task as in_progress in todolist
- Analyze source implementation details in $SOURCE_FOLDER
- Identify dependencies and data structures
- Understand the complete logic flow
- Document what exactly needs to be ported
- Update todolist with specific components found

Step 2 - Research Destination for Progress:
Use researcher to assess current state in raddbg

- Continue tracking in todolist
- Check what's already implemented in $DESTINATION_FOLDER
- Identify integration points and gaps
- Understand existing infrastructure that can be reused
- Map out where the new code should go
- Update todolist with integration requirements

Step 3 - Research raddbg Style for Context:
Use researcher to understand raddbg-specific patterns for this task

- Deep dive into src/raddbg coding conventions
- Study similar implementations in raddbg
- Identify naming conventions, data structure patterns
- Understand raddbg's approach to similar problems
- Note specific idioms and architectural patterns
- THIS IS CRITICAL: raddbg has unique patterns that MUST be followed

Step 4 - Execute Changes:
Use executioner to implement the port following raddbg patterns

- Mark execution task as in_progress in todolist
- Implement using EXACT raddbg style discovered in Step 3
- Follow naming conventions precisely
- Use raddbg's data structures and patterns
- Ensure seamless integration with existing code
- Mark completed implementation as done IMMEDIATELY

Step 5 - Research Quality vs raddbg Standards:
Use researcher to verify implementation quality

- Compare your implementation against raddbg examples
- Check if patterns match existing raddbg code
- Verify naming conventions are consistent
- Ensure architectural alignment with raddbg
- Identify any style deviations or improvements needed
- This step prevents style drift and ensures consistency

Step 6 - Adjust Todos & Commit:
MANDATORY: Full todolist update and commit cycle

- Commit current porting progress with descriptive message
- Mark ALL completed items as done in todolist
- Add ANY new tasks discovered during this cycle
- Add tasks for any style fixes identified in Step 5
- Remove obsolete tasks that are no longer needed
- Ensure todolist accurately reflects remaining work
- Maintain the 6-step pattern for remaining tasks
- NEVER skip this todolist update - it's CRITICAL for tracking

CRITICAL CYCLE ENFORCEMENT:

- After this commit, you MUST return to Step 1 for the next task
- DO NOT jump to executioner to "quickly fix" something
- DO NOT skip research steps even if the task seems simple
- EVERY task starts with Step 1, no exceptions
- If issues were found, they become new tasks that start at Step 1

# Example todolist structure for raddbg porting:

1. Research: Analyze memory management in source
2. Research: Check raddbg's current memory handling
3. Research: Study raddbg's arena allocator patterns
4. Execute: Implement memory management using raddbg arenas
5. Research: Verify implementation matches raddbg standards
6. Adjust & Commit: Update todos and commit memory management port
7. Research: Analyze UI rendering in source
8. Research: Check raddbg's current UI infrastructure
9. Research: Study raddbg's immediate mode UI patterns
10. Execute: Implement UI using raddbg's IM approach
11. Research: Verify UI implementation quality
12. Adjust & Commit: Update todos and commit UI port
    ...continue 6-step pattern...

# Quality assurance and final commit

Final research step to validate the complete port:

- Verify all requirements from "$INSTRUCTIONS" are met
- Check complete consistency with raddbg patterns
- Ensure no style deviations from raddbg conventions
- Verify seamless integration with existing raddbg code
- Make final commit summarizing the completed port to raddbg

Think carefully at each step! The goal is systematic porting from $SOURCE_FOLDER to raddbg that PERFECTLY matches raddbg's unique style and patterns!

REMEMBER: The todolist is your primary tool for success - keep it updated CONSTANTLY throughout all 6 steps!
REMEMBER: raddbg has specific patterns that MUST be researched and followed - never assume, always verify!
REMEMBER: After EVERY commit in Step 6, return to Step 1 - no shortcuts, no exceptions!
