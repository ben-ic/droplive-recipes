#!/usr/bin/env python3
"""Play the Northstar seed into Vikunja, at image build time.

This runs in a build stage and never ships. Vikunja will not accept a creation
date by any route it offers -- the task API ignores one, and its own file
migrator stamps every imported task with the moment of the import -- and a board
whose every task and comment was written seconds ago is the one thing a
worked-in board never looks like. So the seed is played into a database here,
the two date columns are corrected directly, and the finished database is what
the image carries. The running image gains nothing: no client, no interpreter,
no database tool.

The seed file holds one complete request per line, `METHOD PATH BIND BODY`
split on the first three spaces. A line whose method is CLI is not a request at
all; local registration is closed in this recipe, so accounts are made by
Vikunja's own binary.
"""
import base64
import json
import os
import re
import secrets
import sqlite3
import subprocess
import sys
import time
import urllib.error
import urllib.request

BASE = os.environ.get("DROPLIVE_VIKUNJA_BASE", "http://127.0.0.1:3456")
SEED = os.environ.get("DROPLIVE_VIKUNJA_SEED", "/seed/vikunja.jsonl")
BINARY = os.environ.get("DROPLIVE_VIKUNJA_BINARY", "/app/vikunja/vikunja")
DATABASE = os.environ.get("VIKUNJA_DATABASE_PATH", "/db/vikunja.db")
OWNER = "maya"
# A placeholder. The entrypoint replaces it with the value DropLive mints for
# the session before the app is ever reachable, so this never authenticates
# anything outside this build.
OWNER_PASSWORD = "seed-only-" + secrets.token_urlsafe(24)

ids = {}
tokens = {}
passwords = {OWNER: OWNER_PASSWORD}
backdate = []


def request(method, path, body=None, token=None):
    data = None if body is None else json.dumps(body).encode()
    call = urllib.request.Request(BASE + path, data=data, method=method)
    call.add_header("Content-Type", "application/json")
    if token:
        call.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(call, timeout=30) as answer:
            return answer.status, json.loads(answer.read().decode() or "null")
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode()[:200]


def sign_in(username):
    if username in tokens:
        return tokens[username]
    status, answer = request("POST", "/api/v1/login", {
        "username": username, "password": passwords[username]})
    if status != 200:
        raise SystemExit("could not sign in as %s: %s" % (username, answer))
    tokens[username] = answer["token"]
    return tokens[username]


