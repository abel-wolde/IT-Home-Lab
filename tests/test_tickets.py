import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "ticketing"))

import tickets


@pytest.fixture
def conn(tmp_path):
    c = tickets.connect(tmp_path / "test.db")
    yield c
    c.close()


def test_create_and_list(conn):
    tid = tickets.create_ticket(conn, "Wi-Fi drops", "abel", "P2")
    rows = tickets.list_tickets(conn)
    assert len(rows) == 1
    assert rows[0]["id"] == tid
    assert rows[0]["status"] == "new"
    assert rows[0]["priority"] == "P2"


def test_create_defaults_to_p3(conn):
    tid = tickets.create_ticket(conn, "Improve docs", "abel")
    assert tickets.get_ticket(conn, tid)["priority"] == "P3"


def test_create_rejects_bad_priority_and_empty_title(conn):
    with pytest.raises(ValueError):
        tickets.create_ticket(conn, "Bad", "abel", "P9")
    with pytest.raises(ValueError):
        tickets.create_ticket(conn, "   ", "abel")


def test_open_filter_excludes_closed(conn):
    a = tickets.create_ticket(conn, "One", "abel")
    tickets.create_ticket(conn, "Two", "abel")
    tickets.set_status(conn, a, "closed", "fixed it")
    open_rows = tickets.list_tickets(conn, "open")
    assert [r["id"] for r in open_rows] == [2]
    assert tickets.list_tickets(conn, "closed")[0]["id"] == a


def test_close_records_resolution(conn):
    tid = tickets.create_ticket(conn, "Broken", "abel")
    tickets.set_status(conn, tid, "closed", "replaced cable")
    row = tickets.get_ticket(conn, tid)
    assert row["status"] == "closed"
    assert row["resolution"] == "replaced cable"


def test_unknown_ticket_raises(conn):
    with pytest.raises(LookupError):
        tickets.get_ticket(conn, 99)
    with pytest.raises(LookupError):
        tickets.set_status(conn, 99, "closed")


def test_bad_status_raises(conn):
    tid = tickets.create_ticket(conn, "X", "abel")
    with pytest.raises(ValueError):
        tickets.set_status(conn, tid, "done")
