from services.scorer import priority_score


def test_age_increases_score():
    assert priority_score("low", 3, blocking=False) == 4


def test_unknown_severity_defaults_low():
    assert priority_score("???", 0, blocking=False) == 1
