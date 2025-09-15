# Tools in the Agentic Loop: In-Memory State and Execution

This document provides a comprehensive technical description of how an agent manages tools in memory during the agentic loop, including tool loading, state management, and execution flow.

## 1. Agent's In-Memory State During the Agentic Loop

### 1.1 Core Runtime State

When an agent is executing within the agentic loop (session/index.ts), it maintains the following in-memory state:

```typescript
// Primary state components during execution
{
  // Session Context
  sessionID: string,              // Unique session identifier
  messageID: string,              // Current message being processed
  agentName: string,              // Active agent (e.g., "build", "general", "plan")

  // Stream State
  streamController: AbortController,  // For cancellation
  fullStream: AsyncIterator,         // AI SDK stream iterator
  streamMode: "tool-calling" | "regular",

  // Message Management
  userMessage: MessageV2,         // Input message with parts
  assistantMessage: MessageV2,    // Response being constructed
  parts: Part[],                  // Message parts (text, tool calls, results)

  // Tool State
  availableTools: Map<string, Tool>,  // Tool ID → Tool instance
  enabledTools: Record<string, boolean | "ask">,  // Permission state
  toolCallStack: ToolCall[],      // Active tool calls

  // Execution Context
  abortSignal: AbortSignal,       // Propagated to all tools
  metadata: Map<string, any>,     // Real-time execution metadata

  // Provider State
  providerID: string,             // LLM provider (anthropic, openai, etc.)
  modelID: string,                // Model identifier
  modelSettings: {                // Runtime model configuration
    temperature: number,
    maxTokens: number,
    tools: Tool[],                // Transformed tool descriptions
  }
}
```

### 1.2 Tool Description State

Tool descriptions are loaded and transformed at session initialization:

```typescript
// Tool description in memory
interface LoadedTool {
  id: string // Unique identifier (e.g., "bash", "edit")
  description: string // Full markdown description from .txt file
  parameters: ZodSchema // Validated parameter schema

  // Provider-specific transformations
  transformedSchema: {
    // OpenAI: Optional parameters become nullable
    // Google: Sanitized for Gemini compatibility
    // Anthropic: Original schema preserved
  }

  // Execution function with full context
  execute: (args, context) => Promise<Result>

  // Permission state
  permission: "allow" | "deny" | "ask"

  // Metadata
  category: string // Tool category (file, system, web, etc.)
  riskLevel: "low" | "medium" | "high"
}
```

## 2. Tool Loading and Registration Process

### 2.1 Static Registration Phase

Tools are statically registered in the ToolRegistry (tool/registry.ts):

```typescript
// At build time - tools are imported and registered
const ALL = [
  BashTool, // Command execution
  EditTool, // File modification
  ReadTool, // File reading
  WriteTool, // File creation
  GlobTool, // Pattern matching
  GrepTool, // Content search
  TaskTool, // Sub-agent delegation
  WebFetchTool, // Web content retrieval
  TodoTool, // Task tracking
  // ... additional tools
]
```

### 2.2 Session Initialization Phase

When a session starts, tools are loaded dynamically:

```typescript
// Tool loading flow (session/index.ts:794-859)
async function loadToolsForSession(agent, provider, model) {
  // Step 1: Calculate enabled tools
  const enabledTools = mergeDeep(
    agent.tools, // Agent's tool configuration
    ToolRegistry.enabled(provider, model, agent), // Registry permissions
    userOverrides, // User-specified permissions
  )

  // Step 2: Load and transform tool descriptions
  const tools = {}
  for (const toolDef of ToolRegistry.tools(provider, model)) {
    if (!isEnabled(toolDef.id, enabledTools)) continue

    // Step 3: Wrap with AI SDK tool function
    tools[toolDef.id] = tool({
      id: toolDef.id,
      description: toolDef.description,
      inputSchema: transformSchema(toolDef.parameters, provider),
      execute: wrapWithPlugins(toolDef.execute),
    })
  }

  // Step 4: Load MCP tools if configured
  const mcpTools = await loadMCPTools(agent)
  Object.assign(tools, mcpTools)

  return tools
}
```

## 3. Tool Description Handling

### 3.1 Description Loading

Each tool loads its description from a corresponding text file:

```typescript
// Tool description loading pattern
const DESCRIPTION = fs.readFileSync(path.join(__dirname, "bash.txt"), "utf-8")
```

### 3.2 Description Transformation for LLM

Tool descriptions are transformed based on the provider:

```typescript
function prepareToolForLLM(tool, provider) {
  const description = {
    name: tool.id,
    description: tool.description,

    // Provider-specific parameter formatting
    parameters:
      provider === "anthropic"
        ? tool.parameters // Anthropic uses raw Zod schema
        : provider === "openai"
          ? convertToOpenAIFormat(tool.parameters) // OpenAI JSON schema
          : provider === "google"
            ? sanitizeForGemini(tool.parameters) // Gemini compatibility
            : tool.parameters,
  }

  return description
}
```

