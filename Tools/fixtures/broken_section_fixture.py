"""Deliberately broken section module for the lint self-test.

Registered ONLY when GEN_INCLUDE_BROKEN_FIXTURE=1: a marker with no citations,
no tier, an empty chips list, and a LOC placeholder gene. The generator MUST
exit nonzero when this is included — run_checks.sh verifies that the lint
actually has teeth.
"""


def register(add):
    add(
        "rs99999901", "LOC999", "Broken Fixture Marker", "1", 1000,
        ["traits"], "preliminary", "A", "G",
        "Broken on purpose: missing citations/tier and placeholder gene.",
        {"label": "x", "impact": "typical", "summary": "x", "detail": "x", "actions": {}},
        {"label": "x", "impact": "typical", "summary": "x", "detail": "x", "actions": {}},
        {"label": "x", "impact": "typical", "summary": "x", "detail": "x", "actions": {}},
        citations=[], tier=None, chips=[], transferability="euro-biased",
    )
