# Tool Implementations and Usage in OpenCode

This document provides a comprehensive description of all tool implementations in OpenCode, their specific functionalities, and how agents use them during execution.

## Overview of Implemented Tools

OpenCode currently implements **14 primary tools** and **3 utility tools** that agents can use during their execution. Each tool is designed with specific security measures, output limits, and usage patterns.

## Core File System Tools

### 1. Read Tool (`read.ts`)
**Purpose**: Safe file reading with format detection and limits

**Implementation Details**:
- **Limits**: 5000 lines maximum, 5000 characters per line
- **Binary Detection**: Uses 30% non-printable character threshold
- **Format**: Line-numbered output (e.g., `00001| content`)
- **Encoding**: UTF-8 with fallback error handling

**Usage by Agent**:
```typescript
// Agent reads a file to understand code structure
await ReadTool.execute({
  file_path: "/absolute/path/to/file.ts",
  offset: 100,  // Optional: start from line 100
  limit: 200    // Optional: read 200 lines
})
```

**Common Use Cases**:
- Understanding existing code before modifications
- Analyzing configuration files
- Reading documentation
- Verifying file contents after edits

### 2. Write Tool (`write.ts`)
**Purpose**: Create new files or completely overwrite existing ones

**Security Requirements**:
- Must read existing files first (via FileTime tracking)
- Path validation prevents directory traversal
- Permission checks before writing

**Usage by Agent**:
```typescript
// Agent creates a new configuration file
await WriteTool.execute({
  file_path: "/project/config.json",
  content: JSON.stringify(configData, null, 2)
})
```

**Common Use Cases**:
- Creating new source files
- Generating configuration files
- Writing documentation
- Creating test files

### 3. Edit Tool (`edit.ts`)
**Purpose**: Intelligent string replacement with multiple matching strategies

**Advanced Matching Algorithms**:
1. **SimpleReplacer**: Exact string match
2. **LineTrimmedReplacer**: Ignores leading/trailing whitespace
3. **BlockAnchorReplacer**: Uses first/last line anchors
4. **WhitespaceNormalizedReplacer**: Normalizes all whitespace
5. **IndentationFlexibleReplacer**: Handles indentation variations
6. **EscapeNormalizedReplacer**: Handles escape sequences

**Usage by Agent**:
```typescript
// Agent modifies a function implementation
await EditTool.execute({
  file_path: "/src/utils.ts",
  old_string: "function oldImplementation() {\n  return 42;\n}",
  new_string: "function newImplementation() {\n  return 100;\n}",
  replace_all: false  // Only replace first occurrence
})
```

**Diff Generation**: Creates unified diffs for all changes

**Common Use Cases**:
- Modifying function implementations
- Updating import statements
- Fixing bugs in existing code
- Refactoring code patterns

### 4. MultiEdit Tool (`multiedit.ts`)
**Purpose**: Apply multiple sequential edits to a single file

**Implementation**: Wraps EditTool for atomic multi-edit operations

**Usage by Agent**:
```typescript
// Agent makes multiple changes to a file
await MultiEditTool.execute({
  file_path: "/src/component.tsx",
  edits: [
    { old_string: "import React", new_string: "import * as React" },
    { old_string: "useState(0)", new_string: "useState(10)" },
    { old_string: "className", new_string: "className", replace_all: true }
  ]
})
```

**Common Use Cases**:
- Bulk refactoring
- Multiple related fixes
- Systematic code updates

## Code Search and Discovery Tools

### 5. Glob Tool (`glob.ts`)
**Purpose**: Fast file pattern matching using ripgrep

**Implementation**:
- Uses ripgrep's `--files` mode for performance
- Sorts results by modification time (newest first)
- Limits to 100 files to prevent overwhelming output

**Usage by Agent**:
```typescript
// Agent finds all TypeScript test files
await GlobTool.execute({
  pattern: "**/*.test.ts",
  path: "/src"  // Optional: search within specific directory
})
```

**Common Use Cases**:
- Finding files by extension
- Locating configuration files
- Discovering test files
- Mapping project structure

### 6. Grep Tool (`grep.ts`)
**Purpose**: Content searching with regex support

**Implementation**:
- Direct ripgrep execution with full regex support
- Line number output with `-n` flag
- File grouping in results

**Usage by Agent**:
```typescript
// Agent searches for function definitions
await GrepTool.execute({
  pattern: "function\\s+\\w+\\s*\\(",
  path: "/src",
  glob: "*.ts"  // Optional: filter by file pattern
})
```

**Output Format**:
```
path/to/file.ts
  42: function processData() {
  89: function validateInput() {
```

**Common Use Cases**:
- Finding function/class definitions
- Searching for TODOs or FIXMEs
- Locating import statements
- Finding configuration values

### 7. List Tool (`ls.ts`)
**Purpose**: Directory structure visualization

**Implementation**:
- Recursive directory traversal with ignore patterns
- Tree-style output with indentation
- Filters common build artifacts and dependencies

