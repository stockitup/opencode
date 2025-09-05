---
description: Port functionality from jad/urls.py to server/routing.py with strict 6-step process
agent: build
---

# Parse optional target functionality from arguments
TARGET="$ARGUMENTS"

if [ -n "$TARGET" ]; then
  echo "🎯 Targeting specific functionality: $TARGET"
else
  echo "📦 Porting all jad/urls.py functionality to server/routing.py"
fi

# Check if we're already on a specialized branch, create one if not
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" || "$CURRENT_BRANCH" == "develop" ]]; then
  BRANCH_NAME="port-jad-to-server-$(date +%Y%m%d)"
  echo "Creating branch: $BRANCH_NAME"
  git checkout -b "$BRANCH_NAME"
else
  echo "Already on specialized branch: $CURRENT_BRANCH"
fi

# CRITICAL: Create and maintain the EXACT 6-step todolist!
# This is a STRICT process - DO NOT deviate from these 6 steps
# The todolist MUST follow this exact format throughout

Use TodoWrite tool to create this EXACT todolist:
1. Researcher subagent: research the relevant functionality (py/html/js/css) of the old jad/urls.py server
2. Researcher subagent: research the relevant functionality of the new server/routing.py server
3. Executioner subagent: implement the discovered changes in the new server/routing.py server
4. Research the quality of the changes given the rest of the @server/
5. Commit the worthy progress
6. Update the todos with these exact 6 steps

# STEP 1: Research old jad/urls.py server
Mark step 1 as in_progress in todolist BEFORE starting

Use researcher agent to analyze the old jad/urls.py server:
- Read and analyze jad/urls.py to understand URL patterns
- Identify related view handlers (uber_views, uni_views, etc.)
- Find associated templates in jad/templates/
- Document JavaScript/CSS dependencies
- Map the complete request flow from URL to response
- Create a comprehensive list of functionality to port
- Focus on: $TARGET (if specified)

Mark step 1 as completed IMMEDIATELY after finishing

# STEP 2: Research new server/routing.py server  
Mark step 2 as in_progress in todolist BEFORE starting

Use researcher agent to analyze the new server/routing.py:
- Read and analyze server/routing.py structure
- Understand the routing pattern: (path, handler, rights, [params])
- Identify existing handler modules in server/
- Understand authentication and rights system
- Map template structure in server/templates/
- Document the new architecture patterns
- Identify what's already been ported
- Determine integration points for new functionality

Mark step 2 as completed IMMEDIATELY after finishing

# STEP 3: Execute implementation in server/routing.py
Mark step 3 as in_progress in todolist BEFORE starting

Use executioner agent to implement the discovered changes:
- Add new routes to server/routing.py following the pattern
- Create handler modules in appropriate directories:
  - server/sellfiller/ for main business logic
  - server/integrations/ for external integrations
  - server/api_handlers/ for API endpoints
- Port view logic from Django to async handlers
- Migrate templates from Django to Jinja2
- Ensure proper rights/authentication setup
- Follow naming conventions (handle, handle_single, etc.)
- Test each route for basic functionality

Mark step 3 as completed IMMEDIATELY after finishing

# STEP 4: Research quality of changes
Mark step 4 as in_progress in todolist BEFORE starting

Research the quality of the implemented changes:
- Review all modified files in server/
- Check consistency with existing patterns
- Verify proper error handling
- Ensure authentication/authorization is correct
- Check database queries are properly async
- Validate template rendering
- Test WebSocket compatibility if needed
- Identify any issues or improvements needed

Mark step 4 as completed IMMEDIATELY after finishing

# STEP 5: Commit worthy progress
Mark step 5 as in_progress in todolist BEFORE starting

Commit the changes if they are worthy:
- Run git status to see all changes
- Run git diff to review modifications
- Only commit if changes are functional and follow patterns
- Use descriptive commit message: "port: [functionality] from jad to server"
- If changes need more work, document what's needed

Mark step 5 as completed IMMEDIATELY after finishing

# STEP 6: Update todos with these exact 6 steps
Mark step 6 as in_progress in todolist BEFORE starting

MANDATORY: Reset the todolist for the next cycle
- If more porting is needed, recreate the EXACT same 6-step todolist
- Each cycle must follow these exact 6 steps
- Continue cycles until all required functionality is ported
- NEVER deviate from this 6-step pattern

Mark step 6 as completed, then create new 6-step todo cycle if needed

# IMPORTANT REMINDERS:
- BE VERY STRICT about adhering to this todo format
- Update todos IMMEDIATELY when starting/completing each step
- Each cycle MUST have exactly these 6 steps
- This is a repurpose of goalv2.md with extra research steps
- Focus on systematic, quality porting of functionality
- Maintain the strict 6-step discipline throughout

Think carefully! Port functionality systematically through these exact 6 steps!