from locust import FastHttpUser, task, between, events
import json
import time
import random
import csv

# Global variables for CSV writing
results_file = None
results_writer = None

@events.init.add_listener
def on_locust_init(environment, **kwargs):
    """Initialize CSV file when Locust starts"""
    global results_file, results_writer
    results_file = open('detailed_request_results.csv', 'w', newline='')
    results_writer = csv.writer(results_file)
    # Write header
    results_writer.writerow([
        'timestamp', 'request_type', 'name', 'response_time',
        'response_length', 'status_code', 'success', 'user_id', 'exception'
    ])
    results_file.flush()  # Ensure header is written immediately

@events.request.add_listener
def on_request(request_type, name, response_time, response_length,
               exception, context, **kwargs):
    """Fires for every single request - logs to CSV"""
    global results_writer
    if results_writer:
        results_writer.writerow([
            time.time(),  # timestamp
            request_type,  # GET, POST, etc.
            name,  # endpoint name
            response_time,  # in milliseconds
            response_length,  # response size in bytes
            context.get('response_status_code', 'N/A'),  # HTTP status code
            'True' if exception is None else 'False',  # success flag
            context.get('user_id', 'N/A'),  # user identifier
            str(exception) if exception else ''  # error message if any
        ])
        # Periodically flush to ensure data is written
        if random.random() < 0.1:  # Flush ~10% of the time to balance performance
            results_file.flush()

@events.quitting.add_listener
def on_quitting(environment, **kwargs):
    """Clean up - close CSV file when test ends"""
    global results_file
    if results_file:
        results_file.flush()
        results_file.close()

class PlumberApiUser(FastHttpUser):
    wait_time = between(1, 2)  # Wait between 1-2 seconds between tasks

    @task(3)
    def get_small_batch(self):
        """Query a small batch of penguins (1-10 records)"""
        n = random.randint(1, 10)
        with self.client.get(
            "/penguins",
            params={"n": n},
            catch_response=True,
            name="/penguins?n=[1-10]"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")

    @task(2)
    def get_medium_batch(self):
        """Query a medium batch of penguins (11-100 records)"""
        n = random.randint(11, 100)
        with self.client.get(
            "/penguins",
            params={"n": n},
            catch_response=True,
            name="/penguins?n=[11-100]"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")

    @task(1)
    def get_large_batch(self):
        """Query a large batch of penguins (101-1000 records)"""
        n = random.randint(101, 1000)
        with self.client.get(
            "/penguins",
            params={"n": n},
            catch_response=True,
            name="/penguins?n=[101-1000]"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")