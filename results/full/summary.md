
#### `GET /api/books/1` (small response, 375 B) — 100 connections

| Metric | Goma Gateway 1.2.1 | Traefik v3.7.19 | Difference |
|---|---|---|---|
| Requests/sec | 20,638 [20,551–20,688] | 22,315 [22,304–22,453] | Traefik by 8% |
| Latency avg (ms) | 4.87 [4.87–4.90] | 4.53 [4.50–4.53] | Traefik by 8% |
| Latency p50 (ms) | 4.59 [4.59–4.61] | 4.21 [4.19–4.21] | Traefik by 9% |
| Latency p99 (ms) | 12.29 [12.27–12.36] | 11.89 [11.76–11.90] | Traefik by 3% |
| Latency p99.9 (ms) | 15.95 [15.68–15.99] | 16.07 [15.98–16.20] | ≈ tie |
| Latency max (ms) | 27.4 [24.6–28.4] | 26.6 [26.4–27.4] | Traefik by 3% |
| Gateway CPU (cores, of 2) | 1.64 [1.64–1.64] | 1.64 [1.64–1.64] | ≈ tie |
| Gateway peak memory (MiB) | 20 [19–21] | 77 [73–89] | Goma by 74% |
| Requests/sec per CPU core | 12,584 [12,531–12,615] | 13,607 [13,600–13,691] | Traefik by 8% |
| Errors (all reps) | 0 | 0 | |

#### `GET /api/books/1` (small response, 375 B) — 500 connections

| Metric | Goma Gateway 1.2.1 | Traefik v3.7.19 | Difference |
|---|---|---|---|
| Requests/sec | 23,262 [23,241–23,339] | 19,451 [19,345–19,653] | Goma by 20% |
| Latency avg (ms) | 21.43 [21.37–21.45] | 25.60 [25.33–25.75] | Goma by 16% |
| Latency p50 (ms) | 20.23 [20.09–20.25] | 24.58 [24.33–24.60] | Goma by 18% |
| Latency p99 (ms) | 42.36 [42.08–43.25] | 46.33 [44.98–47.28] | Goma by 9% |
| Latency p99.9 (ms) | 53.99 [52.72–54.74] | 58.58 [56.34–60.99] | Goma by 8% |
| Latency max (ms) | 75.0 [73.6–75.2] | 83.6 [81.2–92.2] | Goma by 10% |
| Gateway CPU (cores, of 2) | 1.65 [1.64–1.65] | 1.61 [1.61–1.61] | ≈ tie |
| Gateway peak memory (MiB) | 52 [49–52] | 180 [180–182] | Goma by 71% |
| Requests/sec per CPU core | 14,098 [14,085–14,231] | 12,081 [12,015–12,207] | Goma by 17% |
| Errors (all reps) | 0 | 0 | |

#### `GET /api/books` (large response, 36 KB) — 100 connections

| Metric | Goma Gateway 1.2.1 | Traefik v3.7.19 | Difference |
|---|---|---|---|
| Requests/sec | 15,578 [15,533–15,673] | 18,132 [17,922–18,146] | Traefik by 14% |
| Latency avg (ms) | 6.50 [6.46–6.53] | 5.60 [5.59–5.67] | Traefik by 16% |
| Latency p50 (ms) | 6.04 [6.01–6.04] | 5.19 [5.19–5.25] | Traefik by 16% |
| Latency p99 (ms) | 17.43 [17.20–17.76] | 15.33 [15.14–15.48] | Traefik by 14% |
| Latency p99.9 (ms) | 22.62 [22.35–23.16] | 20.80 [20.68–21.09] | Traefik by 9% |
| Latency max (ms) | 33.6 [31.8–41.0] | 33.2 [31.8–36.0] | ≈ tie |
| Gateway CPU (cores, of 2) | 1.50 [1.50–1.50] | 1.59 [1.58–1.59] | Goma by 6% |
| Gateway peak memory (MiB) | 27 [26–27] | 87 [82–107] | Goma by 69% |
| Requests/sec per CPU core | 10,386 [10,355–10,449] | 11,404 [11,343–11,413] | Traefik by 9% |
| Errors (all reps) | 0 | 0 | |