## 4. Tool Calling Flow in the Agentic Loop

### 4.1 Tool Call Generation

The LLM generates tool calls during streaming:

```typescript
// Tool call processing in the stream loop (session/index.ts:1296-1575)
for await (const event of stream.fullStream) {
  switch (event.type) {
    case "tool-call":
      // LLM has decided to call a tool
      const toolCall = {
        id: event.toolCallId,
        name: event.toolName,
        arguments: event.args,
        state: "pending",
      }

      // Add to message parts
      parts.push({
        type: "tool-call",
        ...toolCall,
      })

      // Execute the tool
      const result = await executeToolCall(toolCall)

      // Add result to parts
      parts.push({
        type: "tool-result",
        toolCallId: toolCall.id,
        result: result.output,
      })
      break
  }
}
```

### 4.2 Tool Execution Context

When a tool is executed, it receives rich context:

```typescript
interface ToolExecutionContext {
  // Session identification
  sessionID: string,              // Current session
  messageID: string,              // Message triggering the call
  callID: string,                 // Unique tool call ID
  agent: string,                  // Agent executing the tool

  // Control flow
  abort: AbortSignal,             // For cancellation

  // Real-time updates
  metadata: async (update) => {   // Stream execution progress
    // Updates are sent to client in real-time
    await updateToolMetadata(callID, update)
  },

  // Additional context
  extra: {
    workingDirectory: string,
    environment: Record<string, string>,
    permissions: ToolPermissions,
    fileReadTimes: Map<string, number>,  // File consistency tracking
  }
}
```

### 4.3 Tool Result Processing

Tool results are processed and transformed:

```typescript
async function processToolResult(result, toolCall) {
  // Structure the result
  const formattedResult = {
    title: result.title || `Executed ${toolCall.name}`,
    metadata: result.metadata || {},
    output: truncateIfNeeded(result.output, MAX_OUTPUT_LENGTH),

    // Execution metadata
    executionTime: Date.now() - toolCall.startTime,
    status: "success" | "error",

    // For file operations - track changes
    filesModified: result.metadata?.filesModified || [],
    filesRead: result.metadata?.filesRead || [],
  }

  // Update session state
  await updateSessionState({
    lastToolCall: toolCall.id,
    toolResults: [...previousResults, formattedResult],
  })

  return formattedResult
}
```

## 5. State Management During Tool Execution

### 5.1 Pre-Execution State

Before a tool executes:

```typescript
{
  // Tool call is pending
  toolCall: {
    state: "pending",
    arguments: validated,        // Zod-validated arguments
    permissions: checked,        // Permissions verified
  },

  // Session maintains consistency
  fileReadTimes: Map<string, number>,  // Track file versions
  openTransactions: [],          // Any ongoing operations
}
```

### 5.2 During Execution State

While a tool is executing:

```typescript
{
  // Tool call is active
  toolCall: {
    state: "executing",
    startTime: Date.now(),
    abortController: new AbortController(),

    // Real-time updates
    metadata: {
      progress: "Reading file...",
      linesProcessed: 150,
      // Streamed to client via SSE
    }
  },

  // Resource tracking
  activeProcesses: Set<ChildProcess>,  // For bash tool
  openFileHandles: Set<FileHandle>,    // For file tools
  activeRequests: Set<Request>,        // For web tools
}
```

### 5.3 Post-Execution State

After tool execution:

```typescript
{
  // Tool call is complete
  toolCall: {
    state: "completed",
    result: processedOutput,
    executionTime: duration,

    // Side effects tracked
    sideEffects: {
      filesModified: ["src/index.ts"],
      processesStarted: [],
      networkRequests: ["https://api.example.com"],
    }
  },

  // Session state updated
  messagePartS: [...previousParts, toolResult],
  lastActivity: Date.now(),
  toolCallCount: incrementedCount,
}
```

## 6. Tool Permission and Security Model

### 6.1 Permission Resolution

Tools have a three-tier permission model:

```typescript
enum ToolPermission {
  ALLOW = "allow", // Tool can execute without confirmation
  DENY = "deny", // Tool is blocked
  ASK = "ask", // Requires user confirmation
}

function resolveToolPermission(toolId, agent, userConfig) {
  // Priority order:
  // 1. User configuration (highest priority)
  if (userConfig[toolId] !== undefined) {
    return userConfig[toolId]
  }

  // 2. Agent configuration
  if (agent.tools[toolId] !== undefined) {
    return agent.tools[toolId]
  }

  // 3. Tool default (lowest priority)
  return getToolDefault(toolId)
}
```

### 6.2 Security Constraints

Tools operate within security boundaries:

