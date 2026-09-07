# WorldFixture workbench links

Filestash, S3 Manager, SnappyMail, and Node-RED now declare `DROPLIVE_WORKBENCH_PORT: "4715"` as a non-secret Compose environment literal. This is an explicit opt-in to DropLive's existing session-service route and link pattern. It requires the platform change in https://github.com/ben-ic/droplive-tryfirst/pull/7 . Deploy that change before these recipe versions are offered.

The workbench uses a separate `workbench--<session hostname>` origin and the same Firecracker guest. The existing session lifecycle removes its route and link. Old recipes without this declaration retain their existing profile surfaces.

The pinned WorldFixture 0.2.5 CLI already starts the workbench on `0.0.0.0:4715` in single-container mode for Filestash, S3 Manager, and SnappyMail. Node-RED's direct-runtime adapter now starts `startWorkbench` with its existing provider instance and closes it during shutdown. No second emulator instance is started. Datasette uses a fixed SQLite snapshot and has no live workbench.

Validation: the recipe parser retains all four workbench literals; all 56 recipe lint errors match the existing baseline. The updated Node-RED amd64 image built, and its local workbench showed the three active providers and populated GitHub data. Exact public Firecracker app/workbench reviews and production release remain required.
