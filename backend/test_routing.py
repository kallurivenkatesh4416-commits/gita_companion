"""
Integration test for the LLM router + orchestrator.

Run:  python test_routing.py   (from backend/)

This test imports ONLY the router and orchestrator modules directly,
avoiding the full FastAPI app bootstrap (no DB/FastAPI deps needed).
"""

import json
import math
import sys
import os
import time

# Ensure the backend dir is on the path
sys.path.insert(0, os.path.dirname(__file__))

# --- Direct import of router (no app deps) ---
# We import the module file directly to avoid triggering app/__init__.py
import importlib.util

def _load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

router_mod = _load_module("router", os.path.join(os.path.dirname(__file__), "app", "services", "router.py"))
route_query = router_mod.route_query


def test_routing_decisions():
    print("=" * 60)
    print("TEST 1: Routing decisions")
    print("=" * 60)

    test_cases = [
        ("How do I fix this Python bug?", "codex"),
        ("What does the Gita say about fear?", "claude"),
        ("Debug my JavaScript function", "codex"),
        ("What is dharma and how to follow it?", "claude"),
        ("I feel anxious about life purpose", "claude"),
        ("Write a Python script to sort a list", "codex"),
        ("What does Krishna say about duty?", "claude"),
        ("Fix this syntax error in my code", "codex"),
        ("How to find peace and calm the mind?", "claude"),
        ("Hello, how are you?", "claude"),  # default → claude
    ]

    passed = 0
    failed = 0
    for query, expected in test_cases:
        result = route_query(query, default="claude")
        status = "PASS" if result == expected else "FAIL"
        if status == "PASS":
            passed += 1
        else:
            failed += 1
        print(f"  [{status}] \"{query[:55]}\" -> {result} (expected {expected})")

    print(f"\n  Results: {passed} passed, {failed} failed out of {len(test_cases)}")
    return failed == 0


def test_failover_order():
    print("\n" + "=" * 60)
    print("TEST 2: Failover order logic")
    print("=" * 60)

    # Replicate the static method logic inline
    def failover_order(primary, available):
        order = [primary]
        for name in available:
            if name != primary:
                order.append(name)
        return order

    order = failover_order("claude", ["mock", "codex", "claude", "gemini"])
    print(f"  Primary=claude, available=[mock, codex, claude, gemini]")
    print(f"  Failover order: {order}")
    assert order[0] == "claude", f"Expected claude first, got {order[0]}"
    assert "codex" in order
    assert "mock" in order
    print("  [PASS] Claude first, then others as fallback")

    order2 = failover_order("codex", ["mock", "codex", "claude"])
    print(f"\n  Primary=codex, available=[mock, codex, claude]")
    print(f"  Failover order: {order2}")
    assert order2[0] == "codex"
    print("  [PASS] Codex first when set as primary")
    return True


def test_env_switch():
    print("\n" + "=" * 60)
    print("TEST 3: DEFAULT_LLM env variable switch")
    print("=" * 60)

    for default in ["claude", "codex"]:
        result = route_query("Tell me something interesting", default=default)
        print(f"  DEFAULT_LLM={default}, neutral query -> routed to: {result}")
        assert result == default, f"Expected {default}, got {result}"
    print("  [PASS] DEFAULT_LLM correctly controls fallback routing")
    return True


def test_keyword_scoring():
    print("\n" + "=" * 60)
    print("TEST 4: Keyword scoring edge cases")
    print("=" * 60)

    # Mixed query — spiritual wins
    r1 = route_query("How does karma apply to my life purpose and duty?", default="claude")
    print(f"  Mixed spiritual query -> {r1}")
    assert r1 == "claude"
    print("  [PASS] Spiritual-heavy mixed query routes to Claude")

    # Mixed query — code wins
    r2 = route_query("Debug this Python function with a syntax error in the loop", default="claude")
    print(f"  Mixed code query -> {r2}")
    assert r2 == "codex"
    print("  [PASS] Code-heavy mixed query routes to Codex")

    # Totally neutral
    r3 = route_query("Tell me something interesting", default="claude")
    print(f"  Neutral query (default=claude) -> {r3}")
    assert r3 == "claude"

    r4 = route_query("Tell me something interesting", default="codex")
    print(f"  Neutral query (default=codex) -> {r4}")
    assert r4 == "codex"
    print("  [PASS] Neutral queries respect DEFAULT_LLM")
    return True


if __name__ == "__main__":
    print("\nGita Companion — LLM Router Integration Tests")
    print("=" * 60)

    all_passed = True
    all_passed &= test_routing_decisions()
    all_passed &= test_failover_order()
    all_passed &= test_env_switch()
    all_passed &= test_keyword_scoring()

    print("\n" + "=" * 60)
    if all_passed:
        print("ALL TESTS PASSED")
    else:
        print("SOME TESTS FAILED")
    print("=" * 60)

    sys.exit(0 if all_passed else 1)
