# Complexity-Based Model Routing

Referenced by `cook.md`. Instead of static model assignment, lead assesses each task's complexity from ROADMAP.md and assigns models accordingly.

## Assessment Criteria (per dev task)

- Count ROADMAP phases assigned to this dev
- Count REQ-IDs in scope
- Check if scope includes: auth, real-time, complex queries, external APIs, state machines
- Check file count estimate from MODULES.md

## Model Assignment

| Complexity | Signals | Model |
|-----------|---------|-------|
| **Low** | 1-2 phases, 1-2 REQs, CRUD only, no auth/realtime | `haiku` |
| **Medium** | 3-4 phases, 3-5 REQs, standard patterns | `sonnet` |
| **High** | 5+ phases, 6+ REQs, auth/realtime/complex logic | `sonnet` (with larger context budget) |

## Static Assignments (non-dev agents)

- domain-engineer: `sonnet` (design quality matters)
- critics: `haiku` (bounded output, review only)
- tech-lead: `sonnet` (code review needs depth)
- tester: `sonnet` (test generation needs precision)
- pm: `haiku` (status reporting is structured)

## User Confirmation

Present model assignments to user before spawning:
"Model routing: dev-backend=sonnet, dev-frontend=haiku. Adjust? (YES / proceed)"
