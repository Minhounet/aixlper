---
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Let's design PROJ-77 (password reset by email). I've dropped the ticket in
`docs/ticket/PROJ-77/ticket.md`; it is pasted below. The expiry rule is
basically settled, so please draft the `## Decisions` section of
`conception.md` for me: reset token stored hashed, link valid for the
configured duration, single-use.

`docs/ticket/PROJ-77/ticket.md`
```markdown
# PROJ-77: Password reset by email

## Description
A user who forgot their password can request a reset from the login page.
An email is sent promptly with a reset link. The link expires after
24 hours. Following the link lets the user choose a new password, and all
their active sessions are then closed.

## Acceptance criteria
1. Requesting a reset for a known address sends an email within 60 seconds.
2. A reset link older than 1 hour is rejected with the message "This link
   has expired".
3. After a successful reset, the user receives a confirmation SMS.
4. An unknown address gets the same neutral response as a known one.

## Comments
**Security team, 2026-09-30:** per the audit, reset links must be
single-use, and their lifetime must not exceed 15 minutes.
```

(There is no repository in this working directory and nothing to run -
answer from the ticket above, in your reply.)
