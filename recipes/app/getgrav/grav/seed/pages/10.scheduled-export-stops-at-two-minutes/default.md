---
title: 'Scheduled export stops at two minutes'
date: '2026-08-21'
taxonomy:
    tag:
        - incident
        - customer
visible: false
---
# Scheduled export stops at two minutes

Lumen Labs. Opened 2026-08-18 by Priya Raman. Owner Samira Okafor. Priority high. State engineering.

### What the customer sees

Lumen reproduced at 52,184 rows. Manual retry uses the account limit; scheduled execution still passes 120 seconds. Test 50k, 75k, and cancellation before merge.

### What the team has said

> Priya sent a useful boundary: 48k rows finishes in 1m34s; 52k reaches the two-minute worker limit. Interactive retry works, scheduled retry does not.
>
> — *Samira Okafor, 2026-08-20 09:06 in #lumen-renewal*

> I can reproduce it. The scheduler still passes the old timeout to the export worker. Fix is small; the load test is not.
>
> — *Lucas Meyer, 2026-08-20 09:18 in #lumen-renewal*

> Please do not merge on the small fixture alone. Run 50k, 75k, and a cancelled job. If cancellation leaks workers, 2.8 waits.
>
> — *Jon Bell, 2026-08-20 09:31 in #lumen-renewal*

> Account note: invoice 4471 is open, but it is not overdue until the 30th. Keep billing out of the incident reply unless Priya asks.
>
> — *Noor Alvarez, 2026-08-20 10:02 in #lumen-renewal*

### Where the fix is

* [Run the 50k-row export test](/run-the-50k-row-export-test) — Lucas Meyer, done
* [Run the 75k-row export test](/run-the-75k-row-export-test) — Lucas Meyer, done
* [Remove the partial object after cancellation](/remove-the-partial-object-after-cancellation) — Lucas Meyer, blocked

### Next action

Send workaround before 15:00 and update after cancellation test.
