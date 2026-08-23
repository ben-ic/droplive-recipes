#!/bin/sh
# Deliver the world's timeline into the notebook while the visitor is watching.
#
# The platform mounts one read-only world artifact per session and points
# DROPLIVE_WORLD_PATH at it. That artifact carries timeline.json: a short list of
# things that happen after the demo opens, each with its own delay. This turns
# those into memos at the moment they arrive, through the same public API the
# seed uses, so a notebook that was full when the visitor arrived also gains a
# line while they read it.
#
# WHICH KINDS THIS APP CAN REPRESENT HONESTLY: all three.
#
# Everything in Memos is a note written by the notebook's owner. There is no
# mailbox, no channel and no ledger to put an arrival in, so an arrival becomes
# what a person actually does with a notes app -- a note recording what came in,
# with the sender named in the text. An email, a colleague's message and a
# payment notification are all things Maya would write down, and writing them
# down is the only shape this application has. Nothing is presented as something
# it is not: no memo claims to be an email, and none is attributed to anyone but
# the notebook's owner.
#
# A webhook is supported only for finance.invoice.paid. Any other webhook event
# is skipped, because the recipe would be inventing a sentence for something the
# world has not described.
set -eu

WORLD="${DROPLIVE_WORLD_PATH:-}"
READER=/usr/local/lib/droplive-memos-timeline.awk
DONE=/var/opt/memos/droplive-arrivals.done
BASE="http://127.0.0.1:${MEMOS_PORT:-5230}"

# The world's people, by the ids its timeline uses. Written out rather than
# derived from the id, because turning "priya-raman" into a name by rule is how
# a demo ends up addressing somebody as Mcdonald. An id that is not here is not
# delivered.
who() {
  case "$1" in
  priya-raman) echo "Priya Raman" ;;
  maya-chen) echo "Maya Chen" ;;
  jon-bell) echo "Jon Bell" ;;
  noor-alvarez) echo "Noor Alvarez" ;;
  elena-petrov) echo "Elena Petrov" ;;
  samira-okafor) echo "Samira Okafor" ;;
  lucas-meyer) echo "Lucas Meyer" ;;
  hana-ito) echo "Hana Ito" ;;
  david-banerjee) echo "David Banerjee" ;;
  imani-brooks) echo "Imani Brooks" ;;
  theo-martin) echo "Theo Martin" ;;
  *) echo "" ;;
  esac
}

what_customer() {
  case "$1" in
  lumen) echo "Lumen Labs" ;;
  ember) echo "Ember Commerce" ;;
  fieldnote) echo "Fieldnote Studio" ;;
  harbor) echo "Harbor Mobility" ;;
  *) echo "" ;;
  esac
}

field() {
  awk -v mode=field -v want="$1" -v field="$2" -f "$READER" "$WORLD/timeline.json" 2>/dev/null
}

# A memo body is markdown with newlines in it, so it is encoded rather than
# quoted into the request.
json_string() {
  awk 'BEGIN { printf "\"" }
       { gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, "\\t")
         if (NR > 1) printf "\\n"
         printf "%s", $0 }
       END { printf "\"" }'
}

post_memo() {
  body=$(json_string)
  wget -q -T 15 -O /dev/null \
    --header 'content-type: application/json' \
    --header "authorization: Bearer $TOKEN" \
    --post-data "{\"content\":$body,\"visibility\":\"PRIVATE\"}" \
    "$BASE/api/v1/memos" 2>/dev/null
}

deliver() {
  id=$1
  kind=$2

  case "$kind" in
  incoming-email)
    sender=$(who "$(field "$id" from_id)")
    subject=$(field "$id" subject)
    text=$(field "$id" body_text)
    [ -n "$sender" ] && [ -n "$subject" ] || return 1
    printf '# Email from %s — %s\n\n%s\n' "$sender" "$subject" \
      "$(printf '%s\n' "$text" | sed 's/^/> /')" | post_memo
    ;;
  chat-message)
    sender=$(who "$(field "$id" author_id)")
    channel=$(field "$id" channel_id)
    text=$(field "$id" text)
    [ -n "$sender" ] && [ -n "$text" ] || return 1
    channel=${channel#channel-}
    printf '# %s in #%s\n\n%s\n' "$sender" "$channel" \
      "$(printf '%s\n' "$text" | sed 's/^/> /')" | post_memo
    ;;
  webhook)
    event=$(field "$id" event)
    [ "$event" = "finance.invoice.paid" ] || return 1
    customer=$(what_customer "$(field "$id" customer_id)")
    invoice=$(field "$id" invoice_id)
    cents=$(field "$id" amount_cents)
    [ -n "$customer" ] && [ -n "$invoice" ] && [ -n "$cents" ] || return 1
    invoice=${invoice#inv-}
    amount=$(awk -v c="$cents" 'BEGIN { printf "%.2f", c / 100 }')
    printf '# Invoice %s paid — %s USD\n\n%s settled invoice %s.\n' \
      "$invoice" "$amount" "$customer" "$invoice" | post_memo
    ;;
  *)
    return 1
    ;;
  esac
}

main() {
  if [ -z "$WORLD" ] || [ ! -r "$WORLD/timeline.json" ]; then
    echo "[droplive] no world timeline; nothing will arrive" >&2
    return 0
  fi

  events=$(awk -v mode=list -f "$READER" "$WORLD/timeline.json" 2>/dev/null | sort -n)
  if [ -z "$events" ]; then
    echo "[droplive] the world timeline has no events" >&2
    return 0
  fi

  password="${MEMOS_OWNER_PASSWORD:-}"
  [ -n "$password" ] || { echo "[droplive] no owner password; nothing will arrive" >&2; return 0; }

  TOKEN=$(wget -q -T 10 -O - \
    --header 'content-type: application/json' \
    --post-data "{\"passwordCredentials\":{\"username\":\"maya\",\"password\":\"$password\"}}" \
    "$BASE/api/v1/auth/signin" 2>/dev/null |
    sed -n 's/.*"accessToken":[[:space:]]*"\([^"]*\)".*/\1/p')
  [ -n "$TOKEN" ] || { echo "[droplive] could not sign in; nothing will arrive" >&2; return 0; }

  touch "$DONE" 2>/dev/null || true
  anchor=$(date +%s)
  delivered=0

  # Only what the timeline declares, in the order it declares, and nothing after
  # the last one: this exits rather than waiting for something that will not come.
  printf '%s\n' "$events" | while IFS='	' read -r after id kind; do
    [ -n "$id" ] || continue

    if grep -qxF "$id" "$DONE" 2>/dev/null; then
      continue
    fi

    now=$(date +%s)
    remaining=$((anchor + after - now))
    if [ "$remaining" -gt 0 ]; then
      sleep "$remaining"
    fi

    if deliver "$id" "$kind"; then
      printf '%s\n' "$id" >>"$DONE"
      echo "[droplive] arrived: $id ($kind)" >&2
      delivered=$((delivered + 1))
    else
      # An unsupported kind, or one this app cannot say honestly. Recorded so a
      # restart does not reconsider it, and the demo carries on.
      printf '%s\n' "$id" >>"$DONE"
      echo "[droplive] skipped: $id ($kind) -- nothing this notebook can say" >&2
    fi
  done

  echo "[droplive] the timeline is finished" >&2
}

main "$@"
