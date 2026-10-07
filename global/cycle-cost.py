#!/usr/bin/env python3
"""Report tokens and dollars spent by one implementation cycle in Claude Code.

A cycle starts at the user prompt that led to the first load of one of the
chain skills (chottomatte-archi, igiari-tdd, kanpeki-fp by default) and runs
to the end of the session. Everything is read after the fact from the
session transcript, so the skills themselves carry no measuring step.

Usage:
  cycle-cost.py                     latest session of the current project
  cycle-cost.py <session.jsonl|id>  a given session
  cycle-cost.py --all               the whole session, not just the cycle
  cycle-cost.py --skills a,b        other skills mark the cycle start
  cycle-cost.py --json              machine-readable output

Claude Code only: Gemini CLI does not write these transcripts.
"""

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"
CHAIN = ("chottomatte-archi", "igiari-tdd", "kanpeki-fp")

# USD per million tokens: (input, output, cache read). Cache writes are
# priced from input: 1.25x for the 5-minute TTL, 2x for the 1-hour one.
# Anthropic first-party rates as of 2026-09-25. Matched by prefix, most
# specific first, so a dated suffix (claude-haiku-4-5-20251001) still matches.
PRICES_AS_OF = "2026-09-25"
PRICES = [
    ("claude-fable-5-1", 10.0, 50.0, 0.25),
    ("claude-mythos-5-1", 10.0, 50.0, 0.25),
    ("claude-fable-5", 10.0, 50.0, 1.0),
    ("claude-mythos-5", 10.0, 50.0, 1.0),
    ("claude-opus-5-5", 4.0, 20.0, 0.20),
    ("claude-opus-5", 5.0, 25.0, 0.50),
    ("claude-opus-4", 5.0, 25.0, 0.50),
    ("claude-sonnet-5-5", 2.0, 10.0, 0.20),
    ("claude-sonnet-5", 2.0, 10.0, 0.20),
    ("claude-sonnet-4", 3.0, 15.0, 0.30),
    ("claude-haiku-4-5", 1.0, 5.0, 0.10),
]
FAST_MULTIPLIER = 2.0

COUNTERS = ("input", "write_5m", "write_1h", "read", "output")


def rate(model):
    for prefix, inp, out, read in PRICES:
        if model.startswith(prefix):
            return inp, out, read
    return None


def cost(model, tokens, speed):
    r = rate(model)
    if r is None:
        return None
    inp, out, read = r
    usd = (tokens["input"] * inp + tokens["write_5m"] * inp * 1.25
           + tokens["write_1h"] * inp * 2 + tokens["read"] * read
           + tokens["output"] * out) / 1e6
    return usd * (FAST_MULTIPLIER if speed == "fast" else 1)


def tokens_of(usage):
    created = usage.get("cache_creation_input_tokens", 0) or 0
    split = usage.get("cache_creation") or {}
    w1h = split.get("ephemeral_1h_input_tokens", 0) or 0
    w5m = split.get("ephemeral_5m_input_tokens", created - w1h) or 0
    return {"input": usage.get("input_tokens", 0) or 0, "write_5m": w5m,
            "write_1h": w1h, "read": usage.get("cache_read_input_tokens", 0) or 0,
            "output": usage.get("output_tokens", 0) or 0}


def records(path):
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            try:
                yield json.loads(line)
            except ValueError:
                continue


def ts(rec):
    t = rec.get("timestamp")
    return datetime.fromisoformat(t.replace("Z", "+00:00")) if t else None


def prompt_text(rec):
    """The text of a prompt the person typed, or None for tool results and meta."""
    if rec.get("type") != "user" or rec.get("isMeta") or rec.get("isSidechain"):
        return None
    content = (rec.get("message") or {}).get("content")
    if isinstance(content, str):
        return content
    texts = [c.get("text", "") for c in content or [] if c.get("type") == "text"]
    return " ".join(texts) if texts else None


def skill_loaded(rec, names):
    """Name of a chain skill this record loads, if any."""
    msg = rec.get("message") or {}
    blobs = []
    if rec.get("type") == "assistant":
        blobs = [json.dumps(c.get("input", {})) for c in msg.get("content", [])
                 if c.get("type") == "tool_use" and c.get("name") == "Skill"]
    elif rec.get("type") == "user":
        text = prompt_text(rec) or ""
        content = msg.get("content")
        if rec.get("isMeta") and isinstance(content, list):
            text = " ".join(c.get("text", "") for c in content if c.get("type") == "text")
        if "<command-name>" in text or text.startswith("Base directory for this skill:"):
            blobs = [text[:400]]
    for blob in blobs:
        for name in names:
            if re.search(rf"(?<![\w-]){re.escape(name)}(?![\w-])", blob):
                return name
    return None


def responses(path, sub_agent):
    """One entry per API response: a response split over several lines shares its id."""
    seen = set()
    for rec in records(path):
        msg = rec.get("message") or {}
        if rec.get("type") != "assistant" or "usage" not in msg:
            continue
        model = msg.get("model", "")
        if not model or model.startswith("<"):
            continue
        key = msg.get("id") or rec.get("requestId") or rec.get("uuid")
        if key in seen:
            continue
        seen.add(key)
        yield {"t": ts(rec), "model": model, "sub": sub_agent,
               "speed": msg["usage"].get("speed"), "tokens": tokens_of(msg["usage"])}


