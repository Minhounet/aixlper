#!/usr/bin/env python3
"""Report LiteLLM key budget for the Claude Code gateway.

Modes:
  --statusline  render one status-bar line (status-line JSON arrives on stdin)
  --hook        emit SessionStart hook JSON injecting the budget into Claude's context
  --show        human-readable one-off check
  --refresh     refresh the cache only (used for the status line's background refresh)
"""

import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

HOME = Path.home()
SETTINGS = Path(os.environ.get("CLAUDE_SETTINGS", HOME / ".claude" / "settings.json"))
CACHE = HOME / ".claude" / "cache" / "litellm-budget.json"
CACHE_TTL = 60

WARN_PCT = 60
CRIT_PCT = 85

RESET, DIM, GREEN, YELLOW, RED = "\033[0m", "\033[2m", "\033[32m", "\033[33m", "\033[31m"


def credentials():
    base = os.environ.get("ANTHROPIC_BASE_URL", "")
    key = os.environ.get("ANTHROPIC_AUTH_TOKEN", "")
    if not (base and key):
        try:
            env = json.loads(SETTINGS.read_text()).get("env", {})
        except (OSError, ValueError):
            env = {}
        base = base or env.get("ANTHROPIC_BASE_URL", "")
        key = key or env.get("ANTHROPIC_AUTH_TOKEN", "")
    return base.rstrip("/"), key


def fetch(timeout=6):
    base, key = credentials()
    if not (base and key):
        return None
    # --noproxy: the gateway is expected to be reachable without going through
    # a configured HTTP(S) proxy. NO_PROXY may already cover its host, but hooks
    # do not always inherit it, and routing this call through the proxy fails.
    try:
        out = subprocess.run(
            ["curl", "-s", "--noproxy", "*", "--max-time", str(timeout),
             f"{base}/key/info?key={key}", "-H", f"Authorization: Bearer {key}"],
            capture_output=True, timeout=timeout + 2,
        ).stdout
        data = json.loads(out)
    except (OSError, ValueError, subprocess.SubprocessError):
        return None
    info = data.get("info", data)
    if not isinstance(info, dict) or "spend" not in info:
        return None
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE.with_suffix(f".{os.getpid()}.tmp")
    tmp.write_text(json.dumps(info))
    tmp.replace(CACHE)  # atomic: a concurrent reader never sees a half-written cache
    return info


def cached():
    try:
        return json.loads(CACHE.read_text()), time.time() - CACHE.stat().st_mtime
    except (OSError, ValueError):
        return None, None


def load(blocking_timeout=6, background_refresh=False):
    info, age = cached()
    if info is not None and age < CACHE_TTL:
        return info
    if info is not None and background_refresh:
        subprocess.Popen(
            [sys.executable, os.path.abspath(__file__), "--refresh"],
            start_new_session=True,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        return info
    return fetch(blocking_timeout) or info


def summarize(info):
    spend = float(info.get("spend") or 0)
    cap = info.get("max_budget")
    cap = float(cap) if cap else None
    pct = int(round(spend / cap * 100)) if cap else None
    reset_local = None
    raw = info.get("budget_reset_at")
    if raw:
        try:
            reset_local = datetime.fromisoformat(raw.replace("Z", "+00:00")).astimezone()
        except ValueError:
            pass
    return spend, cap, pct, reset_local, (info.get("budget_duration") or "").strip()


def claude_models(info):
    return [m for m in info.get("models", []) if m.startswith("claude-")]


def mode_statusline():
    try:
        ctx = json.load(sys.stdin)
    except (ValueError, OSError):
        ctx = {}
    parts = []
    cwd = (ctx.get("workspace") or {}).get("current_dir") or ctx.get("cwd")
    if cwd:
        parts.append(f"{DIM}{Path(cwd).name}{RESET}")
    model = (ctx.get("model") or {}).get("display_name")
    if model:
        parts.append(f"{DIM}{model}{RESET}")

    info = load(blocking_timeout=4, background_refresh=True)
    if info is None:
        parts.append(f"{DIM}budget n/a{RESET}")
    else:
        spend, cap, pct, reset_local, duration = summarize(info)
        if cap is None:
            parts.append(f"{DIM}${spend:.2f} spent{RESET}")
        else:
            color = RED if pct >= CRIT_PCT else YELLOW if pct >= WARN_PCT else GREEN
            seg = f"{color}${spend:.2f}/${cap:.0f} ({pct}%){RESET}"
            if reset_local and duration == "1d":
                seg += f" {DIM}resets {reset_local:%H:%M}{RESET}"
            elif reset_local:
                seg += f" {DIM}resets {reset_local:%d %b %H:%M}{RESET}"
            parts.append(seg)
    print("  ".join(parts))


def mode_hook():
    info = load(blocking_timeout=6)
    if info is None:
        return  # never delay or pollute a session start because the gateway is unreachable
    spend, cap, pct, reset_local, duration = summarize(info)
    if cap is None:
        text = f"LiteLLM gateway key: ${spend:.2f} spent, no budget cap set."
    else:
        window = {"1d": "daily", "1mo": "monthly", "30d": "30-day"}.get(duration, duration or "")
        text = (f"LiteLLM gateway budget: ${spend:.2f} of ${cap:.2f} {window} used ({pct}%)"
                f"{f', resets {reset_local:%Y-%m-%d %H:%M} local' if reset_local else ''}.")
        models = claude_models(info)
        if models:
            text += " Models on this key: " + ", ".join(models) + "."
        if pct >= CRIT_PCT:
            text += (f" This is above {CRIT_PCT}% — before starting substantial work,"
                     " tell the user and recommend a cheaper model (Sonnet for implementation,"
                     " Haiku for mechanical edits) unless the task genuinely needs Opus.")
        elif pct >= WARN_PCT:
            text += (f" This is above {WARN_PCT}% — mention it if the user asks for a long or"
                     " token-heavy task, and suggest Sonnet where it would do.")
    json.dump({"hookSpecificOutput": {"hookEventName": "SessionStart",
                                      "additionalContext": text},
               "suppressOutput": True}, sys.stdout)
    print()


def mode_show():
    info = load(blocking_timeout=10)
    if info is None:
        print("Budget unavailable (gateway unreachable or credentials missing).")
        return 1
    spend, cap, pct, reset_local, duration = summarize(info)
    print(f"spend          {spend:.2f}")
    print(f"max_budget     {cap if cap is not None else '(none)'}")
    print(f"used           {f'{pct}%' if pct is not None else '(n/a)'}")
    print(f"window         {duration or '(none)'}")
    print(f"resets         {reset_local.strftime('%Y-%m-%d %H:%M %Z') if reset_local else '(n/a)'}")
    print(f"claude models  {', '.join(claude_models(info)) or '(none)'}")
    return 0


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "--show"
    if mode == "--statusline":
        mode_statusline()
    elif mode == "--hook":
        mode_hook()
    elif mode == "--refresh":
        fetch()
    else:
        sys.exit(mode_show())
