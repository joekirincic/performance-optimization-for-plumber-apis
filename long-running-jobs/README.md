# Long-Running Jobs with Plumber APIs

This directory demonstrates different patterns for handling long-running tasks in Plumber APIs. It includes implementations of a naive async pattern, polling pattern, and webhook pattern using a machine learning model training example.

## Overview

All APIs train a linear regression model to predict penguin body mass using the `penguins` dataset from `{palmerpenguins}`.

## File Structure

```         
long-running-jobs/
├── docker-compose.yml          # Multi-container orchestration
├── Dockerfile.plumber          # Container image definition
├── R/
│   ├── main.R                  # Entry point with app selection
│   ├── naive-api.R             # Naive async pattern
│   ├── polling-pattern-api.R   # Polling pattern implementation
│   ├── webhook-pattern-api.R   # Webhook server implementation
│   └── webhook-client-api.R    # Webhook client implementation
└── README.md                   # This file
```

## Shared Components

All APIs use:

-   `{mirai}`: Async execution with 4 worker daemons

-   `{memoise}`: Caching for model loading operations

-   `{plumber2}`: Plumber API framework

## Docker

Start all services:

``` bash
docker compose up -d --build
```

## Architecture Patterns

### 1. Naive Async Pattern (naive-api.R)

**Port:** 8003

A simple async implementation using `{plumber2}`'s `@async` decorator with mirai daemons.

**Endpoints:**

-   `POST /train`: Submits training job and returns immediately.

-   `POST /predict`: Makes predictions using the trained model.

**Implementation Details:**

-   Uses `@async` and `@then` decorators for non-blocking execution.

-   Trains model asynchronously in background daemons.

-   Invalidates memoised cache after training completes.

**Example**

``` bash
# Train model
curl -X POST http://localhost:8003/train

# Predict
curl -X POST http://localhost:8003/predict \
  -H "Content-Type: application/json" \
  -d '{"data": {...}}'
```

### 2. Polling Pattern (polling-pattern-api.R)

**Port:** 8004

Implements the polling pattern where clients repeatedly check task status until completion.

**Endpoints:**

-   `POST /train`: Creates task, returns task ID and Location header (202 status).

-   `GET /train/{id}/status`: Check task status (queued/running/completed/failed/cancelled).

-   `GET /train/{id}/result`: Retrieve training results.

-   `DELETE /train/{id}`: Cancel a running task.

-   `POST /predict`: Makes predictions using the trained model.

**Implementation Details:**

-   Returns `202 Accepted` with `Location` header pointing to status endpoint.

-   Includes `Retry-After` header suggesting poll interval.

-   Stores task metadata in environment for state management.

-   Handles task lifecycle: queued → running → completed/failed/cancelled.

-   Supports task cancellation via `stop_mirai()`.

**Client Flow:**

1.  Submit task via `POST /train`.

2.  Receive task ID and status URL.

3.  Poll `GET /train/{id}/status` until status is "completed".

4.  Retrieve results from `GET /train/{id}/result`.

**Example**

``` bash
# Submit training job
TASK_ID=$(curl -X POST http://localhost:8004/train | jq -r '.id')

# Poll status
curl http://localhost:8004/train/$TASK_ID/status

# Get result when complete
curl http://localhost:8004/train/$TASK_ID/result

# Cancel task
curl -X DELETE http://localhost:8004/train/$TASK_ID
```

### 3. Webhook Pattern (webhook-pattern-api.R + webhook-client-api.R)

**Ports:** 8005 (server), 8006 (client)

Implements the webhook pattern where the server notifies the client upon task completion.

#### Server API (webhook-pattern-api.R)

**Endpoints:**

-   `POST /train`: Accepts task with `callback_url`, returns task ID (202 status).

-   `DELETE /train/{id}`: Cancel a running task.

-   `POST /predict`: Makes predictions using the trained model.

**Implementation Details:**

-   Requires `callback_url` in request body.

-   Executes training asynchronously with mirai.

-   Sends HTTP POST to callback URL upon completion/failure.

-   Includes retry logic (3 attempts with constant rate of 2 seconds).

-   Payload includes task ID, created timestamp, status, and result/error.

#### Client API (webhook-client-api.R)

**Endpoints:**

-   `POST /callback`

-   Receives webhook callbacks from training API.

-   `POST /train`

-   Initiates training request to webhook API.

**Implementation Details:**

-   Provides callback endpoint for receiving job completion notifications.

-   Logs received webhook notifications with timestamps.

-   Can initiate training jobs on behalf of external callers.

**Client Flow:**

1.  Client exposes callback endpoint.

2.  Client submits task to `POST /train` with `callback_url`.

3.  Server processes task asynchronously.

4.  Server sends results to `callback_url` when complete.

5.  Client receives and processes webhook notification.

#### Examples

``` bash
# Submit training job with callback URL
curl -X POST http://localhost:8005/train \
  -H "Content-Type: application/json" \
  -d '{"callback_url": "http://webhook-client-api:8006/callback"}'

# Or use the client API to initiate training
curl -X POST http://localhost:8006/train
```