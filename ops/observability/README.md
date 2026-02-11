# Voice Observability Pack

This folder contains baseline observability artifacts for the live voice runtime.

## Files
- `prometheus/voice-alert-rules.yml`: Prometheus alert rules for voice reliability and latency.
- `grafana/voice-runtime-dashboard.json`: Grafana dashboard for `voice.*` runtime metrics.

## Backend requirements
The Spring backend must expose:
- `/actuator/prometheus`
- `/actuator/metrics`

Current backend settings are configured in:
- `ailanguagebuddy/src/main/resources/application.properties`

## Suggested rollout
1. Import the Grafana dashboard JSON.
2. Load the Prometheus alert rules file into your Prometheus rule config.
3. Validate metric names in your environment (Micrometer naming can vary by registry).
4. Tune thresholds after 24-48h baseline traffic.

## Notes
- Alert thresholds in this package are intentionally conservative initial defaults.
- For production, set severity levels and routes according to your on-call policy.
