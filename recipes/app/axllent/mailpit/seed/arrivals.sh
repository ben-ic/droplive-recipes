#!/bin/sh
# Deliver the world's timeline into the mailbox while the visitor is watching.
#
# The platform mounts one read-only world artifact per session and points
# DROPLIVE_WORLD_PATH at it. That artifact carries timeline.json: a short list of
# things that happen after the demo opens, each with its own delay. This delivers
# the ones that are mail, over SMTP, through `mailpit sendmail` -- the command
# Mailpit documents for exactly this. Nothing here writes to its store.
#
# WHICH KINDS THIS APP CAN REPRESENT HONESTLY: incoming-email, and only that.
#
#   incoming-email  Mailpit is a mail server. An incoming email is not something
#                   the recipe has to represent as anything -- it is the object
#                   this application holds. It arrives the way every other message
#                   in this mailbox arrived, over SMTP, and the inbox count moves
#                   while the visitor is looking at it.
#
#   chat-message    Skipped. A message in a team channel is not an email. Turning
#                   one into an email would put a message in this mailbox that
#                   nobody ever sent, and a mail tool whose contents are invented
#                   is worse than one that is merely quiet.
#
#   webhook         Skipped, for the same reason. A payment notification is not
#                   correspondence.
set -eu

WORLD="${DROPLIVE_WORLD_PATH:-}"
READER=/usr/local/lib/droplive-mailpit-timeline.awk
SMTP="127.0.0.1:1025"
API="http://127.0.0.1:${MP_HTTP_PORT:-8025}"

# The world's people at the addresses this mailbox already knows them by. Written
# out rather than derived, because the staff and the customers are on different
# domains and no rule reads that off an id.
address() {
  case "$1" in
  maya-chen) echo "Maya Chen <maya@northstar-relay.invalid>" ;;
  jon-bell) echo "Jon Bell <jon@northstar-relay.invalid>" ;;
  noor-alvarez) echo "Noor Alvarez <noor@northstar-relay.invalid>" ;;
  elena-petrov) echo "Elena Petrov <elena@northstar-relay.invalid>" ;;
  samira-okafor) echo "Samira Okafor <samira@northstar-relay.invalid>" ;;
  lucas-meyer) echo "Lucas Meyer <lucas@northstar-relay.invalid>" ;;
  hana-ito) echo "Hana Ito <hana@northstar-relay.invalid>" ;;
  david-banerjee) echo "David Banerjee <david@northstar-relay.invalid>" ;;
  imani-brooks) echo "Imani Brooks <imani@northstar-relay.invalid>" ;;
  theo-martin) echo "Theo Martin <theo@northstar-relay.invalid>" ;;
  priya-raman) echo "Priya Raman <priya@lumen-labs.invalid>" ;;
  *) echo "" ;;
  esac
}

bare() {
  printf '%s' "$1" | sed -n 's/.*<\([^>]*\)>.*/\1/p'
}

# Whether this event's message is already in the mailbox, asked by the
# Message-ID it was delivered under.
already_here() {
  # `total` in a search answer is the size of the whole mailbox, not the number
  # of matches -- reading it says every message is already here and nothing ever
  # arrives. `messages_count` is the count of what matched.
  wget -q -T 5 -O - "$API/api/v1/search?query=$1" 2>/dev/null |
    grep -q '"messages_count":[1-9]'
}

field() {
  awk -v mode=field -v want="$1" -v field="$2" -f "$READER" "$WORLD/timeline.json" 2>/dev/null
}

deliver() {
  id=$1
  kind=$2
  [ "$kind" = "incoming-email" ] || return 1

  from=$(address "$(field "$id" from_id)")
  to=$(address "$(field "$id" to_id)")
  subject=$(field "$id" subject)
  body=$(field "$id" body_text)
  [ -n "$from" ] && [ -n "$to" ] && [ -n "$subject" ] || return 1

  # Written as a message and handed to SMTP, so Mailpit parses it the way it
  # parses every other message it receives. The date is now, because that is
  # when this arrived -- it is the one thing about it that is not from the world.
  {
    printf 'Message-ID: <%s@northstar-relay.invalid>\n' "$id"
    printf 'Date: %s\n' "$(date -R 2>/dev/null || date)"
    printf 'From: %s\n' "$from"
    printf 'To: %s\n' "$to"
    printf 'Subject: %s\n' "$subject"
    printf 'Content-Type: text/plain; charset="utf-8"\n'
    printf 'MIME-Version: 1.0\n'
    printf '\n'
    printf '%s\n' "$body"
  } | /mailpit sendmail --smtp-addr "$SMTP" -f "$(bare "$from")" "$(bare "$to")" 2>/dev/null
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

  anchor=$(date +%s)

  # Only what the timeline declares, and nothing after the last one.
  printf '%s\n' "$events" | while IFS='	' read -r after id kind; do
    [ -n "$id" ] || continue
    # ASKED OF MAILPIT, NOT OF A FILE. Mailpit is given no database, so a
    # restart begins with an empty mailbox and the seed ingests the Northstar
    # mail again -- but the container's filesystem survives that restart, so a
    # file recording what had arrived would outlive the messages it described
    # and the arrivals would be skipped into a mailbox that no longer had them.
    # Every message carries its event id as its Message-ID, so the mailbox is
    # its own record of what it holds and the two can never disagree.
    if already_here "$id"; then
      continue
    fi

    now=$(date +%s)
    remaining=$((anchor + after - now))
    if [ "$remaining" -gt 0 ]; then
      sleep "$remaining"
    fi

    if deliver "$id" "$kind"; then
      echo "[droplive] arrived: $id ($kind)" >&2
    else
      echo "[droplive] skipped: $id ($kind) -- not mail" >&2
    fi
  done

  echo "[droplive] the timeline is finished" >&2
}

main "$@"
