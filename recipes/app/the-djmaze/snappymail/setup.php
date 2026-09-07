<?php
$_ENV['SNAPPYMAIL_INCLUDE_AS_API'] = true;
require '/snappymail/index.php';
set_exception_handler(function (Throwable $e) { fwrite(STDERR, $e->getMessage().'\n'); exit(1); });
$b = json_decode(file_get_contents('/data/snappymail/bindings.json'), true, 512, JSON_THROW_ON_ERROR);
[$imapHost, $imapPort] = explode(':', $b['IMAP_HOST_PORT']);
[$smtpHost, $smtpPort] = explode(':', $b['SMTP_HOST_PORT']);
$domain = substr(strrchr($b['IMAP_USERNAME'], '@'), 1);
$config = \RainLoop\Api::Config();
$config->Set('security', 'allow_admin_panel', false);
$config->Set('login', 'default_domain', $domain);
$config->Set('contacts', 'enable', false);
$config->Set('webmail', 'title', 'Northstar mail');
$config->Save();
$d = \RainLoop\Model\Domain::fromArray($domain, [
    'IMAP' => ['host'=>$imapHost, 'port'=>(int)$imapPort, 'type'=>0, 'shortLogin'=>false],
    'SMTP' => ['host'=>$smtpHost, 'port'=>(int)$smtpPort, 'type'=>0, 'shortLogin'=>false, 'useAuth'=>true],
    'Sieve' => ['enabled'=>false, 'host'=>'127.0.0.1', 'port'=>4190, 'type'=>0], 'whiteList'=>'',
]);
$provider = new \RainLoop\Providers\Domain\DefaultDomain(APP_PRIVATE_DATA.'domains');
if (!$provider->Save($d)) throw new RuntimeException('Cannot save mailbox domain');

if (!$provider->Load($domain)) throw new RuntimeException('Mailbox domain was not saved');
