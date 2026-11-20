#!/usr/bin/env bash
# Goma Gateway vs Traefik benchmark runner.
#
# For each repetition, each gateway is started fresh (order alternates between
# repetitions to cancel out drift), its idle memory is recorded, then:
#   1. max-throughput tests (wrk, closed loop) for every endpoint x concurrency
#   2. fixed-rate latency tests (oha, open loop, coordinated-omission corrected)
# CPU time and memory of the gateway container are sampled from its cgroup
# during every test. Results land in results/<timestamp>/ as JSON lines.
set -euo pipefail
cd "$(dirname "$0")/.."

TARGETS=${TARGETS:-"goma traefik"}
REPS=${REPS:-3}
DURATION=${DURATION:-60}          # seconds per measured run
WARMUP=${WARMUP:-15}              # seconds of warm-up before each measured run
ENDPOINTS=${ENDPOINTS:-"/api/books/1 /api/books"}
CONNS=${CONNS:-"100 500"}
WRK_THREADS=${WRK_THREADS:-3}
RATES=${RATES:-"5000 15000"}      # fixed-rate test, requests/s
RATE_CONNS=${RATE_CONNS:-200}
RATE_ENDPOINT=${RATE_ENDPOINT:-/api/books/1}

OUT=${OUT:-results/$(date -u +%Y%m%dT%H%M%SZ)}
mkdir -p "$OUT"
DC="docker compose"
LG="docker exec bench-loadgen"
log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$OUT/run.log"; }

cg() { echo "/sys/fs/cgroup/system.slice/docker-$(docker inspect -f '{{.Id}}' "$1").scope"; }
cpu_usec() { awk '/^usage_usec/{print $2}' "$1/cpu.stat"; }
anon_bytes() { awk '/^anon /{print $2}' "$1/memory.stat"; }

# Sample gateway anon memory every 0.5s in the background; prints max MiB on stop.
start_sampler() {
  local cgp=$1 f=$2; : > "$f"
  ( while :; do anon_bytes "$cgp" >> "$f"; sleep 0.5; done ) & SAMPLER=$!
}
stop_sampler() { kill "$SAMPLER" 2>/dev/null; wait "$SAMPLER" 2>/dev/null || true; sort -n "$1" | tail -1; }

env_info() {
  {
    echo "date_utc=$(date -u +%FT%TZ)"
    echo "host=$(hostname) kernel=$(uname -r) cpus=$(nproc) mem=$(free -g | awk '/Mem/{print $2}')G"
    echo "cpu_model=$(awk -F: '/model name/{print $2; exit}' /proc/cpuinfo | xargs)"
    echo "docker=$(docker version --format '{{.Server.Version}}')"
    echo "proxy_cpus=${PROXY_CPUS:-0-1} backend_cpus=${BACKEND_CPUS:-2-4} loadgen_cpus=${LOADGEN_CPUS:-5-7}"
    for i in jkaninda/goma-gateway:1.2.1 traefik:v3.7.19 nginx:1.29-alpine; do
      echo "image $i $(docker image inspect -f '{{index .RepoDigests 0}}' $i)"; done
    echo "wrk=$($LG wrk --version 2>&1 | head -1) oha=$($LG oha --version)"
    echo "REPS=$REPS DURATION=$DURATION WARMUP=$WARMUP ENDPOINTS=$ENDPOINTS CONNS=$CONNS RATES=$RATES RATE_CONNS=$RATE_CONNS"
  } > "$OUT/env.txt"
}

start_gateway() {
  local t=$1
  $DC --profile goma --profile traefik rm -sf goma traefik >/dev/null 2>&1 || true
  $DC --profile "$t" up -d "$t" >/dev/null 2>&1
  for _ in $(seq 60); do
    $LG curl -fs -o /dev/null "http://$t:80/api/books/1" && return 0; sleep 1
  done
  log "ERROR: $t did not become ready"; return 1
}

