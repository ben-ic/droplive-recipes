<?php
declare(strict_types=1);

$target = $argv[1] ?? '';
$feed = getenv('DROPLIVE_FEED_URL') ?: '';
if ($target === '' || filter_var($feed, FILTER_VALIDATE_URL) === false) {
    fwrite(STDERR, "Invalid DropLive RSS binding\n");
    exit(64);
}
$escaped = htmlspecialchars($feed, ENT_XML1 | ENT_QUOTES, 'UTF-8');
$document = <<<XML
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head><title>Northstar company briefing</title></head>
  <body>
    <outline text="Northstar" title="Northstar">
      <outline type="rss" text="Company briefing" title="Company briefing" xmlUrl="{$escaped}" htmlUrl="{$escaped}"/>
    </outline>
  </body>
</opml>
XML;
if (file_put_contents($target, $document) === false) {
    fwrite(STDERR, "Could not write FreshRSS import\n");
    exit(1);
}
