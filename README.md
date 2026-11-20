# Performance Benchmark: Goma Gateway vs Traefik

A reproducible HTTP reverse-proxy benchmark comparing **Goma Gateway 1.2.1** and **Traefik v3.7.19**. Both run on the same hardware with the same CPU budget, in front of the same backend, under the same load.

> **Run date:** 2026-11-20 · **Raw data:** [`results/full/`](results/full/) · **Generated tables:** [`results/full/summary.md`](results/full/summary.md)

---

## TL;DR

| | Goma Gateway 1.2.1 | Traefik v3.7.19 |
|---|---|---|
| **Max throughput, 100 conns** (small / large body) | 20.6k / 15.6k req/s | 🟢 **22.3k / 18.1k req/s** (+8% / +14%) |
| **Max throughput, 500 conns** (small / large body) | 🟢 **23.3k / 16.9k req/s** (+20% / +9%) | 19.5k / 15.6k req/s |
| **p99 latency at a fixed 15k req/s** | 🟢 **6.9 ms** | 10.2 ms |
| **p99 latency at a fixed 5k req/s** | 1.24 ms | 1.18 ms (≈ tie) |
| **Memory, idle** | 🟢 **6 MiB** | 17 MiB |
| **Memory, peak under load** | 🟢 **20–58 MiB** | 77–184 MiB |
| **Errors** (≈ 17M requests per gateway) | 0 | 0 |

**What this means**

- **Neither gateway wins across the board.** The winner depends on how many connections the gateway has to handle.
- **At moderate concurrency (100 connections), Traefik is faster.** It handles 8–14% more requests per second and has slightly lower latency.
- **At high concurrency (500 connections), Goma is faster.** It handles 9–20% more requests per second and has lower median latency. Traefik's throughput drops as connections grow from 100 to 500. Goma's goes up.
- **Goma uses 3–4× less memory** in every scenario, idle and under load.
- **At a fixed load well below saturation, latency is essentially the same.** At 75% load (15k req/s), Goma has a noticeably better p99 and Traefik a slightly better p90.
- **CPU efficiency follows the same split as throughput.** Both gateways were CPU-bound on their 2 cores, so requests per CPU core track the throughput results.

---

## What changed from the previous version of this benchmark

