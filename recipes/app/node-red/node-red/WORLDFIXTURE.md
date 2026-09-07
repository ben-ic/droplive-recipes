# WorldFixture provider workflows

This recipe starts pinned WorldFixture 0.2.5 GitHub, Slack, and Notion providers inside the same guest as Node-RED. Generated tokens stay in process configuration and a private bindings file. The flow JSON contains no credentials.

The two manual flows read real emulator data and make synthetic writes:

- GitHub to Slack: read open repository issues, post a channel summary, and read the message back.
- Notion to GitHub: read a page and its blocks, create an issue, and read the issue back.

The world clock stays paused. The recipe does not require external provider accounts. Node-RED keeps its Node 20 runtime; WorldFixture uses the separately pinned Node 22 executable.

CLI 0.2.5 cannot select Notion by name. The launcher therefore uses the pinned internal `loadManifests`, `resolveEnvironment`, and `start` functions to select the exact provider capabilities. This is an upgrade dependency. The app stops if a provider process stops.

Local browser runs of both flows and independent API readback passed. A fresh second instance did not contain the first instance's writes. Runtime syntax checks pass. The current recipe lint has 57 existing errors elsewhere; this change removes Node-RED's stale world-reference error. Public sandbox review and production release remain required.

Known limit: seeded Notion page URL strings are malformed in this WorldFixture pin. These flows use page IDs and do not open those URLs. Timeline events, OAuth, webhooks, full pagination, and reset during an active app session have not been tested.

## Workbench

`compose.yaml` declares the non-secret `DROPLIVE_WORKBENCH_PORT=4715` runtime literal. DropLive uses that explicit declaration to show **Open workbench** under the session services, on a separate hostname in the same guest. It does not change old recipes that omit the declaration.

This adapter also imports `startWorkbench` from `/opt/worldfixture/runtime/src/workbench.mjs` and attaches it to the same running GitHub, Slack, and Notion instance. It closes the workbench when the app stops. The clock remains paused as before; the workbench has no scheduler timeline from this direct-runtime adapter. Local amd64 image build, workbench overview, and populated GitHub view passed. Updated Firecracker and production browser review remain pending.
