#!/bin/sh
# Start Kanboard, then fill it with the shared Northstar boards.
#
# The seed runs THROUGH KANBOARD'S OWN JSON-RPC API, not against the SQLite file.
# Every project, column, category, card, subtask, comment, and link is created by
# a documented procedure, so the demo exercises the path an operator uses and
# nothing here depends on a private schema.
#
# It uses the *application* API (user `jsonrpc`, the token Kanboard shows under
# Settings -> API) rather than the user API. That is not a shortcut: with a logged
# in user session Kanboard forces `creator_id` and every comment author to be the
# calling user, so the whole board would be signed by one person. The application
# API has no user session, so the ten people in the world keep their own work and
# their own words. Reading that token out of the settings row, and the dates
# backdate() writes, are the only two places this script touches SQLite, and both
# run as nginx so the database never changes owner.
set -eu

SEED=/usr/local/lib/droplive-kanboard-seed.jsonl
MAP=/tmp/droplive-kanboard-bindings.sed
BASE=http://127.0.0.1

rpc() {
  # The request body arrives on standard input, so no argument is ever quoted.
  curl -s -m 30 -u "jsonrpc:$1" -H 'Content-Type: application/json' \
    --data-binary @- "$BASE/jsonrpc.php" 2>/dev/null || true
}

# The one thing Kanboard's API cannot say: when a card or a comment was written.
# Everything the seed creates is stamped with the moment of the call, so a card
# ends up claiming it was created two days after it was started, every comment
# reads "a few seconds ago", and every card shows an age of "<15m" on the board.
# These are the dates the world already fixed, written to the columns Kanboard
# itself owns on rows Kanboard itself just created. Nothing else is written, and
# it runs as nginx so the database does not change owner.
backdate() {
  DL_ROW=$(printf '%s' "$1" | sed -n 's/.*_id":\([0-9][0-9]*\).*/\1/p')
  DL_CREATED=$(printf '%s' "$1" | sed -n 's/.*"created":\([0-9][0-9]*\).*/\1/p')
  DL_MOVED=$(printf '%s' "$1" | sed -n 's/.*"moved":\([0-9][0-9]*\).*/\1/p')
  [ -n "$DL_ROW" ] && [ -n "$DL_CREATED" ] || return 1
  export DL_ROW DL_CREATED DL_MOVED

  case "$1" in
  *'"method":"droplive.task_dates"'*)
    s6-setuidgid nginx php -r '
      $db = new PDO("sqlite:/var/www/app/data/db.sqlite");
      $s = $db->prepare("update tasks set date_creation = ?, date_modification = ?, date_moved = ? where id = ?");
      $s->execute([(int) getenv("DL_CREATED"), (int) getenv("DL_MOVED"), (int) getenv("DL_MOVED"), (int) getenv("DL_ROW")]);
    ' 2>/dev/null </dev/null
    ;;
  *)
    s6-setuidgid nginx php -r '
      $db = new PDO("sqlite:/var/www/app/data/db.sqlite");
      $s = $db->prepare("update comments set date_creation = ?, date_modification = ? where id = ?");
      $s->execute([(int) getenv("DL_CREATED"), (int) getenv("DL_CREATED"), (int) getenv("DL_ROW")]);
    ' 2>/dev/null </dev/null
    ;;
  esac
}

