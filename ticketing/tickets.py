"""Small SQLite ticket tracker for the IT home lab.

Usage (from this folder):
    python3 tickets.py new --title "CLIENT01 cannot log on" --reporter abel --priority P2
    python3 tickets.py list
    python3 tickets.py list --status open
    python3 tickets.py show 1
    python3 tickets.py close 1 --note "DNS pointed at router, not DC01; fixed"

Data lives in tickets.db next to this script. No server, no fake data:
tickets only exist if someone creates them.
"""

import argparse
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

DB_PATH = Path(__file__).with_name("tickets.db")
PRIORITIES = ("P1", "P2", "P3", "P4")
OPEN_STATUSES = ("new", "in_progress", "on_hold")
ALL_STATUSES = OPEN_STATUSES + ("resolved", "closed")


def connect(db_path=DB_PATH):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute(
        """CREATE TABLE IF NOT EXISTS tickets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            reporter TEXT NOT NULL,
            priority TEXT NOT NULL DEFAULT 'P3',
            status TEXT NOT NULL DEFAULT 'new',
            description TEXT DEFAULT '',
            resolution TEXT DEFAULT '',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )"""
    )
    conn.commit()
    return conn


def _now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def create_ticket(conn, title, reporter, priority="P3", description=""):
    if priority not in PRIORITIES:
        raise ValueError(f"priority must be one of {PRIORITIES}")
    if not title.strip():
        raise ValueError("title must not be empty")
    now = _now()
    cur = conn.execute(
        "INSERT INTO tickets (title, reporter, priority, status, description, created_at, updated_at)"
        " VALUES (?, ?, ?, 'new', ?, ?, ?)",
        (title.strip(), reporter.strip(), priority, description, now, now),
    )
    conn.commit()
    return cur.lastrowid


def list_tickets(conn, status=None):
    if status is None:
        rows = conn.execute("SELECT * FROM tickets ORDER BY id").fetchall()
    elif status == "open":
        rows = conn.execute(
            "SELECT * FROM tickets WHERE status IN ('new','in_progress','on_hold') ORDER BY id"
        ).fetchall()
    elif status in ALL_STATUSES:
        rows = conn.execute(
            "SELECT * FROM tickets WHERE status = ? ORDER BY id", (status,)
        ).fetchall()
    else:
        raise ValueError(f"unknown status filter: {status}")
    return rows


def get_ticket(conn, ticket_id):
    row = conn.execute("SELECT * FROM tickets WHERE id = ?", (ticket_id,)).fetchone()
    if row is None:
        raise LookupError(f"no ticket with id {ticket_id}")
    return row


def set_status(conn, ticket_id, status, note=""):
    if status not in ALL_STATUSES:
        raise ValueError(f"status must be one of {ALL_STATUSES}")
    get_ticket(conn, ticket_id)  # raises LookupError if missing
    conn.execute(
        "UPDATE tickets SET status = ?, resolution = ?, updated_at = ? WHERE id = ?",
        (status, note, _now(), ticket_id),
    )
    conn.commit()


def _print_row(row):
    print(f"#{row['id']} [{row['priority']}] {row['status']} — {row['title']} (by {row['reporter']}, {row['created_at']})")


def main(argv=None):
    parser = argparse.ArgumentParser(description="Lab ticket tracker")
    sub = parser.add_subparsers(dest="command", required=True)

    p_new = sub.add_parser("new", help="create a ticket")
    p_new.add_argument("--title", required=True)
    p_new.add_argument("--reporter", required=True)
    p_new.add_argument("--priority", default="P3", choices=PRIORITIES)
    p_new.add_argument("--description", default="")

    p_list = sub.add_parser("list", help="list tickets")
    p_list.add_argument("--status", default=None,
                        help="filter: open, or one of new/in_progress/on_hold/resolved/closed")

    p_show = sub.add_parser("show", help="show one ticket")
    p_show.add_argument("id", type=int)

    p_close = sub.add_parser("close", help="close a ticket")
    p_close.add_argument("id", type=int)
    p_close.add_argument("--note", default="", help="what fixed it")

    args = parser.parse_args(argv)
    conn = connect()

    if args.command == "new":
        tid = create_ticket(conn, args.title, args.reporter, args.priority, args.description)
        print(f"Created ticket #{tid}")
    elif args.command == "list":
        rows = list_tickets(conn, args.status)
        if not rows:
            print("No tickets.")
        for row in rows:
            _print_row(row)
    elif args.command == "show":
        row = get_ticket(conn, args.id)
        _print_row(row)
        if row["description"]:
            print(f"Description: {row['description']}")
        if row["resolution"]:
            print(f"Resolution: {row['resolution']}")
    elif args.command == "close":
        set_status(conn, args.id, "closed", args.note)
        print(f"Closed ticket #{args.id}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
