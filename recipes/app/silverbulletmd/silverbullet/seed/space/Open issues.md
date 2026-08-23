---
tags: software
modified: 2026-08-20
---
Three issues are open across the three services.

### relay-core issue 318 — Scheduled exports keep the legacy 120s worker timeout

Lumen reproduced at 52,184 rows. Manual retry uses the account limit; scheduled execution still passes 120 seconds. Test 50k, 75k, and cancellation before merge.

Repository relay-core (Go). Assignee lucasmeyer. Labels: bug, customer-lumen, release-2.8.

### exports-service issue 319 — Add cancellation case to large-export load fixture

Current fixture measures completion only. A cancelled 75k-row job must release its worker lease and partial object.

Repository exports-service (TypeScript). Assignee hanaito. Labels: test, release-2.8.

### web-console issue 322 — Audit export labels timestamps as UTC after local conversion

Value is converted correctly, but the suffix remains UTC. Visual bug only; keep out of the export worker branch.

Repository web-console (TypeScript). Assignee hanaito. Labels: bug, audit-page, small.
