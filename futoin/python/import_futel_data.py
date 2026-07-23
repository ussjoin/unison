import influxdb_client
from influxdb_client import InfluxDBClient, Point, WriteOptions
import configparser
from datetime import datetime
import requests
import pathlib

config = configparser.ConfigParser()
configpath = f"{pathlib.Path(__file__).parent.resolve()}/config.ini"
config.read(configpath)

INFLUXDB_URL = config["influxdb"]["url"]
INFLUXDB_ORG = config["influxdb"]["org"]
INFLUXDB_BUCKET = config["influxdb"]["bucket"]
INFLUXDB_TOKEN = config["influxdb"]["token"]


def fetch_data(year=datetime.now().year, month=datetime.now().month):
    # https://futel.github.io/usage/data/date/{year}/{month}.json
    # https://github.com/futel/usage/blob/main/web/src/data-loader.js for examples
    
    url = f"https://futel.github.io/usage/data/date/{year}/{month:02d}.json"
    r = requests.get(url, timeout=30)
    if r.status_code == 200:
        return r.json()
    else:
        print(f"ERROR: {r.status_code} {r.text}")
        return None


def write_data(somedata):
    
    records = [Point("futel_event")
        .tag("channel", d['channel'])
        .tag("endpoint", d['endpoint'])
        .field("event", d['event'])
        .time(d['timestamp'])
        for d in somedata if 'endpoint' in d]
    
    with InfluxDBClient(
        url=INFLUXDB_URL, token=INFLUXDB_TOKEN, org=INFLUXDB_ORG
    ) as _client:

        with _client.write_api(
            write_options=WriteOptions(
                batch_size=500,
                flush_interval=10_000,
                jitter_interval=2_000,
                retry_interval=5_000,
                max_retries=5,
                max_retry_delay=30_000,
                max_close_wait=300_000,
                exponential_base=2,
            )
        ) as writer:
            ret = writer.write(bucket=INFLUXDB_BUCKET, record=records)
            print(f"Return value from write: {ret}")
            
if __name__ == "__main__":
    # for year in range(2022, 2026):
    #     for month in range(1,13):
    #         data = fetch_data(year, month)
    #         #print(data)
    #         write_data(data)
    write_data(fetch_data())