def find_session(arg):
    if arg:
        p = Path(arg)
        if p.is_file():
            return p
        hits = list(PROJECTS.glob(f"*/{arg}.jsonl"))
        if hits:
            return hits[0]
        sys.exit(f"no session found for {arg}")
    project = PROJECTS / re.sub(r"[^A-Za-z0-9]", "-", str(Path.cwd()))
    sessions = sorted(project.glob("*.jsonl"), key=lambda p: p.stat().st_mtime)
    if not sessions:
        sys.exit(f"no session transcript in {project}")
    return sessions[-1]


def analyse(path, names, whole):
    recs = list(records(path))
    prompts, loads = [], []
    for rec in recs:
        text = prompt_text(rec)
        if text is not None and ts(rec):
            prompts.append((ts(rec), text))
        name = skill_loaded(rec, names)
        if name and ts(rec) and name not in [n for _, n in loads]:
            loads.append((ts(rec), name))

    if whole:
        start = prompts[0][0] if prompts else None
    elif not loads:
        return {"session": str(path), "loads": [], "start": None}
    else:
        before = [t for t, _ in prompts if t <= loads[0][0]]
        start = before[-1] if before else loads[0][0]

    resp = list(responses(path, False))
    for sub in sorted((path.parent / path.stem / "subagents").glob("*.jsonl")):
        resp += list(responses(sub, True))
    resp = [r for r in resp if r["t"] and (start is None or r["t"] >= start)]

    in_cycle = [p for p in prompts if start is None or p[0] >= start]
    rows = []
    for i, (t, text) in enumerate(in_cycle):
        nxt = in_cycle[i + 1][0] if i + 1 < len(in_cycle) else None
        mine = [r for r in resp if r["t"] >= t and (nxt is None or r["t"] < nxt)]
        rows.append(summarise(mine, prompt=" ".join(text.split())[:60], t=t))

    by_model = {}
    for r in resp:
        by_model.setdefault((r["model"], r["sub"]), []).append(r)
    models = [summarise(rs, model=m, sub_agent=s) for (m, s), rs in sorted(by_model.items())]

    state = [r for r in recs if r.get("type") == "cost-state"]
    return {"session": str(path), "start": start, "loads": loads, "prompts": rows,
            "models": models, "total": summarise(resp),
            "claude_code_session_usd": state[-1].get("totalCostUSD") if state else None}


def summarise(resp, **extra):
    tokens = {k: sum(r["tokens"][k] for r in resp) for k in COUNTERS}
    costs = [cost(r["model"], r["tokens"], r["speed"]) for r in resp]
    priced = [c for c in costs if c is not None]
    return {**extra, "responses": len(resp), "tokens": tokens,
            "usd": sum(priced), "unpriced": len(costs) - len(priced)}


def k(n):
    return f"{n / 1e6:.2f}M" if n >= 1e6 else f"{n / 1e3:.1f}k" if n >= 1e3 else str(n)


def money(s):
    return f"${s['usd']:.2f}" + (" + ?" if s["unpriced"] else "")


def show(rep, names):
    print(f"session  {rep['session']}")
    if rep["start"] is None:
        print(f"no cycle: none of {', '.join(names)} was loaded (use --all for the whole session)")
        return
    for t, n in rep["loads"]:
        print(f"loaded   {t:%H:%M:%S}  {n}")
    print(f"cycle    from {rep['start']:%Y-%m-%d %H:%M:%S} UTC to end of session\n")

    print(f"{'time':8}  {'resp':>4}  {'output':>7}  {'cost':>8}  prompt")
    for p in rep["prompts"]:
        print(f"{p['t']:%H:%M:%S}  {p['responses']:>4}  {k(p['tokens']['output']):>7}  "
              f"{money(p):>8}  {p['prompt']}")

    print(f"\n{'model':38}  {'resp':>4}  {'input':>7}  {'write':>7}  {'read':>7}  {'output':>7}  {'cost':>8}")
    for m in rep["models"] + [dict(rep["total"], model="TOTAL", sub_agent=False)]:
        t = m["tokens"]
        label = m["model"] + (" (subagent)" if m["sub_agent"] else "")
        print(f"{label:38}  {m['responses']:>4}  {k(t['input']):>7}  "
              f"{k(t['write_5m'] + t['write_1h']):>7}  {k(t['read']):>7}  {k(t['output']):>7}  {money(m):>8}")

    print(f"\nprices: Anthropic list rates as of {PRICES_AS_OF}; a gateway may bill differently.")
    if rep["total"]["unpriced"]:
        print("'+ ?': some responses came from a model missing from the price table.")
    if rep["claude_code_session_usd"] is not None:
        print(f"Claude Code's own figure for the whole session so far: "
              f"${rep['claude_code_session_usd']:.2f}\n"
              "  (written at turn ends, so it may lag; it also counts background calls that"
              " never reach the transcript, so the figures above are a slight lower bound)")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("session", nargs="?", help="transcript path or session id")
    ap.add_argument("--skills", default=",".join(CHAIN), help="comma-separated skill names")
    ap.add_argument("--all", action="store_true", help="measure the whole session")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    names = [n.strip() for n in args.skills.split(",") if n.strip()]
    rep = analyse(find_session(args.session), names, args.all)
    if args.json:
        print(json.dumps(rep, default=str, indent=1))
    else:
        show(rep, names)


if __name__ == "__main__":
    main()
