# Ticketing workflow

Tickets are how lab work gets tracked: every problem, request, or change is
a ticket, so nothing lives only in someone's head.

## States

```
New → In Progress → Resolved → Closed
                ↘ On Hold (waiting on something, with a note)
```

- **New** — reported, not yet picked up.
- **In Progress** — someone is working on it.
- **On Hold** — blocked (e.g. waiting on an ISO download); the ticket must
  say what it is waiting on.
- **Resolved** — fixed; the ticket records what the fix was.
- **Closed** — confirmed fixed by the reporter.

## Priority

- **P1** — lab down (DC01 won't boot, no logons work)
- **P2** — one machine or service broken
- **P3** — annoyance / improvement (default)
- **P4** — nice to have

## Fields every ticket needs

Title, reporter, priority, status, and a description that says what happened,
what was expected, and what was already tried. A ticket that just says
"it doesn't work" gets sent back for details.

## Option 1 — local tracker (included here)

`ticketing/tickets.py` is a small SQLite-backed CLI tracker. No server,
no account, data lives in `tickets.db` next to the script.

```bash
cd ticketing
python3 tickets.py new --title "CLIENT01 cannot log on" --reporter abel --priority P2
python3 tickets.py list
python3 tickets.py list --status open
python3 tickets.py close 1 --note "DNS pointed at router, not DC01; fixed"
python3 tickets.py show 1
```

## Option 2 — GitHub Issues (for a shared lab)

If the lab is shared, use GitHub Issues in the lab repo instead:

- Labels: `bug`, `request`, `P1`, `P2`, `P3`, `P4`, `in-progress`, `on-hold`
- One issue template ("Bug report") asking for: machine, what happened,
  expected result, steps tried, logs
- Close an issue only with a comment saying what fixed it, and link the
  commit if a script changed
