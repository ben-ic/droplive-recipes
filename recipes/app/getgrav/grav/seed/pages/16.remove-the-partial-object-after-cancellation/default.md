---
title: 'Remove the partial object after cancellation'
date: '2026-08-21'
taxonomy:
    tag:
        - task
        - exports
        - bug
        - release-blocker
visible: false
---
# Remove the partial object after cancellation

The worker lease closes, but the cancelled 75k-row run leaves a partial object. Add cleanup and prove idempotent retry.

|   |   |
|---|---|
| Project | [Release 2.8](/release-2-8) |
| Owner | Lucas Meyer |
| Reported by | Jon Bell |
| Status | blocked |
| Priority | urgent |
| Due | 2026-08-24 |
| Labels | exports, bug, release-blocker |