```typescript
interface ToolSecurityContext {
  // Path containment
  workingDirectory: string // Cannot access outside
  allowedPaths: string[] // Additional allowed paths

  // Command restrictions (bash tool)
  blockedCommands: string[] // e.g., ["rm -rf", "sudo"]
  requireConfirmation: string[] // e.g., ["git push", "npm publish"]

  // Network restrictions (webfetch tool)
  allowedDomains: string[] // Whitelist
  blockedDomains: string[] // Blacklist

  // Resource limits
  maxFileSize: number // File operation limits
  maxExecutionTime: number // Tool timeout
  maxOutputLength: number // Output truncation
}
```

## 7. Tool Call Orchestration

### 7.1 Sequential vs Parallel Execution

The agent manages tool calls based on dependencies:

```typescript
// Sequential execution for dependent tools
async function executeSequential(toolCalls) {
  const results = []
  for (const call of toolCalls) {
    const result = await executeToolCall(call)
    results.push(result)

    // Update context for next tool
    updateExecutionContext(result)
  }
  return results
}

// Parallel execution for independent tools
async function executeParallel(toolCalls) {
  return Promise.all(toolCalls.map((call) => executeToolCall(call)))
}
```

### 7.2 Tool Call Stack Management

The agent maintains a call stack for nested operations:

```typescript
class ToolCallStack {
  private stack: ToolCall[] = []

  push(call: ToolCall) {
    // Check for recursion
    if (this.hasRecursion(call)) {
      throw new Error("Tool recursion detected")
    }

    // Check depth limit
    if (this.stack.length >= MAX_TOOL_DEPTH) {
      throw new Error("Maximum tool depth exceeded")
    }

    this.stack.push(call)
  }

  pop(): ToolCall {
    return this.stack.pop()
  }

  getCurrentContext(): ToolContext {
    return {
      depth: this.stack.length,
      parentCall: this.stack[this.stack.length - 1],
      rootCall: this.stack[0],
    }
  }
}
```

## 8. Memory Management and Optimization

### 8.1 Tool Description Caching

Tool descriptions are cached to avoid reloading:

```typescript
class ToolDescriptionCache {
  private cache = new Map<string, LoadedTool>()

  async get(toolId: string, provider: string): Promise<LoadedTool> {
    const key = `${toolId}-${provider}`

    if (!this.cache.has(key)) {
      const tool = await loadTool(toolId)
      const transformed = transformForProvider(tool, provider)
      this.cache.set(key, transformed)
    }

    return this.cache.get(key)
  }
}
```

### 8.2 Output Buffering and Streaming

Large outputs are handled efficiently:

```typescript
class ToolOutputBuffer {
  private chunks: string[] = []
  private totalSize = 0

  append(chunk: string) {
    this.chunks.push(chunk)
    this.totalSize += chunk.length

    // Stream to client if large
    if (this.totalSize > STREAM_THRESHOLD) {
      this.flush()
    }
  }

  flush() {
    const output = this.chunks.join("")

    // Truncate if necessary
    if (output.length > MAX_OUTPUT_LENGTH) {
      return output.slice(0, MAX_OUTPUT_LENGTH) + "\n[Output truncated]"
    }

    return output
  }
}
```

## 9. Error Handling and Recovery

### 9.1 Tool Execution Errors

Errors are caught and transformed:

```typescript
async function safeToolExecute(tool, args, context) {
  try {
    return await tool.execute(args, context)
  } catch (error) {
    // Categorize error
    const errorType = categorizeError(error)

    // Return structured error
    return {
      title: `Error: ${tool.id}`,
      metadata: {
        error: true,
        errorType,
        errorMessage: error.message,
      },
      output: formatErrorForLLM(error),
    }
  }
}
```

### 9.2 State Recovery

The system maintains consistency after errors:

```typescript
class StateRecovery {
  async recoverFromToolError(session, toolCall, error) {
    // Roll back any partial changes
    await this.rollbackChanges(toolCall)

    // Update session state
    session.parts.push({
      type: "tool-error",
      toolCallId: toolCall.id,
      error: error.message,
    })

    // Clean up resources
    await this.cleanupResources(toolCall)

    // Continue with next operation
    return session
  }
}
```

## Conclusion

The agent's in-memory state during the agentic loop is a sophisticated orchestration of tool descriptions, execution contexts, and state management. The system maintains:

1. **Rich Context**: Every tool execution has full session and execution context
2. **Security Boundaries**: Permissions and constraints are enforced at multiple levels
3. **Real-time Updates**: Metadata streaming provides live execution feedback
4. **Error Recovery**: Robust error handling maintains consistency
5. **Performance Optimization**: Caching and buffering ensure efficiency
6. **Provider Flexibility**: Tool descriptions adapt to different LLM providers

This architecture enables the agent to seamlessly integrate multiple tools while maintaining security, performance, and reliability throughout the agentic loop.
