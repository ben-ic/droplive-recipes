#!/usr/bin/env python3
import json
import os
import time
import urllib.error
import urllib.request

API = "http://127.0.0.1:5000/api/v1/watch"
DATASTORE = "/datastore/url-watches.json"
WANTED = (
    ("Northstar company", os.environ["DROPLIVE_COMPANY_URL"], "Company", None),
    ("Lumen release page", os.environ["DROPLIVE_CHANGING_URL"], "Product launch", 15),
)


def request(method="GET", payload=None):
    body = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(API, data=body, method=method)
    if body is not None:
        req.add_header("Content-Type", "application/json")
    with open(DATASTORE, encoding="utf-8") as source:
        settings = json.load(source)["settings"]["application"]
    token = settings.get("api_access_token")
    if not isinstance(token, str) or not token:
        raise RuntimeError("changedetection.io API token is absent")
    req.add_header("x-api-key", token)
    with urllib.request.urlopen(req, timeout=10) as response:
        return json.load(response)


deadline = time.monotonic() + 60
while True:
    try:
        current = request()
        break
    except (OSError, KeyError, RuntimeError, json.JSONDecodeError, urllib.error.URLError):
        if time.monotonic() >= deadline:
            raise RuntimeError("changedetection.io did not become ready for setup")
        time.sleep(0.5)

# The company URL is served by the session's HTTP-target emulator.  The app
# becomes healthy before the launcher exposes that companion hostname, so a
# seed request made immediately after the local API is ready can create a watch
# whose first check records the edge's temporary 404.  Wait for the primary
# target to be reachable before creating watches; this keeps the seed data
# deterministic without changing the reviewed bindings or creating duplicates.
while True:
    try:
        with urllib.request.urlopen(WANTED[0][1], timeout=10) as response:
            if response.status == 200:
                break
            raise RuntimeError(f"company target returned HTTP {response.status}")
    except (OSError, RuntimeError, urllib.error.URLError):
        if time.monotonic() >= deadline:
            raise RuntimeError("changedetection.io company target did not become reachable")
        time.sleep(0.5)

existing = {item.get("url") for item in current.values()} if isinstance(current, dict) else set()
for title, url, tag, interval_seconds in WANTED:
    if url not in existing:
        payload = {"url": url, "title": title, "tag": tag}
        if interval_seconds is not None:
            payload["time_between_check_use_default"] = False
            payload["time_between_check"] = {
                "weeks": None,
                "days": None,
                "hours": None,
                "minutes": None,
                "seconds": interval_seconds,
            }
        request("POST", payload)
