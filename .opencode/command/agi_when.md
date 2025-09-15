---
description: Create or modify slash commands based on user requirements
agent: build
---

# Parse arguments for the new command

# Expected format: "command-name description of what it should do"

# Split on first space to separate command name from description

echo "Parsing command arguments: $ARGUMENTS"

# Extract command name (first word) and requirements (rest)

COMMAND_NAME=$(echo "$ARGUMENTS" | cut -d' ' -f1)
REQUIREMENTS=$(echo "$ARGUMENTS" | cut -d' ' -f2-)

# Validate we have both parts

if [ -z "$COMMAND_NAME" ] || [ -z "$REQUIREMENTS" ] || [ "$COMMAND_NAME" = "$REQUIREMENTS" ]; then
echo "❌ Error: Please provide both command name and description"
echo "Usage: /agi_when <command-name> <description-of-what-it-should-do>"
echo "Example: /agi_when test-runner 'create a command that runs tests with coverage'"
exit 1
fi

# Step 1: Research existing slash commands for patterns

echo "📚 Studying existing slash commands to understand patterns..."

Use researcher to analyze @.opencode/command folder:

- Read 3-4 existing command files to understand structure
- Identify common patterns and conventions
- Note the YAML frontmatter format (description, agent)
- Understand how arguments are handled ($ARGUMENTS)
- Study how agents are used (researcher, executioner, etc.)

# Step 2: Fetch and understand slash command documentation

echo "📖 Learning from official documentation..."

Use WebFetch to get slash command documentation:

- Fetch https://opencode.ai/docs/commands/
- Understand the command structure requirements
- Learn about available features and limitations
- Note best practices for command creation

# Step 3: Design the new command based on requirements

echo "🎨 Designing command '$COMMAND_NAME' for: $REQUIREMENTS"

Design the command structure:

- Determine if it needs arguments and what format
- Decide which agents to use (researcher, executioner, or both)
- Plan the command flow and steps
- Consider if it needs todolists, branches, or commits
- Determine if it should be cyclic (like goalv2) or linear

# Step 4: Create or modify the command file

echo "✍️ Creating/modifying @.opencode/command/${COMMAND_NAME}.md"

Generate the command file with:

- Proper YAML frontmatter
  - description: concise description of what the command does
  - agent: appropriate agent (build, plan, researcher, executioner)
- Clear argument parsing (if needed using $ARGUMENTS)
- Well-structured command logic
- Appropriate use of agents
- Clear instructions for each step
- Any necessary safety checks or validations

Example patterns to consider:

- Simple execution: Direct bash commands or single agent use
- Research-first: Use researcher to understand before acting
- Cyclic pattern: Like goalv2/port with alternating modes
- Multi-step process: Like port_to_raddbg with specific phases
- Tool-specific: Commands that focus on specific tools

# Step 5: Validate and test the command

echo "✅ Validating the new command..."

Ensure the command:

- Has valid markdown structure
- Includes proper YAML frontmatter
- Handles arguments correctly
- Uses agents appropriately
- Follows existing command conventions
- Is clear and unambiguous in instructions
- Includes error handling where needed

# Step 6: Provide usage instructions

echo "📝 Command created successfully!"

Show the user:

- How to use the new command: /$COMMAND_NAME [arguments]
- What the command will do when executed
- Any important notes or limitations
- Suggest testing with a simple case first

# Common command patterns from @.opencode/command:

## Pattern 1: Simple task executor

```
---
description: Do a specific task
agent: build
---
Execute the task using appropriate tools
```

## Pattern 2: Research and execute

```
---
description: Research then implement
agent: build
---
Use researcher to understand $ARGUMENTS
Use executioner to implement changes
```

## Pattern 3: Cyclic workflow (like goalv2)

```
---
description: Iterative task completion
agent: build
---
Create todolist
Cycle through: Research → Execute → Adjust
Maintain todolist throughout
```

## Pattern 4: Multi-codebase operations (like port_to_raddbg)

```
---
description: Work across multiple codebases
agent: build
---
Research source
Research destination
Research integration points
Execute changes
Verify quality
```

Think carefully about what kind of command pattern best fits: "$REQUIREMENTS"!
