import sqlite3

import pytest

from services.api import create_task, find_tasks


@pytest.fixture
def conn():
    c = sqlite3.connect(":memory:")
    c.execute("CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, severity TEXT)")
    return c


def test_create_and_find(conn):
    create_task(conn, "Fix login", "high")
    create_task(conn, "Update docs", "low")
    assert find_tasks(conn, "high") == ["Fix login"]


def test_find_none(conn):
    assert find_tasks(conn, "urgent") == []
