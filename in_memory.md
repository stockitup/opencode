# OpenCode Agent In-Memory State During Agentic Loop Execution

This document describes the complete in-memory state of an OpenCode agent while actively processing a request through the agentic loop. The state represents a live snapshot of all data structures, contexts, and variables maintained during execution.

## Core Runtime Architecture

The agentic loop operates as a streaming, event-driven system where state flows through multiple layers:

```
User Request → Session Manager → Stream Processor → Tool Executor → Response Builder
                      ↓                 ↓                ↓              ↓
                 [Session State]  [Stream State]   [Tool Context]  [Message Parts]
```

## 1. Session State Container

The session manager (`packages/opencode/src/session/index.ts:137-168`) maintains a multi-layered state structure:

### Active Session Maps
```typescript
{
  // All registered sessions indexed by session ID
  sessions: Map<string, {
    id: string                    // ULID identifier
    path: { cwd: string, root: string }
    time: { created: number }
    mode: "build" | "plan" | "agent:*"
    agentName?: string
  }>,
  
  // Message history cache per session  
  messages: Map<string, MessageV2.Info[]>,
  
  // Active execution locks (one per running session)
  pending: Map<string, AbortController>,
  
  // Auto-summarization flags for long conversations
  autoCompacting: Map<string, boolean>,
  
  // Queued messages for busy sessions
  queued: Map<string, QueuedMessage[]>
}
```

### Queued Message Structure
When a session is busy, incoming requests queue with:
- `input`: Original chat parameters
- `message`: User message metadata
- `parts`: Message content parts
- `processed`: Processing status flag
- `callback`: Completion handler function

## 2. Active Message State

During execution, two primary message objects exist:

### User Message (`MessageV2.User`)
```typescript
{
  id: "01JFN3X8Q2..."           // ULID timestamp-based ID
  role: "user"
  sessionID: "01JFN3X8Q1..."    
  time: { 
    created: 1734567890123       // Unix timestamp
  }
}
```

### Assistant Message (`MessageV2.Assistant`)
```typescript
{
  id: "01JFN3X8Q3..."
  role: "assistant"
  sessionID: "01JFN3X8Q1..."
  system: [                      // System prompt components
    "You are Claude Code...",
    "Environment: linux...",
    "Git status: ..."
  ]
  mode: "build"                  // Active agent mode
  path: {
    cwd: "/home/user/project",
    root: "/home/user/project"
  }
  cost: 0.00234                  // Running cost in USD
  tokens: {
    input: 1543,
    output: 267,
    reasoning: 0,                // For O1-style models
    cache: {
      read: 1200,                // Cached prompt tokens
      write: 343                 // New cache writes
    }
  }
  modelID: "claude-3-5-sonnet-20241022"
  providerID: "anthropic"
  time: {
    created: 1734567890456,
    completed: undefined         // Set when finished
  }
  error: undefined               // Populated on failure
}
```

## 3. Stream Processor State

The `createProcessor` function (`session/index.ts:1285-1296`) maintains real-time execution state:

```typescript
{
  // Active tool executions indexed by call ID
  toolcalls: {
    "toolu_01abc...": {
      id: "01JFN3X8Q4..."
      type: "tool"
      callID: "toolu_01abc..."
      name: "Read"
      status: "running"          // pending|running|completed|error
      input: { file_path: "/src/index.ts" }
      output?: "File contents..."
      error?: { message: "..." }
      time: {
        created: 1734567891234,
        completed?: 1734567892456
      }
    }
  },
  
  // Git snapshot for tracking file changes
  snapshot: "snap_01JFN3X8Q5...",
  
  // Emergency stop flag (set by stopWhen conditions)
  shouldStop: false,
  
  // Current streaming text part
  currentText: {
    id: "01JFN3X8Q6..."
    type: "text"
    content: "I'll help you with..."  // Accumulating text
    time: { created: 1734567890789 }
  },
  
  // O1-style reasoning traces
  reasoningMap: {
    "reasoning_01abc...": {
      id: "01JFN3X8Q7..."
      type: "reasoning"
      content: "Analyzing the request..."
      time: { created: 1734567890567 }
    }
  }
}
```

## 4. LLM Stream Configuration

The `streamText()` call (`session/index.ts:924-1038`) operates with:

```typescript
{
  // Full conversation history
  messages: [
    { role: "user", content: "..." },
    { role: "assistant", content: [...parts] },
    { role: "user", content: "..." }
  ],
  
  // Tool implementations
  tools: {
    Read: { description: "...", parameters: ZodSchema, execute: fn },
    Edit: { description: "...", parameters: ZodSchema, execute: fn },
    Bash: { description: "...", parameters: ZodSchema, execute: fn },
    // ... 15+ tools
  },
  
  // Active tool names
  activeTools: ["Read", "Edit", "Bash", "Write", "Grep", ...],
  
  // Generation parameters
  maxOutputTokens: 8192,
  temperature: 0.2,
  topP: 0.95,
  
  // Cancellation signal
  abortSignal: AbortSignal { aborted: false },
  
  // Provider-specific options
  providerOptions: {
    anthropic: {
      headers: {
        "anthropic-beta": "prompt-caching-2024-07-31,streaming-thinking-2024-12-09"
      }
    }
  },
  
  // Custom stop conditions
  stopWhen: (event) => {
    return event.finishReason === "error" || 
           processor.shouldStop || 
           event.usage.steps > 1000
  }
}
```

## 5. Tool Execution Context

Each tool invocation receives (`tool/tool.ts:7-15`):

