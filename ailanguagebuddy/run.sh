#!/bin/sh
# Load .env and start Spring Boot (so DATASOURCE_URL and GROQ_API_KEY are set).
cd "$(dirname "$0")"
set -a
[ -f .env ] && . ./.env
set +a
./mvnw spring-boot:run
