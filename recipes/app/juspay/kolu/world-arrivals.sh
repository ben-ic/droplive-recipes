#!/usr/bin/env bash
set -euo pipefail

log=/workspace/northstar-relay/var/activity.log

sleep 8
printf '%s\n' '[8s · release] Maya: 75k export passed in 141s; cancellation cleanup remains the gate.' >> "$log"
sleep 10
printf '%s\n' '[18s · support] Imani: Lumen received the manual-retry steps and confirmed the export started.' >> "$log"
sleep 12
printf '%s\n' '[30s · engineering] Noor: issue 319 reproduces only when cancellation lands after multipart upload.' >> "$log"
sleep 14
printf '%s\n' '[44s · review] Elena: worker lease-age telemetry is ready for review in relay-core.' >> "$log"
sleep 16
printf '%s\n' '[60s · audit] Hana: account-time-zone labels pass the isolated audit-log checks.' >> "$log"
sleep 20
printf '%s\n' '[80s · release] Samira: the cancellation fixture is now part of the Release 2.8 gate.' >> "$log"
