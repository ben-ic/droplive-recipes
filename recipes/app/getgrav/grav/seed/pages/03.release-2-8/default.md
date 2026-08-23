---
title: 'Release 2.8'
date: '2026-08-21'
taxonomy:
    tag:
        - project
visible: true
---
# Release 2.8

Ship the audit improvements without hiding the remaining export risk.

|   |   |
|---|---|
| Owner | Elena Petrov |
| Status | at-risk |
| Started | 2026-07-27 |
| Target | 2026-08-27 |
| Team | Elena Petrov, Jon Bell, Lucas Meyer, Hana Ito, Imani Brooks, Samira Okafor |

### Tasks

| Task | Owner | Status | Priority | Due |
|---|---|---|---|---|
| Run the 50k-row export test | Lucas Meyer | done | high | 2026-08-21 |
| Run the 75k-row export test | Lucas Meyer | done | high | 2026-08-21 |
| Remove the partial object after cancellation | Lucas Meyer | blocked | urgent | 2026-08-24 |
| Correct the audit timezone label | Hana Ito | review | normal | 2026-08-25 |
| Write release notes for audit history | Elena Petrov | in-progress | normal | 2026-08-25 |
| Approve the audit empty state | Imani Brooks | done | normal | 2026-08-19 |

### Time logged

| Date | Person | Minutes | Note |
|---|---|---|---|
| 2026-08-20 | Lucas Meyer | 95 | Prepared the scheduled fixture and captured the baseline. |
| 2026-08-21 | Lucas Meyer | 40 | Ran the fix branch and checked worker memory. |
| 2026-08-21 | Lucas Meyer | 55 | Completed the large run and checked lease release. |
| 2026-08-21 | Lucas Meyer | 70 | Found the partial object left by cancellation. |
| 2026-08-20 | Hana Ito | 35 | Reproduced the suffix error and added a view test. |
| 2026-08-20 | Elena Petrov | 50 | Drafted the audit history section. |
| 2026-08-19 | Imani Brooks | 45 | Reviewed copy in the narrow and wide layouts. |