def cli(*arguments):
    result = subprocess.run([BINARY] + list(arguments),
                            capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit("vikunja %s failed: %s" % (arguments[0], result.stderr[-400:]))
    return result.stdout


def user_id(username):
    # `user create` says only that it worked, so the id is read back from the
    # list, which Vikunja draws as a table with box-drawing rules.
    for line in cli("user", "list").splitlines():
        columns = [column.strip() for column in line.split("\u2502")]
        if len(columns) > 2 and columns[2] == username:
            return int(columns[1])
    raise SystemExit("no account called %s after creating it" % username)


def bound(name):
    if name == "secret:random":
        return secrets.token_urlsafe(18)
    if name not in ids:
        raise SystemExit("nothing bound for " + name)
    return ids[name]


def resolve(text):
    # A placeholder standing alone as a JSON value loses its quotes, because
    # what it stands for is a number and Vikunja refuses a string where it
    # expects one. Everywhere else -- inside a path, inside a longer string --
    # it is substituted as text.
    text = re.sub(r'"@([a-z]+:[^@]+)@"',
                  lambda m: json.dumps(bound(m.group(1))), text)
    return re.sub(r"@([a-z]+:[^@]+)@", lambda m: str(bound(m.group(1))), text)


def wait_for_vikunja():
    for _ in range(180):
        try:
            with urllib.request.urlopen(BASE + "/api/v1/info", timeout=3) as answer:
                if answer.status == 200:
                    return True
        except Exception:
            pass
        time.sleep(1)
    return False


def play():
    owner_token = sign_in(OWNER)
    ids["user:maya"] = user_id(OWNER)

    for line in open(SEED):
        line = line.rstrip("\n")
        if not line.strip():
            continue
        method, rest = line.split(" ", 1)
        path, rest = rest.split(" ", 1)
        bind, rest = rest.split(" ", 1)
        path = resolve(path)
        body = json.loads(resolve(rest))

        if method == "CLI":
            username = body["username"]
            passwords[username] = secrets.token_urlsafe(18)
            cli("user", "create", "--username", username, "--email", body["email"],
                "--password", passwords[username])
            ids[bind] = user_id(username)
            continue

        actor = body.pop("_as", None)
        created = body.pop("_created", None)
        bucket = body.pop("_bucket", None)
        token = sign_in(actor) if actor and actor != OWNER else owner_token

        # SQLite has one writer. Vikunja answers a contended write with a 500
        # rather than waiting, and a seed is the one workload that writes as
        # fast as it can, so a locked database is retried rather than dropped.
        for attempt in range(6):
            status, answer = request(method, path, body or None, token)
            if status != 500:
                break
            time.sleep(0.2 * (attempt + 1))
        if status >= 300:
            print("[droplive] %s %s -> %s %s" % (method, path, status, answer),
                  file=sys.stderr)
            continue

        if bind.startswith("view:"):
            # A project is made with four views; the one with lanes is the
            # kanban one, and its id is what every bucket call needs.
            ids[bind] = next(v["id"] for v in answer if v["view_kind"] == "kanban")
        elif bind.startswith("buckets:"):
            # Vikunja gives a new board three lanes already. They are referred
            # to by where they sit rather than by what they are called, because
            # what they are called is about to change.
            key = bind.split(":", 1)[1]
            ordered = sorted(answer, key=lambda b: b["position"])
            for name, bucket_row in zip(["first", "second", "last"], ordered):
                ids["bucket:%s/%s" % (key, name)] = bucket_row["id"]
        elif bind != "-" and isinstance(answer, dict) and "id" in answer:
            ids[bind] = answer["id"]

        if bucket and isinstance(answer, dict) and "id" in answer:
            request("POST", bucket + "/tasks", {"task_id": answer["id"]}, owner_token)

        if created and isinstance(answer, dict) and "id" in answer:
            # Order matters: a comment is created at /tasks/<id>/comments, so
            # asking about /tasks first files every comment under the wrong
            # table and stamps a task that happens to share the number.
            table = ("task_comments" if path.endswith("/comments") else
                     "tasks" if "/tasks" in path else "projects")
            backdate.append((table, answer["id"], created))


# What the first phase found to correct, handed to the second one, beside the
# database it belongs to.
STATE = os.environ.get(
    "DROPLIVE_VIKUNJA_STATE",
    os.path.join(os.path.dirname(DATABASE), "droplive-dates.json"))


def apply_dates(rows):
    if not rows:
        return
    connection = sqlite3.connect(DATABASE)
    try:
        for table, row_id, when in rows:
            stamp = when.replace("T", " ").replace("Z", "")
            connection.execute(
                "UPDATE %s SET created = ?, updated = ? WHERE id = ?" % table,
                (stamp, stamp, row_id))
        connection.commit()
    finally:
        connection.close()
    print("[droplive] dated %d rows" % len(rows), file=sys.stderr)


def main():
    # Second phase. The server has been stopped by now, so the database has no
    # other writer and the dates can be corrected before the file is taken.
    if "--dates" in sys.argv:
        apply_dates(json.load(open(STATE)))
        return

    if not wait_for_vikunja():
        raise SystemExit("vikunja did not become ready")
    cli("user", "create", "--username", OWNER,
        "--email", "maya@northstar-relay.invalid", "--password", OWNER_PASSWORD)
    play()
    json.dump(backdate, open(STATE, "w"))
    print("[droplive] seeded %d bindings, %d rows to date"
          % (len(ids), len(backdate)), file=sys.stderr)


if __name__ == "__main__":
    main()
