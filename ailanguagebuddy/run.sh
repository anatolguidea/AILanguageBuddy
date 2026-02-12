#!/bin/sh
# Load .env and start Spring Boot (so DATASOURCE_URL and GROQ_API_KEY are set).
cd "$(dirname "$0")"
set -a
[ -f .env ] && . ./.env
set +a

# Enable native access for Netty high-perf IO on macOS (Apple Silicon)
export MAVEN_OPTS="--enable-native-access=ALL-UNNAMED"

./mvnw spring-boot:run \
  -Dspring-boot.run.jvmArguments="--enable-native-access=ALL-UNNAMED"
