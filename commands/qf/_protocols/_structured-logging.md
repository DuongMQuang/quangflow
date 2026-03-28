# Structured Logging Protocol

Referenced by `dev-teammate.md` and `3-handoff.md`. Defines the logging standard for all application code produced by QuangFlow agents.

---

## HARD-GATE

> **All application code MUST use structured logging format.** No `console.log("something happened")`. No `print(data)`. Every log entry must be machine-parseable and contain context. Unstructured logs are technical debt.

---

## Log Format Standard

All log entries MUST be JSON-structured with the following fields:

```json
{
  "timestamp": "2026-03-28T14:30:00.000Z",
  "level": "ERROR",
  "source": "backend",
  "module": "auth/jwt",
  "req_id": "req-abc-123",
  "trace_id": "trace-xyz-789",
  "message": "Token validation failed",
  "context": {
    "user_id": "u-456",
    "token_exp": "2026-03-27T00:00:00Z"
  },
  "stack": "Error: Token expired\n    at validateJWT (auth/jwt.ts:42)..."
}
```

### Required Fields

| Field | Type | Description |
|---|---|---|
| `timestamp` | ISO 8601 string | When the event occurred (UTC) |
| `level` | enum | `INFO`, `WARN`, `ERROR`, or `FATAL` |
| `source` | string | `frontend`, `backend`, `worker`, `cli` |
| `module` | string | Slash-delimited module path (e.g., `auth/jwt`, `api/users`) |
| `req_id` | string | Request ID for correlating logs within a single request |
| `trace_id` | string | Trace ID for correlating across services (optional for single-service apps) |
| `message` | string | Human-readable description of the event |
| `context` | object | Structured key-value data relevant to the event |
| `stack` | string | Stack trace (only for ERROR and FATAL levels) |

---

## Log Levels

| Level | When to Use | Useful for Debugging |
|---|---|---|
| `INFO` | Normal operations: request received, task completed, state transitions | Understanding flow |
| `WARN` | Recoverable issues: retry triggered, deprecated API used, slow query | Catching early signals |
| `ERROR` | Failures requiring attention: unhandled exception, external service down | Root cause analysis |
| `FATAL` | Application cannot continue: missing config, database unreachable on startup | Postmortem analysis |

---

## Frontend → Backend Log Bridge

Frontend applications cannot write logs to disk directly. Use this bridge pattern:

### What to Capture (Frontend)
- Unhandled exceptions (window.onerror, unhandledrejection)
- API call failures (non-2xx responses)
- User-facing error states
- Performance threshold violations

### How to Send
```
POST /api/logs
Content-Type: application/json

{
  "entries": [
    { "timestamp": "...", "level": "ERROR", "source": "frontend", "module": "checkout/payment", ... }
  ]
}
```

### Backend Handler
- Validate log entries (reject malformed)
- Rate-limit per client (prevent log flooding)
- Write to the same log store as backend logs
- Tag with `source: "frontend"` for filtering

---

## Log File Locations

| Location | Purpose |
|---|---|
| `./logs/` | Runtime application logs (gitignored) |
| `.evidence/logs/` | Build, test, and lint output saved as evidence (committed) |

Application logs (`./logs/`) are NOT committed to git. Evidence logs (`.evidence/logs/`) ARE committed because they prove discipline compliance.

---

## Integration with Other Protocols

- **`_systematic-debugging.md`**: Investigation phase reads structured logs to trace code paths. Structured format makes this possible; unstructured logs make it guesswork.
- **`_tdd-enforcement.md`**: Test runner output saved to `.evidence/tdd/` follows file naming rules, not JSON format (raw runner output is fine for evidence).
- **`_verification-gates.md`**: Build and lint logs saved to `.evidence/logs/` are raw command output, not application log format.

---

## Red Flags

| Statement | Response |
|---|---|
| "I'll use console.log for now and add proper logging later" | Add structured logging now. It takes the same effort. |
| "This is a small app, structured logging is overkill" | Small apps grow. Structured logging costs nothing extra upfront. |
| "The log message is self-explanatory" | Without context fields, you cannot filter, search, or correlate. Add context. |
| "We don't need req_id for this endpoint" | Every request needs a req_id. It's how you trace failures across log lines. |
| "Stack traces are too verbose" | Stack traces are the most valuable part of an error log. Always include them. |

---

## Implementation Notes for Dev Agents

When implementing logging in a new project:

1. **Set up the logger first** — Before any feature code, create a logging utility that enforces the JSON format
2. **Generate req_id in middleware** — Every incoming request gets a unique req_id attached to the request context
3. **Pass logger via context** — Don't import a global logger; pass it through request context so req_id is automatic
4. **Log at boundaries** — Log at function entry/exit for key operations, not inside tight loops
5. **Never log secrets** — Sanitize passwords, tokens, API keys from context objects before logging
6. **Test the logger** — The logging utility itself should have unit tests (it's logic code, TDD applies)
