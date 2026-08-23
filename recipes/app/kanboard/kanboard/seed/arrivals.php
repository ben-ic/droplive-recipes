<?php
// Deliver the world's timeline onto the boards while the visitor is watching.
//
// The platform mounts one read-only world artifact per session and points
// DROPLIVE_WORLD_PATH at it. That artifact carries timeline.json: a short list of
// things that happen after the demo opens, each with its own delay. This turns
// the ones a kanban board can honestly show into comments on the cards they are
// about, through the same application API the seed uses.
//
// WHICH KINDS THIS BOARD CAN REPRESENT HONESTLY: chat-message, and only that.
//
//   chat-message  A named person saying something about a piece of work, and the
//                 payload names the work: entity_refs.issue_id. The board already
//                 carries that person's earlier messages as comments on that same
//                 card, so the arrival is the next one. Nothing is invented --
//                 the author, the words and the card all come from the world.
//
//   incoming-email  Skipped. A board is not a mailbox. There is no card that is a
//                 customer's inbox, and the sender is not a board user, so the
//                 only way to show it would be to attribute a customer's email to
//                 a member of staff.
//
//   webhook       Skipped. Kanboard requires an author for every comment and a
//                 webhook has none. Signing a payment notification with somebody's
//                 name would be putting words in their mouth, and there is no
//                 "system" account on these boards to sign it with instead.
//
// A version of this that showed all three would be a better demo and a worse
// record of what happened.

const DONE_FILE = '/var/www/app/data/droplive-arrivals.done';
const ENDPOINT  = 'http://127.0.0.1/jsonrpc.php';

function log_line(string $message): void {
    fwrite(STDERR, "[droplive] $message\n");
}

function rpc(string $token, string $method, array $params) {
    $body = json_encode([
        'jsonrpc' => '2.0',
        'id'      => 1,
        'method'  => $method,
        'params'  => $params,
    ]);
    $handle = curl_init(ENDPOINT);
    curl_setopt_array($handle, [
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $body,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
        CURLOPT_USERPWD        => 'jsonrpc:' . $token,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 30,
    ]);
    $answer = curl_exec($handle);
    curl_close($handle);
    if ($answer === false) {
        return null;
    }
    $decoded = json_decode($answer, true);
    return $decoded['result'] ?? null;
}

function read_json(string $path) {
    if (!is_readable($path)) {
        return null;
    }
    $decoded = json_decode((string) file_get_contents($path), true);
    return is_array($decoded) ? $decoded : null;
}

// The title of the issue an arrival is about. The world is the only place that
// knows it, and the card the seed made carries the same title.
function issue_title(array $world, string $issueId): ?string {
    foreach ($world['software']['repositories'] ?? [] as $repository) {
        foreach ($repository['issues'] ?? [] as $issue) {
            if (($issue['id'] ?? null) === $issueId) {
                return $issue['title'] ?? null;
            }
        }
    }
    return null;
}

// The card that tracks it. Looked up by title rather than remembered from the
// seed, because a card id belongs to this session's database and nothing the
// recipe writes down would survive it.
function find_task(string $token, string $title): ?array {
    $projects = rpc($token, 'getAllProjects', []);
    if (!is_array($projects)) {
        return null;
    }
    foreach ($projects as $project) {
        $tasks = rpc($token, 'getAllTasks', ['project_id' => (int) $project['id'], 'status_id' => 1]);
        foreach (is_array($tasks) ? $tasks : [] as $task) {
            if (($task['title'] ?? null) === $title) {
                return $task;
            }
        }
    }
    return null;
}

// The board's account for the person the world names. Their username is the
// first part of their id, which is the rule the seed created them under, and it
// is checked against the board rather than assumed.
function find_user(string $token, string $personId): ?array {
    $username = explode('-', $personId)[0];
    $user = rpc($token, 'getUserByName', ['username' => $username]);
    return is_array($user) && isset($user['id']) ? $user : null;
}

function deliver(string $token, array $world, array $event): bool {
    if (($event['kind'] ?? null) !== 'chat-message') {
        return false;
    }
    $payload = $event['payload'] ?? [];
    $issueId = $payload['entity_refs']['issue_id'] ?? null;
    $authorId = $payload['author_id'] ?? null;
    $text = $payload['text'] ?? null;
    if (!$issueId || !$authorId || !$text) {
        return false;
    }

    $title = issue_title($world, $issueId);
    if ($title === null) {
        return false;
    }
    $task = find_task($token, $title);
    if ($task === null) {
        return false;
    }
    $user = find_user($token, $authorId);
    if ($user === null) {
        return false;
    }

    $result = rpc($token, 'createComment', [
        'task_id' => (int) $task['id'],
        'user_id' => (int) $user['id'],
        'content' => $text,
    ]);
    return $result !== null && $result !== false;
}

function main(): void {
    $worldPath = getenv('DROPLIVE_WORLD_PATH') ?: '';
    $timeline = $worldPath === '' ? null : read_json($worldPath . '/timeline.json');
    if (!is_array($timeline) || $timeline === []) {
        log_line('no world timeline; nothing will arrive');
        return;
    }
    $world = read_json($worldPath . '/world.json');
    if (!is_array($world)) {
        log_line('the world has no readable world.json; nothing will arrive');
        return;
    }

    // Opened read-only through a URI, so no journal file appears beside the
    // database. A root-owned journal there makes the whole database read-only
    // for the web server that has to write to it, which is the one way a reader
    // can break a running Kanboard.
    $token = '';
    try {
        $database = new PDO('sqlite:file:/var/www/app/data/db.sqlite?mode=ro');
        $token = (string) $database
            ->query("select value from settings where option = 'api_token'")
            ->fetchColumn();
        $database = null;
    } catch (Throwable $error) {
        $token = '';
    }
    if ($token === '') {
        log_line('no application API token; nothing will arrive');
        return;
    }

    usort($timeline, static fn(array $left, array $right) =>
        ($left['after_seconds'] ?? 0) <=> ($right['after_seconds'] ?? 0));

    $delivered = [];
    if (is_readable(DONE_FILE)) {
        $delivered = array_flip(array_filter(
            array_map('trim', explode("\n", (string) file_get_contents(DONE_FILE)))));
    }

    $anchor = time();
    // Only what the timeline declares, in the order it declares, and nothing
    // after the last one. This returns rather than waiting for what will not come.
    foreach ($timeline as $event) {
        $id = $event['id'] ?? null;
        if (!is_string($id) || $id === '') {
            continue;
        }
        if (isset($delivered[$id])) {
            continue;
        }

        $remaining = $anchor + (int) ($event['after_seconds'] ?? 0) - time();
        if ($remaining > 0) {
            sleep($remaining);
        }

        $kind = (string) ($event['kind'] ?? 'unknown');
        if (deliver($token, $world, $event)) {
            log_line("arrived: $id ($kind)");
        } else {
            // An unsupported kind, or one this board cannot say honestly.
            // Recorded so a restart does not reconsider it.
            log_line("skipped: $id ($kind) -- nothing this board can say");
        }
        file_put_contents(DONE_FILE, $id . "\n", FILE_APPEND);
    }

    log_line('the timeline is finished');
}

main();
