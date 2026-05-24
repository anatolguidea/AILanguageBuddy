FROM python:3.11-slim

# Install curl for health check
RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r voicegroup && useradd -r -g voicegroup voiceuser

WORKDIR /app

# Install dependencies before copying source for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY . .

RUN chown -R voiceuser:voicegroup /app

USER voiceuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
