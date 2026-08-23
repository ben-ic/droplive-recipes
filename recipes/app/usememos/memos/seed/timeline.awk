# Read the world's timeline.json without a JSON tool.
#
# BusyBox awk and wget are the only things in this image, so the timeline is
# scanned rather than parsed: the file is a flat array of objects, each with
# `id`, `kind`, `after_seconds` and a `payload` object of scalars, and that is
# the whole shape this has to understand.
#
#   -v mode=list           print "after_seconds<TAB>id<TAB>kind" per event
#   -v mode=field          print one payload field of one event, decoded
#   -v want=<event id>     which event, for mode=field
#   -v field=<name>        which payload key, for mode=field
#
# A field is printed exactly as the world wrote it, newlines included, which is
# why it is fetched one at a time instead of being packed into the list.

function decode(s,   out, i, c, n) {
    out = ""
    n = length(s)
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (c == "\\" && i < n) {
            i++
            c = substr(s, i, 1)
            if (c == "n") out = out "\n"
            else if (c == "t") out = out "\t"
            else if (c == "r") out = out "\r"
            else if (c == "u") { i += 4 }          # not used by this world
            else out = out c
        } else {
            out = out c
        }
    }
    return out
}

# Walk the whole file once, tracking depth and string state, so a brace or a
# quote inside a body cannot be mistaken for structure.
{ text = text $0 "\n" }

END {
    depth = 0; instr = 0; esc = 0
    start = 0
    n = length(text)
    for (i = 1; i <= n; i++) {
        c = substr(text, i, 1)
        if (instr) {
            if (esc) esc = 0
            else if (c == "\\") esc = 1
            else if (c == "\"") instr = 0
            continue
        }
        if (c == "\"") { instr = 1; continue }
        if (c == "{") { depth++; if (depth == 1) start = i; continue }
        if (c == "}") {
            depth--
            if (depth == 0 && start > 0) {
                emit(substr(text, start, i - start + 1))
                start = 0
            }
            continue
        }
    }
}

# One event object. Its own `payload` is nested, but every key this needs is
# unique within the object, so a keyed scan is enough and no nesting is walked.
function emit(obj,   id, kind, after, value) {
    id = scalar(obj, "id")
    kind = scalar(obj, "kind")
    after = scalar(obj, "after_seconds")
    if (id == "" || kind == "") return
    if (mode == "list") {
        if (after == "") after = "0"
        print after "\t" id "\t" kind
        return
    }
    if (mode == "field" && id == want) {
        value = scalar(obj, field)
        if (value != "") print decode(value)
    }
}

# The value of "<key>": in this object, as raw JSON text. Strings come back
# without their quotes; numbers come back as written.
function scalar(obj, key,   at, rest, c, i, out, esc2) {
    at = index(obj, "\"" key "\":")
    if (at == 0) return ""
    rest = substr(obj, at + length(key) + 3)
    sub(/^[ \t\n]+/, "", rest)
    if (substr(rest, 1, 1) == "\"") {
        out = ""; esc2 = 0
        for (i = 2; i <= length(rest); i++) {
            c = substr(rest, i, 1)
            if (esc2) { out = out "\\" c; esc2 = 0; continue }
            if (c == "\\") { esc2 = 1; continue }
            if (c == "\"") break
            out = out c
        }
        return out
    }
    out = ""
    for (i = 1; i <= length(rest); i++) {
        c = substr(rest, i, 1)
        if (c ~ /[0-9.-]/) out = out c
        else break
    }
    return out
}
