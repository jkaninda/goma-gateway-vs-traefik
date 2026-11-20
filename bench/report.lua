-- wrk reporter: prints one JSON object with throughput, latency percentiles and errors.
done = function(summary, latency, requests)
  local s = summary.duration / 1e6
  local e = summary.errors
  io.write(string.format(
    '{"requests":%d,"duration_s":%.3f,"rps":%.2f,"bytes":%d,' ..
    '"lat_avg_ms":%.3f,"lat_stdev_ms":%.3f,"lat_max_ms":%.3f,' ..
    '"p50_ms":%.3f,"p90_ms":%.3f,"p99_ms":%.3f,"p999_ms":%.3f,' ..
    '"err_connect":%d,"err_read":%d,"err_write":%d,"err_status":%d,"err_timeout":%d}\n',
    summary.requests, s, summary.requests / s, summary.bytes,
    latency.mean / 1e3, latency.stdev / 1e3, latency.max / 1e3,
    latency:percentile(50) / 1e3, latency:percentile(90) / 1e3,
    latency:percentile(99) / 1e3, latency:percentile(99.9) / 1e3,
    e.connect, e.read, e.write, e.status, e.timeout))
end