**Default Ignores**:
- `node_modules`, `.git`, `dist`, `build`
- Binary files, cache directories
- OS-specific files (`.DS_Store`, `Thumbs.db`)

**Usage by Agent**:
```typescript
// Agent explores project structure
await ListTool.execute({
  path: "/src",
  ignore: ["*.test.ts", "*.spec.ts"]  // Additional ignores
})
```

**Common Use Cases**:
- Understanding project structure
- Finding relevant directories
- Exploring unfamiliar codebases

## System Execution Tools

### 8. Bash Tool (`bash.ts`)
**Purpose**: Secure command execution with comprehensive controls

**Security Features**:
- **Tree-sitter parsing**: Analyzes commands before execution
- **Path validation**: Prevents access outside working directory
- **Permission system**: Wildcard-based allow/deny/ask rules
- **Command restrictions**: Blocks dangerous operations

**Implementation Details**:
- Real-time output streaming via metadata updates
- Default timeout: 2 minutes (max: 10 minutes)
- Output limit: 30,000 characters

**Usage by Agent**:
```typescript
// Agent runs tests
await BashTool.execute({
  command: "npm test",
  timeout: 60000,  // Optional: 1 minute timeout
  description: "Running unit tests"
})
```

**Permission Examples**:
```javascript
// Permission configuration
{
  "bash": {
    "allow": ["npm test", "npm run *"],
    "deny": ["rm -rf", "sudo *"],
    "ask": ["git push", "npm publish"]
  }
}
```

**Common Use Cases**:
- Running build scripts
- Executing tests
- Git operations
- Package management
- File operations

### 9. Patch Tool (`patch.ts`)
**Purpose**: Apply structured patches to multiple files

**Patch Format**:
```diff
*** Update File: src/index.ts
@@ function main() { @@
 console.log("Hello");
-console.log("Old");
+console.log("New");

*** Add File: src/new.ts
+export const value = 42;

*** Delete File: src/old.ts
```

**Implementation**:
- Validates all files before applying changes
- Atomic operations (all or nothing)
- Context-based line matching

**Usage by Agent**:
```typescript
// Agent applies multi-file refactoring
await PatchTool.execute({
  patch: patchContent
})
```

**Common Use Cases**:
- Multi-file refactoring
- Applying generated patches
- Bulk code updates

## Web and External Tools

### 10. WebFetch Tool (`webfetch.ts`)
**Purpose**: Retrieve and process web content

**Features**:
- Format support: text, markdown, HTML
- HTML to Markdown conversion via TurndownService
- Size limit: 5MB
- Timeout: 30s default (120s max)

**Usage by Agent**:
```typescript
// Agent fetches API documentation
await WebFetchTool.execute({
  url: "https://api.example.com/docs",
  format: "markdown"  // Convert HTML to markdown
})
```

**Common Use Cases**:
- Fetching documentation
- Retrieving API responses
- Reading web-based resources
- Gathering external information

## Agent Orchestration Tools

### 11. Task Tool (`task.ts`)
**Purpose**: Delegate complex tasks to specialized sub-agents

**Architecture**:
- Creates new sessions for sub-tasks
- Inherits model configuration from parent
- Disables recursive task calls
- Streams real-time execution metadata

**Available Sub-Agents**:
- **general**: Research and information gathering
- **plan**: Task planning and decomposition
- Custom agents from configuration

**Usage by Agent**:
```typescript
// Agent delegates research task
await TaskTool.execute({
  description: "Research API usage",
  prompt: "Find all API endpoints used in the codebase and document their purposes",
  subagent_type: "general"
})
```

**Tool Restrictions for Sub-Agents**:
- Cannot use TodoWrite/TodoRead
- Cannot recursively call Task
- Respects agent-specific permissions

**Common Use Cases**:
- Complex research tasks
- Multi-step operations
- Specialized processing
- Parallel task execution

## Task Management Tools

### 12. TodoWrite Tool (`todo.ts`)
**Purpose**: Maintain structured task lists

**Data Structure**:
```typescript
interface Todo {
  id: string
  content: string
  status: "pending" | "in_progress" | "completed" | "cancelled"
  priority?: number
}
```

**Usage by Agent**:
```typescript
// Agent creates task list
await TodoWriteTool.execute({
  todos: [
    { content: "Analyze requirements", status: "completed" },
    { content: "Implement feature", status: "in_progress" },
    { content: "Write tests", status: "pending" }
  ]
})
```

**Common Use Cases**:
- Planning complex tasks
- Tracking progress
- Organizing multi-step operations

### 13. TodoRead Tool (`todo.ts`)
**Purpose**: Retrieve current task list

**Output**: JSON-formatted task list with status

**Usage by Agent**:
```typescript
// Agent checks current tasks
const tasks = await TodoReadTool.execute({})
```

## Language Server Protocol Tools

### 14. LSP Hover Tool (`lsp-hover.ts`)
**Purpose**: Get type information and documentation

