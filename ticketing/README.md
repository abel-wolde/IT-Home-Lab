# Ticket tracker

SQLite-backed CLI ticket tracker for the home lab. See
`../docs/ticketing-workflow.md` for the full workflow.

```bash
python3 tickets.py new --title "CLIENT01 cannot log on" --reporter abel --priority P2
python3 tickets.py list
python3 tickets.py list --status open
python3 tickets.py show 1
python3 tickets.py close 1 --note "DNS pointed at router, not DC01; fixed"
```

Data lives in `tickets.db` in this folder (git-ignored). Tickets only exist
if someone creates them — nothing is seeded.
