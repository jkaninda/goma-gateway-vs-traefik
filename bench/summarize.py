#!/usr/bin/env python3
"""Summarize a results/<run>/ directory into Markdown tables (median of reps, [min-max])."""
import json, statistics, sys
from collections import defaultdict
from pathlib import Path

d = Path(sys.argv[1] if len(sys.argv) > 1 else "results/full")
load = lambda f: [json.loads(l) for l in open(d / f) if l.strip()]
T = ["goma", "traefik"]
NAME = {"goma": "Goma Gateway 1.2.1", "traefik": "Traefik v3.7.19"}

def agg(rows, key, fmt="{:,.0f}"):
    v = [r[key] for r in rows]
    m = statistics.median(v)
    return fmt.format(m) + (f" [{fmt.format(min(v))}–{fmt.format(max(v))}]" if len(v) > 1 else "")

def med(rows, key): return statistics.median(r[key] for r in rows)

def diff(g, t, higher_better):
    if t == 0: return "–"
    pct = (g - t) / t * 100
    win = "Goma" if (pct > 0) == higher_better else "Traefik"
    return "≈ tie" if abs(pct) < 3 else f"{win} by {abs(pct):.0f}%"

out = []
tp = defaultdict(list)
for r in load("throughput.jsonl"):
    tp[(r["endpoint"], r["conns"], r["target"])].append(r)
for ep, label in [("/api/books/1", "small response, 375 B"), ("/api/books", "large response, 36 KB")]:
    for c in sorted({k[1] for k in tp if k[0] == ep}):
        g, t = tp[(ep, c, "goma")], tp[(ep, c, "traefik")]
        if not g or not t: continue
        out.append(f"\n#### `GET {ep}` ({label}) — {c} connections\n")
        out.append(f"| Metric | {NAME['goma']} | {NAME['traefik']} | Difference |")
        out.append("|---|---|---|---|")
        rows = [("Requests/sec", "rps", "{:,.0f}", True),
                ("Latency avg (ms)", "lat_avg_ms", "{:.2f}", False),
                ("Latency p50 (ms)", "p50_ms", "{:.2f}", False),
                ("Latency p99 (ms)", "p99_ms", "{:.2f}", False),
                ("Latency p99.9 (ms)", "p999_ms", "{:.2f}", False),
                ("Latency max (ms)", "lat_max_ms", "{:.1f}", False),
                ("Gateway CPU (cores, of 2)", "cpu_cores", "{:.2f}", False),
                ("Gateway peak memory (MiB)", "peak_anon_mib", "{:.0f}", False)]
        for name, k, f, hb in rows:
            out.append(f"| {name} | {agg(g, k, f)} | {agg(t, k, f)} | {diff(med(g, k), med(t, k), hb)} |")
        for x in (g, t):
            for r in x: r["eff"] = r["rps"] / r["cpu_cores"] if r["cpu_cores"] else 0
        out.append(f"| Requests/sec per CPU core | {agg(g, 'eff')} | {agg(t, 'eff')} | {diff(med(g,'eff'), med(t,'eff'), True)} |")
        errs = lambda x: sum(r["err_connect"] + r["err_read"] + r["err_write"] + r["err_status"] + r["err_timeout"] for r in x)
        out.append(f"| Errors (all reps) | {errs(g)} | {errs(t)} | |")

lat = defaultdict(list)
for r in load("latency.jsonl"):
    lat[(r["rate"], r["target"])].append(r)
for q in sorted({k[0] for k in lat}):
    g, t = lat[(q, "goma")], lat[(q, "traefik")]
    out.append(f"\n#### Fixed rate {q:,} req/s — `GET /api/books/1`\n")
    out.append(f"| Metric | {NAME['goma']} | {NAME['traefik']} | Difference |")
    out.append("|---|---|---|---|")
    for name, k, f, hb in [("Achieved req/s", "rps", "{:,.0f}", True), ("p50 (ms)", "p50_ms", "{:.2f}", False),
                           ("p90 (ms)", "p90_ms", "{:.2f}", False), ("p99 (ms)", "p99_ms", "{:.2f}", False),
                           ("p99.9 (ms)", "p999_ms", "{:.2f}", False), ("max (ms)", "max_ms", "{:.1f}", False),
                           ("Gateway CPU (cores)", "cpu_cores", "{:.2f}", False),
                           ("Gateway peak memory (MiB)", "peak_anon_mib", "{:.0f}", False)]:
        out.append(f"| {name} | {agg(g, k, f)} | {agg(t, k, f)} | {diff(med(g, k), med(t, k), hb)} |")
    out.append(f"| Success rate | {min(r['success'] for r in g):.4%} | {min(r['success'] for r in t):.4%} | |")

idle = defaultdict(list)
for r in load("idle.jsonl"): idle[r["target"]].append(r)
out.append("\n#### Idle memory (anonymous memory, 10 s after start)\n")
out.append(f"| | {NAME['goma']} | {NAME['traefik']} |\n|---|---|---|")
out.append(f"| Idle memory (MiB) | {agg(idle['goma'], 'idle_anon_mib')} | {agg(idle['traefik'], 'idle_anon_mib')} |")
print("\n".join(out))
