# Shared Agent Protocols

Referenced by all agent instruction files. Do NOT duplicate — link here instead.

---

## Documentation Research
When you need framework/library docs, check `doc_lookup` from the CK Context Block:
- **context7**: Use `mcp__context7__resolve-library-id` + `mcp__context7__get-library-docs`
- **websearch**: Use WebSearch/WebFetch (use sparingly — high token cost)
- **none**: Rely on training knowledge only, skip doc lookup

## Completion Protocol
When your work is done:
1. Mark task as completed via `TaskUpdate`
2. Send summary message to lead with:
   - What you produced (files created/modified)
   - Any assumptions made
   - Any concerns or deviations from plan
