# 🚀 Performance Benchmark: Traefik vs Goma Gateway

This benchmark compares **Traefik** and **Goma Gateway** under identical load conditions using [`wrk`](https://github.com/wg/wrk), a modern HTTP benchmarking tool.

```bash
wrk -t8 -c500 -d60s http://localhost/api/books
```

> **Test environment:** 8 threads, 500 concurrent connections, 60 seconds duration

---

## 📊 Summary

| **Metric**              | **Traefik**  | **Goma Gateway** |
| ----------------------- | ------------ | ---------------- |
| **Requests/sec**        | 🟢 29,278.35 | 23,108.16        |
| **Avg Latency**         | 81.58 ms     | 🟢 **71.92 ms**  |
| **Latency StdDev**      | 143.85 ms    | 🟢 **120.47 ms** |
| **Max Latency**         | 🟢 1.54 s    | 1.82 s           |
| **Total Requests**      | 🟢 1,757,995 | 1,388,634        |
| **Timeouts**            | 74           | 🟢 **18**        |
| **Transfer/sec**        | 6.42 MB      | 🟢 **6.81 MB**   |
| **Memory (Idle)**       | \~76 MB      | 🟢 **\~5 MB**    |
| **Memory (Under Load)** | \~250 MB     | 🟢 **\~50 MB**   |

---

## 🧠 Analysis

### ✅ Traefik Highlights

* High throughput: \~29K RPS and \~1.75M total requests.

### ✅ Goma Gateway Highlights

* 12% lower average latency and more consistent performance.
* 76% fewer timeouts under the same load.
* 5x smaller memory footprint
* Higher per-request transfer efficiency.

---

## ⚙️ Throughput vs Stability

| Feature       | Traefik       | Goma Gateway       |
| ------------- | ------------- | ------------------ |
| 🚦 Throughput | 🟢 High       | Moderate           |
| ⏱️ Latency    | Moderate      | 🟢 Lower           |
| 📉 Stability  | Higher jitter | 🟢 More consistent |
| ⛔ Timeouts    | Higher        | 🟢 Fewer           |
| 🧠 Memory     | 76–250 MB     | 🟢 5–50 MB         |

## Screenshot


![Test Screenshot](https://raw.githubusercontent.com/jkaninda/goma-gateway-vs-traefik/main/screenshot.png)

---

## 🧪 Reproducing the Test

### ✅ Requirements

* Docker

### 🛠️ Setup: `docker-compose`

Create a file named `compose.yaml`:

```yaml
services:
  okapi-example:
    image: jkaninda/okapi-example:1.0.0
    container_name: okapi-example
    labels:
      - traefik.enable=true
      - traefik.http.routers.okapi-example.rule=Host(`okapi-example.jkaninda.dev`) || Host(`localhost`)
      - traefik.http.routers.okapi-example.entrypoints=web
      - traefik.http.services.okapi-example.loadbalancer.server.port=8080
    restart: always
    ports:
      - 8080:8080
    networks:
      - default

  gateway:
    image: jkaninda/goma-gateway:0.3.3
    container_name: gateway
    command: server
    restart: always
    volumes:
      - ./goma.yml:/etc/goma/goma.yml:ro
    ports:
      - 80:80
      - 443:443
    networks:
      - default

  traefik:
    image: traefik:v3.3.4
    container_name: traefik
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
    ports:
      - 80:80
      - 443:443
    networks:
      - default
```

---

### 🔧 Configuration Files

#### `goma.yml` (Goma Gateway)

```yaml
gateway:
  log:
    level: error
  entryPoints:
    web:
      address: ":80"
    webSecure:
      address: ":443"
  networking:
    transport:
      insecureSkipVerify: true
  routes:
    - name: okapi-example
      path: /
      hosts:
       - localhost
      target: http://okapi-example:8080
```

#### `traefik.yml` (Traefik)

```yaml
log:
  level: ERROR

providers:
  docker:
    exposedByDefault: false

api:
  dashboard: true   # Disable if not needed
  insecure: true
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

serversTransport:
  insecureSkipVerify: true
```

---

## 🚦 Running the Tests

### 🟢 Goma Gateway

Start the gateway and backend:

```sh
docker compose up -d gateway okapi-example
```

Check readiness:

```sh
curl http://localhost/api/books
```

Run the performance test:

```sh
echo "GOMA GATEWAY"
wrk -t8 -c500 -d60s http://localhost/api/books
```

---

### 🔁 Switch to Traefik

Stop Goma Gateway:

```sh
docker stop gateway okapi-example && docker rm gateway okapi-example
```

Start Traefik and backend:

```sh
docker compose up -d traefik okapi-example --force-recreate
```

Check readiness:

```sh
curl http://localhost/api/books
```

Run the test:

```sh
echo "TRAEFIK"
wrk -t8 -c500 -d60s http://localhost/api/books
```

> 💡 You can substitute `okapi-example` with any backend to run your own tests.

### Clean

```sh
docker compose down
```
---

## 🔗 Useful Links

* 🔧 **Goma Gateway**: [github.com/jkaninda/goma-gateway](https://github.com/jkaninda/goma-gateway)
* 📚 **Okapi Example**: [github.com/jkaninda/okapi-example](https://github.com/jkaninda/okapi-example)

