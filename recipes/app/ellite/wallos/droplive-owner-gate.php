<?php
// Applied to every PHP request by a tiny ini override; only first registration
// is gated. CLI lifecycle commands and established installations return here.
if (PHP_SAPI === 'cli') {
    return;
}

$script = basename(parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?? '');
if ($script !== 'registration.php') {
    return;
}

try {
    $gateDb = new SQLite3('/var/www/html/db/wallos.db', SQLITE3_OPEN_READONLY);
    $gateDb->busyTimeout(3000);
    $gateUserCount = (int) $gateDb->querySingle('SELECT COUNT(*) FROM user');
    $gateDb->close();
} catch (Throwable $error) {
    http_response_code(503);
    exit('Owner setup is not ready.');
}

if ($gateUserCount > 0) {
    return;
}

$gateExpected = trim((string) @file_get_contents('/run/wallos/owner-setup.sha256'));
$gateCookie = $_COOKIE['droplive_owner_setup'] ?? '';
if (strlen($gateExpected) === 64 && is_string($gateCookie) &&
    hash_equals($gateExpected, $gateCookie)) {
    return;
}

header('Cache-Control: no-store');
header('Location: /droplive-owner-setup.php', true, 302);
exit;
