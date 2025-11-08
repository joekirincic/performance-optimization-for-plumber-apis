#!/bin/bash

# Create results directory if it doesn't exist
mkdir -p load-test-results

# Run load test against plumber2-sync-api
echo "Starting headless load test against service plumber2-sync-api..."
docker compose exec locust \
  locust -f locustfile.py \
  --headless -u 200 -r 10 -t 1m \
  --host http://plumber2-sync-api:8000

# Copy CSV from container to local directory
echo "Copying results to local machine..."
docker compose cp locust:/app/detailed_request_results.csv load-test-results/load-test_plumber2-sync.csv


# Run load test against plumber2-async-api
echo "Starting headless load test against service plumber2-async-api..."
docker compose exec locust \
  locust -f locustfile.py \
  --headless -u 200 -r 10 -t 1m \
  --host http://plumber2-async-api:8001

# Copy CSV from container to local directory
echo "Copying results to local machine..."
docker compose cp locust:/app/detailed_request_results.csv load-test-results/load-test_plumber2-async.csv

# Run load test against plumber-async-api
echo "Starting headless load test against service plumber-async-api..."
docker compose exec locust \
  locust -f locustfile.py \
  --headless -u 200 -r 10 -t 1m \
  --host http://plumber-async-api:8002

# Copy CSV from container to local directory
echo "Copying results to local machine..."
docker compose cp locust:/app/detailed_request_results.csv load-test-results/load-test_plumber-async.csv

echo "Load test complete."
