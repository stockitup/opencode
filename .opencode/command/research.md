---
description: Deep research on codebase or topic
agent: researcher
---

# Research Task: $ARGUMENTS

Perform comprehensive research on the specified topic or codebase area. This should include:

1. **Codebase Analysis** (if relevant):
   - Search for relevant files, functions, and implementations
   - Understand the architecture and patterns used
   - Identify key modules and dependencies
   - Map out data flow and relationships

2. **Documentation Review**:
   - Check for existing documentation
   - Review comments and docstrings
   - Look for README files or guides

3. **External Research** (if needed):
   - Search for best practices
   - Find relevant documentation
   - Look up APIs or libraries used

4. **Summary**:
   - Provide a comprehensive overview of findings
   - Highlight important patterns and conventions
   - Note any issues or areas for improvement
   - Suggest next steps if applicable

Be thorough but focused. Use multiple search strategies to ensure complete coverage.

## Delegation to Researcher Subagent
- ALWAYS launch the researcher subagent to perform the investigative work end-to-end.
- Provide a highly detailed prompt that includes: scope, hypotheses, files/areas of interest, and the exact outputs you expect (lists, maps, timelines, risks).
- The main agent must not manually do the research; it should orchestrate, aggregate, and sanity-check the researcher's report.
- If further digging is needed, iterate by relaunching the researcher with refined prompts and explicit follow-up questions.
- Require the researcher to return: sources with links/paths, concise findings, contradictions/gaps, and clear next actions.
- When URLs are involved, instruct the researcher to recursively fetch linked pages as needed and cite them.
- Ensure privacy: forbid uploading secrets or internal files; the researcher must summarize rather than exfiltrate.
- After receiving the report, synthesize into actionable conclusions and decisions before proceeding.