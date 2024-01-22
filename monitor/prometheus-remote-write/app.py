import time
import logging
import random
from prometheus_client import start_http_server, Gauge, CollectorRegistry
from datetime import datetime

# Create a Prometheus Gauge metric with a custom registry
registry = CollectorRegistry()
metric_licenses = Gauge('acme_corp', 'Acme Corporation', ['product', 'type'], registry=registry)


def query_rest_api():
    produced = random.randint(a=50, b=100)
    sold = random.randint(a=50, b=100)

    logging.debug(f"main:: widgets:produced = {produced}, widgets:sold = {sold}")

    metric_licenses.labels(product='widgets', type='produced').set(produced)
    metric_licenses.labels(product='widgets', type='sold').set(sold)


if __name__ == '__main__':
    # Start the Prometheus HTTP server
    logging.basicConfig(level="DEBUG",
                        format='%(asctime)s - %(levelname)s - %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')

    start_http_server(8000, registry=registry)  # Pass the custom registry to the HTTP server

    # Periodically query the REST API and update the metric
    while True:
        query_rest_api()
        time.sleep(1)