**Implementation**: Integrates with language servers

**Usage by Agent**:
```typescript
// Agent gets type information
await LspHoverTool.execute({
  file_path: "/src/utils.ts",
  line: 42,
  character: 15
})
```

### 15. LSP Diagnostics Tool (`lsp-diagnostics.ts`)
**Purpose**: Retrieve compilation errors and warnings

**Output**: Structured diagnostic information

**Usage by Agent**:
```typescript
// Agent checks for errors after edit
await LspDiagnosticTool.execute({
  file_path: "/src/component.tsx"
})
```

## Utility Tools

### 16. Invalid Tool (`invalid.ts`)
**Purpose**: Handle malformed tool calls

**Simple Implementation**: Returns error messages for invalid calls

**Usage**: Automatically invoked when tool calls fail validation

## Tool Usage Patterns by Agents

### Build Agent (Primary Coding Agent)
**Common Tool Sequence**:
1. **Read** → Understand existing code
2. **Grep/Glob** → Find related files
3. **Edit/MultiEdit** → Make changes
4. **Bash** → Run tests/build
5. **LSP Diagnostics** → Check for errors

### General Agent (Research Agent)
**Common Tool Sequence**:
1. **Grep/Glob** → Search codebase
2. **Read** → Examine files
3. **List** → Understand structure
4. **WebFetch** → Get external info
5. **TodoWrite** → Document findings

### Plan Agent (Planning Agent)
**Common Tool Sequence**:
1. **TodoWrite** → Create task breakdown
2. **Read** → Analyze requirements
3. **Task** → Delegate to specialists
4. **TodoRead** → Track progress

## Tool Execution Context

All tools receive rich context during execution:

```typescript
interface ToolContext {
  sessionID: string       // Current session
  messageID: string       // Current message
  agent: string          // Executing agent
  callID: string         // Unique call ID
  abort: AbortSignal     // For cancellation
  
  // Real-time updates
  metadata: (update: any) => Promise<void>
  
  // Additional context
  extra: {
    workingDirectory: string
    environment: Record<string, string>
    permissions: ToolPermissions
    fileReadTimes: Map<string, number>
  }
}
```

## Security and Permissions

### Three-Tier Permission Model
1. **Allow**: Tool executes without confirmation
2. **Deny**: Tool is blocked
3. **Ask**: Requires user confirmation

### Priority Order
1. User configuration (highest)
2. Agent configuration
3. Tool defaults (lowest)

### Common Security Patterns
- Path containment validation
- Command parsing and analysis
- Resource limits (time, size, count)
- File time tracking for consistency
- Permission-based execution control

## Output Management

### Consistent Format
All tools return:
```typescript
{
  title: string        // Human-readable title
  metadata: any        // Execution metadata
  output: string       // Main output content
}
```

### Output Limits
- **Bash**: 30,000 characters
- **Read**: 5000 lines × 5000 chars/line
- **Grep**: 100 matches
- **Glob**: 100 files
- **List**: 100 entries
- **WebFetch**: 5MB

## Error Handling

### Validation Errors
- Zod schema validation for all parameters
- Clear error messages with parameter details

### Execution Errors
- Graceful degradation with helpful messages
- File suggestions when files don't exist
- Permission denial explanations

### Recovery Mechanisms
- Atomic operations (all or nothing)
- State rollback on failure
- Resource cleanup on abort

## Best Practices for Tool Usage

### 1. File Operations
- Always **Read** before **Edit** or **Write**
- Use **MultiEdit** for multiple changes to same file
- Verify changes with **LSP Diagnostics**

### 2. Code Discovery
- Start with **Grep** for content search
- Use **Glob** for file patterns
- Combine with **Read** for detailed analysis

### 3. Execution Safety
- Check permissions before **Bash** commands
- Use appropriate timeouts
- Monitor output with metadata updates

### 4. Task Delegation
- Use **Task** for complex multi-step operations
- Choose appropriate sub-agent type
- Provide clear, detailed prompts

### 5. Progress Tracking
- Update **Todo** lists frequently
- Mark tasks as in_progress before starting
- Complete tasks immediately after finishing

## Performance Considerations

### Optimizations
- **Ripgrep backend**: Fast file operations
- **Streaming output**: Real-time feedback
- **Caching**: Tool descriptions cached per session
- **Lazy loading**: Tools initialized on demand

### Resource Management
- Output truncation prevents memory issues
- Timeout controls prevent hanging
- Abort signals enable cancellation
- File limits prevent overwhelming results

## Conclusion

OpenCode's tool system provides a comprehensive, secure, and efficient set of capabilities for AI agents to perform software engineering tasks. The tools are designed with:

- **Security first**: Multiple layers of validation and permissions
- **User control**: Confirmation for sensitive operations
- **Performance**: Optimized for large codebases
- **Reliability**: Robust error handling and recovery
- **Extensibility**: Plugin system and MCP integration

This architecture enables agents to safely and effectively work with code, files, and external resources while maintaining user control and system security.