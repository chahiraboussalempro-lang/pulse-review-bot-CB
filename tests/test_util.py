from services.util import clamp_score


def test_clamp_caps_high():
    assert clamp_score(42) == 10


def test_clamp_floors_negative():
    assert clamp_score(-5) == 0