#### `GET /api/books` (large response, 36 KB) — 500 connections

| Metric | Goma Gateway 1.2.1 | Traefik v3.7.19 | Difference |
|---|---|---|---|
| Requests/sec | 16,890 [16,838–16,948] | 15,566 [15,558–15,624] | Goma by 9% |
| Latency avg (ms) | 29.53 [29.44–29.63] | 32.00 [31.88–32.01] | Goma by 8% |
| Latency p50 (ms) | 27.63 [27.47–27.81] | 30.82 [30.58–30.86] | Goma by 10% |
| Latency p99 (ms) | 60.60 [59.77–60.61] | 59.26 [59.18–60.17] | ≈ tie |
| Latency p99.9 (ms) | 75.76 [75.55–76.25] | 77.01 [75.66–77.87] | ≈ tie |
| Latency max (ms) | 98.2 [97.4–101.4] | 112.3 [110.5–113.9] | Goma by 13% |
| Gateway CPU (cores, of 2) | 1.51 [1.50–1.51] | 1.56 [1.56–1.57] | Goma by 3% |
| Gateway peak memory (MiB) | 58 [57–60] | 184 [181–189] | Goma by 68% |
| Requests/sec per CPU core | 11,224 [11,151–11,260] | 9,978 [9,910–10,016] | Goma by 12% |
| Errors (all reps) | 0 | 0 | |

#### Fixed rate 5,000 req/s — `GET /api/books/1`

| Metric | Goma Gateway 1.2.1 | Traefik v3.7.19 | Difference |
|---|---|---|---|
| Achieved req/s | 5,000 [5,000–5,000] | 5,000 [5,000–5,000] | ≈ tie |
| p50 (ms) | 0.37 [0.37–0.37] | 0.37 [0.37–0.37] | ≈ tie |
| p90 (ms) | 0.63 [0.62–0.63] | 0.64 [0.62–0.64] | ≈ tie |
| p99 (ms) | 1.24 [1.23–1.24] | 1.18 [1.15–1.19] | Traefik by 5% |
| p99.9 (ms) | 2.42 [2.37–2.62] | 2.27 [2.18–2.28] | Traefik by 7% |
| max (ms) | 7.7 [5.5–8.3] | 9.1 [8.6–12.0] | Goma by 15% |
| Gateway CPU (cores) | 0.51 [0.50–0.51] | 0.51 [0.51–0.51] | ≈ tie |
| Gateway peak memory (MiB) | 27 [20–28] | 52 [50–57] | Goma by 48% |
| Success rate | 100.0000% | 100.0000% | |

#### Fixed rate 15,000 req/s — `GET /api/books/1`

| Metric | Goma Gateway 1.2.1 | Traefik v3.7.19 | Difference |
|---|---|---|---|
| Achieved req/s | 15,000 [14,999–15,000] | 14,999 [14,999–14,999] | ≈ tie |
| p50 (ms) | 0.84 [0.83–0.88] | 0.81 [0.81–0.82] | Traefik by 3% |
| p90 (ms) | 2.49 [2.48–2.96] | 2.29 [2.16–2.31] | Traefik by 8% |
| p99 (ms) | 6.85 [6.85–10.19] | 10.21 [9.56–11.43] | Goma by 33% |
| p99.9 (ms) | 16.62 [15.48–20.90] | 18.13 [17.97–20.77] | Goma by 8% |
| max (ms) | 33.0 [27.6–34.2] | 33.4 [31.0–38.1] | ≈ tie |
| Gateway CPU (cores) | 1.12 [1.12–1.13] | 1.10 [1.09–1.10] | ≈ tie |
| Gateway peak memory (MiB) | 27 [26–28] | 83 [80–98] | Goma by 67% |
| Success rate | 100.0000% | 100.0000% | |

#### Idle memory (anonymous memory, 10 s after start)

| | Goma Gateway 1.2.1 | Traefik v3.7.19 |
|---|---|---|
| Idle memory (MiB) | 6 [6–6] | 17 [17–19] |
