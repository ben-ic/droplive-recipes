<?php
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
if ($path === '/healthz') {
    header('Content-Type: text/plain'); echo 'ready'; return true;
}
// Use SnappyMail's native, single-use SSO ticket. Provider credentials stay
// outside the web root. The marker is not an authentication cookie.
if (($path === '/demo-login' && $_SERVER['REQUEST_METHOD'] === 'GET') ||
    ($path === '/' && empty($_SERVER['QUERY_STRING']) && empty($_COOKIE['droplive_mail_opened']))) {
    header('Content-Type: text/html; charset=utf-8');
    header('Cache-Control: no-store');
    echo '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Northstar mail</title><style>body{font:18px system-ui;max-width:520px;margin:12vh auto;padding:24px;color:#173042}button{font:inherit;background:#195a87;color:white;border:0;border-radius:6px;padding:12px 20px;cursor:pointer}</style><h1>Northstar mail</h1><p>Open Maya Chen’s mailbox to read company email or send a message within the demo.</p><form method="post" action="/demo-login"><button>Open mailbox</button></form></html>';
    return true;
}
if ($path === '/demo-login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $_ENV['SNAPPYMAIL_INCLUDE_AS_API'] = true;
    require '/snappymail/index.php';
    $b = json_decode(file_get_contents('/data/snappymail/bindings.json'), true, 512, JSON_THROW_ON_ERROR);
    $hash = \RainLoop\Api::CreateUserSsoHash($b['IMAP_USERNAME'], $b['IMAP_PASSWORD']);
    if (!$hash) { http_response_code(503); echo 'Mailbox login is not ready'; return true; }
    setcookie('droplive_mail_opened', '1', ['path'=>'/', 'httponly'=>true, 'samesite'=>'Lax']);
    header('Cache-Control: no-store');
    header('Location: /?sso&hash='.rawurlencode($hash), true, 303);
    return true;
}
// Never let the development server serve a PHP include or hidden file as data.
if ($path === '/include.php' || str_contains($path, '/.')) { http_response_code(404); return true; }
return false;
