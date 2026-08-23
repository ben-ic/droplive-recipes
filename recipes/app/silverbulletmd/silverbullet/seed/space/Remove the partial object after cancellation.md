---
tags: task, exports, bug, release-blocker
modified: 2026-08-21
---
The worker lease closes, but the cancelled 75k-row run leaves a partial object. Add cleanup and prove idempotent retry.

|   |   |
|---|---|
| Project | [[Release 2.8]] |
| Owner | Lucas Meyer |
| Reported by | Jon Bell |
| Status | blocked |
| Priority | urgent |
| Due | 2026-08-24 |
| Labels | exports, bug, release-blocker |
