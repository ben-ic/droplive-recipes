# SnappyMail protocol review

The purpose of this integration is to test WorldFixture IMAP and SMTP through a real mail client. Use the pinned built-in `business.saas-company.v2` fixture: 16 users and 74 messages. The large v3 fixture has 161 users and 3,069 messages and exceeded DropLive's 120-second build readiness window even with `skiplist_unsafe: 1`.

This change selects the smaller official fixture and removes that Cyrus durability override. The normal runtime state paths and authentication remain in use. SnappyMail reads and sends messages through the generated IMAP and SMTP bindings inside its own Firecracker guest. SMTP AUTH is not requested because the emulator does not implement it; IMAP uses generated credentials.

Required review: open the seeded inbox, read a message, send a synthetic message through SMTP, verify it through IMAP, save a secret-free screenshot, and end the session through the public UI. Local validation passed: the fresh image was ready within 24.1 seconds, SnappyMail opened the seeded inbox and a message, SMTP sent a synthetic message, and an independent IMAP client authenticated, searched for it, and fetched the expected body. Firecracker validation is pending.