```typescript
{
  sessionID: "01JFN3X8Q1..."    // Current session
  messageID: "01JFN3X8Q3..."    // Assistant message ID
  agent: "build"                // Active agent name
  callID: "toolu_01abc..."      // Unique tool call ID
  abort: AbortSignal { ... },   // Cancellation signal
  extra: {                      // Additional context
    snapshot?: "snap_01JFN3X8Q5..."
  },
  metadata: (input) => {        // Progress callback
    // Updates tool part metadata in real-time
  }
}
```

## 6. Agent Configuration

The active agent maintains (`agent/agent.ts:60-136`):

```typescript
{
  name: "build",
  description: "Primary coding agent",
  mode: "primary",
  builtIn: true,
  temperature: 0.2,
  topP: 0.95,
  permission: {
    edit: "allow",              // allow|ask|deny
    bash: {
      "rm": "deny",
      "sudo": "deny",
      "*": "allow"
    },
    webfetch: "allow"
  },
  model: {
    modelID: "claude-3-5-sonnet-20241022",
    providerID: "anthropic"
  },
  prompt: undefined,            // Custom system prompt
  tools: {                      // Tool availability
    Read: true,
    Edit: true,
    Bash: true,
    Write: true,
    Grep: true,
    Glob: true,
    Task: true,
    WebFetch: true,
    Todo: true,
    // ... more tools
  },
  options: {}                   // Provider-specific options
}
```

## 7. Message Parts Collection

Throughout execution, message parts accumulate representing the complete interaction:

```typescript
[
  // User input
  { type: "file", id: "...", source: "editor", content: "..." },
  { type: "text", id: "...", content: "Help me fix this bug" },
  
  // Assistant reasoning (if O1 model)
  { type: "reasoning", id: "...", content: "Analyzing the code..." },
  
  // Assistant response
  { type: "text", id: "...", content: "I'll analyze your code..." },
  
  // Tool execution
  { 
    type: "tool",
    id: "...",
    callID: "toolu_01abc...",
    name: "Read",
    status: "completed",
    input: { file_path: "/src/index.ts" },
    output: "File contents...",
    time: { created: 123456, completed: 123789 }
  },
  
  // More text
  { type: "text", id: "...", content: "Based on the file..." },
  
  // Step boundaries (for multi-step reasoning)
  { type: "step-start", id: "...", name: "analyze" },
  { type: "step-finish", id: "...", name: "analyze", tokens: {...} }
]
```

## 8. Environment Context

System prompts include environment state:

```typescript
{
  workingDirectory: "/home/user/project",
  isGitRepo: true,
  platform: "linux",
  osVersion: "Linux 5.15.167.4",
  todaysDate: "2025-09-02",
  gitStatus: {
    branch: "main",
    modifiedFiles: ["src/index.ts"],
    untrackedFiles: ["new-file.md"]
  },
  fileTree: [                   // Up to 200 files
    "package.json",
    "src/index.ts",
    "src/utils.ts",
    // ...
  ],
  instructions: {
    global: "Content of ~/.claude/CLAUDE.md",
    local: "Content of ./AGENTS.md"
  }
}
```

## 9. Streaming Event Processing

During the main loop (`session/index.ts:1296-1575`), events flow through:

```typescript
for await (const event of stream.fullStream) {
  switch (event.type) {
    case "tool-input-start":
      // Create new tool part
      // Update toolcalls map
      break
      
    case "tool-call":
      // Execute tool with context
      // Stream output chunks
      break
      
    case "tool-result":
      // Finalize tool part
      // Update tokens/cost
      break
      
    case "text-start":
      // Initialize text part
      // Set currentText
      break
      
    case "text-delta":
      // Append to currentText
      // Trigger UI update
      break
      
    case "reasoning-delta":
      // Update reasoning part
      // Hidden from user view
      break
      
    case "finish":
      // Finalize message
      // Calculate total cost
      // Set completion time
      break
  }
}
```

## 10. Resource Management

### Token and Cost Tracking
```typescript
{
  totalTokens: {
    input: 15234,
    output: 3456,
    reasoning: 0,
    cacheRead: 12000,
    cacheWrite: 3234
  },
  totalCost: 0.00456,           // USD
  modelRates: {
    input: 0.000003,             // Per token
    output: 0.000015,
    cacheRead: 0.0000003,
    cacheWrite: 0.0000037
  }
}
```

### Memory Limits
- Max output tokens: 8192 (configurable)
- Max tool iterations: 1000
- Max file read: 5000 lines × 5000 chars/line
- Message history: Full until auto-compaction
- Queue size: Unbounded (memory permitting)

## 11. Error State

On failure, the assistant message includes:

```typescript
{
  error: {
    code: "tool_execution_failed",
    message: "File not found: /src/missing.ts",
    details: {
      toolName: "Read",
      callID: "toolu_01abc...",
      timestamp: 1734567892789
    }
  },
  time: {
    created: 1734567890456,
    completed: 1734567892789,
    failed: 1734567892789
  }
}
```

## 12. Cleanup and Persistence

After completion:
1. Message and parts persist to database
2. Streaming processor state is garbage collected
3. AbortController is removed from pending map
4. Snapshot may persist for undo operations
5. Token costs are logged for billing

## Memory Lifecycle

1. **Initialization**: Session created, agent loaded, system prompt built
2. **Request Processing**: User message parsed, parts created
3. **Stream Setup**: Processor initialized, tools registered
4. **Execution Loop**: Events processed, state updated, tools executed
5. **Finalization**: Message completed, state persisted
6. **Cleanup**: Temporary state released, session unlocked

This represents the complete in-memory state during an active agentic loop execution, capturing all transient and persistent data structures that enable the sophisticated multi-turn, tool-using conversations in OpenCode.