$DC up -d --build api-example loadgen >/dev/null 2>&1
sleep 2
env_info
log "results -> $OUT"

for rep in $(seq "$REPS"); do
  order=$TARGETS; (( rep % 2 == 0 )) && order=$(echo $TARGETS | tr ' ' '\n' | tac | xargs)
  for t in $order; do
    log "rep $rep: starting $t"
    start_gateway "$t"
    CG=$(cg "bench-$t")
    sleep 10
    idle=$(anon_bytes "$CG")
    hdrs=$($LG curl -s -D - -o /dev/null "http://$t:80/api/books/1" | tr -d '\r' | grep -v '^$' | paste -sd'|')
    echo "{\"target\":\"$t\",\"rep\":$rep,\"idle_anon_mib\":$(( idle / 1048576 )),\"headers\":$(jq -Rn --arg h "$hdrs" '$h')}" >> "$OUT/idle.jsonl"

    for ep in $ENDPOINTS; do
      for c in $CONNS; do
        url="http://$t:80$ep"
        $LG wrk -t"$WRK_THREADS" -c"$c" -d"${WARMUP}s" "$url" >/dev/null
        start_sampler "$CG" "$OUT/.mem"
        c0=$(cpu_usec "$CG")
        res=$($LG wrk -t"$WRK_THREADS" -c"$c" -d"${DURATION}s" --timeout 5s -s /bench/report.lua "$url" | tail -1)
        c1=$(cpu_usec "$CG")
        peak=$(stop_sampler "$OUT/.mem")
        cores=$(awk -v a="$c0" -v b="$c1" -v d="$DURATION" 'BEGIN{printf "%.2f", (b-a)/1e6/d}')
        echo "$res" | jq -c --arg t "$t" --arg ep "$ep" --argjson c "$c" --argjson rep "$rep" \
          --argjson cores "$cores" --argjson peak "$(( peak / 1048576 ))" \
          '{target:$t,endpoint:$ep,conns:$c,rep:$rep,cpu_cores:$cores,peak_anon_mib:$peak} + .' | tee -a "$OUT/throughput.jsonl"
      done
    done

    for q in $RATES; do
      url="http://$t:80$RATE_ENDPOINT"
      $LG oha --no-tui -z "${WARMUP}s" -c "$RATE_CONNS" -q "$q" "$url" >/dev/null
      start_sampler "$CG" "$OUT/.mem"
      c0=$(cpu_usec "$CG")
      $LG oha --no-tui --output-format json --latency-correction -z "${DURATION}s" -c "$RATE_CONNS" -q "$q" "$url" > "$OUT/.oha.json"
      c1=$(cpu_usec "$CG")
      peak=$(stop_sampler "$OUT/.mem")
      cores=$(awk -v a="$c0" -v b="$c1" -v d="$DURATION" 'BEGIN{printf "%.2f", (b-a)/1e6/d}')
      jq -c --arg t "$t" --argjson q "$q" --argjson rep "$rep" --argjson cores "$cores" --argjson peak "$(( peak / 1048576 ))" \
        '{target:$t,rate:$q,rep:$rep,cpu_cores:$cores,peak_anon_mib:$peak,
          rps:.summary.requestsPerSec,success:.summary.successRate,
          p50_ms:(.latencyPercentiles.p50*1000),p90_ms:(.latencyPercentiles.p90*1000),
          p99_ms:(.latencyPercentiles.p99*1000),p999_ms:(.latencyPercentiles["p99.9"]*1000),
          max_ms:(.summary.slowest*1000),status:.statusCodeDistribution,errors:.errorDistribution}' \
        "$OUT/.oha.json" | tee -a "$OUT/latency.jsonl"
    done
    $DC --profile "$t" rm -sf "$t" >/dev/null 2>&1
  done
done
rm -f "$OUT/.mem" "$OUT/.oha.json"
log "done"
