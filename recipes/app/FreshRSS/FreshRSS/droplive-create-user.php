<?php
declare(strict_types=1);

require('/var/www/FreshRSS/cli/_cli.php');
performRequirementCheck(FreshRSS_Context::systemConf()->db['type'] ?? '');

if (in_array('maya', listUsers(), true)) {
    exit(0);
}
$password = getenv('FRESHRSS_PASSWORD') ?: '';
if ($password === '') {
    fwrite(STDERR, "FreshRSS password is absent\n");
    exit(64);
}
$email = 'maya.chen@example.invalid';
$ok = FreshRSS_user_Controller::createUser(
    'maya',
    $email,
    $password,
    ['language' => 'en', 'mail_login' => $email],
    false
);
if (!$ok) {
    fwrite(STDERR, "FreshRSS owner creation failed\n");
    exit(1);
}
accessRights();