The previous version (Goma 0.3.3 vs Traefik v3.3.4, see [history](#history)) had several methodology problems, which this version fixes:

| Problem in the old test | Fix |
|---|---|
| **The backend was the bottleneck.** `okapi-example` writes 3 log lines per request and maxes out at about 8k req/s on its own, so the old test mostly measured the backend. | The backend is now nginx serving **byte-identical payloads** captured from `okapi-example:2.0.0`, with access logging off. It does about 274k req/s, more than 10× what either gateway reaches. |
| **The load generator shared CPUs with the gateway**, and the results were run against a public domain, not the documented `localhost`. | Each component is pinned to its own CPUs: gateway on 0–1, backend on 2–4, load generator on 5–7. All traffic stays on a private Docker bridge network, so no NAT or `docker-proxy` is in the path. |
| **Single 60 s run, no warm-up.** | 3 repetitions, 15 s warm-up before each measured 60 s run. Gateway order alternates between repetitions and each gateway starts fresh every time. Tables report the median with the [min–max] range. |
| **Memory was eyeballed and CPU was not measured.** | Anonymous memory and CPU time are read from each gateway's cgroup during every test. |
| **Latency was measured only under closed-loop `wrk`**, which hides queueing delays (*coordinated omission*). | An added fixed-rate test uses `oha` with `--latency-correction`. |
| **"Higher transfer efficiency" was misleading.** Goma's responses were simply larger (it adds headers), not more efficient. | Removed. Transfer/sec is a function of body size and req/s, so it is not reported as a separate metric. |
| **Unfair Traefik config.** The Docker provider polled `docker.sock` and the dashboard and API were enabled. | Traefik uses the file provider with the dashboard and API off, matching Goma's static config. Neither gateway has metrics, access logs or middlewares enabled. |
| **One endpoint only.** | Small (375 B) and large (36 KB) responses, each tested at 100 and 500 connections. |

---

## Test setup

**Host:** 8 vCPU AMD EPYC VM, 15 GiB RAM, AlmaLinux 10.3 (kernel 6.12), Docker 29.10.0.

| Component | Image | CPUs | Notes |
|---|---|---|---|
| Gateway under test | `jkaninda/goma-gateway:1.2.1` / `traefik:v3.7.19` | 0–1 (2 cores) | Only one runs at a time. Memory limit 1 GiB. |
| Backend | `nginx:1.29-alpine` | 2–4 | Serves `okapi-example` payloads (see [`backend/`](backend/)). |
| Load generator | `wrk 4.1.0` + `oha 1.17.0` ([`loadgen/`](loadgen/)) | 5–7 | Same Docker network as the gateway. |

Image digests and all run parameters are recorded in [`results/full/env.txt`](results/full/env.txt).

**Configuration:** both gateways run with their **out-of-the-box** defaults, plus the single route needed to reach the backend.

- [`config/goma.yml`](config/goma.yml)
- [`config/traefik.yml`](config/traefik.yml) + [`config/traefik-dynamic.yml`](config/traefik-dynamic.yml)

**Tests run per repetition, per gateway:**

1. **Idle memory**, measured 10 s after the gateway is ready.
2. **Max throughput** (`wrk -t3 -c{100,500} -d60s --timeout 5s`) on:
   - `GET /api/books/1`: 375 B JSON
   - `GET /api/books`: 36 KB JSON (the endpoint used by the old test)
3. **Fixed-rate latency** (`oha -c200 -q {5000,15000} -z60s --latency-correction`) on `GET /api/books/1`. This is about 25% and 75% of the gateways' saturation point.

---

## Results

Each cell shows the **median of 3 runs**, followed by the [min–max] range across those runs.

### Maximum throughput: `GET /api/books/1` (375 B)

| Metric | Goma 1.2.1 | Traefik v3.7.19 | Difference |
|---|---|---|---|
| **100 connections**: req/s | 20,638 [20,551–20,688] | 22,315 [22,304–22,453] | Traefik by 8% |
| p50 / p99 (ms) | 4.59 / 12.29 | 4.21 / 11.89 | Traefik by 9% / 3% |
| p99.9 / max (ms) | 15.95 / 27.4 | 16.07 / 26.6 | ≈ tie |
| Peak memory (MiB) | **20** | 77 | Goma by 74% |
| **500 connections**: req/s | **23,262** [23,241–23,339] | 19,451 [19,345–19,653] | Goma by 20% |
| p50 / p99 (ms) | **20.23 / 42.36** | 24.58 / 46.33 | Goma by 18% / 9% |
| p99.9 / max (ms) | **53.99 / 75.0** | 58.58 / 83.6 | Goma by 8% / 10% |
| Peak memory (MiB) | **52** | 180 | Goma by 71% |

### Maximum throughput: `GET /api/books` (36 KB)

| Metric | Goma 1.2.1 | Traefik v3.7.19 | Difference |
|---|---|---|---|
| **100 connections**: req/s | 15,578 [15,533–15,673] | **18,132** [17,922–18,146] | Traefik by 14% |
| p50 / p99 (ms) | 6.04 / 17.43 | **5.19 / 15.33** | Traefik by 16% / 14% |
| p99.9 / max (ms) | 22.62 / 33.6 | 20.80 / 33.2 | Traefik by 9% / ≈ tie |
| Peak memory (MiB) | **27** | 87 | Goma by 69% |
| **500 connections**: req/s | **16,890** [16,838–16,948] | 15,566 [15,558–15,624] | Goma by 9% |
| p50 / p99 (ms) | **27.63** / 60.60 | 30.82 / 59.26 | Goma by 10% / ≈ tie |
| p99.9 / max (ms) | 75.76 / **98.2** | 77.01 / 112.3 | ≈ tie / Goma by 13% |
| Peak memory (MiB) | **58** | 184 | Goma by 68% |

Both gateways used the same CPU in every throughput test: 1.50–1.65 of their 2 cores. That makes req/s per CPU core track the req/s results directly (see [`summary.md`](results/full/summary.md)).

### Latency at a fixed request rate (open loop, coordinated-omission corrected)

| Metric | Goma 1.2.1 | Traefik v3.7.19 |
|---|---|---|
| **5,000 req/s**: p50 / p90 (ms) | 0.37 / 0.63 | 0.37 / 0.64 |
| p99 / p99.9 (ms) | 1.24 / 2.42 | **1.18 / 2.27** |
| CPU (cores) / peak memory (MiB) | 0.51 / **27** | 0.51 / 52 |
| **15,000 req/s**: p50 / p90 (ms) | 0.84 / 2.49 | **0.81 / 2.29** |
| p99 / p99.9 (ms) | **6.85 / 16.62** | 10.21 / 18.13 |
| CPU (cores) / peak memory (MiB) | 1.12 / **27** | 1.10 / 83 |

Both gateways sustained the target rate with a **100% success rate**.

### Idle memory

| | Goma 1.2.1 | Traefik v3.7.19 |
|---|---|---|
| Anonymous memory, 10 s after start | **6 MiB** | 17 MiB |

---

## Caveats

- **Default settings, not tuned ones.** Goma 1.2.1 limits each backend to 256 connections (`maxConnsPerHost: 256`) and keeps up to 256 of them idle. Traefik has no connection limit and keeps up to 200 idle connections per host. Results with tuned connection pools could differ.
- **The gateways modify headers differently.** Goma removes the backend's `Server` header and adds `Proxied-By` and `X-Goma-Request-Id`. Traefik passes headers through unchanged. Generating a request ID per request is a small amount of extra work that Goma does and Traefik does not.
- **Results come from one machine.** Absolute numbers depend on the hardware and on the 2-core limit. The relative results are what matter.
- **Plain HTTP/1.1 only.** TLS, HTTP/2, middlewares (auth, rate limiting) and config reloads were not tested.
- **Other services shared the host.** It also ran a small, mostly idle stack (Postgres, Redis, a web app). Those services ran on unpinned CPUs. The run-to-run spread stayed under about 2%, so their effect was negligible.

---

## Reproducing

Requirements: Docker with Compose v2, `jq` (used on the host), and a Linux host with cgroup v2 and at least 8 vCPUs. To use a different CPU layout, set `PROXY_CPUS`, `BACKEND_CPUS` and `LOADGEN_CPUS`.

```sh
git clone https://github.com/jkaninda/goma-gateway-vs-traefik && cd goma-gateway-vs-traefik

# Full run: 3 reps × 2 gateways, about 46 minutes
bench/run.sh                       # writes results/<timestamp>/

# Quick smoke test
REPS=1 DURATION=10 WARMUP=3 bench/run.sh

# Summary tables
python3 bench/summarize.py results/<timestamp>
```

Every setting is an environment variable: `TARGETS`, `REPS`, `DURATION`, `WARMUP`, `ENDPOINTS`, `CONNS`, `RATES`, `RATE_CONNS`, `RATE_ENDPOINT`, `OUT`. See [`bench/run.sh`](bench/run.sh).

To try a single gateway by hand:

```sh
docker compose --profile goma up -d          # or: --profile traefik
docker exec bench-loadgen wrk -t3 -c500 -d60s http://goma:80/api/books/1
```

---

## History

The original benchmark (Goma 0.3.3 vs Traefik v3.3.4, a single `wrk -t8 -c500 -d60s` run against `okapi-example`) reported these results:

- **Traefik:** 29.3k req/s, 81.6 ms average latency
- **Goma:** 23.1k req/s, 71.9 ms average latency

Those results are kept only for reference ([screenshot](screenshot.png)). They are not comparable to the current results, for the reasons listed under [What changed](#what-changed-from-the-previous-version-of-this-benchmark).
