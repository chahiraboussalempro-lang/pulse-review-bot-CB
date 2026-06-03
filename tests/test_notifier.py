from services.notifier import format_notification


def test_high_priority_flag():
    msg = format_notification("amir", "Fix login", 10)
    assert msg.startswith("[!]")
    assert "Fix login" in msg


def test_low_priority_flag():
    assert format_notification("lea", "Tidy", 1).startswith("[ ]")
