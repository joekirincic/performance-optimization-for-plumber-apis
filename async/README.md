# Performance Optimization for Plumber APIs: Async

This project load tests three APIs with a similar endpoint and compares their performance. The aim is to show the performance benefit of using async endpoints for I/O bound tasks.

## Overview

A brief description of each app is as follows.

1.  **Synchronous API** (baseline) - `{plumber2}` API without async enabled.
2.  **Async API 1** -`{plumber2}` API with async enabled via the @async tag.
3.  **Async API 2** - `{plumber}` API with async enabled via explicit `{mirai}` usage.

The project includes a complete dockerized setup with a Postgres database, load testing via the Python package `locust`, and a shell script to download CSVs from each load test to your local machine for further analysis.

## Prerequisites

-   Docker and Docker Compose
-   8GB+ RAM recommended for load testing with 200 concurrent users

## Quick Start

### 1. Start All Services

``` bash
docker compose up -d --build
```

This will start:

-   PostgreSQL database (port 5432)

-   Database seeding service (runs once)

-   Synchronous API (port 8000)

-   Async API with `{plumber2}` (port 8001)

-   Async API with `{plumber}` (port 8002)

-   Locust load testing UI (port 8089)

### 2. Test the APIs Manually

``` bash
# Synchronous API
curl "http://localhost:8000/penguins?n=10"

# Async API with `{plumber2}`
curl "http://localhost:8001/penguins?n=10"

# Async API with `{plumber}`
curl "http://localhost:8002/penguins?n=10"
```

### 3. Run Load Tests

#### Option A: Using Locust Web UI

1.  Open http://localhost:8089 in your browser.
2.  Configure test parameters:
    -   Number of users: 200
    -   Spawn rate: 10 users/second
    -   Host: `http://plumber2-async-api:8001` (or other API variant)
3.  Click "Start",

#### Option B: Using the Automated Script

``` bash
chmod +x ./generate-load-test-data.sh
./generate-load-test-data.sh
```

This script runs comprehensive load tests against all three API implementations and saves results to `load-test-results/`.

### 4. Analyze Results

Load test results are saved as CSV files in `async/load-test-results/`:

-   `load-test_sync.csv`

-   `load-test_plumber2-async.csv`

-   `load-test_plumber-async.csv`

Each file contains:

-   timestamp: when the request was issued

-   request_type: (GET, POST, etc.)

-   name: specific request issued

-   response_time: response time in milliseconds

-   response_length: size of response payload in bytes

-   status_code: HTTP status code of the response

-   success: whether the request was successful

-   user_id: user (not specified in load tests)

-   exception: errors captured

## Project Structure

```         
async/
├── R/                              # R API implementations
│   ├── main.R                      # API entry point
│   ├── sync-api-plumber2.R         # Synchronous baseline with `{plumber2}`
│   ├── async-api-plumber.R         # Async API with `{plumber}`
│   ├── async-api-plumber2.R        # Async API with `{plumber2}`
│   └── seed-database.R             # Database initialization
├── docker-compose.yml              # Service orchestration
├── Dockerfile.plumber              # R API container
├── Dockerfile.locust               # Load testing container
├── locustfile.py                   # Locust test scenarios
├── generate-load-test-data.sh      # Load testing script
├── .env                            # Environment variables
└── load-test-results/              # Benchmark results
```

## Load Testing Details

The Locust test suite simulates realistic traffic patterns with three workload types:

-   **Small batches** (1-10 records): 3x weight - frequent, light queries
-   **Medium batches** (11-100 records): 2x weight - moderate queries
-   **Large batches** (101-1000 records): 1x weight - heavy queries

Default test configuration:

-   200 concurrent users

-   10 users/second spawn rate

-   Random wait time: 1-2 seconds between requests

## Cleanup

``` bash
docker compose down -v  # Remove containers and volumes
```

## Performance Insights

Compare the three implementations by analyzing their *throughput*, that is, requests per second under load. The async implementations should demonstrate superior performance under concurrent load, with differences between `{plumber}` and `{plumber2}` async approaches becoming apparent at high request volumes.