seed() {
  # No minted password means no account to hand the visitor, so the demo is left
  # on the image's own sign-in rather than half-configured.
  password="${KANBOARD_OWNER_PASSWORD:-}"
  [ -n "$password" ] || { echo "[droplive] no owner password; leaving Kanboard unseeded" >&2; return 0; }
  [ -r "$SEED" ] || return 0

  # Ready, not merely listening: Kanboard installs its schema during the first
  # request, and /login is the first page that answers 200 once it has.
  waited=0
  while [ "$waited" -lt 120 ]; do
    code=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "$BASE/login" 2>/dev/null || echo 000)
    [ "$code" = "200" ] && break
    sleep 1
    waited=$((waited + 1))
  done
  [ "$waited" -lt 120 ] || { echo "[droplive] kanboard did not become ready; skipping seed" >&2; return 0; }

  # As nginx, because a root-owned journal beside db.sqlite makes the database
  # read-only for the web server that has to write to it. \x27 is a single quote
  # in a PHP double-quoted string, which keeps the whole program in one pair of
  # shell quotes.
  token=$(s6-setuidgid nginx php -r 'echo (new PDO("sqlite:/var/www/app/data/db.sqlite"))->query("select value from settings where option = \x27api_token\x27")->fetchColumn();' 2>/dev/null || true)
  [ -n "$token" ] || { echo "[droplive] no application API token; skipping seed" >&2; return 0; }

  # IDEMPOTENT BY THE FIRST THING THE SEED CREATES: the account the visitor signs
  # in as. If Maya is already there this volume has been seeded, and a restart
  # must leave the boards alone rather than doubling them.
  present=$(printf '%s' '{"jsonrpc":"2.0","id":"-","method":"getUserByName","params":{"username":"maya"}}' | rpc "$token")

  case "$present" in
  *'"username":"maya"'*)
    echo "[droplive] kanboard already has the Northstar boards; leaving them alone" >&2
    ;;
  *)
    : >"$MAP"
    # sed replacement text treats & and the delimiter specially.
    owner=$(printf '%s' "$password" | sed 's/[\\&|]/\\&/g')
    written=0
    failed=0
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      # The binding name for whatever this call returns rides in the JSON-RPC id.
      bind=$(printf '%s' "$line" | sed -n 's/^{"jsonrpc":"2.0","id":"\([^"]*\)".*/\1/p')
      # Every identifier this line depends on was bound by an earlier line, and
      # each of the nine accounts nobody signs in as gets its own throwaway secret.
      body=$(printf '%s' "$line" | sed -f "$MAP" |
        sed "s|@secret:owner-password@|$owner|g; s|@secret:random@|$(openssl rand -hex 24)|g")

      # Two methods in the seed are not Kanboard procedures. They set the dates
      # Kanboard's API cannot express -- see backdate() -- and are run here rather
      # than posted.
      case "$body" in
      *'"method":"droplive.'*)
        backdate "$body" && written=$((written + 1)) || failed=$((failed + 1))
        continue
        ;;
      esac

      response=$(printf '%s' "$body" | rpc "$token")

      case "$response" in
      *'"error"'* | *'"result":false'* | '')
        failed=$((failed + 1))
        echo "[droplive] kanboard rejected a $bind call" >&2
        continue
        ;;
      esac
      written=$((written + 1))

      case "$bind" in
      -) ;;
      columns:*)
        # Kanboard names the four columns a new project starts with but does not
        # say what their identifiers are, so they are read back and bound by title.
        key=${bind#columns:}
        printf '%s' "$response" | tr '}' '\n' | while IFS= read -r part; do
          column=$(printf '%s' "$part" | sed -n 's/.*"id":\([0-9][0-9]*\).*/\1/p')
          title=$(printf '%s' "$part" | sed -n 's/.*"title":"\([^"]*\)".*/\1/p')
          [ -n "$column" ] && [ -n "$title" ] || continue
          grep -qF "\"@column:$key/$title@\"" "$MAP" ||
            printf 's|"@column:%s/%s@"|%s|g\n' "$key" "$title" "$column" >>"$MAP"
        done
        ;;
      *)
        value=$(printf '%s' "$response" | sed -n 's/.*"result":\([0-9][0-9]*\).*/\1/p')
        [ -n "$value" ] && printf 's|"@%s@"|%s|g\n' "$bind" "$value" >>"$MAP" || true
        ;;
      esac
    done <"$SEED"
    rm -f "$MAP"
    echo "[droplive] seeded kanboard with $written calls, $failed refused" >&2
    ;;
  esac

  # Kanboard ships an admin/admin account and prints nothing about it. Retiring it
  # runs on every start, not only after a fresh seed, so an interrupted seed can
  # never leave a published default password live on a demo. Maya has the app-admin
  # role, so nothing is lost with it.
  visitor=$(printf '%s' '{"jsonrpc":"2.0","id":"-","method":"getUserByName","params":{"username":"maya"}}' | rpc "$token")
  case "$visitor" in
  *'"username":"maya"'*)
    printf '%s' '{"jsonrpc":"2.0","id":"-","method":"disableUser","params":{"user_id":1}}' | rpc "$token" >/dev/null
    ;;
  *)
    echo "[droplive] maya was not created; keeping the shipped admin account so the demo can be opened" >&2
    ;;
  esac
}

"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT

seed || echo "[droplive] seed failed; the app is still running" >&2

# The boards were worked-in when the visitor arrived; the world says a few more
# things happen after they get here. This runs in the background because it
# spends most of its life asleep, and it exits after the last one rather than
# waiting for something that will not come.
if [ -r /usr/local/lib/droplive-kanboard-arrivals.php ]; then
  php /usr/local/lib/droplive-kanboard-arrivals.php &
fi

wait "$server_pid"
