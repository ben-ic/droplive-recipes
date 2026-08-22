#!/usr/bin/env python3
import json
import os
import time
import urllib.error
import urllib.request

API = "http://127.0.0.1:5000/api/v1/watch"
DATASTORE = "/datastore/url-watches.json"
WANTED = (
    ("Northstar company", os.environ["DROPLIVE_COMPANY_URL"], "Company"),
    ("Lumen release page", os.environ["DROPLIVE_CHANGING_URL"], "Product launch"),
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

existing = {item.get("url") for item in current.values()} if isinstance(current, dict) else set()
for title, url, tag in WANTED:
    if url not in existing:
        request("POST", {"url": url, "title": title, "tag": tag})
